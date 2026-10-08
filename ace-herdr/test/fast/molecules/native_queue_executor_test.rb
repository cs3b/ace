# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Molecules
      class NativeQueueExecutorTest < Minitest::Test
        Status = Struct.new(:success?, :exitstatus)

        def setup
          @dir = Dir.mktmpdir
          @calls = []
          @stdout = "queued"
          @stderr = ""
          @status = Status.new(true, 0)
          runner = lambda do |argv, **options|
            @calls << [argv, options]
            [@stdout, @stderr, @status]
          end
          @executor = NativeQueueExecutor.new(pi_client: "pi-client", runner: runner)
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def test_pi_uses_digest_bound_client_and_validates_receipt
          @stdout = JSON.generate("ok" => true, "id" => "inb-12345678",
            "session_id" => "thread-1", "payload_sha256" => "a" * 64)
          result = @executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")

          assert result["accepted"]
          assert_equal [["pi-client", "--delivery", "inb-12345678", "--session-id", "thread-1",
            "--payload-sha256", "a" * 64, "--payload-bytes", "5"],
            {stdin_data: "hello", timeout_s: NativeQueueExecutor::DEFAULT_SUBMIT_TIMEOUT_S}], @calls.fetch(0)

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
          result = @executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
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

          result = executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
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

        def test_oversize_pi_payload_is_rejected_before_launch
          result = @executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "x" * (NativeQueueExecutor::PI_PAYLOAD_LIMIT_BYTES + 1))

          assert result["pre_submit"]
          refute result["accepted"]
          assert_match(/1..65536/, result["error"])
          assert_empty @calls
        end

        def test_post_launch_io_failure_is_not_classified_pre_submit
          Molecules::BoundedProcess.stub(:call,
            lambda { |*| raise Molecules::BoundedProcess::PostLaunchError, "EIO on drained pipe" }) do
              executor = NativeQueueExecutor.new(pi_client: "pi-client")

              error = assert_raises(ExecutorError) do
                executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
                  digest: "a" * 64, payload: "hello")
              end

              assert_match(/post-launch/, error.message)
            end
        end

        def test_e2big_at_spawn_is_a_pre_submission_rejection
          runner = ->(*, **) { raise Errno::E2BIG, "argument list too long" }
          executor = NativeQueueExecutor.new(pi_client: "pi-client", runner: runner)

          result = executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")

          assert result["pre_submit"]
          refute result["accepted"]
          assert_match(/argument list too long/, result["error"])
        end

        def test_stalled_real_process_is_killed_at_the_deadline
          pid_file = File.join(@dir, "child.pid")
          script = File.join(@dir, "stalling-pi")
          File.write(script, <<~SH)
            #!/bin/sh
            echo $$ > '#{pid_file}'
            exec sleep 30
          SH
          FileUtils.chmod(0o755, script)
          executor = NativeQueueExecutor.new(pi_client: script, submit_timeout_s: 1.5)

          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          result = executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

          refute result["accepted"]
          refute result["pre_submit"]
          assert_match(/timed out/, result["error"])
          assert_operator elapsed, :<, 5, "deadline must not wait for the stalled child"
          child_pid = File.read(pid_file).to_i
          assert_raises(Errno::ESRCH) { Process.kill(0, child_pid) }
        end

        def test_real_process_receives_stdin_payload_and_validates_receipt
          script = File.join(@dir, "pi-client")
          File.write(script, <<~SH)
            #!/bin/sh
            cat > /dev/null
            printf '{"ok":true,"id":"inb-12345678","session_id":"thread-1","payload_sha256":"%s"}\\n' \\
              "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          SH
          FileUtils.chmod(0o755, script)
          executor = NativeQueueExecutor.new(pi_client: script, submit_timeout_s: 5)

          result = executor.submit(agent: "pi", thread: "thread-1", event_id: "inb-12345678",
            digest: "a" * 64, payload: "hello")

          assert result["accepted"]
        end
      end
    end
  end
end
