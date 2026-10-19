# frozen_string_literal: true

require "yaml"

module Ace
  module Overseer
    module Molecules
      # Read-only probe of a task worktree's handoff truth (L6.4): the
      # ordered role-sequence legs for the task (ace-assign's own
      # assignment files, ordered by creation — the order the planner
      # composed them in), each leg's real assignment state, the role of
      # each leg (from the per-role start configs ace-coworker prepare
      # wrote), and the worktree's executor truth (commissioned config +
      # assignment inventory) via the SAME coworker probe/ rule prepare
      # uses — one active-executor concept, no second copy. Writes
      # nothing; owns no state (ADR-034).
      class HandoffProbe
        ASSIGN_DIR = File.join(".ace-local", "assign")
        # Reuse the coworker-owned location constant: one definition of
        # where prepare writes per-role start configs.
        PREPARE_DIR = Ace::Coworker::Organisms::StartConfigWriter::PREPARE_DIR

        # @param executor_probe [#probe] WorktreeExecutorProbe-compatible
        #   seam (defaults to the coworker probe anchored at the probed
        #   worktree)
        def initialize(executor_probe: nil)
          @executor_probe = executor_probe
        end

        # @param worktree_path [String] the task worktree
        # @param task_id [String] canonical task id
        # @return [Hash] {legs: Array<{"role" => String|nil,
        #   "assignment" => String, "name" => String, "state" => String}>,
        #   executor: {config:, assignments:}} in sequence order
        # @raise [Error] when the assignment inventory cannot be read
        def probe(worktree_path, task_id:)
          executor = executor_probe(worktree_path).probe(worktree_path)
          states = executor[:assignments].to_h { |a| [a["id"].to_s, a["state"].to_s] }
          roles = prepare_roles(worktree_path)

          legs = sequence_assignments(worktree_path, task_id).map do |record|
            mapping = roles[record["id"]] || {}
            {
              "role" => mapping["role"],
              "start_config" => mapping["start_config"],
              "assignment" => record["id"],
              "name" => record["name"],
              "state" => states.fetch(record["id"], "")
            }
          end
          {legs: legs, executor: executor}
        end

        private

        def executor_probe(worktree_path)
          @executor_probe || Ace::Coworker::Molecules::WorktreeExecutorProbe.new(project_root: worktree_path)
        end

        # The task's role-sequence assignments from ace-assign's own
        # files ("<task>-<role>" with task_id), in composition order
        # (created_at, then id as a stable tie-breaker).
        def sequence_assignments(worktree_path, task_id)
          Dir.glob(File.join(worktree_path, ASSIGN_DIR, "*", "assignment.yaml")).filter_map do |path|
            data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
            next unless data.is_a?(Hash) && data["task_id"].to_s == task_id

            {"id" => File.basename(File.dirname(path)), "name" => data["name"].to_s,
             "created_at" => data["created_at"]}
          end.sort_by { |record| [record["created_at"].to_s, record["id"]] }
        end

        # assignment id -> {"role" =>, "start_config" => relative path},
        # from the per-leg start configs
        # (.ace-local/coworker/prepare/<role>.yml). An unreadable config,
        # or one without BOTH a non-empty assignment id and a non-empty
        # role, contributes nothing: its leg keeps role nil and the
        # handoff gate refuses to start it instead of guessing. The
        # carried start_config is the actually-globbed file path, so a
        # ready verdict can never point at a nonexistent config.
        def prepare_roles(worktree_path)
          Dir.glob(File.join(worktree_path, PREPARE_DIR, "*.yml")).filter_map do |path|
            data = begin
              YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
            rescue StandardError
              next
            end
            next unless data.is_a?(Hash)

            assignment = data["assignment"].to_s
            role = data["role"].to_s
            next if assignment.empty? || role.strip.empty?

            [assignment, {"role" => role,
                          "start_config" => File.join(PREPARE_DIR, File.basename(path))}]
          end.to_h
        end
      end
    end
  end
end
