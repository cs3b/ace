# frozen_string_literal: true

require "ace/git/worktree/atoms/task_id_extractor"

module Ace
  module Coworker
    module Atoms
      # Pure disposition rules for the preparation decision procedure.
      # Inputs are the structured hashes returned by the worktree owner
      # (ace-git-worktree switch/create results); outputs are dispositions
      # with reasons. No IO, no writes.
      module PrepareDecision
        # @param switch_result [Hash] WorktreeManager#switch result
        # @param expected_task_id [String] id of the task being prepared
        # @param directory_exists [Boolean] whether the resolved worktree
        #   directory exists on disk
        # @return [Hash] {disposition:, reason:, worktree_path:, branch:, task_id:}
        #   disposition: :reuse | :conflict_mismatch | :stale_recovery | :miss
        def self.from_switch(switch_result, expected_task_id:, directory_exists:)
          return {disposition: :miss, reason: switch_result[:error].to_s,
                  worktree_path: nil, branch: nil, task_id: nil} unless switch_result[:success]

          task_id = switch_result[:task_id].to_s
          base = {worktree_path: switch_result[:worktree_path],
                  branch: switch_result[:branch], task_id: task_id}
          unless directory_exists
            return base.merge(disposition: :stale_recovery,
              reason: "worktree metadata resolves to a missing directory: #{switch_result[:worktree_path]}")
          end
          if expected_ids(expected_task_id).include?(task_id)
            base.merge(disposition: :reuse, reason: "worktree already prepared for this task")
          else
            base.merge(disposition: :conflict_mismatch,
              reason: "resolved worktree belongs to task '#{task_id}', not '#{expected_task_id}'")
          end
        end

        # ace-git-worktree stores the worktree association under the task's
        # short id (e.g. "aaa") while ace-task resolves the full id
        # ("8xh.t.aaa"); accept every recognized form of the expected id.
        def self.expected_ids(expected_task_id)
          full = expected_task_id.to_s
          [full, Ace::Git::Worktree::Atoms::TaskIDExtractor.short_id(full),
           Ace::Git::Worktree::Atoms::TaskIDExtractor.normalize(full)].compact.uniq
        end
        private_class_method :expected_ids

        # @param create_result [Hash] WorktreeManager#create_task result
        # @param occupied_directory [Boolean] whether the task's expected
        #   worktree directory exists on disk (a foreign occupant when the
        #   create failed)
        # @return [Hash] {disposition:, reason:, worktree_path:, branch:}
        #   disposition: :created | :recovered | :reuse | :conflict_mismatch | :error
        def self.from_create(create_result, occupied_directory: false)
          if create_result[:success]
            disposition = create_result[:existing] ? :reuse : (create_result[:recovered] ? :recovered : :created)
            return {disposition: disposition, reason: create_result[:message].to_s,
                    worktree_path: create_result[:worktree_path], branch: create_result[:branch]}
          end

          disposition = occupied_directory ? :conflict_mismatch : :error
          {disposition: disposition, reason: create_result[:error].to_s,
           worktree_path: nil, branch: nil}
        end
      end
    end
  end
end
