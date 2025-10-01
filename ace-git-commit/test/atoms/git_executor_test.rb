# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class GitExecutorTest < TestCase
  def setup
    @git = Ace::GitCommit::Atoms::GitExecutor.new
  end

  def test_execute_runs_git_command_successfully
    Open3.stub :capture2, mock_capture2_success("git version 2.39.0\n") do
      result = @git.execute("--version")
      assert_equal "git version 2.39.0\n", result
    end
  end

  def test_execute_raises_on_command_failure
    Open3.stub :capture2, mock_capture2_failure("error", 128) do
      error = assert_raises(Ace::GitCommit::GitError) do
        @git.execute("invalid-command")
      end
      assert_match(/Git command failed/, error.message)
    end
  end

  def test_execute_with_capture_stderr
    Open3.stub :capture3, mock_capture3_success("output\n", "warning\n") do
      result = @git.execute("command", capture_stderr: true)
      assert_equal "output\nwarning\n", result
    end
  end

  def test_execute_with_capture_stderr_on_failure
    Open3.stub :capture3, mock_capture3_failure("", "fatal error\n", 1) do
      error = assert_raises(Ace::GitCommit::GitError) do
        @git.execute("bad-command", capture_stderr: true)
      end
      assert_match(/fatal error/, error.message)
    end
  end

  def test_in_repository_returns_true_when_in_repo
    Open3.stub :capture2, mock_capture2_success(".git\n") do
      assert @git.in_repository?
    end
  end

  def test_in_repository_returns_false_when_not_in_repo
    Open3.stub :capture2, mock_capture2_failure("fatal: not a git repository\n", 128) do
      refute @git.in_repository?
    end
  end

  def test_repository_root_returns_path
    Open3.stub :capture2, mock_capture2_success("/home/user/project\n") do
      root = @git.repository_root
      assert_equal "/home/user/project", root
    end
  end

  def test_has_changes_returns_true_when_changes_exist
    Open3.stub :capture2, mock_capture2_success(" M file.txt\n?? new.txt\n") do
      assert @git.has_changes?
    end
  end

  def test_has_changes_returns_false_when_no_changes
    Open3.stub :capture2, mock_capture2_success("") do
      refute @git.has_changes?
    end
  end

  def test_has_staged_changes_returns_true_when_staged
    Open3.stub :capture2, mock_capture2_success("file.txt\n") do
      assert @git.has_staged_changes?
    end
  end

  def test_has_staged_changes_returns_false_when_none_staged
    Open3.stub :capture2, mock_capture2_success("") do
      refute @git.has_staged_changes?
    end
  end
end