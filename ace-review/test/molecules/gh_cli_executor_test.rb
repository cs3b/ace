# frozen_string_literal: true

require 'test_helper'
require 'ace/review/molecules/gh_cli_executor'

module Ace
  module Review
    module Molecules
      class GhCliExecutorTest < AceReviewTest
        def setup
          super
          @executor = GhCliExecutor
        end

        # Test: Basic command execution with successful result
        def test_execute_successful_command
          # Stub Open3.capture3 to return success
          stdout = "test output"
          stderr = ""
          status = Minitest::Mock.new
          status.expect(:success?, true)
          status.expect(:success?, true)  # Called twice: once for check_installed, once for result
          status.expect(:exitstatus, 0)
          status.expect(:exitstatus, 0)

          Open3.stub(:capture3, [stdout, stderr, status]) do
            result = @executor.execute("--version")

            assert result[:success]
            assert_equal stdout, result[:stdout]
            assert_equal stderr, result[:stderr]
            assert_equal 0, result[:exit_code]
          end

          status.verify
        end

        # Test: Command execution with failure result
        def test_execute_failed_command
          install_check_status = Minitest::Mock.new
          install_check_status.expect(:success?, true)
          install_check_status.expect(:exitstatus, 0)

          exec_status = Minitest::Mock.new
          exec_status.expect(:success?, false)
          exec_status.expect(:exitstatus, 1)

          stdout = ""
          stderr = "error message"
          call_count = 0

          Open3.stub(:capture3, ->(*args, **opts) {
            call_count += 1
            if call_count == 1  # check_installed call
              ["gh version", "", install_check_status]
            else  # actual execute call
              [stdout, stderr, exec_status]
            end
          }) do
            result = @executor.execute("invalid", ["command"])

            refute result[:success]
            assert_equal stderr, result[:stderr]
            assert_equal 1, result[:exit_code]
          end

          install_check_status.verify
          exec_status.verify
        end

        # Test: Command execution with timeout
        def test_execute_with_timeout
          error = assert_raises(Ace::Review::Errors::GhNetworkError) do
            Open3.stub(:capture3, ->(*args, **opts) { raise Timeout::Error }) do
              @executor.execute("pr", ["diff", "123"], timeout: 5)
            end
          end

          assert_match(/timed out after 5 seconds/, error.message)
        end

        # Test: gh CLI not installed
        def test_execute_raises_when_gh_not_installed
          error = assert_raises(Ace::Review::Errors::GhCliNotInstalledError) do
            Open3.stub(:capture3, ->(*args, **opts) { raise Errno::ENOENT }) do
              @executor.execute("--version")
            end
          end

          assert_match(/GitHub CLI.*not installed/i, error.message)
        end

        # Test: check_installed detects gh CLI
        def test_check_installed_returns_true_when_gh_exists
          stdout = "gh version 2.40.0"
          stderr = ""
          status = Minitest::Mock.new
          status.expect(:success?, true)
          status.expect(:exitstatus, 0)

          Open3.stub(:capture3, [stdout, stderr, status]) do
            result = @executor.check_installed
            assert result
          end
        end

        # Test: check_installed raises when gh missing
        def test_check_installed_raises_when_gh_missing
          error = assert_raises(Ace::Review::Errors::GhCliNotInstalledError) do
            Open3.stub(:capture3, ->(*args, **opts) { raise Errno::ENOENT }) do
              @executor.check_installed
            end
          end

          assert_match(/not installed/, error.message)
        end

        # Test: check_authenticated detects authentication
        def test_check_authenticated_returns_status_when_authenticated
          stdout = ""
          stderr = "✓ Logged in to github.com as testuser (oauth_token)"
          status = Minitest::Mock.new
          status.expect(:success?, true)
          status.expect(:exitstatus, 0)

          Open3.stub(:capture3, [stdout, stderr, status]) do
            result = @executor.check_authenticated

            assert result[:authenticated]
            assert_equal "testuser", result[:username]
          end
        end

        # Test: check_authenticated raises when not authenticated
        def test_check_authenticated_raises_when_not_authenticated
          stdout = ""
          stderr = "You are not logged into any GitHub hosts"
          status = Minitest::Mock.new
          status.expect(:success?, false)
          status.expect(:exitstatus, 1)

          error = assert_raises(Ace::Review::Errors::GhAuthenticationError) do
            Open3.stub(:capture3, [stdout, stderr, status]) do
              @executor.check_authenticated
            end
          end

          assert_match(/authentication required/i, error.message)
        end

        # Test: extract_username parses gh auth status output
        def test_extract_username_from_auth_status
          output = "✓ Logged in to github.com as johndoe (oauth_token)\n"
          username = @executor.send(:extract_username, output)

          assert_equal "johndoe", username
        end

        # Test: extract_username handles different formats
        def test_extract_username_with_different_format
          output = "Logged in to github.com as jane_doe via oauth"
          username = @executor.send(:extract_username, output)

          assert_equal "jane_doe", username
        end

        # Test: extract_username returns nil when no match
        def test_extract_username_returns_nil_when_no_match
          output = "Not logged in"
          username = @executor.send(:extract_username, output)

          assert_nil username
        end

        # Test: execute uses Timeout module with correct timeout value
        def test_execute_uses_timeout_module
          stdout = "output"
          stderr = ""
          install_check_status = Minitest::Mock.new
          install_check_status.expect(:success?, true)
          install_check_status.expect(:exitstatus, 0)

          exec_status = Minitest::Mock.new
          exec_status.expect(:success?, true)
          exec_status.expect(:exitstatus, 0)

          timeouts_seen = []
          call_count = 0

          # Stub Timeout.timeout to capture the timeout value
          Timeout.stub(:timeout, ->(seconds, &block) {
            timeouts_seen << seconds
            # Execute the block to continue with Open3.capture3
            block.call
          }) do
            Open3.stub(:capture3, ->(*args) {
              call_count += 1
              if call_count == 1  # check_installed call
                ["gh version", "", install_check_status]
              else  # actual execute call
                [stdout, stderr, exec_status]
              end
            }) do
              @executor.execute("pr", ["view", "123"], timeout: 60)
            end
          end

          # Second timeout should be the one we passed (60)
          assert_equal 60, timeouts_seen[1], "Execute should use Timeout module with correct value"
          install_check_status.verify
          exec_status.verify
        end

        # Test: execute uses array form for safe command execution
        def test_execute_uses_array_form_for_safety
          stdout = "safe"
          stderr = ""
          install_check_status = Minitest::Mock.new
          install_check_status.expect(:success?, true)
          install_check_status.expect(:exitstatus, 0)

          exec_status = Minitest::Mock.new
          exec_status.expect(:success?, true)
          exec_status.expect(:exitstatus, 0)

          open3_called_with_array = false
          call_count = 0

          Open3.stub(:capture3, ->(*args, **opts) {
            call_count += 1
            if call_count == 1  # check_installed call
              ["gh version", "", install_check_status]
            else  # actual execute call - verify array form
              open3_called_with_array = (args[0] == "gh" && args[1] == "pr" && args[2] == "diff" && args[3] == "123")
              [stdout, stderr, exec_status]
            end
          }) do
            @executor.execute("pr", ["diff", "123"])
          end

          assert open3_called_with_array, "Commands should be passed as array, not shell string"
          install_check_status.verify
          exec_status.verify
        end
      end
    end
  end
end
