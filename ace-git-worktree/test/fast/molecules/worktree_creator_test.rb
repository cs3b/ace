# frozen_string_literal: true

require_relative "../../test_helper"

class WorktreeCreatorTest < Minitest::Test
  def setup
    setup_temp_dir
    @creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new
  end

  def teardown
    teardown_temp_dir
  end

  # with_git_stubs helper is now in test_helper.rb

  def test_create_worktree_success
    # Mock successful git worktree creation
    mock_result = {
      success: true,
      output: "Preparing worktree (detached HEAD abc123)",
      error: "",
      exit_code: 0
    }

    worktree_path = File.join(@temp_dir, "feature-worktree")

    with_git_stubs(worktree_result: mock_result) do
      result = @creator.create_traditional("feature-branch", worktree_path)

      assert result[:success], "Expected success but got error: #{result[:error]}"
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

    with_git_stubs(worktree_result: mock_result) do
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
      "hotfix/v1.0.0",
      "hotfix/security-patch",
      "123-task-number",
      "branch_with_underscores",
      "branch.with.dots"
    ]

    mock_result = {
      success: true,
      output: "Preparing worktree",
      error: "",
      exit_code: 0
    }

    valid_branches.each do |valid_branch|
      worktree_path = File.join(@temp_dir, "worktree-#{valid_branch.tr("/", "-")}")

      with_git_stubs(worktree_result: mock_result) do
        result = @creator.create_traditional(valid_branch, worktree_path)

        assert result[:success], "Should accept valid branch: #{valid_branch}"
      end
    end
  end

  def test_handles_timeout_during_creation
    # Mock command timeout by returning error result
    mock_result = {
      success: false,
      output: "",
      error: "Command timed out",
      exit_code: -1
    }

    with_git_stubs(worktree_result: mock_result) do
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
      "hotfix/v1.0.0/patch",
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
      worktree_path = File.join(@temp_dir, "worktree-#{slash_branch.tr("/", "-")}")

      with_git_stubs(worktree_result: mock_result) do
        result = @creator.create_traditional(slash_branch, worktree_path)
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
      worktree_path = File.join(@temp_dir, "worktree-#{mainline_branch}")

      with_git_stubs(worktree_result: mock_result) do
        result = @creator.create_traditional(mainline_branch, worktree_path)
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
    git_result = {success: true, output: "", error: nil}
    with_git_stubs(worktree_result: git_result) do
      result = creator.create_traditional("test-branch", nil, git_root: @temp_dir)

      assert result[:success]
      assert_match %r{custom-worktrees/test-branch}, result[:worktree_path]
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
      @creator.stub(:validate_worktree_path, {valid: true, error: nil}) do
        # Mock fetch
        @creator.stub(:fetch_remote_branch, {success: true, error: nil}) do
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
    assert_match(/PR data is required/, result[:error])
  end

  def test_create_for_pr_without_config
    pr_data = {number: 26, title: "Test", head_branch: "test", base_branch: "main"}
    result = @creator.create_for_pr(pr_data, nil)

    refute result[:success]
    assert_match(/Configuration is required/, result[:error])
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
      @creator.stub(:validate_worktree_path, {valid: true, error: nil}) do
        # Mock fetch failure
        @creator.stub(:fetch_remote_branch, {success: false, error: "Network error"}) do
          result = @creator.create_for_pr(pr_data, config)

          refute result[:success]
          assert_match(/Network error/, result[:error])
        end
      end
    end
  end

  # Tests for branch worktree creation
  def test_create_for_branch_remote_success
    config = mock_pr_config(@temp_dir)

    @creator.stub(:detect_git_root, @temp_dir) do
      # Mock remote branch detection
      @creator.stub(:detect_remote_branch, {remote: "origin", branch: "feature/auth"}) do
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
    assert_match(/Branch name is required/, result[:error])
  end

  def test_create_for_branch_empty_branch_name
    config = mock_pr_config(@temp_dir)
    result = @creator.create_for_branch("", config)

    refute result[:success]
    assert_match(/Branch name is required/, result[:error])
  end

  def test_create_for_branch_without_config
    result = @creator.create_for_branch("feature", nil)

    refute result[:success]
    assert_match(/Configuration is required/, result[:error])
  end

  def test_detect_remote_branch_with_remote
    remote_branches = {
      "origin/feature" => {remote: "origin", branch: "feature"},
      "upstream/main" => {remote: "upstream", branch: "main"},
      "origin/feature/auth" => {remote: "origin", branch: "feature/auth"},
      "fork/bugfix/123" => {remote: "fork", branch: "bugfix/123"}
    }

    remote_branches.each do |input, expected|
      # Stub validate_remote_exists to return true for the expected remote
      @creator.stub(:validate_remote_exists, ->(remote, _path) {
        {exists: remote == expected[:remote], remotes: [expected[:remote]]}
      }) do
        result = @creator.send(:detect_remote_branch, input)
        assert_equal expected, result, "Failed for #{input}"
      end
    end
  end

  def test_detect_remote_branch_without_remote
    local_branches = ["main", "feature", "bugfix-123", "candidate_v1.0"]

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

  def test_detect_remote_branch_with_local_slash_branch
    # Branches with slashes should return nil if the first part isn't a real remote
    # This is the bug fix: "feature/login" should NOT be treated as remote "feature" branch "login"
    local_slash_branches = [
      "feature/login",
      "bugfix/issue-123",
      "hotfix/v1.0.0",
      "hotfix/security-patch",
      "epic/user-management",
      "team/frontend/component"
    ]

    # Stub validate_remote_exists to return false (these aren't real remotes)
    @creator.stub(:validate_remote_exists, ->(remote, _path) {
      {exists: false, remotes: ["origin", "upstream"]}
    }) do
      local_slash_branches.each do |branch|
        result = @creator.send(:detect_remote_branch, branch)
        assert_nil result, "Should return nil for local branch with slash: #{branch}"
      end
    end
  end

  def test_detect_remote_branch_distinguishes_real_remotes_from_branch_prefixes
    # "origin/feature" should be detected as remote when "origin" is configured
    # "feature/login" should NOT be detected as remote when "feature" is not configured

    @creator.stub(:validate_remote_exists, ->(remote, _path) {
      # Only "origin" and "upstream" are real remotes
      real_remotes = %w[origin upstream]
      {exists: real_remotes.include?(remote), remotes: real_remotes}
    }) do
      # Real remote branches should be detected
      origin_result = @creator.send(:detect_remote_branch, "origin/feature")
      assert_equal({remote: "origin", branch: "feature"}, origin_result)

      upstream_result = @creator.send(:detect_remote_branch, "upstream/main")
      assert_equal({remote: "upstream", branch: "main"}, upstream_result)

      # Local branches with slash prefixes should NOT be detected as remote
      feature_result = @creator.send(:detect_remote_branch, "feature/login")
      assert_nil feature_result, "feature/login should be nil when 'feature' is not a remote"

      non_remote_result = @creator.send(:detect_remote_branch, "candidate/v2.0")
      assert_nil non_remote_result, "candidate/v2.0 should be nil when 'candidate' is not a remote"
    end
  end

  def test_format_pr_name_with_number
    pr_data = {number: 26, title: "Add Feature"}
    template = "pr-{number}"

    result = @creator.send(:format_pr_name, template, pr_data)
    assert_equal "pr-26", result
  end

  def test_format_pr_name_with_slug
    pr_data = {number: 26, title: "Add Authentication Feature"}
    template = "pr-{number}-{slug}"

    # Mock slug generator
    Ace::Git::Worktree::Atoms::SlugGenerator.stub(:from_title, "add-authentication-feature") do
      result = @creator.send(:format_pr_name, template, pr_data)
      assert_equal "pr-26-add-authentication-feature", result
    end
  end

  def test_format_pr_name_with_multiple_variables
    pr_data = {number: 26, title: "Test Feature", base_branch: "main"}
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
    config.define_singleton_method(:configure_push_for_mismatch?) { true }
    config
  end

  def test_validate_remote_exists_with_valid_remote
    Dir.mktmpdir do |root_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock git remote command to return "origin"
      Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, {success: true, output: "origin\nupstream\n"}) do
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
      Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, {success: true, output: "origin\n"}) do
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
      Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, {success: true, output: ""}) do
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
      creator.stub(:validate_remote_exists, {exists: false, remotes: ["origin", "upstream"]}) do
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
      creator.stub(:validate_remote_exists, {exists: false, remotes: []}) do
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
      creator.stub(:validate_remote_exists, {exists: true, remotes: ["origin"]}) do
        # Mock fetch command to succeed
        Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, {success: true, output: ""}) do
          result = creator.send(:fetch_remote_branch, "origin", "main", root_path)

          assert result[:success]
          assert_nil result[:error]
        end
      end
    end
  end

  def test_create_worktree_with_tracking_configures_push_when_names_differ
    Dir.mktmpdir do |worktree_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock successful worktree creation
      Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, {success: true, output: "", error: nil}) do
        # Mock git config commands
        config_calls = []
        Ace::Git::Worktree::Atoms::GitCommand.stub(:execute) do |*args|
          config_calls << args
          {success: true, output: "", error: nil}
        end

        result = creator.send(:create_worktree_with_tracking,
          worktree_path,
          "local-branch",
          "origin/remote-branch",
          "/tmp",
          configure_push: true)

        assert result[:success]
        assert_equal "local-branch", result[:branch]
        assert_equal "origin/remote-branch", result[:tracking]

        # Check that git config was called to set push behavior
        assert config_calls.any? { |args| args.include?("push.default") && args.include?("upstream") }
        assert config_calls.any? { |args| args.include?("push.autoSetupRemote") && args.include?("true") }
      end
    end
  end

  def test_create_worktree_with_tracking_skips_push_config_when_names_match
    Dir.mktmpdir do |worktree_path|
      creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

      # Mock successful worktree creation
      Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, {success: true, output: "", error: nil}) do
        # Mock git config commands
        config_calls = []
        Ace::Git::Worktree::Atoms::GitCommand.stub(:execute) do |*args|
          config_calls << args
          {success: true, output: "", error: nil}
        end

        result = creator.send(:create_worktree_with_tracking,
          worktree_path,
          "feature-branch",
          "origin/feature-branch",
          "/tmp",
          configure_push: true)

        assert result[:success]
        assert_equal "feature-branch", result[:branch]
        assert_equal "origin/feature-branch", result[:tracking]

        # Check that git config was NOT called since branch names match
        refute config_calls.any? { |args| args.include?("push.default") }
      end
    end
  end

  def test_configure_push_for_mismatch_config_option
    # Test that the config option is available
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({
      "git" => {
        "worktree" => {
          "pr" => {
            "configure_push_for_mismatch" => false
          }
        }
      }
    })

    refute config.configure_push_for_mismatch?, "Should return false when disabled in config"

    # Test default (should be true)
    default_config = Ace::Git::Worktree::Models::WorktreeConfig.new
    assert default_config.configure_push_for_mismatch?, "Should default to true"
  end

  # Tests for start_point (source) parameter
  def test_create_traditional_uses_current_branch_as_default_start_point
    config = mock_config(File.join(@temp_dir, "worktrees"))
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)

    FileUtils.mkdir_p(File.join(@temp_dir, "worktrees"))

    captured_args = nil
    worktree_stub = lambda do |*args, **opts|
      captured_args = args
      {success: true, output: "", error: nil}
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, worktree_stub) do
      Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
        Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "feature-branch") do
          Ace::Git::Worktree::Atoms::GitCommand.stub(:ref_exists?, true) do
            result = creator.create_traditional("new-branch", nil, git_root: @temp_dir)

            assert result[:success]
            # The worktree command should include the start_point (current branch)
            assert_includes captured_args, "feature-branch", "Should pass current branch as start-point"
          end
        end
      end
    end
  end

  def test_create_traditional_with_explicit_source
    config = mock_config(File.join(@temp_dir, "worktrees"))
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)

    FileUtils.mkdir_p(File.join(@temp_dir, "worktrees"))

    captured_args = nil
    worktree_stub = lambda do |*args, **opts|
      captured_args = args
      {success: true, output: "", error: nil}
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, worktree_stub) do
      Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
        Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "feature-branch") do
          Ace::Git::Worktree::Atoms::GitCommand.stub(:ref_exists?, true) do
            result = creator.create_traditional("new-branch", nil, git_root: @temp_dir, source: "main")

            assert result[:success]
            # The worktree command should use the explicit source instead of current branch
            assert_includes captured_args, "main", "Should pass explicit source as start-point"
            refute_includes captured_args, "feature-branch", "Should not use current branch when source specified"
          end
        end
      end
    end
  end

  def test_create_traditional_returns_start_point_in_result
    config = mock_config(File.join(@temp_dir, "worktrees"))
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)

    FileUtils.mkdir_p(File.join(@temp_dir, "worktrees"))

    git_result = {success: true, output: "", error: nil}
    Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, git_result) do
      Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
        Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "develop") do
          Ace::Git::Worktree::Atoms::GitCommand.stub(:ref_exists?, true) do
            result = creator.create_traditional("new-branch", nil, git_root: @temp_dir)

            assert result[:success]
            assert_equal "develop", result[:start_point], "Should include start_point in result"
          end
        end
      end
    end
  end

  def test_create_traditional_fails_with_invalid_source
    config = mock_config(File.join(@temp_dir, "worktrees"))
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)

    FileUtils.mkdir_p(File.join(@temp_dir, "worktrees"))

    Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
      Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "main") do
        # ref_exists? returns false for invalid refs
        Ace::Git::Worktree::Atoms::GitCommand.stub(:ref_exists?, false) do
          result = creator.create_traditional("new-branch", nil, git_root: @temp_dir, source: "nonexistent-ref")

          refute result[:success]
          assert_match(/Source ref.*does not exist/, result[:error])
        end
      end
    end
  end

  def test_create_traditional_fails_when_current_branch_unknown
    config = mock_config(File.join(@temp_dir, "worktrees"))
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)

    FileUtils.mkdir_p(File.join(@temp_dir, "worktrees"))

    Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
      # Simulate inability to determine current branch
      Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, nil) do
        result = creator.create_traditional("new-branch", nil, git_root: @temp_dir)

        refute result[:success]
        assert_match(/Cannot determine current branch/, result[:error])
      end
    end
  end

  def test_create_for_task_with_source_parameter
    task_data = {id: "v.0.9.0+task.081", title: "Fix auth bug", status: "pending"}
    config = mock_task_config(@temp_dir)

    Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
      Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "feature-x") do
        Ace::Git::Worktree::Atoms::GitCommand.stub(:ref_exists?, true) do
          captured_args = nil
          worktree_stub = lambda do |*args, **opts|
            captured_args = args
            {success: true, output: "", error: nil}
          end

          Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, worktree_stub) do
            creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new
            result = creator.create_for_task(task_data, config, source: "main")

            assert result[:success]
            assert_includes captured_args, "main", "Should use explicit source"
          end
        end
      end
    end
  end

  def test_create_for_task_uses_current_branch_by_default
    task_data = {id: "v.0.9.0+task.081", title: "Fix auth bug", status: "pending"}
    config = mock_task_config(@temp_dir)

    Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
      Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "feature-x") do
        Ace::Git::Worktree::Atoms::GitCommand.stub(:ref_exists?, true) do
          captured_args = nil
          worktree_stub = lambda do |*args, **opts|
            captured_args = args
            {success: true, output: "", error: nil}
          end

          Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, worktree_stub) do
            creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new
            result = creator.create_for_task(task_data, config)

            assert result[:success]
            assert_includes captured_args, "feature-x", "Should use current branch as default start-point"
          end
        end
      end
    end
  end

  # Tests for branch existence detection (TC-002, TC-010 fix)
  def test_branch_exists_with_local_branch
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

    # Mock show-ref to return success for local branch
    execute_stub = lambda do |*args, **opts|
      if args.include?("refs/heads/existing-branch")
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: false, output: "", error: "", exit_code: 1}
      end
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, execute_stub) do
      assert creator.send(:branch_exists?, "existing-branch"), "Should detect existing local branch"
      refute creator.send(:branch_exists?, "nonexistent-branch"), "Should return false for nonexistent branch"
    end
  end

  def test_branch_exists_with_remote_tracking_branch
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

    # Mock show-ref to return failure for local but success for remote tracking branch
    execute_stub = lambda do |*args, **opts|
      if args.include?("refs/remotes/origin/remote-branch")
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: false, output: "", error: "", exit_code: 1}
      end
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, execute_stub) do
      assert creator.send(:branch_exists?, "remote-branch"), "Should detect remote tracking branch"
    end
  end

  def test_branch_exists_with_local_only_branch
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

    # Track calls to ensure we're testing the fix (separate calls for local and remote)
    call_count = 0
    execute_stub = lambda do |*args, **opts|
      call_count += 1
      if args.include?("refs/heads/local-only-branch")
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: false, output: "", error: "", exit_code: 1}
      end
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, execute_stub) do
      result = creator.send(:branch_exists?, "local-only-branch")
      assert result, "Should detect local-only branch (no remote tracking)"
      # Should short-circuit after finding local branch
      assert_equal 1, call_count, "Should short-circuit after finding local branch"
    end
  end

  def test_branch_exists_with_remote_only_branch
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

    # Mock: local branch doesn't exist, but remote tracking does
    execute_stub = lambda do |*args, **opts|
      if args.include?("refs/remotes/origin/remote-only-branch")
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: false, output: "", error: "", exit_code: 1}
      end
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, execute_stub) do
      result = creator.send(:branch_exists?, "remote-only-branch")
      assert result, "Should detect remote-only branch when local doesn't exist"
    end
  end

  def test_branch_exists_returns_false_when_neither_exists
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

    execute_stub = lambda do |*args, **opts|
      {success: false, output: "", error: "", exit_code: 1}
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, execute_stub) do
      result = creator.send(:branch_exists?, "nonexistent-branch")
      refute result, "Should return false when neither local nor remote branch exists"
    end
  end

  def test_branch_exists_short_circuits_on_local_hit
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

    # Track which refs are checked
    checked_refs = []
    execute_stub = lambda do |*args, **opts|
      ref = args.find { |a| a.start_with?("refs/") }
      checked_refs << ref if ref
      if args.include?("refs/heads/test-branch")
        {success: true, output: "", error: "", exit_code: 0}
      else
        {success: false, output: "", error: "", exit_code: 1}
      end
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, execute_stub) do
      result = creator.send(:branch_exists?, "test-branch")
      assert result
      # Should only check local ref since it found it
      assert_equal ["refs/heads/test-branch"], checked_refs, "Should short-circuit after local hit"
    end
  end

  def test_create_traditional_uses_existing_branch
    config = mock_config(File.join(@temp_dir, "worktrees"))
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)

    FileUtils.mkdir_p(File.join(@temp_dir, "worktrees"))

    # Track which method was called
    captured_method = nil
    captured_args = nil

    # Mock branch_exists? to return true
    creator.stub(:branch_exists?, true) do
      # Mock create_worktree_for_existing_branch
      creator.stub(:create_worktree_for_existing_branch) do |path, branch, root|
        captured_method = :create_worktree_for_existing_branch
        captured_args = {path: path, branch: branch, root: root}
        {success: true, worktree_path: path, branch: branch, start_point: nil, git_root: root, error: nil}
      end

      Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
        result = creator.create_traditional("existing-branch", nil, git_root: @temp_dir)

        assert result[:success]
        assert_equal :create_worktree_for_existing_branch, captured_method, "Should use create_worktree_for_existing_branch"
        assert_equal "existing-branch", captured_args[:branch]
      end
    end
  end

  def test_create_traditional_creates_new_branch_when_not_exists
    config = mock_config(File.join(@temp_dir, "worktrees"))
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new(config: config)

    FileUtils.mkdir_p(File.join(@temp_dir, "worktrees"))

    # Mock branch_exists? to return false
    creator.stub(:branch_exists?, false) do
      # Mock create_worktree to be called (new branch path)
      Ace::Git::Worktree::Atoms::GitCommand.stub(:git_root, @temp_dir) do
        Ace::Git::Worktree::Atoms::GitCommand.stub(:current_branch, "main") do
          Ace::Git::Worktree::Atoms::GitCommand.stub(:ref_exists?, true) do
            captured_args = nil
            worktree_stub = lambda do |*args, **opts|
              captured_args = args
              {success: true, output: "", error: nil}
            end

            Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, worktree_stub) do
              result = creator.create_traditional("new-branch", nil, git_root: @temp_dir)

              assert result[:success]
              # The -b flag indicates a new branch is being created
              assert_includes captured_args, "-b", "Should use -b flag for new branch"
              assert_includes captured_args, "new-branch", "Should include branch name"
            end
          end
        end
      end
    end
  end

  def test_create_worktree_for_existing_branch_uses_no_b_flag
    creator = Ace::Git::Worktree::Molecules::WorktreeCreator.new

    captured_args = nil
    worktree_stub = lambda do |*args, **opts|
      captured_args = args
      {success: true, output: "", error: nil}
    end

    Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, worktree_stub) do
      result = creator.send(:create_worktree_for_existing_branch,
        "/tmp/worktree-path",
        "existing-branch",
        "/repo")

      assert result[:success]
      refute_includes captured_args, "-b", "Should NOT use -b flag for existing branch"
      assert_includes captured_args, "existing-branch", "Should include branch name"
      assert_includes captured_args, "/tmp/worktree-path", "Should include worktree path"
    end
  end

  # Regression test for local branch creation bug (codex-max finding)
  # Previously, an array was passed as a single argument to GitCommand.execute
  # instead of splatted arguments, causing local branch validation to fail.
  def test_create_for_local_branch_passes_correct_arguments
    config = mock_pr_config(@temp_dir)

    @creator.stub(:detect_git_root, @temp_dir) do
      @creator.stub(:detect_remote_branch, nil) do
        # Capture the arguments passed to GitCommand.execute
        captured_execute_args = []
        execute_stub = lambda do |*args, **opts|
          captured_execute_args << args
          # Return success for show-ref check
          {success: true, output: "", error: "", exit_code: 0}
        end

        Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, execute_stub) do
          Ace::Git::Worktree::Atoms::GitCommand.stub(:worktree, {success: true, output: "", error: nil}) do
            @creator.create_for_local_branch("my-feature", config, @temp_dir)
          end
        end

        # Verify that show-ref was called with individual arguments (not an array)
        showref_call = captured_execute_args.find { |args| args.include?("show-ref") }
        assert_not_nil showref_call, "Should call show-ref for local branch validation"

        # Ensure arguments are individual strings, not a single array
        showref_call.each do |arg|
          refute arg.is_a?(Array), "Arguments should be individual strings, not arrays: #{arg.inspect}"
        end

        # Verify the correct arguments are passed
        assert_includes showref_call, "show-ref", "Should include show-ref command"
        assert_includes showref_call, "--verify", "Should include --verify flag"
        assert_includes showref_call, "--quiet", "Should include --quiet flag"
        assert showref_call.any? { |arg| arg.include?("refs/heads/my-feature") }, "Should include branch ref"
      end
    end
  end

  private

  def mock_task_config(root_path)
    config = Object.new
    config.define_singleton_method(:absolute_root_path) { root_path }
    config.define_singleton_method(:format_directory) { |task_data, counter = nil| "task.081" }
    config.define_singleton_method(:format_branch) { |task_data| "081-fix-auth-bug" }
    config
  end
end
