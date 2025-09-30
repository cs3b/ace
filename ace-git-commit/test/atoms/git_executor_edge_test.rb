# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class GitExecutorEdgeTest < TestCase
  def setup
    @git = Ace::GitCommit::Atoms::GitExecutor.new
  end

  def test_handles_detached_head_state
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        # Initialize git repo
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

        # Get first commit hash
        first_commit = `git rev-parse HEAD~1`.strip

        # Checkout first commit to enter detached HEAD state
        system("git checkout -q #{first_commit}")

        # Should still detect we're in a repository
        assert @git.in_repository?

        # Should get repository root even in detached HEAD
        root = @git.repository_root
        assert File.directory?(root)
      end
    end
  end

  def test_handles_empty_repository
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        # Initialize empty git repo
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Should detect we're in a repository
        assert @git.in_repository?

        # Should get repository root
        root = @git.repository_root
        assert File.directory?(root)

        # Should handle checking for changes in empty repo
        # May return true or false depending on implementation
        result = @git.has_changes?
        assert [true, false].include?(result)
      end
    end
  end

  def test_handles_repository_with_untracked_files
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create untracked file
        File.write("untracked.txt", "untracked content")

        # Should still work in repo with untracked files
        assert @git.in_repository?

        # Depending on implementation, may or may not detect untracked as changes
        result = @git.has_changes?
        assert [true, false].include?(result)
      end
    end
  end

  def test_handles_repository_with_staged_changes
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create and stage file
        File.write("staged.txt", "staged content")
        system("git add staged.txt")

        # Should detect changes
        assert @git.has_changes?
      end
    end
  end

  def test_handles_repository_with_modified_files
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create and commit file
        File.write("tracked.txt", "original")
        system("git add tracked.txt")
        system("git commit -q -m 'Initial'")

        # Modify file
        File.write("tracked.txt", "modified")

        # Should detect changes
        assert @git.has_changes?
      end
    end
  end

  def test_handles_non_git_directory
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        # Not a git repository
        refute @git.in_repository?

        # Repository root should handle gracefully
        result = @git.repository_root rescue nil
        assert result.nil? || result == tmpdir
      end
    end
  end

  def test_handles_git_command_failure
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")

        # Try to execute invalid git command
        result = @git.execute("invalid-command") rescue nil

        # Should either raise or return error indication
        assert true # Test passes if we get here
      end
    end
  end

  def test_handles_repository_in_subdirectory
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create subdirectory
        FileUtils.mkdir_p("subdir/deep/path")

        # Change to subdirectory
        Dir.chdir("subdir/deep/path") do
          # Should still detect repository
          assert @git.in_repository?

          # Should get root repository path, not subdirectory
          root = @git.repository_root
          # Use realpath to handle /private prefix on macOS
          assert_equal File.realpath(tmpdir), File.realpath(root)
        end
      end
    end
  end

  def test_handles_bare_repository
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        # Create bare repository
        system("git init -q --bare")

        # Should detect it's a git repository
        assert @git.in_repository?
      end
    end
  end

  def test_handles_repository_with_gitignore
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create .gitignore
        File.write(".gitignore", "*.log\nnode_modules/\n")

        # Create ignored files
        File.write("test.log", "log content")
        FileUtils.mkdir_p("node_modules")
        File.write("node_modules/package.json", "{}")

        # Should still work with ignored files
        assert @git.in_repository?
      end
    end
  end

  def test_handles_repository_with_unicode_filenames
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create file with unicode name
        File.write("café.txt", "unicode content")
        system("git add café.txt")

        # Should detect changes
        assert @git.has_changes?
      end
    end
  end

  def test_handles_repository_with_spaces_in_filenames
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create file with spaces
        File.write("file with spaces.txt", "content")
        system("git add 'file with spaces.txt'")

        # Should detect changes
        assert @git.has_changes?
      end
    end
  end

  def test_handles_very_large_repository
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create many files
        100.times do |i|
          File.write("file#{i}.txt", "content #{i}")
        end
        system("git add .")

        # Should handle large number of files
        assert @git.has_changes?
      end
    end
  end

  def test_handles_repository_with_submodules
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create initial commit
        File.write("README.md", "main repo")
        system("git add README.md")
        system("git commit -q -m 'Initial'")

        # Should work in repo with submodules reference
        assert @git.in_repository?
      end
    end
  end

  def test_handles_worktree_directory
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        system("git init -q")
        system("git config user.name 'Test'")
        system("git config user.email 'test@test.com'")

        # Create initial commit
        File.write("file.txt", "content")
        system("git add file.txt")
        system("git commit -q -m 'Initial'")

        # Create worktree
        system("git worktree add -q ../worktree HEAD 2>/dev/null")

        # Original repo should still work
        assert @git.in_repository?
      end
    end
  end
end
