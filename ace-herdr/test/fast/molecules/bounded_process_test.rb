# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Molecules
      class BoundedProcessTest < Minitest::Test
        def setup
          @dir = Dir.mktmpdir
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def test_completing_child_returns_streams_and_status
          result = BoundedProcess.call(["/bin/echo", "hello"], timeout_s: 5)

          assert_equal "hello\n", result.stdout
          assert_empty result.stderr
          assert_predicate result.status, :success?
          refute result.oversized
        end

        def test_interrupted_pipe_read_keeps_original_child_and_deadline_loop
          original_loop = BoundedProcess.method(:run_loop)
          invocations = 0
          reads = 0
          observed_child = nil
          controlled = lambda do |stdin, stdout, stderr, waiter, **limits|
            invocations += 1
            observed_child = waiter
            assert_equal 5, limits.fetch(:timeout_s)
            original_read = stdout.method(:read_nonblock)
            stdout.define_singleton_method(:read_nonblock) do |*arguments, **options|
              reads += 1
              raise Errno::EINTR if reads == 1
              original_read.call(*arguments, **options)
            end
            original_loop.call(stdin, stdout, stderr, waiter, **limits)
          end
          result = BoundedProcess.stub(:run_loop, controlled) do
            BoundedProcess.call(["/bin/echo", "unchanged"], timeout_s: 5)
          end
          assert_equal 1, invocations, "interruption must not start another child"
          assert_operator reads, :>=, 2
          assert_equal "unchanged\n", result.stdout
          assert_predicate result.status, :success?
          refute observed_child.alive?
        end

        def test_clean_exit_with_group_cleanup_returns_original_status
          result = BoundedProcess.call(["/bin/sh", "-c", "printf exact; exit 0"],
            timeout_s: 5, cleanup_group: true)
          assert_equal "exact", result.stdout
          assert_predicate result.status, :success?
          refute result.oversized
        end

        def test_stdin_payload_reaches_the_child
          result = BoundedProcess.call(["/bin/cat"], stdin_data: "payload-bytes", timeout_s: 5)

          assert_equal "payload-bytes", result.stdout
          assert_predicate result.status, :success?
        end

        def test_stalled_child_is_killed_at_the_deadline
          pid_file = File.join(@dir, "child.pid")
          script = File.join(@dir, "stall")
          File.write(script, <<~SH)
            #!/bin/sh
            echo $$ > '#{pid_file}'
            exec sleep 30
          SH
          FileUtils.chmod(0o755, script)

          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          assert_raises(Timeout::Error) do
            BoundedProcess.call([script], timeout_s: 1.0)
          end
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

          assert_operator elapsed, :<, 5, "must not block in cleanup past the deadline"
          child_pid = File.read(pid_file).to_i
          assert_raises(Errno::ESRCH) { Process.kill(0, child_pid) }
        end

        def test_large_stdin_payload_to_nonreading_child_hits_deadline_without_blocking
          pid_file = File.join(@dir, "child.pid")
          script = File.join(@dir, "nonreader")
          File.write(script, <<~SH)
            #!/bin/sh
            echo $$ > '#{pid_file}'
            exec sleep 30
          SH
          FileUtils.chmod(0o755, script)

          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          assert_raises(Timeout::Error) do
            BoundedProcess.call([script], stdin_data: "x" * 1_048_576, timeout_s: 1.0)
          end
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

          assert_operator elapsed, :<, 5, "a full pipe must not block past the deadline"
          child_pid = File.read(pid_file).to_i
          assert_raises(Errno::ESRCH) { Process.kill(0, child_pid) }
        end

        def test_post_launch_io_error_kills_child_and_raises_post_launch_error
          child_waiter = nil
          offender = lambda do |_, _, _, waiter, **|
            child_waiter = waiter
            assert_kind_of Integer, waiter.pid
            assert_operator waiter.pid, :>, 0
            assert waiter.alive?, "the exact spawned child must be live before injecting the IO failure"
            assert_equal 1, Process.kill(0, waiter.pid)
            # The cleanup check must reject this real surviving child.
            assert_raises(Minitest::Assertion) { assert_owned_child_absent(waiter.pid) }
            raise Errno::EIO, "injected pipe failure"
          rescue Minitest::Assertion
            cleanup_owned_fixture_child(waiter)
            raise
          end
          Molecules::BoundedProcess.stub(:run_loop, offender) do
            error = assert_raises(Molecules::BoundedProcess::PostLaunchError) do
              Molecules::BoundedProcess.call(["/bin/sleep", "30"], timeout_s: 5)
            end

            assert_match(/post-launch/, error.message)
          end
          refute child_waiter.alive?, "cleanup must reap the exact spawned child"
          assert_cleanup_termination(child_waiter.value)
          assert_owned_child_absent(child_waiter.pid)
        ensure
          # Only an unreaped handle retained from this invocation is eligible
          # for failing-path cleanup; never a file-derived or recycled PID.
          cleanup_owned_fixture_child(child_waiter)
        end

        def cleanup_owned_fixture_child(waiter)
          return unless waiter&.alive?
          begin
            Process.kill("KILL", -waiter.pid)
          rescue Errno::ESRCH
            # An already-exiting owned child still must be reaped below.
          end
          assert waiter.join(5), "owned fixture child cleanup must remain bounded"
        end

        def test_fixture_assertion_failure_cleans_only_its_owned_child
          owned_waiter = nil
          assert_raises(Minitest::Assertion) do
            Open3.popen3("/bin/sleep", "30", pgroup: true) do |_, _, _, waiter|
              owned_waiter = waiter
              begin
                assert_equal 1, Process.kill(0, waiter.pid)
                flunk "controlled fixture assertion failure"
              ensure
                cleanup_owned_fixture_child(waiter)
              end
            end
          end
          refute owned_waiter.alive?
          assert_owned_child_absent(owned_waiter.pid)
        end

        def test_absence_check_refuses_invalid_identity_without_probing_processes
          probes = []
          Process.stub(:kill, ->(*args) { probes << args; 1 }) do
            [nil, "", 0, -1].each do |pid|
              assert_raises(Minitest::Assertion) { assert_owned_child_absent(pid) }
            end
          end
          assert_empty probes, "invalid identity must not probe a process"
        end

        def test_normal_exit_cannot_satisfy_cleanup_termination_proof
          _, status = Open3.capture2("/bin/sh", "-c", "exit 0")
          assert_predicate status, :success?
          assert_raises(Minitest::Assertion) { assert_cleanup_termination(status) }
        end

        def assert_cleanup_termination(status)
          assert_predicate status, :signaled?, "cleanup must terminate the child rather than await natural exit"
          assert_equal Signal.list.fetch("KILL"), status.termsig
        end

        def assert_owned_child_absent(pid)
          assert_kind_of Integer, pid
          assert_operator pid, :>, 0
          assert_raises(Errno::ESRCH) { Process.kill(0, pid) }
        end

        def test_oversized_output_is_truncated_and_reported
          result = BoundedProcess.call(["/bin/echo", "x" * 10_000], timeout_s: 5, output_limit: 1024)

          assert_operator result.stdout.bytesize, :<=, 1024
          assert result.oversized
          assert_predicate result.status, :success?
        end

        def test_missing_executable_raises_enoent
          assert_raises(Errno::ENOENT) do
            BoundedProcess.call(["/nonexistent/binary-#{Process.pid}"], timeout_s: 5)
          end
        end
      end
    end
  end
end
