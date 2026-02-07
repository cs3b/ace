# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/llm/providers/cli/molecules/safe_capture"

module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          class SafeCaptureTest < Minitest::Test
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

            def test_default_provider_name
              error = assert_raises(Ace::LLM::ProviderError) do
                SafeCapture.call(["sleep", "60"], timeout: 1)
              end

              assert_match(/CLI CLI execution timed out/, error.message)
            end
          end
        end
      end
    end
  end
end
