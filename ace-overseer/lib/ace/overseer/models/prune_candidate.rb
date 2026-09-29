# frozen_string_literal: true

module Ace
  module Overseer
    module Models
      class PruneCandidate
        attr_reader :task_id, :worktree_path, :assignment_complete, :task_done, :git_clean,
          :attempts_terminal, :preserved, :verified_head, :reasons

        def initialize(task_id:, worktree_path:, assignment_complete:, task_done:, git_clean:,
          attempts_terminal: true, preserved: true, verified_head: nil, reasons: [])
          @task_id = task_id.to_s.freeze
          @worktree_path = worktree_path.to_s.freeze
          @assignment_complete = assignment_complete
          @task_done = task_done
          @git_clean = git_clean
          @attempts_terminal = attempts_terminal
          @preserved = preserved
          @verified_head = verified_head
          @reasons = reasons.map(&:to_s).freeze
        end

        def safe_to_prune?
          assignment_complete && task_done && git_clean && attempts_terminal && preserved
        end

        def to_h
          {
            task_id: task_id,
            worktree_path: worktree_path,
            assignment_complete: assignment_complete,
            task_done: task_done,
            git_clean: git_clean,
            attempts_terminal: attempts_terminal,
            preserved: preserved,
            reasons: reasons,
            safe_to_prune: safe_to_prune?
          }
        end
      end
    end
  end
end
