# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/llm/providers/cli/molecules/safe_capture"
require "tmpdir"
require "shellwords"
require "stringio"

module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          class SafeCaptureTest < Minitest::Test
            def setup
              @tracked_pids = []
            end

            def teardown
              @tracked_pids.each do |pid|
                begin
                  Process.kill("KILL", pid)
                rescue Errno::ESRCH, Errno::EPERM
                  nil
                end
              end
            end

            def test_captures_stdout_and_stderr
              stdout, stderr, status = SafeCapture.call(
                ["ruby", "-e", "STDOUT.print 'hello'; STDERR.print 'world'"],
                timeout: 5
              )

              assert_equal "hello", stdout
              assert_equal "world", stderr
              assert status.success?
            end

            def test_timeout_kills_process
              error = assert_raises(Ace::LLM::ProviderError) do
                SafeCapture.call(["sleep", "60"], timeout: 1, provider_name: "Test")
              end

              assert_match(/Test CLI execution timed out after 1 seconds/, error.message)
            end

            def test_stdin_data_passed
              stdout, _stderr, status = SafeCapture.call(
                ["cat"],
                timeout: 5,
                stdin_data: "piped input"
              )

              assert_equal "piped input", stdout
              assert status.success?
            end

            def test_returns_process_status
              _stdout, _stderr, status = SafeCapture.call(["true"], timeout: 5)
              assert_instance_of Process::Status, status
              assert status.success?

              _stdout, _stderr, status = SafeCapture.call(["false"], timeout: 5)
              assert_instance_of Process::Status, status
              refute status.success?
            end

            def test_chdir_option
              stdout, _stderr, status = SafeCapture.call(
                ["pwd"],
                timeout: 5,
                chdir: "/tmp"
              )

              assert_match %r{/tmp}, stdout.strip
              assert status.success?
            end

            def test_provider_name_in_timeout_message
              error = assert_raises(Ace::LLM::ProviderError) do
                SafeCapture.call(["sleep", "60"], timeout: 1, provider_name: "Gemini")
              end

              assert_match(/Gemini CLI execution timed out/, error.message)
            end

            def test_env_option_passed_to_subprocess
              stdout, _stderr, status = SafeCapture.call(
                ["ruby", "-e", "print ENV['ACE_SAFE_CAPTURE_TEST']"],
                timeout: 5,
                env: { "ACE_SAFE_CAPTURE_TEST" => "env-ok" }
              )

              assert_equal "env-ok", stdout
              assert status.success?
            end

            def test_default_provider_name
              error = assert_raises(Ace::LLM::ProviderError) do
                SafeCapture.call(["sleep", "60"], timeout: 1)
              end

              assert_match(/CLI CLI execution timed out/, error.message)
            end

            def test_success_cleanup_terminates_background_descendants
              Dir.mktmpdir do |dir|
                pid_file = File.join(dir, "child.pid")
                escaped = Shellwords.escape(pid_file)

                stdout, _stderr, status = SafeCapture.call(
                  ["bash", "-lc", "sleep 30 & child=$!; echo \"$child\" > #{escaped}; echo done"],
                  timeout: 5,
                  provider_name: "Test"
                )

                assert_equal "done\n", stdout
                assert status.success?

                child_pid = wait_for_pid_file(pid_file)
                @tracked_pids << child_pid
                sleep 0.1

                refute process_alive?(child_pid), "background child PID #{child_pid} should be terminated"
              end
            end

    def test_timeout_cleanup_terminates_background_descendants
      Dir.mktmpdir do |dir|
        pid_file = File.join(dir, "child.pid")
        escaped = Shellwords.escape(pid_file)

                error = assert_raises(Ace::LLM::ProviderError) do
                  SafeCapture.call(
                    ["bash", "-lc", "sleep 30 & child=$!; echo \"$child\" > #{escaped}; sleep 30"],
                    timeout: 1,
                    provider_name: "Test"
                  )
                end

                assert_match(/Test CLI execution timed out after 1 seconds/, error.message)

                child_pid = wait_for_pid_file(pid_file)
                @tracked_pids << child_pid
                sleep 0.1

                refute process_alive?(child_pid), "timed-out child PID #{child_pid} should be terminated"
              end
            end

            def test_timeout_accepts_numeric_string
              error = assert_raises(Ace::LLM::ProviderError) do
                SafeCapture.call(["sleep", "60"], timeout: "1", provider_name: "Test")
              end

              assert_match(/Test CLI execution timed out after 1(\.0+)? seconds/, error.message)
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

            def test_timeout_does_not_emit_closed_stream_errors
              old_stderr = $stderr
              stderr_io = StringIO.new
              $stderr = stderr_io

              error = assert_raises(Ace::LLM::ProviderError) do
                SafeCapture.call(
                  ["ruby", "-e", "STDOUT.puts('stdout'); STDERR.puts('stderr'); sleep 10"],
                  timeout: 1,
                  provider_name: "Test"
                )
              end

              assert_match(/Test CLI execution timed out after 1 seconds/, error.message)
              assert_empty stderr_io.string
            ensure
              $stderr = old_stderr
            end

            private

            def wait_for_pid_file(path, retries: 20, interval: 0.05)
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
          end
        end
      end
    end
  end
end
