# frozen_string_literal: true

require_relative "../../test_helper"

class GitExecutorTest < TestCase
  def setup
    @git = Ace::GitCommit::Atoms::GitExecutor.new
    @cmd_executor = Ace::Git::Atoms::CommandExecutor
  end

  def test_execute_runs_git_command_successfully
    @cmd_executor.stub :execute, {success: true, output: "git version 2.39.0\n", error: ""} do
      result = @git.execute("--version")
      assert_equal "git version 2.39.0\n", result
    end
  end

  def test_execute_raises_on_command_failure
    @cmd_executor.stub :execute, {success: false, output: "", error: "error"} do
      error = assert_raises(Ace::GitCommit::GitError) do
        @git.execute("invalid-command")
      end
      assert_match(/Git command failed/, error.message)
    end
  end

  def test_execute_with_capture_stderr
    @cmd_executor.stub :execute, {success: true, output: "output\n", error: "warning\n"} do
      result = @git.execute("command", capture_stderr: true)
      assert_equal "output\nwarning\n", result
    end
  end

  def test_execute_with_capture_stderr_on_failure
    @cmd_executor.stub :execute, {success: false, output: "", error: "fatal error\n"} do
      error = assert_raises(Ace::GitCommit::GitError) do
        @git.execute("bad-command", capture_stderr: true)
      end
      assert_match(/fatal error/, error.message)
    end
  end

  def test_in_repository_returns_true_when_in_repo
    @cmd_executor.stub :in_git_repo?, true do
      assert @git.in_repository?
    end
  end

  def test_in_repository_returns_false_when_not_in_repo
    @cmd_executor.stub :in_git_repo?, false do
      refute @git.in_repository?
    end
  end

  def test_repository_root_returns_path
    @cmd_executor.stub :repo_root, "/home/user/project" do
      root = @git.repository_root
      assert_equal "/home/user/project", root
    end
  end

  def test_has_changes_returns_true_when_changes_exist
    @cmd_executor.stub :has_unstaged_changes?, true do
      @cmd_executor.stub :has_staged_changes?, false do
        @cmd_executor.stub :has_untracked_changes?, false do
          assert @git.has_changes?
        end
      end
    end
  end

  def test_has_changes_returns_true_when_untracked_files_exist
    @cmd_executor.stub :has_unstaged_changes?, false do
      @cmd_executor.stub :has_staged_changes?, false do
        @cmd_executor.stub :has_untracked_changes?, true do
          assert @git.has_changes?
        end
      end
    end
  end

  def test_has_changes_returns_false_when_no_changes
    @cmd_executor.stub :has_unstaged_changes?, false do
      @cmd_executor.stub :has_staged_changes?, false do
        @cmd_executor.stub :has_untracked_changes?, false do
          refute @git.has_changes?
        end
      end
    end
  end

  def test_has_staged_changes_returns_true_when_staged
    @cmd_executor.stub :has_staged_changes?, true do
      assert @git.has_staged_changes?
    end
  end

  def test_has_staged_changes_returns_false_when_none_staged
    @cmd_executor.stub :has_staged_changes?, false do
      refute @git.has_staged_changes?
    end
  end
end
