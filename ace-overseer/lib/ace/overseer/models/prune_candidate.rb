# frozen_string_literal: true

module Ace
  module Overseer
    module Models
      class PruneCandidate
        attr_reader :task_id, :worktree_path, :assignment_complete, :task_done, :git_clean, :reasons

        def initialize(task_id:, worktree_path:, assignment_complete:, task_done:, git_clean:, reasons: [])
          @task_id = task_id.to_s.freeze
          @worktree_path = worktree_path.to_s.freeze
          @assignment_complete = assignment_complete
          @task_done = task_done
          @git_clean = git_clean
          @reasons = reasons.map(&:to_s).freeze
        end

        def safe_to_prune?
          assignment_complete && task_done && git_clean
        end

        def to_h
          {
            task_id: task_id,
            worktree_path: worktree_path,
            assignment_complete: assignment_complete,
            task_done: task_done,
            git_clean: git_clean,
            reasons: reasons,
            safe_to_prune: safe_to_prune?
          }
        end
      end
    end
  end
end
