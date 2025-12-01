# frozen_string_literal: true

require "test_helper"

class GitCommandTest < Minitest::Test
  include TestHelper

  def setup
    @git_command = Ace::Git::Worktree::Atoms::GitCommand
  end

  def test_current_branch_returns_branch_name
    # Stub execute to return a branch name
    @git_command.stub :execute, ->(*args, **opts) {
      if args.include?("--show-current")
        { success: true, output: "feature-branch\n", error: "", exit_code: 0 }
      else
        { success: false, output: "", error: "unexpected", exit_code: 1 }
      end
    } do
      result = @git_command.current_branch
      assert_equal "feature-branch", result
    end
  end

  def test_current_branch_returns_sha_when_detached
    call_count = 0
    @git_command.stub :execute, ->(*args, **opts) {
      call_count += 1
      if args.include?("--show-current")
        # Empty output indicates detached HEAD
        { success: true, output: "", error: "", exit_code: 0 }
      elsif args.include?("rev-parse") && args.include?("HEAD")
        { success: true, output: "abc123def456\n", error: "", exit_code: 0 }
      else
        { success: false, output: "", error: "unexpected", exit_code: 1 }
      end
    } do
      result = @git_command.current_branch
      assert_equal "abc123def456", result
      assert_equal 2, call_count, "Should call execute twice for detached HEAD"
    end
  end

  def test_current_branch_returns_nil_on_failure
    @git_command.stub :execute, ->(*args, **opts) {
      { success: false, output: "", error: "not a git repository", exit_code: 128 }
    } do
      result = @git_command.current_branch
      assert_nil result
    end
  end

  def test_ref_exists_returns_true_for_valid_ref
    @git_command.stub :execute, ->(*args, **opts) {
      if args.include?("--verify")
        { success: true, output: "abc123\n", error: "", exit_code: 0 }
      else
        { success: false, output: "", error: "unexpected", exit_code: 1 }
      end
    } do
      result = @git_command.ref_exists?("main")
      assert result, "Should return true for valid ref"
    end
  end

  def test_ref_exists_returns_false_for_invalid_ref
    @git_command.stub :execute, ->(*args, **opts) {
      if args.include?("--verify")
        { success: false, output: "", error: "not a valid ref", exit_code: 128 }
      else
        { success: false, output: "", error: "unexpected", exit_code: 1 }
      end
    } do
      result = @git_command.ref_exists?("nonexistent-branch")
      refute result, "Should return false for invalid ref"
    end
  end

  def test_git_repository_check
    @git_command.stub :execute, ->(*args, **opts) {
      if args.include?("--git-dir")
        { success: true, output: ".git\n", error: "", exit_code: 0 }
      else
        { success: false, output: "", error: "unexpected", exit_code: 1 }
      end
    } do
      result = @git_command.git_repository?
      assert result, "Should return true when in git repository"
    end
  end

  def test_git_root_returns_path
    @git_command.stub :execute, ->(*args, **opts) {
      if args.include?("--show-toplevel")
        { success: true, output: "/path/to/repo\n", error: "", exit_code: 0 }
      else
        { success: false, output: "", error: "unexpected", exit_code: 1 }
      end
    } do
      result = @git_command.git_root
      assert_equal "/path/to/repo", result
    end
  end

  def test_worktree_delegates_to_execute
    executed_args = nil
    @git_command.stub :execute, ->(*args, **opts) {
      executed_args = args
      { success: true, output: "worktree output\n", error: "", exit_code: 0 }
    } do
      @git_command.worktree("add", "/path", "-b", "branch")
      assert_equal ["worktree", "add", "/path", "-b", "branch"], executed_args
    end
  end
end
