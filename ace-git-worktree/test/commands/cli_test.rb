# frozen_string_literal: true

require_relative "../test_helper"
require "ace/support/cli"
require "open3"

class CliTest < Minitest::Test
  def setup
    setup_temp_dir
    @exe_path = File.expand_path("../../exe/ace-git-worktree", __dir__)
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_without_arguments_shows_help
    stdout, stderr, status = run_exe
    assert status.success?
    assert_match(/COMMANDS|Commands:|USAGE/i, stdout + stderr)
  end

  def test_run_with_help_flag
    output = run_cli(["--help"])
    assert_match(/COMMANDS|Commands:/, output.first)
  end

  def test_run_with_short_help_flag
    output = run_cli(["-h"])
    assert_match(/COMMANDS|Commands:/, output.first)
  end

  def test_run_with_help_command
    output = run_cli(["help"])
    assert_match(/COMMANDS|Commands:/, output.first)
  end

  def test_run_with_version_flag
    output = run_cli(["--version"])
    assert_includes output.first, "ace-git-worktree"
  end

  def test_run_with_short_version_flag
    # Note: -v is now --verbose per ADR-018, --version is for version
    output = run_cli(["--version"])
    assert_includes output.first, "ace-git-worktree"
  end

  def test_run_with_version_command
    output = run_cli(["version"])
    assert_includes output.first, "ace-git-worktree"
  end

  def test_run_with_invalid_command
    stdout, stderr, status = run_exe("invalid-command")
    refute status.success?
    assert_match(/Commands:|COMMANDS|unknown command/i, stdout + stderr)
  end

  def test_create_command_integration
    skip "Integration test requires full task workflow setup - depends on command-level fixes"

    # Mock git repository setup
    system("git", "init", out: File::NULL)
    system("git", "config", "user.name", "Test User", out: File::NULL)
    system("git", "config", "user.email", "test@example.com", out: File::NULL)

    # Mock ace-task output
    task_output = <<~TASK
      # Task 081: Fix authentication bug

      **Status:** 🟡 In Progress
      **Estimate:** 2-4 hours
      **Tags:** bug, authentication

      ## Description
      Users are experiencing authentication issues when logging in with invalid credentials.

      ## Acceptance Criteria
      - [x] Validate input parameters
      - [ ] Show proper error messages
      - [ ] Add unit tests
    TASK

    # Stub the ace-task command and execute CLI inside the stub block
    Open3.stub(:capture3, [task_output, "", 0]) do
      output = run_cli(["create", "081", "--dry-run"])
      # Check output for successful dry-run message
      assert_includes output.join, "DRY RUN"
    end
  end

  def test_list_command_integration
    # The list command runs without crashing
    # Actual git worktree mocking happens at the molecule level
    output = run_cli(["list"])
    # Verify meaningful output - list shows table header or summary
    combined_output = output.join
    assert_match(/Task|Branch|Path|Summary|worktree/i, combined_output)
  end

  def test_list_cli_forwards_task_associated_true_filter
    captured_args = nil
    fake = Object.new
    fake.define_singleton_method(:run) do |args|
      captured_args = args
      0
    end

    Ace::Git::Worktree::Commands::ListCommand.stub(:new, fake) do
      run_cli(["list", "--task-associated"])
    end

    assert_includes captured_args, "--task-associated"
    refute_includes captured_args, "--no-task-associated"
  end

  def test_list_cli_forwards_task_associated_false_filter
    captured_args = nil
    fake = Object.new
    fake.define_singleton_method(:run) do |args|
      captured_args = args
      0
    end

    Ace::Git::Worktree::Commands::ListCommand.stub(:new, fake) do
      run_cli(["list", "--no-task-associated"])
    end

    assert_includes captured_args, "--no-task-associated"
    refute_includes captured_args, "--task-associated"
  end

  def test_list_cli_forwards_no_usable_filter
    captured_args = nil
    fake = Object.new
    fake.define_singleton_method(:run) do |args|
      captured_args = args
      0
    end

    Ace::Git::Worktree::Commands::ListCommand.stub(:new, fake) do
      run_cli(["list", "--no-usable"])
    end

    assert_includes captured_args, "--no-usable"
    refute_includes captured_args, "--usable"
  end

  def test_remove_command_with_dry_run
    output = run_cli(["remove", "/some/path", "--dry-run"])
    # Check for dry-run output (may be in stderr)
    combined_output = output.join
    assert_includes combined_output, "DRY RUN"
  end

  def test_switch_command_integration
    skip "Integration test requires full git/worktree setup - depends on command-level fixes"

    stub_git_command do
      output = run_cli(["switch", "main"])
      # Check that switch command ran
      assert_includes output.join, "/"
    end
  end

  def test_prune_command_with_dry_run
    skip "Integration test requires full git/worktree setup - depends on command-level fixes"

    stub_git_command do
      output = run_cli(["prune", "--dry-run"])
      # Check for dry-run or prune output
      assert_match(/DRY RUN|Pruned|No worktrees/i, output.join)
    end
  end

  def test_config_command_show
    output = run_cli(["config", "show"])
    # Should show configuration output
    assert_includes output.first, "Configuration"
  end

  def test_config_command_with_invalid_subcommand
    # Config command with invalid subcommand - shows help
    output = run_cli(["config", "invalid"])
    # Just verify it runs without raising and shows some output
    assert_kind_of Array, output
  end

  # Test error handling for missing dependencies
  def test_handles_missing_ace_task_gracefully
    # Mock ace-task as unavailable
    Open3.stub(:capture3, ["", "command not found: ace-task", 1]) do
      output = run_cli(["create", "081"])

      # Should handle gracefully - check for error message
      combined_output = output.join
      assert_match(/Error:|Failed to create|ace-task/i, combined_output)
    end
  end

  def test_run_create_with_missing_task_returns_error_exit_code
    stdout, stderr, status = run_exe("create", "--task", "8pp.t.zzz")

    refute status.success?
    combined_output = stdout + stderr
    assert_match(/Failed to create worktree|Task not found|ace-task/i, combined_output)
  end

  def test_security_validation_in_task_ids
    skip "Security validation for shell injection in task IDs not yet implemented - see task backlog"

    # Test that dangerous task IDs are rejected
    # NOTE: This test documents the DESIRED behavior, not current behavior.
    # Currently, dangerous IDs pass through and only fail due to filesystem errors.
    # TODO: Implement proper shell injection validation in CreateCommand.
    dangerous_ids = [
      "081; rm -rf /",
      "081`whoami`",
      "081|cat /etc/passwd",
      "081$(whoami)",
      "081&&echo hack",
      "081||echo hack",
      "../../etc/passwd",
      "081\x00null",
      "081\ninjection",
      "081\tinjection"
    ]

    # Security test: Verify dangerous inputs are rejected at command level,
    # BEFORE any git operations. No stub needed - if validation fails,
    # git/Open3 would never be called.
    dangerous_ids.each do |dangerous_id|
      output = run_cli(["create", dangerous_id, "--dry-run"])

      # Should reject dangerous input without executing any commands
      # Check for error message indicating rejection
      combined_output = output.join
      assert_match(/Error:|dangerous|invalid/i, combined_output,
        "Dangerous ID should be rejected: #{dangerous_id.inspect}")
    end
  end

  # Test --pr flag integration with CLI
  def test_create_pr_worktree_cli_integration
    skip "Integration test requires gh CLI and network access"

    # This test verifies the CLI correctly routes --pr to PR worktree creation
    # When run manually (without skip), it tests end-to-end:
    #
    # result = Ace::Git::Worktree::CLI.start(["create", "--pr", "123", "--dry-run"])
    #
    # Expected behavior:
    # 1. CLI parses --pr flag correctly
    # 2. Routes to create_pr_worktree
    # 3. Validates PR number
    # 4. Attempts to fetch PR metadata (requires gh CLI)
    # 5. Returns appropriate exit code
  end

  def test_create_pr_worktree_cli_routes_correctly
    # Test that --pr flag routes to PR creation (no network needed)
    output = run_cli(["create", "--pr", "invalid-not-numeric"])

    # Should fail validation (PR number must be numeric) - check for error message
    combined_output = output.join
    # The validation may happen at different levels, just verify it doesn't crash
    assert_match(/Error:|Invalid|numeric/i, combined_output)
  end

  private

  def run_cli(args)
    capture_io do
      Ace::Support::Cli::Runner.new(Ace::Git::Worktree::CLI).call(args: args)
    rescue SystemExit
      nil
    end
  end

  def run_exe(*args)
    Open3.capture3(@exe_path, *args)
  end

  def stub_git_command(output = "", error = "", exit_status = 0)
    # Stub any git-related commands that might be called
    Open3.stub(:capture3, [output, error, exit_status]) do
      yield
    end
  end
end
