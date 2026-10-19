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
          :active_executor, :conflict, :assignments, :start_configs, :report, :dry_run

        # worktree: {"path" =>, "branch" =>, "disposition" =>} or nil
        # conflict: {"kind" =>, "detail" =>, "hitl_event" =>, "delivered" =>}
        #   or nil; a non-nil conflict replaces the worktree in #to_h.
        # assignments: ordered role-sequence assignments composed by the
        #   planner (L4.2): {"role", "position", "of", "assignment",
        #   "disposition", "steps", "outcome"} per role, stored by
        #   ace-assign in the worktree.
        # start_configs: per-role leg configs written by the planner
        #   (L4.3): {"role", "assignment", "path", "disposition"} per leg,
        #   at .ace-local/coworker/prepare/<role>.yml in the worktree.
        # report: the planner's readiness report to the overseer via
        #   ace-hitl (L4.4) on success: {"kind" => "readiness",
        #   "event" =>, "delivered" =>} or {"kind" =>, "error" =>} when
        #   the report could not be created; nil when no report applies
        #   (dry-run) or a conflict escalation replaced it.
        def initialize(task:, task_path:, roles:, worktree: nil,
          worktree_assignments: [], active_executor: nil, conflict: nil,
          assignments: [], start_configs: [], report: nil, dry_run: false)
          @task = task
          @task_path = task_path
          @roles = roles.map(&:freeze).freeze
          @worktree = worktree
          @worktree_assignments = worktree_assignments.map(&:freeze).freeze
          @active_executor = active_executor
          @conflict = conflict
          @assignments = assignments.map(&:freeze).freeze
          @start_configs = start_configs.map(&:freeze).freeze
          @report = report ? report.dup.freeze : nil
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
            "assignments" => assignments,
            "start_configs" => start_configs,
            "report" => report,
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
