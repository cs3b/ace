# frozen_string_literal: true

require_relative "../errors"
require "json"
require "timeout"
require_relative "bounded_process"
require_relative "codex_runtime_selection"

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
        CODEX_PAYLOAD_LIMIT_BYTES = 65_536
        PI_PAYLOAD_LIMIT_BYTES = 65_536

        # runner: test seam. Callable (argv, stdin_data:, timeout_s:) ->
        # [stdout, stderr, status]. Defaults to the bounded runner.
        def initialize(codex_runtime: nil, pi_client: nil, runner: nil, process: BoundedProcess,
          submit_timeout_s: DEFAULT_SUBMIT_TIMEOUT_S,
          identity_timeout_s: DEFAULT_IDENTITY_TIMEOUT_S)
          @codex_runtime = codex_runtime
          @pi_client = pi_client || ENV["ACE_HERDR_PI_QUEUE_CLIENT"] || "pi-overseer-queue-client"
          @runner = runner
          @process = process
          @submit_timeout_s = submit_timeout_s
          @identity_timeout_s = identity_timeout_s
        end

        def pi_identity
          result = execute([@pi_client, "--identity"], stdin_data: "",
            timeout_s: @identity_timeout_s)
          raise ExecutorError, "Pi identity probe failed: #{result.stderr}" unless result.status.success?

          identity = JSON.parse(result.stdout)
          raise ExecutorError, "Pi identity probe returned invalid JSON" unless identity.is_a?(Hash)

          identity.fetch("session_id")
        rescue Errno::ENOENT, Errno::EACCES => e
          raise ExecutorUnavailableError, e.message
        rescue JSON::ParserError, KeyError, TypeError
          raise ExecutorError, "Pi identity probe returned invalid JSON"
        rescue Timeout::Error
          raise ExecutorError, "Pi identity probe timed out"
        end

        def prepare_submission(agent:, thread:, event_id:, attempt_id:, claim_generation:, digest:)
          return nil unless agent == "codex"
          unless @codex_runtime.is_a?(CodexRuntimeSelection)
            raise ValidationError, "Codex has no authenticated original runtime selection"
          end
          @codex_runtime.submission(event_id: event_id, attempt_id: attempt_id,
            claim_generation: claim_generation, digest: digest, thread: thread)
        end

        # Caller retains the original absolute observation budget. This read
        # does not submit, retry, sign or transition the canonical inbox event.
        def observe(agent:, thread:, event_id:, digest:, submission:, deadline:, receipt: nil)
          unless agent == "codex" && @codex_runtime.is_a?(CodexRuntimeSelection) && submission.is_a?(Hash) &&
              submission.values_at("thread_id", "event_id", "payload_sha256") == [thread, event_id, digest]
            return {"outcome" => "uncertain", "error" => "Codex original observation selection differs"}
          end
          @codex_runtime.observe(submission: submission, deadline: deadline, receipt: receipt)
        end

        def submit(agent:, thread:, event_id:, digest:, payload:, submission: nil)
          if agent == "codex"
            unless @codex_runtime.is_a?(CodexRuntimeSelection) && submission.is_a?(Hash) &&
                submission.values_at("thread_id", "event_id", "payload_sha256") == [thread, event_id, digest] &&
                payload.is_a?(String) && payload.bytesize.between?(1, CODEX_PAYLOAD_LIMIT_BYTES)
              return {"accepted" => false, "pre_submit" => true, "error" => "Codex original submission selection differs"}
            end
            deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @submit_timeout_s
            return @codex_runtime.submit(submission: submission, payload: payload, deadline: deadline)
          end
          raise ValidationError, "unsupported native queue agent: #{agent}" unless agent == "pi"
          if payload.empty? || payload.bytesize > PI_PAYLOAD_LIMIT_BYTES
            return {"accepted" => false, "pre_submit" => true, "error" => "Pi payload must be 1..65536 bytes"}
          end
          argv = [@pi_client, "--delivery", event_id, "--session-id", thread,
            "--payload-sha256", digest, "--payload-bytes", payload.bytesize.to_s]
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
        rescue Errno::ENOENT, Errno::EACCES, Errno::E2BIG, ExecutorUnavailableError => e
          # The executable never launched (or exec rejected the argv). No
          # submission could have occurred, so this stays retryable.
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

          @process.call(argv, stdin_data: stdin_data, timeout_s: timeout_s)
        rescue SystemCallError => e
          # popen3 raises spawn failures before the child exists, so no
          # submission can have begun: proven pre-launch, retryable.
          # (Post-launch I/O failures arrive as PostLaunchError instead.)
          raise ExecutorUnavailableError, e.message
        rescue BoundedProcess::PostLaunchError => e
          # The child was live, so the message may already have been accepted:
          # keep this uncertain, never pre-submit retryable.
          raise ExecutorError, e.message
        end
      end
    end
  end
end
