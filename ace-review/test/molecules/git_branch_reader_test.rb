# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/git_branch_reader"
require "tmpdir"
require "fileutils"
require "open3"

module Ace
  module Review
    module Molecules
      class GitBranchReaderTest < Minitest::Test
        def setup
          @original_dir = Dir.pwd
        end

        def teardown
          Dir.chdir(@original_dir)
        end

        def test_current_branch_returns_branch_name
          # Mock Open3.capture3 for deterministic testing
          mock_result = ["main\n", "", mock_status(true)]

          Open3.stub :capture3, mock_result do
            branch = GitBranchReader.current_branch
            assert_equal "main", branch
          end
        end

        def test_current_branch_returns_head_for_detached
          # Create a real temp git repo to test detached HEAD
          Dir.mktmpdir do |tmpdir|
            Dir.chdir(tmpdir) do
              # Set up a temporary git repo
              system("git init > /dev/null 2>&1")
              system("git config user.email 'test@example.com' > /dev/null 2>&1")
              system("git config user.name 'Test User' > /dev/null 2>&1")
              system("touch a && git add a && git commit -m 'initial' > /dev/null 2>&1")

              # Create a detached HEAD state
              system("git checkout --detach HEAD > /dev/null 2>&1")

              branch = GitBranchReader.current_branch
              assert_equal "HEAD", branch
            end
          end
        end

        def test_current_branch_outside_git_repo
          # Mock git command failure (not in a repo)
          mock_result = ["", "fatal: not a git repository", mock_status(false)]

          Open3.stub :capture3, mock_result do
            branch = GitBranchReader.current_branch
            assert_nil branch, "Should return nil outside git repo"
          end
        end

        def test_handles_git_command_failure_gracefully
          # Mock Open3.capture3 to simulate git failure
          mock_result = ["", "error: some git error", mock_status(false)]

          Open3.stub :capture3, mock_result do
            result = GitBranchReader.current_branch
            assert_nil result
          end
        end

        def test_handles_empty_output
          # Mock empty output
          mock_result = ["", "", mock_status(true)]

          Open3.stub :capture3, mock_result do
            branch = GitBranchReader.current_branch
            assert_nil branch, "Should return nil for empty output"
          end
        end

        def test_handles_exception
          # Mock Open3.capture3 to raise an exception
          Open3.stub :capture3, ->(*) { raise StandardError, "simulated error" } do
            result = GitBranchReader.current_branch
            assert_nil result, "Should return nil on exception"
          end
        end

        private

        def mock_status(success)
          status = Minitest::Mock.new
          status.expect :success?, success
          status
        end
      end
    end
  end
end
