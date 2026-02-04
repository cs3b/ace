# frozen_string_literal: true

require "open3"
require "time"

module Ace
  module Scheduler
    module Molecules
      class TaskExecutor
        def initialize(config)
          @config = config
        end

        def run(task_name)
          task = @config[:tasks][task_name.to_sym]
          raise Ace::Scheduler::Error, "Unknown task: #{task_name}" unless task

          run_command(task[:command], task: task_name)
        end

        def run_command(command, task: "(event)")
          started_at = Time.now.utc
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          stdout, stderr, status = Open3.capture3(command)
          duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

          Models::ExecutionResult.new(
            task: task,
            status: status.success? ? "success" : "failed",
            exit_code: status.exitstatus,
            duration: duration,
            stdout: stdout,
            stderr: stderr,
            started_at: started_at
          )
        rescue StandardError => e
          Models::ExecutionResult.new(
            task: task,
            status: "failed",
            exit_code: 1,
            duration: 0,
            stdout: "",
            stderr: e.message,
            started_at: Time.now.utc
          )
        end
      end
    end
  end
end
