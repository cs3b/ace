# frozen_string_literal: true

require "test_helper"

class GitCommandTest < AceGitWorktreeTestCase
  def setup
    @command = Ace::Git::Worktree::Atoms::GitCommand
  end

  def test_execute_returns_hash_with_expected_keys
    with_test_repo do
      result = @command.execute("status", "--short")

      assert result.is_a?(Hash)
      assert result.key?(:success)
      assert result.key?(:output)
      assert result.key?(:error)
      assert result.key?(:exit_code)
    end
  end

  def test_in_git_repo_returns_true_in_repo
    with_test_repo do
      assert @command.in_git_repo?
    end
  end

  def test_in_git_repo_returns_false_outside_repo
    with_temp_dir do
      refute @command.in_git_repo?
    end
  end

  def test_current_branch_returns_branch_name
    with_test_repo do
      # Create and checkout a branch
      system("git checkout -b test-branch 2>/dev/null")

      assert_equal "test-branch", @command.current_branch
    end
  end

  def test_current_branch_returns_main_on_main_branch
    with_test_repo do
      # Git init creates 'main' or 'master' by default
      branch = @command.current_branch
      assert %w[main master].include?(branch), "Expected main or master, got #{branch}"
    end
  end

  def test_repo_root_returns_repository_root
    with_test_repo do |dir|
      root = @command.repo_root
      assert_equal dir, root

      # Test from subdirectory
      Dir.mkdir("subdir")
      Dir.chdir("subdir") do
        assert_equal dir, @command.repo_root
      end
    end
  end

  def test_repo_root_returns_nil_outside_repo
    with_temp_dir do
      assert_nil @command.repo_root
    end
  end

  def test_execute_with_timeout
    skip "Timeout testing requires special setup"

    # This would test timeout, but it's hard to reliably test
    # without actually having a long-running command
  end

  def test_execute_with_chdir_option
    with_test_repo do |repo_dir|
      Dir.mkdir("subdir")
      File.write("subdir/test.txt", "test content")

      # Execute ls in subdir
      result = @command.execute("ls-files", chdir: "subdir")

      assert result[:success]
      assert_empty result[:output] # No tracked files yet

      # Add and check again
      system("cd subdir && git add test.txt")
      result = @command.execute("ls-files", chdir: "subdir")

      assert result[:success]
      assert_match(/test\.txt/, result[:output])
    end
  end

  def test_execute_handles_git_errors
    with_test_repo do
      result = @command.execute("nonexistent-command")

      refute result[:success]
      assert result[:error].length > 0
      assert result[:exit_code] != 0
    end
  end

  def test_execute_handles_invalid_arguments
    with_test_repo do
      result = @command.execute("status", "--invalid-flag")

      refute result[:success]
      assert result[:error].length > 0
    end
  end
end