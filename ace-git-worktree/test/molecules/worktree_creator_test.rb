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
      result = @creator.create_traditional("feature-branch", @temp_dir)

      assert result[:success]
    end
  end

  def test_create_worktree_with_dry_run
    # Dry run is not supported in create_traditional - remove this test
    skip "Dry run option not supported in public API"
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
      result = @creator.create_traditional("invalid-branch", @temp_dir)

      refute result[:success]
      # Error could be about git repo or branch name
      assert result[:error].length > 0
    end
  end

  def test_create_worktree_with_existing_path
    # Create a directory at the target path
    FileUtils.mkdir_p(@temp_dir)

    result = @creator.create_traditional("feature-branch", @temp_dir)

    # Should handle existing directory gracefully
    refute result[:success]
  end

  def test_create_worktree_with_invalid_path
    invalid_paths = [
      "/etc/passwd",         # System file
      "../../../root",       # Path traversal
      "/dev/null",          # Device file
      ""                     # Empty path
    ]

    invalid_paths.each do |invalid_path|
      result = @creator.create_traditional("feature-branch", invalid_path)

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
      result = @creator.create_traditional(invalid_branch, @temp_dir)

      refute result[:success], "Should reject invalid branch: #{invalid_branch}"
    end
  end

  def test_create_worktree_with_force_option
    skip "Force option not supported in public API"
  end

  def test_create_worktree_with_checkout_option
    skip "Checkout option not supported in public API"
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
      result = @creator.create_traditional("safe-branch", dangerous_path)

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
      result = @creator.create_traditional(dangerous_branch, @temp_dir)

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
        result = @creator.create_traditional(valid_branch, @temp_dir)

        assert result[:success], "Should accept valid branch: #{valid_branch}"
      end
    end
  end

  def test_handles_timeout_during_creation
    # Mock command timeout
    Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, -> (*args) { raise StandardError, "Command timed out" }) do
      result = @creator.create_traditional("feature-branch", @temp_dir)

      refute result[:success]
      # Error handling converts exceptions to user-friendly messages
      assert result[:error].is_a?(String)
      assert result[:error].length > 0
    end
  end

  def test_branch_validation_allows_slash_characters
    # Test that branch validation properly allows / characters via create_traditional
    slash_branches = [
      "feature/login",
      "feature/auth/oauth-flow",
      "bugfix/issue-123/security-patch",
      "release/v1.0.0/patch",
      "hotfix/critical/security-update",
      "epic/user-management/permissions",
      "team/frontend/component-library"
    ]

    mock_result = {
      success: true,
      output: "Preparing worktree",
      error: "",
      exit_code: 0
    }

    slash_branches.each do |slash_branch|
      Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, mock_result) do
        result = @creator.create_traditional(slash_branch, @temp_dir)
        assert result[:success], "Should accept branch with slash: #{slash_branch}"
      end
    end
  end

  def test_branch_validation_allows_main_and_master
    # Test that branch validation allows main and master via create_traditional
    mainline_branches = ["main", "master"]

    mock_result = {
      success: true,
      output: "Preparing worktree",
      error: "",
      exit_code: 0
    }

    mainline_branches.each do |mainline_branch|
      Ace::GitDiff::Atoms::CommandExecutor.stub(:execute, mock_result) do
        result = @creator.create_traditional(mainline_branch, @temp_dir)
        assert result[:success], "Should accept mainline branch: #{mainline_branch}"
      end
    end
  end

  def test_branch_validation_still_blocks_truly_invalid_patterns
    # Test that branch validation still blocks actually invalid patterns
    invalid_branches = [
      "",                    # Empty
      "branch..name",        # Double dots
      "@{ref}",              # Starts with @{
      "branch name",         # Contains whitespace
      "branch~name",         # Contains ~
      "branch^name",         # Contains ^
      "branch:name",         # Contains :
      "branch?name",         # Contains ?
      "branch*name",         # Contains *
      "branch[name",         # Contains [
      "branch]name",         # Contains ]
      "branch.name.",        # Ends with .
      "branch.lock",         # Ends with .lock
      ".git/refs/heads"      # Contains .git
    ]

    invalid_branches.each do |invalid_branch|
      result = @creator.create_traditional(invalid_branch, @temp_dir)
      refute result[:success], "Should reject invalid branch: #{invalid_branch}"
    end
  end

  # Tests for config parameter
  def test_generate_default_worktree_path_with_config
    # Create a mock config with custom root_path
    config = mock_config("/custom/root/path")
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)
    git_root = @temp_dir

    path = creator.send(:generate_default_worktree_path, "feature-branch", git_root)

    assert_equal "/custom/root/path/feature-branch", path
  end

  def test_generate_default_worktree_path_without_config
    # Creator without config should use default .ace-wt
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new
    git_root = @temp_dir

    path = creator.send(:generate_default_worktree_path, "feature-branch", git_root)

    expected = File.join(git_root, ".ace-wt", "feature-branch")
    assert_equal expected, path
  end

  def test_generate_default_worktree_path_sanitizes_branch_name
    config = mock_config("/worktrees")
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)
    git_root = @temp_dir

    # Branch name with special characters
    path = creator.send(:generate_default_worktree_path, "feature/sub-branch", git_root)

    assert_equal "/worktrees/feature-sub-branch", path
  end

  def test_create_traditional_with_config_respects_root_path
    config = mock_config(File.join(@temp_dir, "custom-worktrees"))
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)

    # Ensure parent directory exists
    FileUtils.mkdir_p(File.join(@temp_dir, "custom-worktrees"))

    # Mock git command success
    git_result = { success: true, output: "", error: nil }
    Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_result) do
      Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
        result = creator.create_traditional("test-branch", nil, git_root: @temp_dir)

        assert result[:success]
        assert_match %r{custom-worktrees/test-branch}, result[:worktree_path]
      end
    end
  end

  private

  def mock_config(root_path)
    config = Object.new
    config.define_singleton_method(:absolute_root_path) { root_path }
    config
  end
end