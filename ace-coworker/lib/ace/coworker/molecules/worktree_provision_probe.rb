# frozen_string_literal: true

require "ace/git/worktree"
require_relative "../atoms/prepare_decision"

module Ace
  module Coworker
    module Molecules
      # Wraps the worktree owner (ace-git-worktree) for the preparation
      # decision procedure: association-aware find (switch), idempotent
      # create, and stale-metadata recovery (prune + recreate, mirroring
      # the proven ace-overseer provisioner pattern). Returns structured
      # disposition hashes; never raises for expected outcomes.
      class WorktreeProvisionProbe
        def initialize(project_root:, manager: nil)
          @project_root = project_root
          @manager = manager || Ace::Git::Worktree::Organisms::WorktreeManager.new(project_root: project_root)
        end

        # Runs the find/prepare/recover flow for one task.
        #
        # @return [Hash] {disposition:, reason:, worktree_path:, branch:}
        #   disposition: :created | :recovered | :reuse | :conflict_mismatch |
        #   :error | :would_create | :would_recover
        def ensure_prepared(task_ref:, expected_task_id:, dry_run: false)
          decision = locate(task_ref: task_ref, expected_task_id: expected_task_id)

          case decision[:disposition]
          when :reuse, :conflict_mismatch
            decision
          when :stale_recovery
            recover_stale(task_ref: task_ref, decision: decision, dry_run: dry_run)
          when :miss
            prepare(task_ref: task_ref, dry_run: dry_run)
          end
        end

        # Read-only find: association-aware switch + directory verification.
        def locate(task_ref:, expected_task_id:)
          switch = @manager.switch(task_ref.to_s)
          directory_exists = switch[:success] && path_exists?(switch[:worktree_path])
          Atoms::PrepareDecision.from_switch(switch,
            expected_task_id: expected_task_id, directory_exists: directory_exists)
        end

        private

        def prepare(task_ref:, dry_run:)
          return {disposition: :would_create, reason: "no worktree for this task yet",
                  worktree_path: nil, branch: nil} if dry_run

          create = @manager.create_task(task_ref.to_s)
          return create_with_verification(task_ref: task_ref, create: create) if create[:success]

          occupied = expected_directory_exists?(task_ref)
          Atoms::PrepareDecision.from_create(create, occupied_directory: occupied)
        end

        def recover_stale(task_ref:, decision:, dry_run:)
          return decision.merge(disposition: :would_recover) if dry_run

          @manager.prune
          retry_create = @manager.create_task(task_ref.to_s)
          if retry_create[:success]
            return Atoms::PrepareDecision.from_create(retry_create.merge(recovered: true))
          end

          {disposition: :error,
           reason: "#{retry_create[:error]} (after pruning stale worktree metadata; " \
                   "run `ace-git-worktree prune` and retry)",
           worktree_path: decision[:worktree_path], branch: nil}
        end

        def create_with_verification(task_ref:, create:)
          decision = Atoms::PrepareDecision.from_create(create)
          return decision if %i[conflict_mismatch error].include?(decision[:disposition])
          return decision if path_exists?(create[:worktree_path])

          recover_stale(task_ref: task_ref,
            decision: {worktree_path: create[:worktree_path]}, dry_run: false)
        end

        def expected_directory_exists?(task_ref)
          preview = @manager.create_task(task_ref.to_s, {dry_run: true})
          path = preview.dig(:would_create, :worktree_path) if preview[:success]
          path && path_exists?(path)
        end

        def path_exists?(worktree_path)
          path = worktree_path.to_s
          !path.empty? && File.directory?(path)
        end
      end
    end
  end
end
