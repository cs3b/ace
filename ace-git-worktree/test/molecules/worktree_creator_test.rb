# frozen_string_literal: true

require_relative "../test_helper"

class WorktreeCreatorTest < Minitest::Test
  def setup
    setup_temp_dir
    @creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_create_worktree_success
    # Mock successful git worktree creation
    mock_result = {
      success: true,
      output: "Preparing worktree (detached HEAD abc123)",
      error: "",
      exit_code: 0
    }

    Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, mock_result) do
      result = @creator.create_worktree(
        branch: "feature-branch",
        path: @temp_dir
      )

      assert result[:success]
      assert_match(/Preparing worktree/, result[:message])
      assert_equal @temp_dir, result[:path]
    end
  end

  def test_create_worktree_with_dry_run
    result = @creator.create_worktree(
      branch: "feature-branch",
      path: @temp_dir,
      dry_run: true
    )

    assert result[:success]
    assert_match(/dry run/i, result[:message])
    assert_equal @temp_dir, result[:path]
  end

  def test_create_worktree_git_failure
    # Mock git worktree creation failure
    mock_result = {
      success: false,
      output: "",
      error: "fatal: Invalid branch name",
      exit_code: 128
    }

    Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, mock_result) do
      result = @creator.create_worktree(
        branch: "invalid-branch",
        path: @temp_dir
      )

      refute result[:success]
      assert_match(/Invalid branch name/, result[:error])
    end
  end

  def test_create_worktree_with_existing_path
    # Create a directory at the target path
    FileUtils.mkdir_p(@temp_dir)

    result = @creator.create_worktree(
      branch: "feature-branch",
      path: @temp_dir
    )

    # Should handle existing directory gracefully
    refute result[:success]
    assert_match(/already exists/i, result[:error])
  end

  def test_create_worktree_with_invalid_path
    invalid_paths = [
      "/etc/passwd",         # System file
      "../../../root",       # Path traversal
      "/dev/null",          # Device file
      ""                     # Empty path
    ]

    invalid_paths.each do |invalid_path|
      result = @creator.create_worktree(
        branch: "feature-branch",
        path: invalid_path
      )

      refute result[:success], "Should reject invalid path: #{invalid_path}"
    end
  end

  def test_create_worktree_with_invalid_branch
    invalid_branches = [
      "",                    # Empty
      "branch; rm -rf /",    # Command injection
      "branch`whoami`",      # Command injection
      "branch$(whoami)",     # Command injection
      "../../../etc/passwd"   # Path traversal
    ]

    invalid_branches.each do |invalid_branch|
      result = @creator.create_worktree(
        branch: invalid_branch,
        path: @temp_dir
      )

      refute result[:success], "Should reject invalid branch: #{invalid_branch}"
    end
  end

  def test_create_worktree_with_force_option
    mock_result = {
      success: true,
      output: "Preparing worktree (detached HEAD abc123)",
      error: "",
      exit_code: 0
    }

    Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, mock_result) do
      result = @creator.create_worktree(
        branch: "feature-branch",
        path: @temp_dir,
        force: true
      )

      assert result[:success]
    end
  end

  def test_create_worktree_with_checkout_option
    mock_result = {
      success: true,
      output: "Preparing worktree (detached HEAD abc123)",
      error: "",
      exit_code: 0
    }

    Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, mock_result) do
      result = @creator.create_worktree(
        branch: "feature-branch",
        path: @temp_dir,
        checkout: false  # Don't checkout the branch
      )

      assert result[:success]
    end
  end

  def test_path_validation_blocks_dangerous_inputs
    dangerous_paths = [
      "/path; rm -rf /",
      "/path$(whoami)",
      "/path`cat /etc/passwd`",
      "/path\x00with\x00nulls",
      "../../../etc/passwd",
      "/dev/random",
      "/proc/version"
    ]

    dangerous_paths.each do |dangerous_path|
      result = @creator.create_worktree(
        branch: "safe-branch",
        path: dangerous_path,
        dry_run: true  # Use dry run to avoid actual filesystem issues
      )

      refute result[:success], "Should reject dangerous path: #{dangerous_path}"
    end
  end

  def test_branch_validation_blocks_dangerous_inputs
    dangerous_branches = [
      "branch; rm -rf /",
      "branch&&echo hack",
      "branch||echo hack",
      "branch`whoami`",
      "branch$(whoami)",
      "branch|cat /etc/passwd",
      "branch>temp",
      "branch</etc/passwd",
      "../../../etc/passwd",
      "branch\x00injection"
    ]

    dangerous_branches.each do |dangerous_branch|
      result = @creator.create_worktree(
        branch: dangerous_branch,
        path: @temp_dir,
        dry_run: true
      )

      refute result[:success], "Should reject dangerous branch: #{dangerous_branch}"
    end
  end

  def test_valid_branch_names
    valid_branches = [
      "main",
      "master",
      "feature-branch",
      "feature/new-feature",
      "bugfix/issue-123",
      "release/v1.0.0",
      "hotfix/security-patch",
      "123-task-number",
      "branch_with_underscores",
      "branch.with.dots"
    ]

    valid_branches.each do |valid_branch|
      mock_result = {
        success: true,
        output: "Preparing worktree",
        error: "",
        exit_code: 0
      }

      Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, mock_result) do
        result = @creator.create_worktree(
          branch: valid_branch,
          path: @temp_dir
        )

        assert result[:success], "Should accept valid branch: #{valid_branch}"
      end
    end
  end

  def test_handles_timeout_during_creation
    # Mock command timeout
    Ace::GitDiff::Atoms::CommandExecutor.stub(:execute) do
      raise StandardError, "Command timed out"
    end

    result = @creator.create_worktree(
      branch: "feature-branch",
      path: @temp_dir
    )

    refute result[:success]
    assert_match(/timed out|failed/i, result[:error])
  end
end