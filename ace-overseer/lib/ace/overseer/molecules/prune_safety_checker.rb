# frozen_string_literal: true

require "open3"

module Ace
  module Overseer
    module Molecules
      class PruneSafetyChecker
        def initialize(context_collector: nil, task_loader_factory: nil)
          @context_collector = context_collector || WorktreeContextCollector.new
          @task_loader_factory = task_loader_factory || -> { Ace::Task::Organisms::TaskManager.new }
        end

        def check(worktree_path:, task_ref:)
          context = @context_collector.collect(worktree_path)

          assignment_complete = assignment_complete?(context.assignment_status)
          task_done = task_done?(worktree_path, task_ref)
          git_clean = git_clean_for_prune?(worktree_path, context.git_status)

          reasons = []
          reasons << "assignment not complete" unless assignment_complete
          reasons << "task not done" unless task_done
          reasons << "git not clean" unless git_clean

          Models::PruneCandidate.new(
            task_id: task_ref,
            worktree_path: worktree_path,
            assignment_complete: assignment_complete,
            task_done: task_done,
            git_clean: git_clean,
            reasons: reasons
          )
        end

        private

        def assignment_complete?(assignment_status)
          return false unless assignment_status.is_a?(Hash)

          assignment_status.dig("assignment", "state") == "completed"
        end

        def task_done?(worktree_path, task_ref)
          paths = [project_root_from_worktree(worktree_path), worktree_path].compact.uniq
          paths.any? { |path| task_done_in_context?(path, task_ref) }
        end

        def git_clean?(git_status)
          git_status.is_a?(Hash) && (git_status["clean"] == true || git_status[:clean] == true)
        end

        def git_clean_for_prune?(worktree_path, git_status)
          tracked_clean = tracked_changes_clean?(worktree_path)
          return tracked_clean unless tracked_clean.nil?

          git_clean?(git_status)
        end

        def tracked_changes_clean?(worktree_path)
          stdout, status = Open3.capture2(
            "git", "-C", worktree_path, "status", "--porcelain", "--untracked-files=no"
          )
          return nil unless status.success?

          stdout.to_s.strip.empty?
        rescue StandardError
          nil
        end

        def task_done_in_context?(path, task_ref)
          Dir.chdir(path) do
            manager = @task_loader_factory.call
            task = manager.show(task_ref.to_s)
            task && task.status == "done"
          end
        rescue StandardError
          false
        end

        def project_root_from_worktree(worktree_path)
          stdout, status = Open3.capture2(
            "git", "-C", worktree_path, "rev-parse", "--path-format=absolute", "--git-common-dir"
          )
          return nil unless status.success?

          common_dir = stdout.to_s.strip
          return nil if common_dir.empty?

          File.dirname(common_dir)
        rescue StandardError
          nil
        end
      end
    end
  end
end
