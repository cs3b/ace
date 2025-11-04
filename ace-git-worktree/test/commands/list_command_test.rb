# frozen_string_literal: true

require_relative "../test_helper"

class ListCommandTest < Minitest::Test
  def setup
    setup_temp_dir
    @command = Ace::Git::Worktree::Commands::ListCommand.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_with_help_flag
    result = @command.run(["--help"])
    assert_equal 0, result
  end

  def test_run_lists_worktrees
    # Mock worktree manager to return some worktrees
    mock_worktree_manager = Minitest::Mock.new
    mock_worktrees = [
      {
        path: "/path/to/main",
        commit: "abc123",
        branch: "main",
        bare: false
      },
      {
        path: "/path/to/feature",
        commit: "def456",
        branch: "feature-branch",
        bare: false
      }
    ]
    mock_worktree_manager.expect(:list_worktrees, mock_worktrees, [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    # Capture output to verify
    output = capture_io do
      result = @command.run([])
    end

    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_filter_option
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_worktrees, [], [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--filter", "feature"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_detailed_option
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_worktrees, [], [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--detailed"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_task_filter
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_worktrees, [], [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--task"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_handles_list_errors_gracefully
    # Mock worktree manager throwing an error
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_worktrees, nil) do
      raise StandardError, "Git command failed"
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run([])
    assert_equal 1, result
    mock_worktree_manager.verify
  end

  def test_security_validation_on_filter_arguments
    dangerous_filters = [
      "; rm -rf /",
      "$(whoami)",
      "`cat /etc/passwd`",
      "../etc/passwd"
    ]

    dangerous_filters.each do |dangerous_filter|
      result = @command.run(["--filter", dangerous_filter])
      assert_equal 1, result, "Should reject dangerous filter: #{dangerous_filter}"
    end
  end
end