# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class WorktreeContextCollector
        def initialize(repo_status_loader: nil, assignment_discoverer_factory: nil)
          @repo_status_loader = repo_status_loader || -> {
            Ace::Git::Organisms::RepoStatusLoader.load(include_pr_activity: false, include_commits: false)
          }
          @assignment_discoverer_factory = assignment_discoverer_factory || -> { Ace::Assign::Molecules::AssignmentDiscoverer.new }
        end

        def collect(worktree_path, location_type: :worktree)
          with_worktree_context(worktree_path) do
            repo_status = @repo_status_loader.call
            assignments = load_all_assignments
            task_id = extract_task_id(worktree_path, repo_status.branch)

            Models::WorkContext.new(
              task_id: task_id,
              worktree_path: worktree_path,
              branch: repo_status.branch.to_s,
              assignments: assignments,
              git_status: repo_status.to_h,
              location_type: location_type
            )
          end
        end

        def collect_assignments_only(worktree_path, cached_branch:, cached_git_status:, location_type: :worktree)
          with_worktree_context(worktree_path) do
            assignments = load_all_assignments
            task_id = extract_task_id(worktree_path, cached_branch)

            Models::WorkContext.new(
              task_id: task_id,
              worktree_path: worktree_path,
              branch: cached_branch,
              assignments: assignments,
              git_status: cached_git_status,
              location_type: location_type
            )
          end
        end

        private

        def load_all_assignments
          infos = @assignment_discoverer_factory.call.find_all(include_completed: true)
          infos.map { |info| assignment_info_to_h(info) }
        rescue StandardError
          []
        end

        def assignment_info_to_h(info)
          current = info.queue_state.current
          {
            "assignment" => {
              "id" => info.id,
              "name" => info.name,
              "state" => info.state.to_s
            },
            "phase_summary" => {
              "total" => info.queue_state.summary[:total],
              "done" => info.queue_state.summary[:done],
              "failed" => info.queue_state.summary[:failed],
              "in_progress" => info.queue_state.summary[:in_progress],
              "pending" => info.queue_state.summary[:pending]
            },
            "current_phase" => current ? current.name : nil
          }
        end

        def extract_task_id(worktree_path, branch)
          # Match "task.NNN" or "ace-task.xxx" in path (numeric or B36TS directory naming)
          from_path = worktree_path.to_s[/(?:^|\/)(?:ace-)?task\.([0-9a-z]+(?:\.[0-9a-z]+)?)(?:\/|$)/, 1]
          return from_path if from_path

          # Try B36TS prefix from branch (e.g., "hy4-description") then numeric
          branch.to_s[/^([0-9a-z]{3})(?:-|\b)/, 1] || branch.to_s[/^(\d+(?:\.\d+)?)/, 1] || "unknown"
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
