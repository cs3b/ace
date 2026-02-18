# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class WorktreeContextCollector
        def initialize(assignment_executor_factory: nil, repo_status_loader: nil)
          @assignment_executor_factory = assignment_executor_factory || -> { Ace::Assign::Organisms::AssignmentExecutor.new }
          @repo_status_loader = repo_status_loader || -> { Ace::Git::Organisms::RepoStatusLoader.load }
        end

        def collect(worktree_path)
          with_worktree_context(worktree_path) do
            repo_status = @repo_status_loader.call
            assignment_status = load_assignment_status
            task_id = extract_task_id(worktree_path, repo_status.branch)

            Models::WorkContext.new(
              task_id: task_id,
              worktree_path: worktree_path,
              branch: repo_status.branch.to_s,
              assignment_status: assignment_status,
              git_status: repo_status.to_h
            )
          end
        end

        private

        def load_assignment_status
          executor = @assignment_executor_factory.call
          result = executor.status
          state = result[:state]
          current = result[:current]

          {
            "assignment" => {
              "id" => result[:assignment].id,
              "name" => result[:assignment].name,
              "state" => state.assignment_state.to_s
            },
            "current_phase" => current && {
              "number" => current.number,
              "name" => current.name,
              "status" => current.status.to_s,
              "skill" => current.skill
            },
            "phase_summary" => {
              "total" => state.summary[:total],
              "done" => state.summary[:done],
              "failed" => state.summary[:failed],
              "in_progress" => state.summary[:in_progress],
              "pending" => state.summary[:pending]
            }
          }
        rescue Ace::Assign::NoActiveAssignmentError
          nil
        end

        def extract_task_id(worktree_path, branch)
          from_path = worktree_path.to_s[/(?:^|\/)task\.(\d+(?:\.\d+)?)(?:\/|$)/, 1]
          return from_path if from_path

          branch.to_s[/^(\d+(?:\.\d+)?)/, 1] || "unknown"
        end

        def with_worktree_context(worktree_path)
          original_project_root = ENV["PROJECT_ROOT_PATH"]
          Dir.chdir(worktree_path) do
            ENV["PROJECT_ROOT_PATH"] = worktree_path.to_s
            Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
            Ace::Assign.reset_config!
            yield
          ensure
            ENV["PROJECT_ROOT_PATH"] = original_project_root
            Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
            Ace::Assign.reset_config!
          end
        end
      end
    end
  end
end
