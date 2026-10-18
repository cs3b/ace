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

        # Read-only find: association-aware switch plus stale detection.
        # The owner's switch never resolves a worktree whose directory is
        # missing (it fails instead), so a failed switch is cross-checked
        # against the association inventory: a registration for this task
        # pointing at a missing directory is stale metadata, not a miss.
        def locate(task_ref:, expected_task_id:)
          switch = @manager.switch(task_ref.to_s)
          stale = stale_registration(expected_task_id) unless switch[:success]
          Atoms::PrepareDecision.from_switch(switch,
            expected_task_id: expected_task_id, stale_registration: stale)
        end

        private

        def stale_registration(expected_task_id)
          listing = @manager.list_all
          return nil unless listing[:success]

          expected = Atoms::PrepareDecision.expected_ids(expected_task_id)
          stale = listing[:worktrees].find do |info|
            info.respond_to?(:task_id) && expected.include?(info.task_id.to_s) &&
              !path_exists?(info.path)
          end
          return nil unless stale

          {task_id: stale.task_id.to_s, worktree_path: stale.path, branch: stale.branch}
        end

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

          prune = @manager.prune
          unless prune[:success]
            return {disposition: :error,
                    reason: "#{prune[:error]} (could not prune stale worktree metadata at " \
                            "#{decision[:worktree_path]} before recreation)",
                    worktree_path: decision[:worktree_path], branch: nil}
          end

          retry_create = @manager.create_task(task_ref.to_s)
          if retry_create[:success]
            return Atoms::PrepareDecision.from_create(retry_create.merge(recovered: true))
          end

          # Same occupied-location rule as the miss path: a foreign
          # occupant of the expected directory is a conflict, never an
          # operational error.
          occupied = path_exists?(decision[:worktree_path])
          mismatch = Atoms::PrepareDecision.from_create(retry_create, occupied_directory: occupied)
          return mismatch if mismatch[:disposition] == :conflict_mismatch

          # The stale worktree's branch survives its directory (committed
          # work lives on it): when recreation trips over the surviving
          # branch, reattach a worktree to it instead of minting a fresh
          # branch that would orphan that work.
          reattached = @manager.create(decision[:branch].to_s, path: decision[:worktree_path])
          return Atoms::PrepareDecision.from_create(reattached.merge(recovered: true)) if reattached[:success]

          {disposition: :error,
           reason: "#{retry_create[:error]} (stale worktree metadata at " \
                   "#{decision[:worktree_path]} was already pruned and branch reattach " \
                   "failed too; retry the prepare command)",
           worktree_path: decision[:worktree_path], branch: nil}
        end

        def create_with_verification(task_ref:, create:)
          decision = Atoms::PrepareDecision.from_create(create)
          return decision if %i[conflict_mismatch error].include?(decision[:disposition])
          return decision if path_exists?(create[:worktree_path])

          recover_stale(task_ref: task_ref,
            decision: {worktree_path: create[:worktree_path], branch: create[:branch]},
            dry_run: false)
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
