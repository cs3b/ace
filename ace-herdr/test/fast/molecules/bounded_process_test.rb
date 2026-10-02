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
            BoundedProcess.call([script], timeout_s: 0.3)
          end
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

          assert_operator elapsed, :<, 5, "must not block in cleanup past the deadline"
          child_pid = File.read(pid_file).to_i
          assert_raises(Errno::ESRCH) { Process.kill(0, child_pid) }
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
