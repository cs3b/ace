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
    mock_worktree_manager.expect(:create_task_worktree, true, [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--task", "081"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_task_and_dry_run
    # Mock successful dry run
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree, true, [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--task", "081", "--dry-run"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_traditional_branch
    # Mock successful traditional worktree creation
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_traditional_worktree, true, [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["feature-branch"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_branch_and_path
    # Mock successful traditional worktree creation with custom path
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_traditional_worktree, true, [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--branch", "feature-branch", "--path", "/custom/path"])
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
    mock_worktree_manager.expect(:create_task_worktree, true) do |options|
      assert_equal "081", options[:task]
      assert_equal true, options[:dry_run]
      assert_equal "/custom/path", options[:path]
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--task", "081", "--dry-run", "--path", "/custom/path"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_handles_worktree_manager_errors
    # Mock worktree manager throwing an error
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task_worktree, nil) do
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
      mock_worktree_manager.expect(:create_task_worktree, true, [Hash])

      @command.instance_variable_set(:@manager, mock_worktree_manager)

      result = @command.run(["--task", task_format, "--dry-run"])
      assert_equal 0, result, "Should accept task format: #{task_format}"
      mock_worktree_manager.verify
    end
  end

  def test_security_validation_on_paths
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
end