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
          validate_role_names!(Array(sequence))

          # Pre-resolve EVERY leg first (dry-run commission pass): a late
          # leg failure must not leave earlier leg configs on disk — the
          # same all-or-nothing pattern RoleSequenceComposer established.
          # Legs composed under dry_run (a planned sequence, no assignment
          # id yet) cannot be identity-checked against ace-assign, so they
          # are planned as-is; a real run requires a composed assignment.
          resolved_legs = Array(sequence).map do |entry|
            unless dry_run || !entry["assignment"].to_s.strip.empty?
              raise Error, "role '#{entry['role']}' has no composed assignment; " \
                "compose the sequence (prepare without --dry-run) before writing its start config"
            end

            entry = entry.dup
            entry["task"] = task
            entry["overseer"] = overseer
            entry["resolved_config"] =
              entry["assignment"].to_s.strip.empty? ? nil : resolve_leg(entry)
            entry
          end

          resolved_legs.map { |entry| write_leg(entry, dry_run: dry_run) }
        end

        private

        def validate_role_names!(sequence)
          sequence.each do |entry|
            role = entry["role"].to_s
            unless role.match?(/\A[\w.-]+\z/) && !role.match?(/\A\.+\z/)
              raise Error, "invalid role name '#{role}' for start config"
            end
          end
        end

        def resolve_leg(entry)
          commission = @commission_factory.call(@worktree_path,
            target_path(entry["role"]))
          # dry-run commission resolves, identity-checks, and schema-validates
          # the leg config without touching the disk.
          resolved = commission.call(role: entry["role"], task: entry["task"],
            assignment: entry["assignment"], overseer: entry["overseer"],
            force: true, dry_run: true)
          YAML.safe_dump(resolved.config)
        end

        def target_path(role)
          File.join(@worktree_path, PREPARE_DIR, "#{role}.yml")
        end

        def write_leg(entry, dry_run:)
          role = entry["role"]
          content = entry["resolved_config"]
          target = target_path(role)

          existing = File.file?(target) ? File.read(target) : nil
          disposition = if dry_run
            "planned"
          elsif existing == content
            "reused"
          else
            commission = @commission_factory.call(@worktree_path, target)
            commission.call(role: role, task: entry["task"],
              assignment: entry["assignment"], overseer: entry["overseer"],
              force: true, dry_run: false)
            existing.nil? ? "created" : "updated"
          end

          {"role" => role, "assignment" => entry["assignment"],
           "path" => File.join(PREPARE_DIR, "#{role}.yml"), "disposition" => disposition}
        end

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
