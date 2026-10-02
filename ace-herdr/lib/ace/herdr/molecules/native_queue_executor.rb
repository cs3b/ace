# frozen_string_literal: true

require "json"
require "timeout"

module Ace
  module Herdr
    module Molecules
      # The provider-native submission boundary. A failed process does not
      # prove that a message was not accepted, so only validation failures
      # raised before this boundary are retryable without reconciliation.
      #
      # Child processes run under BoundedProcess: the deadline is enforced at
      # the child boundary (process-group kill), never via a cleanup-blocking
      # Timeout.timeout around capture3, so a stalled child cannot hold the
      # inbox event lock past the configured timeout.
      class NativeQueueExecutor
        DEFAULT_SUBMIT_TIMEOUT_S = 60
        DEFAULT_IDENTITY_TIMEOUT_S = 20

        # runner: test seam. Callable (argv, stdin_data:, timeout_s:) ->
        # [stdout, stderr, status]. Defaults to the bounded runner.
        def initialize(codex: "codex", pi_client: nil, runner: nil,
          submit_timeout_s: DEFAULT_SUBMIT_TIMEOUT_S,
          identity_timeout_s: DEFAULT_IDENTITY_TIMEOUT_S)
          @codex = codex
          @pi_client = pi_client || ENV["ACE_HERDR_PI_QUEUE_CLIENT"] || "pi-overseer-queue-client"
          @runner = runner
          @submit_timeout_s = submit_timeout_s
          @identity_timeout_s = identity_timeout_s
        end

        def pi_identity
          result = execute([@pi_client, "--identity"], stdin_data: "",
            timeout_s: @identity_timeout_s)
          raise ExecutorError, "Pi identity probe failed: #{result.stderr}" unless result.status.success?

          JSON.parse(result.stdout).fetch("session_id")
        rescue Errno::ENOENT, Errno::EACCES => e
          raise ExecutorUnavailableError, e.message
        rescue JSON::ParserError, KeyError
          raise ExecutorError, "Pi identity probe returned invalid JSON"
        rescue Timeout::Error
          raise ExecutorError, "Pi identity probe timed out"
        end

        def submit(agent:, thread:, event_id:, digest:, payload:)
          if agent == "pi" && (payload.empty? || payload.bytesize > 65_536)
            return {"accepted" => false, "pre_submit" => true, "error" => "Pi payload must be 1..65536 bytes"}
          end
          argv = if agent == "codex"
            [@codex, "queue", "--thread", thread, "--message", payload]
          elsif agent == "pi"
            [@pi_client, "--delivery", event_id, "--session-id", thread,
              "--payload-sha256", digest, "--payload-bytes", payload.bytesize.to_s]
          else
            raise ValidationError, "unsupported native queue agent: #{agent}"
          end
          result = execute(argv, stdin_data: agent == "pi" ? payload : "",
            timeout_s: @submit_timeout_s)
          raise ExecutorError, "native queue output exceeded the retained limit" if result.oversized
          unless result.status.success?
            return {"accepted" => false, "exit_code" => result.status.exitstatus,
                    "error" => result.stderr.strip}
          end

          if agent == "pi"
            receipt = JSON.parse(result.stdout)
            unless receipt.is_a?(Hash) && receipt["ok"] == true && receipt["id"] == event_id &&
                receipt["session_id"] == thread && receipt["payload_sha256"] == digest
              return {"accepted" => false, "error" => "Pi queue receipt identity or digest mismatch"}
            end
          end
          {"accepted" => true, "exit_code" => result.status.exitstatus, "stdout" => result.stdout.strip}
        rescue Errno::ENOENT, Errno::EACCES => e
          # The executable was not launched. No submission could have occurred.
          {"accepted" => false, "pre_submit" => true, "error" => e.message}
        rescue JSON::ParserError
          {"accepted" => false, "error" => "Pi queue returned invalid receipt JSON"}
        rescue Timeout::Error
          {"accepted" => false, "error" => "native queue timed out after submission may have begun"}
        end

        private

        def execute(argv, stdin_data:, timeout_s:)
          if @runner
            stdout, stderr, status = @runner.call(argv, stdin_data: stdin_data, timeout_s: timeout_s)
            return BoundedProcess::Result.new(stdout, stderr, status, false)
          end

          BoundedProcess.call(argv, stdin_data: stdin_data, timeout_s: timeout_s)
        end
      end
    end
  end
end
