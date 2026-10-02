# frozen_string_literal: true

require "open3"
require "json"
require "timeout"

module Ace
  module Herdr
    module Molecules
      # The provider-native submission boundary. A failed process does not
      # prove that a message was not accepted, so only validation failures
      # raised before this boundary are retryable without reconciliation.
      class NativeQueueExecutor
        def initialize(codex: "codex", pi_client: nil, runner: Open3.method(:capture3))
          @codex = codex
          @pi_client = pi_client || ENV["ACE_HERDR_PI_QUEUE_CLIENT"] || "pi-overseer-queue-client"
          @runner = runner
        end

        def pi_identity
          stdout, stderr, status = Timeout.timeout(20) { @runner.call(@pi_client, "--identity") }
          raise ExecutorError, "Pi identity probe failed: #{stderr}" unless status.success?

          JSON.parse(stdout).fetch("session_id")
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
          stdout, stderr, status = Timeout.timeout(60) do
            @runner.call(*argv, stdin_data: agent == "pi" ? payload : "")
          end
          return {"accepted" => false, "exit_code" => status.exitstatus, "error" => stderr.strip} unless status.success?

          if agent == "pi"
            receipt = JSON.parse(stdout)
            unless receipt.is_a?(Hash) && receipt["ok"] == true && receipt["id"] == event_id &&
                receipt["session_id"] == thread && receipt["payload_sha256"] == digest
              return {"accepted" => false, "error" => "Pi queue receipt identity or digest mismatch"}
            end
          end
          {"accepted" => true, "exit_code" => status.exitstatus, "stdout" => stdout.strip}
        rescue Errno::ENOENT, Errno::EACCES => e
          # The executable was not launched. No submission could have occurred.
          {"accepted" => false, "pre_submit" => true, "error" => e.message}
        rescue JSON::ParserError
          {"accepted" => false, "error" => "Pi queue returned invalid receipt JSON"}
        rescue Timeout::Error
          {"accepted" => false, "error" => "native queue timed out after submission may have begun"}
        end
      end
    end
  end
end
