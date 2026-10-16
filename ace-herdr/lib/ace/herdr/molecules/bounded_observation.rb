# frozen_string_literal: true

require_relative "herdr_executor"

module Ace
  module Herdr
    module Molecules
      # Read-only native attribution under one absolute deadline, including all
      # ancestry probes. Never renew the budget for another process in the chain.
      class BoundedObservation < HerdrExecutor
        def initialize(deadline:, binary: DEFAULT_BINARY, process: BoundedProcess)
          super(binary: binary, process: process)
          @deadline = deadline
        end

        def pane_get(pane) = observe!([@binary, "pane", "get", pane])
        def pane_process_info(pane) = observe!([@binary, "pane", "process-info", "--pane", pane])

        # ProcessIdentity's existing executor seam. Do not let PATH select ps.
        def capture2(command, *args, stdin_data: "")
          raise ArgumentError, "observation only permits ps" unless command == "ps" && stdin_data.empty?
          result = bounded(["/bin/ps", *args])
          [result.stdout, result.status]
        end

        private

        def observe!(argv)
          result = bounded(argv)
          execution = ExecutionResult.new(stdout: result.stdout.strip, stderr: result.stderr.strip,
            success: result.status.success?, exit_code: result.status.exitstatus || -1)
          raise classify(execution, argv) unless execution.success?
          execution
        end

        def bounded(argv)
          remaining = @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise AgentNotReadyError, "native observation deadline elapsed" unless remaining.positive?
          result = @process.call(argv, stdin_data: "", timeout_s: remaining,
            output_limit: WAKE_OUTPUT_LIMIT, cleanup_group: true)
          raise AgentNotReadyError, "native observation output exceeded limit" if result.oversized
          result
        rescue Timeout::Error, BoundedProcess::PostLaunchError
          raise AgentNotReadyError, "native observation did not complete within its bound"
        rescue SystemCallError
          raise ExecutorUnavailableError, "native observation executable unavailable"
        end
      end
    end
  end
end
