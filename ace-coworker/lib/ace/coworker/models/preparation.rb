# frozen_string_literal: true

module Ace
  module Coworker
    module Models
      # Immutable preparation result for `ace-coworker prepare`: the accepted
      # commission (task + roles), the resolved worktree (path/branch/
      # disposition) or the conflict that blocked it, plus the executor
      # evidence collected from the worktree. No IO.
      class Preparation
        attr_reader :task, :task_path, :roles, :worktree, :worktree_assignments,
          :active_executor, :conflict, :dry_run

        # worktree: {"path" =>, "branch" =>, "disposition" =>} or nil
        # conflict: {"kind" =>, "detail" =>, "hitl_event" =>, "delivered" =>}
        #   or nil; a non-nil conflict replaces the worktree in #to_h.
        def initialize(task:, task_path:, roles:, worktree: nil,
          worktree_assignments: [], active_executor: nil, conflict: nil,
          dry_run: false)
          @task = task
          @task_path = task_path
          @roles = roles.map(&:freeze).freeze
          @worktree = worktree
          @worktree_assignments = worktree_assignments.map(&:freeze).freeze
          @active_executor = active_executor
          @conflict = conflict
          @dry_run = dry_run
        end

        def conflict?
          !conflict.nil?
        end

        def to_h
          payload = {
            "task" => task,
            "task_path" => task_path,
            "roles" => roles,
            "active_executor" => active_executor,
            "worktree_assignments" => worktree_assignments,
            "conflict" => conflict
          }
          payload["worktree"] = worktree unless conflict?
          payload
        end
      end
    end
  end
end
