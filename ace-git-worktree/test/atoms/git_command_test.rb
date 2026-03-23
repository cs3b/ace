# frozen_string_literal: true

require "test_helper"

class GitCommandTest < Minitest::Test
  include TestHelper

  def setup
    @git_command = Ace::Git::Worktree::Atoms::GitCommand
    @ace_git_executor = Ace::Git::Atoms::CommandExecutor
  end

  def test_current_branch_delegates_to_ace_git
    # current_branch now simply delegates to ace-git's CommandExecutor
    @ace_git_executor.stub :current_branch, "feature-branch" do
      result = @git_command.current_branch
      assert_equal "feature-branch", result
    end
  end

  def test_current_branch_returns_sha_when_detached
    # ace-git now handles detached HEAD and returns SHA directly
    @ace_git_executor.stub :current_branch, "abc123def456" do
      result = @git_command.current_branch
      assert_equal "abc123def456", result
    end
  end

  def test_current_branch_returns_nil_on_failure
    @ace_git_executor.stub :current_branch, nil do
      result = @git_command.current_branch
      assert_nil result
    end
  end

  def test_ref_exists_returns_true_for_valid_ref
    @git_command.stub :execute, ->(*args, **opts) {
      if args.include?("--verify")
        {success: true, output: "abc123\n", error: "", exit_code: 0}
      else
        {success: false, output: "", error: "unexpected", exit_code: 1}
      end
    } do
      result = @git_command.ref_exists?("main")
      assert result, "Should return true for valid ref"
    end
  end

  def test_ref_exists_returns_false_for_invalid_ref
    @git_command.stub :execute, ->(*args, **opts) {
      if args.include?("--verify")
        {success: false, output: "", error: "not a valid ref", exit_code: 128}
      else
        {success: false, output: "", error: "unexpected", exit_code: 1}
      end
    } do
      result = @git_command.ref_exists?("nonexistent-branch")
      refute result, "Should return false for invalid ref"
    end
  end

  def test_git_repository_check
    # Stub ace-git's in_git_repo? method
    @ace_git_executor.stub :in_git_repo?, true do
      result = @git_command.git_repository?
      assert result, "Should return true when in git repository"
    end
  end

  def test_git_root_returns_path
    # Stub ace-git's repo_root method
    @ace_git_executor.stub :repo_root, "/path/to/repo" do
      result = @git_command.git_root
      assert_equal "/path/to/repo", result
    end
  end

  def test_worktree_delegates_to_execute
    executed_args = nil
    @git_command.stub :execute, ->(*args, **opts) {
      executed_args = args
      {success: true, output: "worktree output\n", error: "", exit_code: 0}
    } do
      @git_command.worktree("add", "/path", "-b", "branch")
      assert_equal ["worktree", "add", "/path", "-b", "branch"], executed_args
    end
  end

  def test_execute_delegates_to_ace_git_command_executor
    # Verify execute properly delegates to ace-git's CommandExecutor
    @ace_git_executor.stub :execute, ->(*args, **opts) {
      {success: true, output: "test output", error: "", exit_code: 0}
    } do
      result = @git_command.execute("status")
      assert result[:success]
      assert_equal "test output", result[:output]
    end
  end

  def test_execute_passes_timeout_to_command_executor
    # Verify timeout parameter is correctly forwarded to ace-git's CommandExecutor
    captured_opts = nil
    @ace_git_executor.stub :execute, ->(*args, **opts) {
      captured_opts = opts
      {success: true, output: "", error: "", exit_code: 0}
    } do
      @git_command.execute("status", timeout: 60)
      assert_equal 60, captured_opts[:timeout], "Timeout should be passed to CommandExecutor"
    end
  end

  def test_execute_uses_default_timeout
    # Verify default timeout is used when not specified
    # Uses config-driven timeout with FALLBACK_TIMEOUT as safety net
    captured_opts = nil
    @ace_git_executor.stub :execute, ->(*args, **opts) {
      captured_opts = opts
      {success: true, output: "", error: "", exit_code: 0}
    } do
      @git_command.execute("status")
      # Default timeout should be either from config or fallback (30)
      expected_timeout = @git_command.default_timeout
      assert_equal expected_timeout, captured_opts[:timeout],
        "Default timeout from config should be used"
    end
  end

  def test_worktree_passes_timeout_to_execute
    # Verify worktree method forwards timeout correctly
    captured_opts = nil
    @ace_git_executor.stub :execute, ->(*args, **opts) {
      captured_opts = opts
      {success: true, output: "", error: "", exit_code: 0}
    } do
      @git_command.worktree("list", timeout: 45)
      assert_equal 45, captured_opts[:timeout], "Timeout should be passed through worktree method"
    end
  end
end
