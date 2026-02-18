# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class WorktreeProvisioner
        def initialize(manager: nil)
          @manager = manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
        end

        def provision(task_ref)
          switch_result = @manager.switch(task_ref.to_s)
          if switch_result[:success]
            return {
              worktree_path: switch_result[:worktree_path],
              branch: switch_result[:branch],
              created: false
            }
          end

          create_result = @manager.create_task(task_ref.to_s)
          raise Error, create_result[:error] || "Failed to provision worktree for task #{task_ref}" unless create_result[:success]

          {
            worktree_path: create_result[:worktree_path],
            branch: create_result[:branch],
            created: true
          }
        end
      end
    end
  end
end
