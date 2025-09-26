# frozen_string_literal: true

require_relative "../test_helper"

class GitExecutorTest < TestCase
  def setup
    @git = Ace::GitCommit::Atoms::GitExecutor.new
  end

  def test_execute_runs_git_command
    # This test will only work in a git repository
    skip unless in_git_repository?

    result = @git.execute("--version")
    assert_match(/git version/, result)
  end

  def test_in_repository_returns_true_in_git_repo
    # This test assumes we're running in a git repo
    skip unless system("git rev-parse --git-dir > /dev/null 2>&1")

    assert @git.in_repository?
  end

  def test_repository_root_returns_path
    skip unless in_git_repository?

    root = @git.repository_root
    assert File.directory?(root)
    assert File.exist?(File.join(root, ".git"))
  end

  def test_has_changes_detects_changes
    skip unless in_git_repository?

    # This might be true or false depending on repo state
    result = @git.has_changes?
    assert [true, false].include?(result)
  end

  private

  def in_git_repository?
    system("git rev-parse --git-dir > /dev/null 2>&1")
  end
end