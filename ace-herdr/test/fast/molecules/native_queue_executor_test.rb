# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Molecules
      class NativeQueueExecutorTest < Minitest::Test
        Status = Struct.new(:success?, :exitstatus)

        def setup
          @calls = []
          @stdout = "queued"
          @stderr = ""
          @status = Status.new(true, 0)
          runner = lambda do |*argv, **options|
            @calls << [argv, options]
            [@stdout, @stderr, @status]
          end
          @executor = NativeQueueExecutor.new(codex: "codex", pi_client: "pi-client", runner: runner)
        end

        def test_codex_uses_exact_thread_queue_without_terminal_input
          result = @executor.submit(agent: "codex", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "line 1\nline 2")

          assert result["accepted"]
          assert_equal [["codex", "queue", "--thread", "thread-1", "--message", "line 1\nline 2"],
            {stdin_data: ""}], @calls.fetch(0)
        end

        def test_pi_uses_digest_bound_client_and_validates_receipt
          @stdout = JSON.generate("ok" => true, "id" => "inb-12345678",
            "session_id" => "thread-1", "payload_sha256" => "a" * 64)
          result = @executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")

          assert result["accepted"]
          assert_equal [["pi-client", "--delivery", "inb-12345678", "--session-id", "thread-1",
            "--payload-sha256", "a" * 64, "--payload-bytes", "5"], {stdin_data: "hello"}], @calls.fetch(0)

          @stdout = JSON.generate("ok" => true, "id" => "inb-other", "session_id" => "thread-1",
            "payload_sha256" => "a" * 64)
          result = @executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")
          refute result["accepted"]
          refute result["pre_submit"]
        end

        def test_nonzero_native_result_is_uncertain
          @status = Status.new(false, 1)
          @stderr = "socket timeout"
          result = @executor.submit(agent: "codex", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")

          refute result["accepted"]
          refute result["pre_submit"]
          assert_equal "socket timeout", result["error"]
        end

        def test_pi_oversize_is_rejected_before_process_launch
          result = @executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "x" * 65_537)

          assert result["pre_submit"]
          assert_empty @calls
        end

        def test_timeout_is_uncertain_after_native_call_starts
          runner = ->(*, **) { raise Timeout::Error }
          executor = NativeQueueExecutor.new(runner: runner)

          result = executor.submit(agent: "codex", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")

          refute result["accepted"]
          refute result["pre_submit"]
          assert_match(/timed out/, result["error"])
        end

        def test_permission_denied_before_process_launch_is_retryable
          runner = ->(*, **) { raise Errno::EACCES, "pi-client" }
          executor = NativeQueueExecutor.new(pi_client: "pi-client", runner: runner)

          assert_raises(ExecutorUnavailableError) { executor.pi_identity }
          result = executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")
          assert_equal true, result["pre_submit"]
          refute result["accepted"]
        end
      end
    end
  end
end
