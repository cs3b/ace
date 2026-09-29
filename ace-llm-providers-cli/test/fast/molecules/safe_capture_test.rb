# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/molecules/safe_capture"
require "tmpdir"
require "shellwords"
require "stringio"

module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          class SafeCaptureTest < Minitest::Test
            FAST_TIMEOUT = 0.2

            def setup
              @tracked_pids = []
            end

            def teardown
              @tracked_pids.each do |pid|
                Process.kill("KILL", pid)
              rescue Errno::ESRCH, Errno::EPERM
                nil
              end
            end

            def test_captures_stdout_and_stderr_as_completed_outcome
              capture = SafeCapture.call(
                ["ruby", "-e", "STDOUT.print 'hello'; STDERR.print 'world'"],
                timeout: 5
              )

              assert_equal "hello", capture.stdout
              assert_equal "world", capture.stderr
              assert_equal Models::CaptureResult::OUTCOME_COMPLETED, capture.outcome
              assert capture.success?
              assert capture.status.success?
              assert capture.execution_began?
            end

            def test_completed_capture_records_deadline_elapsed_and_invocation
              capture = SafeCapture.call(["true"], timeout: 5)

              assert_equal 5, capture.deadline_seconds
              assert capture.elapsed_seconds >= 0
              assert capture.invocation_id.match?(/\A[A-Za-z0-9]{8}\z/)
            end

            def test_deadline_exceeded_returns_typed_outcome_with_partial_output
              capture = SafeCapture.call(
                ["ruby", "-e", "STDOUT.sync=true; STDOUT.puts('partial stdout'); STDERR.sync=true; STDERR.puts('partial stderr'); sleep 2"],
                timeout: FAST_TIMEOUT,
                provider_name: "Test"
              )

              assert_equal Models::CaptureResult::OUTCOME_DEADLINE_EXCEEDED, capture.outcome
              refute capture.success?
              assert_nil capture.status
              assert_includes capture.stdout, "partial stdout"
              assert_includes capture.stderr, "partial stderr"
              assert_equal FAST_TIMEOUT, capture.deadline_seconds
              assert capture.elapsed_seconds >= FAST_TIMEOUT
              assert capture.execution_began?
            end

            def test_deadline_exceeded_evidence_classifies_as_deadline_outcome
              capture = SafeCapture.call(["sleep", "2"], timeout: FAST_TIMEOUT, provider_name: "Test")
              evidence = capture.execution_evidence

              assert_equal :deadline_exceeded, evidence.outcome
              assert_equal "Test", evidence.provider_name
              assert evidence.uncertain_execution?
              assert_equal FAST_TIMEOUT, evidence.deadline_seconds
            end

            def test_nonzero_exit_mentions_timeout_stays_completed_outcome
              capture = SafeCapture.call(
                ["ruby", "-e", "STDERR.print 'request timed out after 30s'; exit 3"],
                timeout: 5,
                provider_name: "Test"
              )

              assert_equal Models::CaptureResult::OUTCOME_COMPLETED, capture.outcome
              refute capture.success?
              assert_equal 3, capture.exit_status
              assert_includes capture.stderr, "timed out"
            end

            def test_nonzero_exit_error_carries_exit_evidence_not_prose
              capture = SafeCapture.call(
                ["ruby", "-e", "STDERR.print 'connection timed out'; exit 7"],
                timeout: 5,
                provider_name: "Test"
              )
              error = capture.provider_error

              assert_instance_of Ace::LLM::ProviderError, error
              assert_equal :nonzero_exit, error.execution_evidence.outcome
              assert_equal 7, error.execution_evidence.exit_status
            end

            def test_transport_disconnect_killed_by_signal_is_typed
              capture = SafeCapture.call(
                ["ruby", "-e", "STDOUT.print 'working'; Process.kill('KILL', Process.pid)"],
                timeout: 5,
                provider_name: "Test"
              )

              assert_equal Models::CaptureResult::OUTCOME_TRANSPORT_FAILURE, capture.outcome
              refute capture.success?
              assert_equal "KILL", capture.signal
            end

            def test_transport_failure_error_carries_signal_evidence
              capture = SafeCapture.call(
                ["ruby", "-e", "Process.kill('KILL', Process.pid)"],
                timeout: 5,
                provider_name: "Test"
              )
              error = capture.provider_error

              assert_equal :transport_failure, error.execution_evidence.outcome
              assert_equal "KILL", error.execution_evidence.signal
              assert error.execution_evidence.uncertain_execution?
            end

            def test_spawn_failure_is_typed_and_reports_execution_not_begun
              capture = SafeCapture.call(
                ["/bin/definitely-not-a-real-binary-ace-test"],
                timeout: 5,
                provider_name: "Test"
              )

              assert_equal Models::CaptureResult::OUTCOME_SPAWN_FAILURE, capture.outcome
              refute capture.success?
              refute capture.execution_began?
              refute_nil capture.spawn_error
              refute capture.execution_evidence.uncertain_execution?
            end

            def test_stdin_data_passed
              capture = SafeCapture.call(
                ["cat"],
                timeout: 5,
                stdin_data: "piped input"
              )

              assert_equal "piped input", capture.stdout
              assert capture.success?
            end

            def test_chdir_option
              capture = SafeCapture.call(
                ["pwd"],
                timeout: 5,
                chdir: "/tmp"
              )

              assert_match %r{/tmp}, capture.stdout.strip
              assert capture.success?
            end

            def test_env_option_passed_to_subprocess
              capture = SafeCapture.call(
                ["ruby", "-e", "print ENV['ACE_SAFE_CAPTURE_TEST']"],
                timeout: 5,
                env: {"ACE_SAFE_CAPTURE_TEST" => "env-ok"}
              )

              assert_equal "env-ok", capture.stdout
              assert capture.success?
            end

            def test_command_prefix_wraps_subprocess
              capture = SafeCapture.call(
                ["ruby", "-e", "print ENV['ACE_SAFE_CAPTURE_TEST']"],
                timeout: 5,
                command_prefix: ["env", "ACE_SAFE_CAPTURE_TEST=wrapped"],
                env: {"ACE_SAFE_CAPTURE_TEST" => "inner"},
                stdin_data: nil
              )

              assert_equal "wrapped", capture.stdout
              assert capture.success?
            end

            def test_deadline_exceeded_error_message_names_provider_and_deadline
              capture = SafeCapture.call(["sleep", "2"], timeout: FAST_TIMEOUT, provider_name: "Gemini")
              error = capture.provider_error

              assert_match(/Gemini CLI execution exceeded its 0\.2s deadline/, error.message)
              assert_equal :deadline_exceeded, error.execution_evidence.outcome
            end

            def test_raise_unless_success_returns_self_on_success
              capture = SafeCapture.call(["true"], timeout: 5)

              assert_same capture, capture.raise_unless_success
            end

            def test_raise_unless_success_raises_evidence_error_on_deadline
              capture = SafeCapture.call(["sleep", "2"], timeout: FAST_TIMEOUT, provider_name: "Test")

              error = assert_raises(Ace::LLM::ProviderError) { capture.raise_unless_success }

              assert_equal :deadline_exceeded, error.execution_evidence.outcome
            end

            def test_with_no_response_evidence_attaches_without_overwriting
              capture = SafeCapture.call(["true"], timeout: 5)
              existing = Ace::LLM::ProviderError.new("boom")
              existing.execution_evidence = :already_there
              error = capture.with_no_response_evidence(existing)

              assert_equal :already_there, error.execution_evidence

              fresh = Ace::LLM::ProviderError.new("Codex CLI produced no final message")
              error = capture.with_no_response_evidence(fresh)

              assert_equal :no_response, error.execution_evidence.outcome
              assert_equal 0, error.execution_evidence.exit_status
            end

            def test_timeout_accepts_numeric_string
              capture = SafeCapture.call(["true"], timeout: "0.2", provider_name: "Test")

              assert_equal 0.2, capture.deadline_seconds
              assert capture.success?
            end

            def test_timeout_rejects_non_numeric_string
              assert_raises(ArgumentError) do
                SafeCapture.call(["sleep", "60"], timeout: "bad", provider_name: "Test")
              end
            end

            def test_debug_logging_emits_lifecycle_markers
              old_env = ENV["ACE_LLM_DEBUG_SUBPROCESS"]
              old_stderr = $stderr
              stderr_io = StringIO.new
              ENV["ACE_LLM_DEBUG_SUBPROCESS"] = "1"
              $stderr = stderr_io

              SafeCapture.call(["true"], timeout: 5, provider_name: "DebugProvider")

              output = stderr_io.string
              assert_includes output, "[SafeCapture][DebugProvider] spawn"
            ensure
              ENV["ACE_LLM_DEBUG_SUBPROCESS"] = old_env
              $stderr = old_stderr
            end

            def test_deadline_does_not_emit_closed_stream_errors
              old_stderr = $stderr
              stderr_io = StringIO.new
              $stderr = stderr_io

              capture = SafeCapture.call(
                ["ruby", "-e", "STDOUT.puts('stdout'); STDERR.puts('stderr'); sleep 2"],
                timeout: FAST_TIMEOUT,
                provider_name: "Test"
              )

              assert_equal Models::CaptureResult::OUTCOME_DEADLINE_EXCEEDED, capture.outcome
              assert_empty stderr_io.string
            ensure
              $stderr = old_stderr
            end

            def test_success_cleanup_terminates_background_descendants
              Dir.mktmpdir do |dir|
                pid_file = File.join(dir, "child.pid")
                escaped = Shellwords.escape(pid_file)

                capture = SafeCapture.call(
                  ["bash", "--noprofile", "--norc", "-c", "sleep 5 & child=$!; echo \"$child\" > #{escaped}; echo done"],
                  timeout: 5,
                  provider_name: "Test"
                )

                assert_equal "done\n", capture.stdout
                assert capture.success?

                child_pid = wait_for_pid_file(pid_file)
                @tracked_pids << child_pid

                refute process_alive?(child_pid),
                  "background child PID #{child_pid} should be terminated (#{process_status(child_pid)})"
              end
            end

            def test_deadline_cleanup_terminates_background_descendants
              Dir.mktmpdir do |dir|
                pid_file = File.join(dir, "child.pid")
                escaped = Shellwords.escape(pid_file)

                capture = SafeCapture.call(
                  ["bash", "--noprofile", "--norc", "-c", "sleep 5 & child=$!; echo \"$child\" > #{escaped}; sleep 5"],
                  timeout: FAST_TIMEOUT,
                  provider_name: "Test"
                )

                assert_equal Models::CaptureResult::OUTCOME_DEADLINE_EXCEEDED, capture.outcome

                child_pid = wait_for_pid_file(pid_file)
                @tracked_pids << child_pid

                refute process_alive?(child_pid),
                  "timed-out child PID #{child_pid} should be terminated (#{process_status(child_pid)})"
              end
            end

            private

            def wait_for_pid_file(path, retries: 20, interval: 0.01)
              retries.times do
                if File.exist?(path)
                  content = File.read(path).strip
                  return content.to_i if content.match?(/\A\d+\z/)
                end
                sleep interval
              end

              flunk("Expected PID file at #{path}")
            end

            def process_alive?(pid)
              Process.kill(0, pid)
              true
            rescue Errno::ESRCH
              false
            rescue Errno::EPERM
              true
            end

            def process_status(pid)
              File.read("/proc/#{pid}/status").lines
                .grep(/\A(?:State|PPid|NSpid):/)
                .map(&:strip)
                .join(", ")
            rescue Errno::ENOENT, Errno::EACCES
              "process status unavailable"
            end
          end
        end
      end
    end
  end
end
