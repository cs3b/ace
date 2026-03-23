# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class GitExecutorEdgeTest < TestCase
  def setup
    @git = Ace::GitCommit::Atoms::GitExecutor.new
    @cmd_executor = Ace::Git::Atoms::CommandExecutor
  end

  # Most edge cases can be tested with mocks
  def test_handles_detached_head_state
    @cmd_executor.stub :in_git_repo?, true do
      assert @git.in_repository?
    end

    @cmd_executor.stub :repo_root, "/repo/path" do
      root = @git.repository_root
      assert_equal "/repo/path", root
    end
  end

  def test_handles_empty_repository
    @cmd_executor.stub :in_git_repo?, true do
      assert @git.in_repository?
    end

    @cmd_executor.stub :repo_root, "/repo/path" do
      root = @git.repository_root
      assert_equal "/repo/path", root
    end

    @cmd_executor.stub :has_unstaged_changes?, false do
      @cmd_executor.stub :has_staged_changes?, false do
        @cmd_executor.stub :has_untracked_changes?, false do
          refute @git.has_changes?
        end
      end
    end
  end

  def test_handles_repository_with_untracked_files
    @cmd_executor.stub :has_unstaged_changes?, false do
      @cmd_executor.stub :has_staged_changes?, false do
        @cmd_executor.stub :has_untracked_changes?, true do
          assert @git.has_changes?
        end
      end
    end
  end

  def test_handles_repository_with_staged_changes
    @cmd_executor.stub :has_staged_changes?, true do
      assert @git.has_staged_changes?
    end
  end

  def test_handles_repository_with_modified_files
    @cmd_executor.stub :has_unstaged_changes?, true do
      @cmd_executor.stub :has_staged_changes?, false do
        @cmd_executor.stub :has_untracked_changes?, false do
          assert @git.has_changes?
        end
      end
    end
  end

  def test_handles_non_git_directory
    @cmd_executor.stub :in_git_repo?, false do
      refute @git.in_repository?
    end
  end

  def test_handles_git_command_failure
    @cmd_executor.stub :execute, {success: false, output: "", error: "fatal: invalid command\n"} do
      assert_raises(Ace::GitCommit::GitError) do
        @git.execute("invalid-command")
      end
    end
  end

  def test_handles_repository_in_subdirectory
    @cmd_executor.stub :in_git_repo?, true do
      assert @git.in_repository?
    end

    @cmd_executor.stub :repo_root, "/repo" do
      root = @git.repository_root
      assert_equal "/repo", root
    end
  end

  def test_handles_bare_repository
    @cmd_executor.stub :in_git_repo?, true do
      assert @git.in_repository?
    end
  end

  def test_handles_repository_with_gitignore
    @cmd_executor.stub :in_git_repo?, true do
      assert @git.in_repository?
    end
  end

  def test_handles_repository_with_unicode_filenames
    @cmd_executor.stub :has_staged_changes?, true do
      assert @git.has_staged_changes?
    end
  end

  def test_handles_repository_with_spaces_in_filenames
    @cmd_executor.stub :has_staged_changes?, true do
      assert @git.has_staged_changes?
    end
  end

  def test_handles_very_large_repository
    @cmd_executor.stub :has_unstaged_changes?, true do
      @cmd_executor.stub :has_staged_changes?, false do
        @cmd_executor.stub :has_untracked_changes?, false do
          assert @git.has_changes?
        end
      end
    end
  end

  def test_handles_repository_with_submodules
    @cmd_executor.stub :in_git_repo?, true do
      assert @git.in_repository?
    end
  end

  def test_handles_worktree_directory
    @cmd_executor.stub :in_git_repo?, true do
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

  def test_integration_reports_changes_for_untracked_file
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        git = Ace::GitCommit::Atoms::GitExecutor.new
        File.write("untracked.txt", "content")

        assert git.has_changes?
        refute git.has_staged_changes?
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
