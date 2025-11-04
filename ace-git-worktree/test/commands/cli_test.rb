# frozen_string_literal: true

require_relative "../test_helper"

class CliTest < Minitest::Test
  def setup
    setup_temp_dir
    @cli = Ace::Git::Worktree::CLI.new([])
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_without_arguments_shows_help
    cli = Ace::Git::Worktree::CLI.new([])
    result = cli.run

    assert_equal 0, result
    # Help should be shown (we can't easily capture stdout here,
    # but we can test that it doesn't crash)
  end

  def test_run_with_help_flag
    cli = Ace::Git::Worktree::CLI.new(["--help"])
    result = cli.run

    assert_equal 0, result
  end

  def test_run_with_short_help_flag
    cli = Ace::Git::Worktree::CLI.new(["-h"])
    result = cli.run

    assert_equal 0, result
  end

  def test_run_with_help_command
    cli = Ace::Git::Worktree::CLI.new(["help"])
    result = cli.run

    assert_equal 0, result
  end

  def test_run_with_version_flag
    cli = Ace::Git::Worktree::CLI.new(["--version"])
    result = cli.run

    assert_equal 0, result
  end

  def test_run_with_short_version_flag
    cli = Ace::Git::Worktree::CLI.new(["-v"])
    result = cli.run

    assert_equal 0, result
  end

  def test_run_with_version_command
    cli = Ace::Git::Worktree::CLI.new(["version"])
    result = cli.run

    assert_equal 0, result
  end

  def test_run_with_invalid_command
    cli = Ace::Git::Worktree::CLI.new(["invalid-command"])
    result = cli.run

    assert_equal 1, result
  end

  def test_create_command_integration
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

    cli = Ace::Git::Worktree::CLI.new(["create", "081", "--dry-run"])

    # Stub the ace-taskflow command
    Open3.stub(:capture3, [task_output, "", 0]) do
      result = cli.run
      # Should succeed in dry-run mode even without actual git repo
      assert_equal 0, result
    end
  end

  def test_list_command_integration
    cli = Ace::Git::Worktree::CLI.new(["list"])

    # Mock git worktree list output
    git_output = <<~GIT
      /path/to/main-worktree  abcdef1234567890 [main]
      /path/to/feature-branch  bcdef1234567890a [feature-branch]
    GIT

    stub_git_command(git_output) do
      result = cli.run
      assert_equal 0, result
    end
  end

  def test_remove_command_with_dry_run
    cli = Ace::Git::Worktree::CLI.new(["remove", "/some/path", "--dry-run"])

    result = cli.run
    assert_equal 0, result
  end

  def test_switch_command_integration
    cli = Ace::Git::Worktree::CLI.new(["switch", "main"])

    stub_git_command do
      result = cli.run
      assert_equal 0, result
    end
  end

  def test_prune_command_with_dry_run
    cli = Ace::Git::Worktree::CLI.new(["prune", "--dry-run"])

    stub_git_command do
      result = cli.run
      assert_equal 0, result
    end
  end

  def test_config_command_show
    cli = Ace::Git::Worktree::CLI.new(["config", "show"])

    result = cli.run
    assert_equal 0, result
  end

  def test_config_command_with_invalid_subcommand
    cli = Ace::Git::Worktree::CLI.new(["config", "invalid"])

    result = cli.run
    assert_equal 1, result
  end

  # Test error handling for missing dependencies
  def test_handles_missing_ace_taskflow_gracefully
    # Mock ace-taskflow as unavailable
    Open3.stub(:capture3, ["", "command not found: ace-taskflow", 1]) do
      cli = Ace::Git::Worktree::CLI.new(["create", "081"])
      result = cli.run

      # Should handle gracefully and not crash
      assert_equal 1, result
    end
  end

  def test_security_validation_in_task_ids
    # Test that dangerous task IDs are rejected
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

    dangerous_ids.each do |dangerous_id|
      cli = Ace::Git::Worktree::CLI.new(["create", dangerous_id, "--dry-run"])

      # Should not crash or execute malicious commands
      result = cli.run
      # Should fail gracefully
      assert_equal 1, result, "Dangerous ID should be rejected: #{dangerous_id.inspect}"
    end
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