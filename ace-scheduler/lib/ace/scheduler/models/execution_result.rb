# frozen_string_literal: true

module Ace
  module Scheduler
    module Models
      class ExecutionResult
        attr_reader :task, :status, :exit_code, :duration, :stdout, :stderr, :started_at

        def initialize(task:, status:, exit_code:, duration:, stdout:, stderr:, started_at:)
          @task = task
          @status = status
          @exit_code = exit_code
          @duration = duration
          @stdout = stdout
          @stderr = stderr
          @started_at = started_at
        end

        def success?
          status == "success"
        end
      end
    end
  end
end
