# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class WorktreeProvisioner
        def initialize(manager: nil)
          @manager = manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
        end

        def provision(task_ref)
          task_ref_str = task_ref.to_s
          switch_result = @manager.switch(task_ref_str)
          if switch_result[:success]
            return build_result(switch_result, created: false) if worktree_path_exists?(switch_result[:worktree_path])

            return recover_from_stale_worktree(task_ref_str, source: :switch, previous_result: switch_result)
          end

          create_result = @manager.create_task(task_ref_str)
          raise Error, create_result[:error] || "Failed to provision worktree for task #{task_ref}" unless create_result[:success]

          created = !create_result[:existing]
          return build_result(create_result, created: created) if worktree_path_exists?(create_result[:worktree_path])

          recover_from_stale_worktree(task_ref_str, source: :create_task, previous_result: create_result)
        end

        private

        def build_result(result, created:)
          {
            worktree_path: result[:worktree_path],
            branch: result[:branch],
            created: created
          }
        end

        def worktree_path_exists?(worktree_path)
          path = worktree_path.to_s
          !path.empty? && File.directory?(path)
        end

        def recover_from_stale_worktree(task_ref, source:, previous_result:)
          @manager.prune

          retry_result = @manager.create_task(task_ref)
          raise Error, retry_result[:error] || "Failed to provision worktree for task #{task_ref}" unless retry_result[:success]

          created = !retry_result[:existing]
          return build_result(retry_result, created: created) if worktree_path_exists?(retry_result[:worktree_path])

          stale_path = retry_result[:worktree_path] || previous_result[:worktree_path]
          raise Error,
                "Worktree path is missing after stale metadata recovery for task #{task_ref}: #{stale_path}. " \
                "Run `ace-git-worktree prune` and retry."
        rescue StandardError => e
          raise e if e.is_a?(Error)

          raise Error, e.message
        end
      end
    end
  end
end
