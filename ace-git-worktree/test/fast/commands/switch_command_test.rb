# frozen_string_literal: true

require_relative "../../test_helper"

class SwitchCommandTest < Minitest::Test
  def setup
    setup_temp_dir
    @command = Ace::Git::Worktree::Commands::SwitchCommand.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_with_help_flag
    result = @command.run(["--help"])
    assert_equal 0, result
  end

  def test_run_with_no_arguments_shows_error
    result = @command.run([])
    assert_equal 1, result
  end

  def test_run_with_worktree_path
    # Mock successful worktree switch
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:switch, {success: true}, [String])

    command = Ace::Git::Worktree::Commands::SwitchCommand.new(manager: mock_worktree_manager)

    result = command.run(["/path/to/worktree"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_branch_name
    # Mock successful branch switch
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      worktree_path: "/path/to/worktree",
      branch: "feature-branch",
      description: "Feature branch worktree"
    }
    mock_worktree_manager.expect(:switch, mock_result, [String])

    command = Ace::Git::Worktree::Commands::SwitchCommand.new(manager: mock_worktree_manager)

    result = command.run(["--branch", "feature-branch"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_task_reference
    # Mock successful task worktree switch
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      worktree_path: "/path/to/task-worktree",
      branch: "task-081",
      task_id: "081",
      description: "Task worktree"
    }
    mock_worktree_manager.expect(:switch, mock_result, [String])

    command = Ace::Git::Worktree::Commands::SwitchCommand.new(manager: mock_worktree_manager)

    result = command.run(["--task", "081"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_list_option
    skip "Mock worktree objects need task_associated? method - incomplete mock structure"

    # Mock successful listing of available worktrees
    mock_worktree_manager = Minitest::Mock.new
    mock_worktrees = [
      {path: "/path/to/main", branch: "main"},
      {path: "/path/to/feature", branch: "feature-branch"}
    ]
    mock_worktree_manager.expect(:list_all, {success: true, worktrees: mock_worktrees}, [Hash])

    command = Ace::Git::Worktree::Commands::SwitchCommand.new(manager: mock_worktree_manager)

    result = command.run(["--list"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_handles_switch_errors_gracefully
    # Mock worktree manager throwing an error
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:switch, nil) do
      raise StandardError, "Worktree not found"
    end

    command = Ace::Git::Worktree::Commands::SwitchCommand.new(manager: mock_worktree_manager)

    result = command.run(["/nonexistent/path"])
    assert_equal 1, result
    mock_worktree_manager.verify
  end

  def test_security_validation_on_paths_and_tasks
    dangerous_inputs = [
      "/etc/passwd",
      "../../../root",
      "; rm -rf /",
      "$(whoami)",
      "`cat /etc/passwd`",
      "081; rm -rf /",
      "task.081`whoami`"
    ]

    # Security test: Verify dangerous inputs are rejected at command level,
    # BEFORE manager is called. No manager mock needed - if validation fails,
    # the manager would never be invoked.
    dangerous_inputs.each do |dangerous_input|
      result = @command.run([dangerous_input])
      assert_equal 1, result, "Should reject dangerous input: #{dangerous_input}"
    end
  end

  def test_mutually_exclusive_arguments
    # Test that conflicting arguments are rejected
    result = @command.run(["--branch", "main", "--task", "081"])
    assert_equal 1, result
  end

  def test_valid_task_formats
    valid_task_formats = [
      "081",
      "task.081",
      "v.0.9.0+081"
    ]

    valid_task_formats.each do |task_format|
      mock_worktree_manager = Minitest::Mock.new
      mock_result = {
        success: true,
        worktree_path: "/path/to/task-worktree",
        branch: "task-081",
        task_id: task_format,
        description: "Task worktree"
      }
      mock_worktree_manager.expect(:switch, mock_result, [String])

      command = Ace::Git::Worktree::Commands::SwitchCommand.new(manager: mock_worktree_manager)

      result = command.run(["--task", task_format])
      assert_equal 0, result, "Should accept valid task format: #{task_format}"
      mock_worktree_manager.verify
    end
  end
end
