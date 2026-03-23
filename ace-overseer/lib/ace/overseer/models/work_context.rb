# frozen_string_literal: true

module Ace
  module Overseer
    module Models
      class WorkContext
        attr_reader :task_id, :worktree_path, :branch, :assignments, :git_status, :tmux_window,
          :location_type

        def initialize(task_id:, worktree_path:, branch:, assignments: [], git_status: nil,
          tmux_window: nil, location_type: :worktree)
          @task_id = task_id.to_s.freeze
          @worktree_path = worktree_path.to_s.freeze
          @branch = branch.to_s.freeze
          @assignments = Array(assignments)
          @git_status = git_status
          @tmux_window = tmux_window&.to_s&.freeze
          @location_type = location_type.to_sym
        end

        def assignment_status
          @assignments.first
        end

        def assignment_count
          @assignments.size
        end

        def to_h
          {
            task_id: task_id,
            worktree_path: worktree_path,
            branch: branch,
            assignments: assignments,
            git_status: git_status,
            tmux_window: tmux_window,
            location_type: location_type
          }
        end
      end
    end
  end
end
