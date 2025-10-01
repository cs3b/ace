# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "open3"

class GitExecutorEdgeTest < TestCase
  def setup
    @git = Ace::GitCommit::Atoms::GitExecutor.new
  end

  # Most edge cases can be tested with mocks
  def test_handles_detached_head_state
    Open3.stub :capture2, mock_capture2_success(".git\n") do
      assert @git.in_repository?
    end

    Open3.stub :capture2, mock_capture2_success("/repo/path\n") do
      root = @git.repository_root
      assert_equal "/repo/path", root
    end
  end

  def test_handles_empty_repository
    Open3.stub :capture2, mock_capture2_success(".git\n") do
      assert @git.in_repository?
    end

    Open3.stub :capture2, mock_capture2_success("/repo/path\n") do
      root = @git.repository_root
      assert_equal "/repo/path", root
    end

    Open3.stub :capture2, mock_capture2_success("") do
      refute @git.has_changes?
    end
  end

  def test_handles_repository_with_untracked_files
    Open3.stub :capture2, mock_capture2_success("?? untracked.txt\n") do
      assert @git.has_changes?
    end
  end

  def test_handles_repository_with_staged_changes
    Open3.stub :capture2, mock_capture2_success("staged.txt\n") do
      assert @git.has_staged_changes?
    end
  end

  def test_handles_repository_with_modified_files
    Open3.stub :capture2, mock_capture2_success(" M tracked.txt\n") do
      assert @git.has_changes?
    end
  end

  def test_handles_non_git_directory
    Open3.stub :capture2, mock_capture2_failure("fatal: not a git repository\n", 128) do
      refute @git.in_repository?
    end
  end

  def test_handles_git_command_failure
    Open3.stub :capture2, mock_capture2_failure("fatal: invalid command\n", 128) do
      assert_raises(Ace::GitCommit::GitError) do
        @git.execute("invalid-command")
      end
    end
  end

  def test_handles_repository_in_subdirectory
    Open3.stub :capture2, mock_capture2_success(".git\n") do
      assert @git.in_repository?
    end

    Open3.stub :capture2, mock_capture2_success("/repo\n") do
      root = @git.repository_root
      assert_equal "/repo", root
    end
  end

  def test_handles_bare_repository
    Open3.stub :capture2, mock_capture2_success(".") do
      assert @git.in_repository?
    end
  end

  def test_handles_repository_with_gitignore
    Open3.stub :capture2, mock_capture2_success(".git\n") do
      assert @git.in_repository?
    end
  end

  def test_handles_repository_with_unicode_filenames
    Open3.stub :capture2, mock_capture2_success("café.txt\n") do
      assert @git.has_staged_changes?
    end
  end

  def test_handles_repository_with_spaces_in_filenames
    Open3.stub :capture2, mock_capture2_success("file with spaces.txt\n") do
      assert @git.has_staged_changes?
    end
  end

  def test_handles_very_large_repository
    # Simulate many files in git status
    many_files = (0...100).map { |i| "?? file#{i}.txt\n" }.join
    Open3.stub :capture2, mock_capture2_success(many_files) do
      assert @git.has_changes?
    end
  end

  def test_handles_repository_with_submodules
    Open3.stub :capture2, mock_capture2_success(".git\n") do
      assert @git.in_repository?
    end
  end

  def test_handles_worktree_directory
    Open3.stub :capture2, mock_capture2_success(".git\n") do
      assert @git.in_repository?
    end
  end

  # Integration tests - Keep 3 real git tests for critical workflows
  def test_integration_real_git_repository
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        git = Ace::GitCommit::Atoms::GitExecutor.new

        assert git.in_repository?
        # Use realpath to handle /private prefix on macOS
        assert_equal File.realpath(tmpdir), File.realpath(git.repository_root)

        # Create and stage file
        File.write("test.txt", "content")
        system("git add test.txt")

        assert git.has_changes?
        assert git.has_staged_changes?
      end
    end
  end

  def test_integration_commit_workflow
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        git = Ace::GitCommit::Atoms::GitExecutor.new

        # Create and stage file
        File.write("test.txt", "content")
        git.execute("add", "test.txt")

        # Commit
        git.execute("commit", "-m", "Initial commit")

        # Verify commit exists
        log = git.execute("log", "--oneline")
        assert_match(/Initial commit/, log)
      end
    end
  end

  def test_integration_detached_head_workflow
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create initial commit
        File.write("file1.txt", "content1")
        system("git add file1.txt")
        system("git commit -q -m 'Initial commit'")

        # Create second commit
        File.write("file2.txt", "content2")
        system("git add file2.txt")
        system("git commit -q -m 'Second commit'")

        # Get first commit hash and checkout
        first_commit = `git rev-parse HEAD~1`.strip
        system("git checkout -q #{first_commit}")

        git = Ace::GitCommit::Atoms::GitExecutor.new

        # Should still work in detached HEAD
        assert git.in_repository?
        root = git.repository_root
        assert File.directory?(root)
      end
    end
  end
end
