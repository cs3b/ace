# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      module ObservationSources
        PROJECT_TASKS = "project_tasks"
        OVERSEER_TASKS = "overseer_tasks"
        WORKTREES = "worktrees"
        COWORKERS = "coworkers"
        HITL = "hitl"
        PROJECT_SESSIONS = "project_sessions"
        REQUIRED = [PROJECT_TASKS, OVERSEER_TASKS, WORKTREES, COWORKERS, HITL].freeze
      end
    end
  end
end
