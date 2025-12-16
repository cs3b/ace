# frozen_string_literal: true

require "test_helper"
require "ace/context/molecules/gh_pr_executor"

module Ace
  module Context
    module Molecules
      class GhPrExecutorTest < Minitest::Test
        # Test helper class that mocks gh command execution
        class MockGhPrExecutor < GhPrExecutor
          attr_accessor :mock_stdout, :mock_stderr, :mock_status

          protected

          def execute_gh_command(args)
            @last_args = args
            [@mock_stdout, @mock_stderr, @mock_status]
          end
        end

        def setup
          @mock_status_success = Minitest::Mock.new
          @mock_status_success.expect(:success?, true)
          @mock_status_success.expect(:exitstatus, 0)

          @mock_status_failure = Minitest::Mock.new
          @mock_status_failure.expect(:success?, false)
          @mock_status_failure.expect(:exitstatus, 1)
        end

        def test_fetch_diff_with_simple_number
          executor = MockGhPrExecutor.new("123")
          executor.mock_stdout = "diff --git a/file.rb b/file.rb\n+new line"
          executor.mock_stderr = ""
          executor.mock_status = @mock_status_success

          result = executor.fetch_diff

          assert result[:success]
          assert_equal "diff --git a/file.rb b/file.rb\n+new line", result[:diff]
          assert_equal "123", result[:identifier]
          assert_equal "pr:123", result[:source]
        end

        def test_fetch_diff_with_qualified_reference
          executor = MockGhPrExecutor.new("owner/repo#456")
          executor.mock_stdout = "diff --git a/lib/foo.rb b/lib/foo.rb\n-old line"
          executor.mock_stderr = ""
          executor.mock_status = @mock_status_success

          result = executor.fetch_diff

          assert result[:success]
          assert_equal "diff --git a/lib/foo.rb b/lib/foo.rb\n-old line", result[:diff]
          assert_equal "owner/repo#456", result[:identifier]
          assert_equal "pr:owner/repo#456", result[:source]
        end

        def test_fetch_diff_with_github_url
          executor = MockGhPrExecutor.new("https://github.com/rails/rails/pull/12345")
          executor.mock_stdout = "diff content"
          executor.mock_stderr = ""
          executor.mock_status = @mock_status_success

          result = executor.fetch_diff

          assert result[:success]
          assert_equal "diff content", result[:diff]
          assert_equal "rails/rails#12345", result[:identifier]
          assert_equal "pr:rails/rails#12345", result[:source]
        end

        def test_fetch_diff_raises_for_not_found
          executor = MockGhPrExecutor.new("999999")
          executor.mock_stdout = ""
          executor.mock_stderr = "Error: PR not found in repository"
          executor.mock_status = @mock_status_failure

          error = assert_raises(GhPrExecutor::PrNotFoundError) do
            executor.fetch_diff
          end

          assert_match(/PR not found/, error.message)
        end

        def test_fetch_diff_raises_for_authentication_error
          executor = MockGhPrExecutor.new("123")
          executor.mock_stdout = ""
          executor.mock_stderr = "Error: authentication required"
          executor.mock_status = @mock_status_failure

          error = assert_raises(GhPrExecutor::GhAuthenticationError) do
            executor.fetch_diff
          end

          assert_match(/Not authenticated/, error.message)
          assert_match(/gh auth login/, error.message)
        end

        def test_fetch_diff_raises_for_unauthorized
          executor = MockGhPrExecutor.new("123")
          executor.mock_stdout = ""
          executor.mock_stderr = "Error: Unauthorized access"
          executor.mock_status = @mock_status_failure

          error = assert_raises(GhPrExecutor::GhAuthenticationError) do
            executor.fetch_diff
          end

          assert_match(/Not authenticated/, error.message)
        end

        def test_fetch_diff_raises_for_generic_error
          executor = MockGhPrExecutor.new("123")
          executor.mock_stdout = ""
          executor.mock_stderr = "Some unexpected error"
          executor.mock_status = @mock_status_failure

          error = assert_raises(GhPrExecutor::GhCommandError) do
            executor.fetch_diff
          end

          assert_match(/gh pr diff failed/, error.message)
          assert_match(/Some unexpected error/, error.message)
        end

        def test_fetch_diff_raises_for_nil_identifier
          executor = MockGhPrExecutor.new(nil)

          error = assert_raises(ArgumentError) do
            executor.fetch_diff
          end

          assert_match(/Invalid PR identifier/, error.message)
        end

        def test_fetch_diff_raises_for_empty_identifier
          executor = MockGhPrExecutor.new("")

          error = assert_raises(ArgumentError) do
            executor.fetch_diff
          end

          assert_match(/Invalid PR identifier/, error.message)
        end

        def test_constructor_raises_for_invalid_format
          error = assert_raises(ArgumentError) do
            GhPrExecutor.new("invalid-format")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        def test_gh_not_installed_error
          # Create a real executor that will actually try to run gh
          # We'll make it raise Errno::ENOENT by stubbing execute_gh_command
          executor = Class.new(GhPrExecutor) do
            protected

            def execute_gh_command(args)
              raise Errno::ENOENT, "No such file or directory - gh"
            end
          end.new("123")

          error = assert_raises(GhPrExecutor::GhNotInstalledError) do
            executor.fetch_diff
          end

          assert_match(/GitHub CLI \(gh\) not installed/, error.message)
          assert_match(/brew install gh/, error.message)
        end

        def test_error_classes_are_standard_errors
          assert_kind_of Class, GhPrExecutor::GhCommandError
          assert_kind_of Class, GhPrExecutor::GhNotInstalledError
          assert_kind_of Class, GhPrExecutor::GhAuthenticationError
          assert_kind_of Class, GhPrExecutor::PrNotFoundError
          assert_kind_of Class, GhPrExecutor::TimeoutError

          assert GhPrExecutor::GhCommandError < StandardError
          assert GhPrExecutor::GhNotInstalledError < StandardError
          assert GhPrExecutor::GhAuthenticationError < StandardError
          assert GhPrExecutor::PrNotFoundError < StandardError
          assert GhPrExecutor::TimeoutError < StandardError
        end

        def test_fetch_diff_raises_for_not_logged_in
          executor = MockGhPrExecutor.new("123")
          executor.mock_stdout = ""
          executor.mock_stderr = "To get started with GitHub CLI, please run: gh auth login"
          executor.mock_status = @mock_status_failure

          error = assert_raises(GhPrExecutor::GhAuthenticationError) do
            executor.fetch_diff
          end

          assert_match(/Not authenticated/, error.message)
          assert_match(/gh auth login/, error.message)
        end

        def test_timeout_raises_timeout_error
          executor = Class.new(GhPrExecutor) do
            protected

            def execute_gh_command(args)
              sleep 0.2  # Simulate slow command
              ["", "", Minitest::Mock.new.tap { |m| m.expect(:success?, true) }]
            end
          end.new("123", timeout: 0.05)

          error = assert_raises(GhPrExecutor::TimeoutError) do
            executor.fetch_diff
          end

          assert_match(/timed out/, error.message)
          assert_match(/123/, error.message)
        end

        def test_custom_timeout_is_used
          executor = GhPrExecutor.new("123", timeout: 60)
          # Verify the timeout is stored (implementation detail, but useful for testing)
          assert_equal 60, executor.instance_variable_get(:@timeout)
        end

        def test_default_timeout_constant
          assert_equal 30, GhPrExecutor::DEFAULT_TIMEOUT
        end
      end
    end
  end
end
