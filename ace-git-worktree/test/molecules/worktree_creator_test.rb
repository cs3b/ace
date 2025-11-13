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

  # Tests for PR worktree creation
  def test_create_for_pr_success
    pr_data = {
      number: 26,
      title: "Add authentication feature",
      head_branch: "feature/auth",
      base_branch: "main"
    }

    config = mock_pr_config(@temp_dir)

    # Mock git root detection
    @creator.stub(:detect_git_root, @temp_dir) do
      # Mock path validation
      @creator.stub(:validate_worktree_path, { valid: true, error: nil }) do
        # Mock fetch
        @creator.stub(:fetch_remote_branch, { success: true, error: nil }) do
          # Mock worktree creation
          @creator.stub(:create_worktree_with_tracking, {
            success: true,
            worktree_path: File.join(@temp_dir, "ace-pr-26"),
            branch: "pr-26",
            tracking: "origin/feature/auth",
            git_root: @temp_dir,
            error: nil
          }) do
            result = @creator.create_for_pr(pr_data, config)

            assert result[:success]
            assert_equal "pr-26", result[:branch]
            assert_equal "origin/feature/auth", result[:tracking]
            assert_equal 26, result[:pr_number]
            assert_equal "Add authentication feature", result[:pr_title]
          end
        end
      end
    end
  end

  def test_create_for_pr_without_pr_data
    config = mock_pr_config(@temp_dir)
    result = @creator.create_for_pr(nil, config)

    refute result[:success]
    assert_match /PR data is required/, result[:error]
  end

  def test_create_for_pr_without_config
    pr_data = { number: 26, title: "Test", head_branch: "test", base_branch: "main" }
    result = @creator.create_for_pr(pr_data, nil)

    refute result[:success]
    assert_match /Configuration is required/, result[:error]
  end

  def test_create_for_pr_fetch_failure
    pr_data = {
      number: 26,
      title: "Test PR",
      head_branch: "feature/test",
      base_branch: "main"
    }

    config = mock_pr_config(@temp_dir)

    @creator.stub(:detect_git_root, @temp_dir) do
      @creator.stub(:validate_worktree_path, { valid: true, error: nil }) do
        # Mock fetch failure
        @creator.stub(:fetch_remote_branch, { success: false, error: "Network error" }) do
          result = @creator.create_for_pr(pr_data, config)

          refute result[:success]
          assert_match /Network error/, result[:error]
        end
      end
    end
  end

  # Tests for branch worktree creation
  def test_create_for_branch_remote_success
    config = mock_pr_config(@temp_dir)

    @creator.stub(:detect_git_root, @temp_dir) do
      # Mock remote branch detection
      @creator.stub(:detect_remote_branch, { remote: "origin", branch: "feature/auth" }) do
        # Mock create_for_remote_branch
        @creator.stub(:create_for_remote_branch, {
          success: true,
          worktree_path: File.join(@temp_dir, "feature-auth"),
          branch: "feature/auth",
          tracking: "origin/feature/auth",
          directory_name: "feature-auth",
          git_root: @temp_dir,
          error: nil
        }) do
          result = @creator.create_for_branch("origin/feature/auth", config)

          assert result[:success]
          assert_equal "feature/auth", result[:branch]
          assert_equal "origin/feature/auth", result[:tracking]
        end
      end
    end
  end

  def test_create_for_branch_local_success
    config = mock_pr_config(@temp_dir)

    @creator.stub(:detect_git_root, @temp_dir) do
      # Mock local branch (no remote prefix)
      @creator.stub(:detect_remote_branch, nil) do
        # Mock create_for_local_branch
        @creator.stub(:create_for_local_branch, {
          success: true,
          worktree_path: File.join(@temp_dir, "feature"),
          branch: "feature",
          tracking: nil,
          directory_name: "feature",
          git_root: @temp_dir,
          error: nil
        }) do
          result = @creator.create_for_branch("feature", config)

          assert result[:success]
          assert_equal "feature", result[:branch]
          assert_nil result[:tracking]
        end
      end
    end
  end

  def test_create_for_branch_without_branch_name
    config = mock_pr_config(@temp_dir)
    result = @creator.create_for_branch(nil, config)

    refute result[:success]
    assert_match /Branch name is required/, result[:error]
  end

  def test_create_for_branch_empty_branch_name
    config = mock_pr_config(@temp_dir)
    result = @creator.create_for_branch("", config)

    refute result[:success]
    assert_match /Branch name is required/, result[:error]
  end

  def test_create_for_branch_without_config
    result = @creator.create_for_branch("feature", nil)

    refute result[:success]
    assert_match /Configuration is required/, result[:error]
  end

  def test_detect_remote_branch_with_remote
    remote_branches = {
      "origin/feature" => { remote: "origin", branch: "feature" },
      "upstream/main" => { remote: "upstream", branch: "main" },
      "origin/feature/auth" => { remote: "origin", branch: "feature/auth" },
      "fork/bugfix/123" => { remote: "fork", branch: "bugfix/123" }
    }

    remote_branches.each do |input, expected|
      result = @creator.send(:detect_remote_branch, input)
      assert_equal expected, result, "Failed for #{input}"
    end
  end

  def test_detect_remote_branch_without_remote
    local_branches = ["main", "feature", "bugfix-123", "release_v1.0"]

    local_branches.each do |branch|
      result = @creator.send(:detect_remote_branch, branch)
      assert_nil result, "Should return nil for local branch: #{branch}"
    end
  end

  def test_detect_remote_branch_invalid_format
    invalid = ["origin/", "/feature", "/", "origin//feature"]

    invalid.each do |input|
      result = @creator.send(:detect_remote_branch, input)
      assert_nil result, "Should return nil for invalid format: #{input}"
    end
  end

  def test_format_pr_name_with_number
    pr_data = { number: 26, title: "Add Feature" }
    template = "pr-{number}"

    result = @creator.send(:format_pr_name, template, pr_data)
    assert_equal "pr-26", result
  end

  def test_format_pr_name_with_slug
    pr_data = { number: 26, title: "Add Authentication Feature" }
    template = "pr-{number}-{slug}"

    # Mock slug generator
    Ace::Git::Worktree::Atoms::SlugGenerator.stub(:generate, "add-authentication-feature") do
      result = @creator.send(:format_pr_name, template, pr_data)
      assert_equal "pr-26-add-authentication-feature", result
    end
  end

  def test_format_pr_name_with_multiple_variables
    pr_data = { number: 26, title: "Test Feature", base_branch: "main" }
    template = "{base_branch}-pr-{number}"

    result = @creator.send(:format_pr_name, template, pr_data)
    assert_equal "main-pr-26", result
  end

  private

  def mock_config(root_path)
    config = Object.new
    config.define_singleton_method(:absolute_root_path) { root_path }
    config
  end

  def mock_pr_config(root_path)
    config = mock_config(root_path)
    config.define_singleton_method(:pr_config) do
      {
        remote_name: "origin",
        directory_format: "ace-pr-{number}",
        branch_format: "pr-{number}"
      }
    end
    config
  end

  def test_validate_remote_exists_with_valid_remote
    Dir.mktmpdir do |root_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock git remote command to return "origin"
      Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, { success: true, output: "origin\nupstream\n" }) do
        result = creator.send(:validate_remote_exists, "origin", root_path)

        assert result[:exists]
        assert_equal ["origin", "upstream"], result[:remotes]
      end
    end
  end

  def test_validate_remote_exists_with_invalid_remote
    Dir.mktmpdir do |root_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock git remote command to return only "origin"
      Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, { success: true, output: "origin\n" }) do
        result = creator.send(:validate_remote_exists, "invalid", root_path)

        refute result[:exists]
        assert_equal ["origin"], result[:remotes]
      end
    end
  end

  def test_validate_remote_exists_with_no_remotes
    Dir.mktmpdir do |root_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock git remote command to return empty
      Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, { success: true, output: "" }) do
        result = creator.send(:validate_remote_exists, "origin", root_path)

        refute result[:exists]
        assert_equal [""], result[:remotes]
      end
    end
  end

  def test_fetch_remote_branch_validates_remote
    Dir.mktmpdir do |root_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock validation to return invalid remote
      creator.stub(:validate_remote_exists, { exists: false, remotes: ["origin", "upstream"] }) do
        result = creator.send(:fetch_remote_branch, "invalid", "main", root_path)

        refute result[:success]
        assert_match(/Remote 'invalid' not found/, result[:error])
        assert_match(/origin, upstream/, result[:error])
      end
    end
  end

  def test_fetch_remote_branch_with_no_remotes_configured
    Dir.mktmpdir do |root_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock validation to return no remotes
      creator.stub(:validate_remote_exists, { exists: false, remotes: [] }) do
        result = creator.send(:fetch_remote_branch, "origin", "main", root_path)

        refute result[:success]
        assert_match(/Remote 'origin' not found/, result[:error])
        assert_match(/no remotes configured/, result[:error])
      end
    end
  end

  def test_fetch_remote_branch_proceeds_with_valid_remote
    Dir.mktmpdir do |root_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock validation to return valid remote
      creator.stub(:validate_remote_exists, { exists: true, remotes: ["origin"] }) do
        # Mock fetch command to succeed
        Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, { success: true, output: "" }) do
          result = creator.send(:fetch_remote_branch, "origin", "main", root_path)

          assert result[:success]
          assert_nil result[:error]
        end
      end
    end
  end
end