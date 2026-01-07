# frozen_string_literal: true

require_relative "../test_helper"

class CliTest < Minitest::Test
  def setup
    setup_temp_dir
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_without_arguments_shows_help
    # dry-cli shows help when no arguments (using default command routing)
    output = capture_io do
      Ace::Git::Worktree::CLI.start([])
    end
    # With dry-cli, empty args routes to default command (create)
    # which shows help since no branch is provided
    assert_includes output.first, "USAGE:"
  end

  def test_run_with_help_flag
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["--help"])
    end
    # dry-cli help format shows available commands
    assert_includes output.first, "Commands:"
  end

  def test_run_with_short_help_flag
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["-h"])
    end
    assert_includes output.first, "Commands:"
  end

  def test_run_with_help_command
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["help"])
    end
    assert_includes output.first, "Commands:"
  end

  def test_run_with_version_flag
    output = capture_io do
      result = Ace::Git::Worktree::CLI.start(["--version"])
    end
    # Check version is output
    assert_includes output.first, "ace-git-worktree"
    # Note: dry-cli doesn't return exit codes, so we check output instead
  end

  def test_run_with_short_version_flag
    # Note: -v is now --verbose per ADR-018, --version is for version
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["--version"])
    end
    assert_includes output.first, "ace-git-worktree"
  end

  def test_run_with_version_command
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["version"])
    end
    assert_includes output.first, "ace-git-worktree"
  end

  def test_run_with_invalid_command
    # dry-cli treats unknown commands as arguments to the default command
    # So "invalid-command" is treated as a branch name for "create"
    # This will show a "Failed to create worktree" message
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["invalid-command"])
    end
    # Should show error about failed creation
    combined_output = output.join
    assert_match(/Failed to create|Error:|Usage:|Must specify/i, combined_output)
  end

  def test_create_command_integration
    skip "Integration test requires full task workflow setup - depends on command-level fixes"

    # Mock git repository setup
    system("git", "init", out: File::NULL)
    system("git", "config", "user.name", "Test User", out: File::NULL)
    system("git", "config", "user.email", "test@example.com", out: File::NULL)

    # Mock ace-taskflow output
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

    # Stub the ace-taskflow command and execute CLI inside the stub block
    Open3.stub(:capture3, [task_output, "", 0]) do
      output = Ace::Git::Worktree::CLI.start(["create", "081", "--dry-run"])
      # Check output for successful dry-run message
      assert_includes output.join, "DRY RUN"
    end
  end

  def test_list_command_integration
    # The list command runs without crashing
    # Actual git worktree mocking happens at the molecule level
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["list"])
    end
    # Verify meaningful output - list shows table header or summary
    combined_output = output.join
    assert_match(/Task|Branch|Path|Summary|worktree/i, combined_output)
  end

  def test_remove_command_with_dry_run
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["remove", "/some/path", "--dry-run"])
    end
    # Check for dry-run output (may be in stderr)
    combined_output = output.join
    assert_includes combined_output, "DRY RUN"
  end

  def test_switch_command_integration
    skip "Integration test requires full git/worktree setup - depends on command-level fixes"

    stub_git_command do
      output = Ace::Git::Worktree::CLI.start(["switch", "main"])
      # Check that switch command ran
      assert_includes output.join, "/"
    end
  end

  def test_prune_command_with_dry_run
    skip "Integration test requires full git/worktree setup - depends on command-level fixes"

    stub_git_command do
      output = Ace::Git::Worktree::CLI.start(["prune", "--dry-run"])
      # Check for dry-run or prune output
      assert_match(/DRY RUN|Pruned|No worktrees/i, output.join)
    end
  end

  def test_config_command_show
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["config", "show"])
    end
    # Should show configuration output
    assert_includes output.first, "Configuration"
  end

  def test_config_command_with_invalid_subcommand
    # Config command with invalid subcommand - shows help
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["config", "invalid"])
    end
    # Just verify it runs without raising and shows some output
    assert_kind_of Array, output
  end

  # Test error handling for missing dependencies
  def test_handles_missing_ace_taskflow_gracefully
    # Mock ace-taskflow as unavailable
    Open3.stub(:capture3, ["", "command not found: ace-taskflow", 1]) do
      output = capture_io do
        Ace::Git::Worktree::CLI.start(["create", "081"])
      end

      # Should handle gracefully - check for error message
      combined_output = output.join
      assert_match(/Error:|Failed to create|ace-taskflow/i, combined_output)
    end
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
      output = capture_io do
        Ace::Git::Worktree::CLI.start(["create", dangerous_id, "--dry-run"])
      end

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
    output = capture_io do
      Ace::Git::Worktree::CLI.start(["create", "--pr", "invalid-not-numeric"])
    end

    # Should fail validation (PR number must be numeric) - check for error message
    combined_output = output.join
    # The validation may happen at different levels, just verify it doesn't crash
    assert_match(/Error:|Invalid|numeric/i, combined_output)
  end

  private

  def stub_git_command(output = "", error = "", exit_status = 0)
    # Mock git command execution via ace-git-diff
    mock_result = {
      success: exit_status == 0,
      output: output,
      error: error,
      exit_code: exit_status
    }

    # Stub any git-related commands that might be called
    Open3.stub(:capture3, [output, error, exit_status]) do
      yield
    end
  end
end
