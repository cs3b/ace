# frozen_string_literal: true

require "yaml"
require_relative "commission_orchestrator"

module Ace
  module Coworker
    module Organisms
      # Writes the planner's per-role start configs (L4.3) into the
      # prepared worktree: `.ace-local/coworker/prepare/<role>.yml`, ONE
      # file per sequence leg. Every config is expanded by the SAME
      # commission primitive that writes the default `config.yml`, so the
      # round-trip guarantee ("what commission writes, start accepts")
      # holds by construction and the ownership split stays one writer per
      # file: `prepare` owns `prepare/<role>.yml`; the default config.yml
      # (or any `--config` target) remains `commission`'s alone.
      # Idempotent: a leg whose file already holds the identical content
      # is reported as "reused" without a write; changed content (e.g. a
      # different overseer) is overwritten deterministically ("updated") —
      # prepare is the single writer of these files. No secrets, no
      # assignment steps: only the seven documented config fields.
      class StartConfigWriter
        PREPARE_DIR = File.join(".ace-local", "coworker", "prepare")

        # @param worktree_path [String] absolute path of the prepared worktree
        # @param commission_factory [#call] test seam building a
        #   CommissionOrchestrator for (worktree_path, target)
        def initialize(worktree_path:, commission_factory: nil)
          @worktree_path = worktree_path
          @commission_factory = commission_factory || method(:default_commission)
        end

        # @param task [String] canonical task id
        # @param sequence [Array<Hash>] composed role-sequence entries
        #   ({"role" =>, "assignment" =>, …} from RoleSequenceComposer)
        # @param overseer [String] reporting address for every leg
        # @param dry_run [Boolean] resolve and validate without writes
        # @return [Array<Hash>] {"role", "assignment", "path", "disposition"}
        #   disposition: "created" | "reused" | "updated" | "planned" (dry-run)
        # @raise [Error] when a leg cannot be commissioned (unknown role,
        #   task/assignment mismatch, invalid assembly)
        def call(task:, sequence:, overseer:, dry_run: false)
          Array(sequence).map do |entry|
            role = entry["role"]
            assignment = entry["assignment"]
            target = File.join(@worktree_path, PREPARE_DIR, "#{role}.yml")

            commission = @commission_factory.call(@worktree_path, target)
            # dry-run commission call resolves, identity-checks, and
            # schema-validates the leg config without touching the disk.
            resolved = commission.call(role: role, task: task, assignment: assignment,
              overseer: overseer, force: true, dry_run: true)
            content = YAML.safe_dump(resolved.config)

            existing = File.file?(target) ? File.read(target) : nil
            disposition = if dry_run
              "planned"
            elsif existing == content
              "reused"
            else
              commission.call(role: role, task: task, assignment: assignment,
                overseer: overseer, force: true, dry_run: false)
              existing.nil? ? "created" : "updated"
            end

            {"role" => role, "assignment" => assignment,
             "path" => File.join(PREPARE_DIR, "#{role}.yml"), "disposition" => disposition}
          end
        end

        private

        def default_commission(worktree_path, target)
          CommissionOrchestrator.new(
            project_root: worktree_path,
            preset_loader: Molecules::RolePresetLoader.new(project_root: worktree_path),
            task_probe: Molecules::TaskProbe.new(project_root: worktree_path),
            assignment_metadata: Molecules::AssignmentMetadata.new(project_root: worktree_path),
            config_path: target)
        end
      end
    end
  end
end
