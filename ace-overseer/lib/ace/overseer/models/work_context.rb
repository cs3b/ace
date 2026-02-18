# frozen_string_literal: true

module Ace
  module Overseer
    module Models
      class WorkContext
        attr_reader :task_id, :worktree_path, :branch, :assignment_status, :git_status, :tmux_window

        def initialize(task_id:, worktree_path:, branch:, assignment_status: nil, git_status: nil, tmux_window: nil)
          @task_id = task_id.to_s.freeze
          @worktree_path = worktree_path.to_s.freeze
          @branch = branch.to_s.freeze
          @assignment_status = assignment_status
          @git_status = git_status
          @tmux_window = tmux_window&.to_s&.freeze
        end

        def to_h
          {
            task_id: task_id,
            worktree_path: worktree_path,
            branch: branch,
            assignment_status: assignment_status,
            git_status: git_status,
            tmux_window: tmux_window
          }
        end
      end
    end
  end
end
