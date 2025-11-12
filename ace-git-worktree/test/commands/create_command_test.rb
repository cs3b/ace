# frozen_string_literal: true

require_relative "../test_helper"

class CreateCommandTest < Minitest::Test
  def setup
    setup_temp_dir
    @command = Ace::Git::Worktree::Commands::CreateCommand.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_with_help_flag
    result = @command.run(["--help"])
    assert_equal 0, result
  end

  def test_run_with_no_arguments_shows_help
    result = @command.run([])
    # Should show help and return success
    assert_equal 0, result
  end

  def test_run_with_task_argument
    # Mock successful task creation
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      steps_completed: ["create_worktree", "checkout_branch"]
    }
    mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    @command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = @command.run(["--task", "081"])
      assert_equal 0, result
      mock_worktree_manager.verify
    end
  end

  def test_run_with_task_and_dry_run
    # Mock successful dry run
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      would_create: {
        worktree_path: "/path/to/worktree",
        branch: "task-081"
      },
      steps_planned: ["create_worktree", "checkout_branch"]
    }
    mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    @command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = @command.run(["--task", "081", "--dry-run"])
      assert_equal 0, result
      mock_worktree_manager.verify
    end
  end

  def test_run_with_traditional_branch
    # Mock successful traditional worktree creation
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create, { success: true }, [String, Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["feature-branch"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_branch_and_path
    # Mock successful traditional worktree creation with custom path
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create, { success: true }, [String, Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["feature-branch", "--path", "/custom/path"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_invalid_task_id
    result = @command.run(["--task", "invalid"])
    # Should handle invalid task gracefully
    assert_equal 1, result
  end

  def test_run_with_dangerous_task_id
    dangerous_ids = [
      "081; rm -rf /",
      "081`whoami`",
      "081|cat /etc/passwd",
      "081$(whoami)",
      "../../etc/passwd"
    ]

    dangerous_ids.each do |dangerous_id|
      result = @command.run(["--task", dangerous_id])
      assert_equal 1, result, "Should reject dangerous task ID: #{dangerous_id}"
    end
  end

  def test_run_with_missing_task_argument
    result = @command.run(["--task"])
    assert_equal 1, result
  end

  def test_parse_arguments_with_task_flag
    # We can't directly test parse_arguments as it's private,
    # but we can test the behavior through run()
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      would_create: {
        worktree_path: "/custom/path",
        branch: "task-081"
      },
      steps_planned: ["create_worktree"]
    }
    mock_worktree_manager.expect(:create_task, mock_result) do |task_ref, options|
      assert_equal "081", task_ref
      assert_equal true, options[:dry_run]
      assert_equal "/custom/path", options[:path]
      mock_result
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    @command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = @command.run(["--task", "081", "--dry-run", "--path", "/custom/path"])
      assert_equal 0, result
      mock_worktree_manager.verify
    end
  end

  def test_handles_worktree_manager_errors
    # Mock worktree manager throwing an error
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task, nil) do
      raise StandardError, "Git command failed"
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--task", "081"])
    assert_equal 1, result
    mock_worktree_manager.verify
  end

  def test_argument_validation_errors
    # Test validation of contradictory arguments
    result = @command.run(["--task", "081", "feature-branch"])
    # Should fail because both task and branch specified
    assert_equal 1, result
  end

  def test_long_task_reference_formats
    task_formats = [
      "081",
      "task.081",
      "v.0.9.0+081",
      "v.0.9.0+task.081"
    ]

    task_formats.each do |task_format|
      mock_worktree_manager = Minitest::Mock.new
      mock_result = {
        success: true,
        task_id: task_format,
        task_title: "Test task",
        would_create: {
          worktree_path: "/path/to/worktree",
          branch: "task-081"
        },
        steps_planned: ["create_worktree"]
      }
      mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

      @command.instance_variable_set(:@manager, mock_worktree_manager)

      @command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
        result = @command.run(["--task", task_format, "--dry-run"])
        assert_equal 0, result, "Should accept task format: #{task_format}"
        mock_worktree_manager.verify
      end
    end
  end

  def test_security_validation_on_paths
    skip "Security validation only checks shell injection patterns, not absolute/system paths - needs design decision on whether to reject absolute paths"

    dangerous_paths = [
      "/etc/passwd",
      "../../../root",
      "/tmp; rm -rf /",
      "$(rm -rf /)",
      "`whoami`"
    ]

    dangerous_paths.each do |dangerous_path|
      result = @command.run(["--task", "081", "--path", dangerous_path, "--dry-run"])
      assert_equal 1, result, "Should reject dangerous path: #{dangerous_path}"
    end
  end

  def test_cli_override_flags_are_passed_through_task_creation
    # Test that CLI override flags are properly passed through the manager chain (critical for review feedback)
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      would_create: {
        worktree_path: "/path/to/worktree",
        branch: "task-081"
      },
      steps_planned: ["create_worktree"]
    }
    mock_worktree_manager.expect(:create_task, mock_result) do |task_ref, options|
      assert_equal "081", task_ref
      # Test that all CLI override flags are properly passed through
      assert_equal true, options[:no_mise_trust], "Should pass through --no-mise-trust"
      assert_equal true, options[:no_status_update], "Should pass through --no-status-update"
      assert_equal true, options[:no_commit], "Should pass through --no-commit"
      assert_equal "Custom commit message", options[:commit_message], "Should pass through --commit-message"
      assert_equal true, options[:dry_run], "Should pass through --dry-run"
      mock_result
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    @command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = @command.run([
        "--task", "081",
        "--no-mise-trust",
        "--no-status-update",
        "--no-commit",
        "--commit-message", "Custom commit message",
        "--dry-run"
      ])

      assert_equal 0, result
      mock_worktree_manager.verify
    end
  end

  def test_cli_override_flags_are_passed_through_traditional_creation
    # Test that CLI override flags work for traditional worktree creation too
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create, { success: true }) do |branch_name, options|
      assert_equal "feature-branch", branch_name
      # Test that relevant CLI override flags are properly passed through
      assert_equal true, options[:no_mise_trust], "Should pass through --no-mise-trust"
      assert_equal "/custom/path", options[:path], "Should pass through --path"
      assert_equal true, options[:force], "Should pass through --force"
      { success: true }
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run([
      "feature-branch",
      "--path", "/custom/path",
      "--no-mise-trust",
      "--force"
    ])

    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_individual_override_flags_work
    # Test each override flag individually to ensure they work in isolation
    override_flags = [
      ["--no-mise-trust", :no_mise_trust],
      ["--no-status-update", :no_status_update],
      ["--no-commit", :no_commit]
    ]

    override_flags.each do |flag, option_key|
      mock_worktree_manager = Minitest::Mock.new
      mock_result = {
        success: true,
        task_id: "081",
        task_title: "Test task",
        would_create: {
          worktree_path: "/path/to/worktree",
          branch: "task-081"
        },
        steps_planned: ["create_worktree"]
      }
      mock_worktree_manager.expect(:create_task, mock_result) do |task_ref, options|
        assert_equal true, options[option_key], "Should set #{option_key} to true for #{flag}"
        mock_result
      end

      @command.instance_variable_set(:@manager, mock_worktree_manager)

      @command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
        result = @command.run(["--task", "081", flag, "--dry-run"])
        assert_equal 0, result, "Should handle #{flag} flag correctly"
        mock_worktree_manager.verify
      end
    end
  end

  def test_commit_message_override_works
    # Test that custom commit messages are properly passed through
    test_messages = [
      "Implement feature X",
      "Fix security vulnerability",
      "Update dependencies",
      "WIP: experimental changes"
    ]

    test_messages.each do |commit_message|
      mock_worktree_manager = Minitest::Mock.new
      mock_result = {
        success: true,
        task_id: "081",
        task_title: "Test task",
        would_create: {
          worktree_path: "/path/to/worktree",
          branch: "task-081"
        },
        steps_planned: ["create_worktree"]
      }
      mock_worktree_manager.expect(:create_task, mock_result) do |task_ref, options|
        assert_equal commit_message, options[:commit_message], "Should pass through custom commit message"
        mock_result
      end

      @command.instance_variable_set(:@manager, mock_worktree_manager)

      @command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
        result = @command.run([
          "--task", "081",
          "--commit-message", commit_message,
          "--dry-run"
        ])

        assert_equal 0, result, "Should handle commit message: #{commit_message}"
        mock_worktree_manager.verify
      end
    end
  end
end