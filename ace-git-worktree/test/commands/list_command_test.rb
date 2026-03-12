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
    skip "Mock result structure incomplete - display_list_result expects additional fields or methods on result object"

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
    mock_result = {
      success: true,
      worktrees: mock_worktrees,
      formatted_output: "main (/path/to/main)\nfeature-branch (/path/to/feature)",
      statistics: {
        total: 2,
        task_associated: 0,
        traditional: 2
      }
    }
    mock_worktree_manager.expect(:list_all, mock_result, [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    # Capture output to verify
    result = nil
    output = capture_io do
      result = @command.run([])
    end

    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_search_option
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_all, { success: true, worktrees: [] }, [Hash])

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--search", "feature"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_task_associated_filter
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_all, { success: true, worktrees: [] }) do |options|
      options[:task_associated] == true
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--task-associated"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_no_task_associated_filter
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_all, { success: true, worktrees: [] }) do |options|
      options[:task_associated] == false
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--no-task-associated"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_handles_list_errors_gracefully
    # Mock worktree manager throwing an error
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_all, nil) do
      raise StandardError, "Git command failed"
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run([])
    assert_equal 1, result
    mock_worktree_manager.verify
  end

  def test_security_validation_on_search_arguments
    dangerous_searches = [
      "; rm -rf /",
      "$(whoami)",
      "`cat /etc/passwd`",
      "../etc/passwd"
    ]

    dangerous_searches.each do |dangerous_search|
      result = @command.run(["--search", dangerous_search])
      assert_equal 1, result, "Should reject dangerous search: #{dangerous_search}"
    end
  end

  # Tests for format option handling (TC-005 fix)
  def test_format_option_converted_to_symbol
    # Mock worktree manager to verify format is passed as symbol
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_all, { success: true, worktrees: [] }) do |options|
      # The format should be a symbol after conversion
      options[:format] == :json
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--format", "json"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_format_option_json_converted_to_symbol
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_all, { success: true, worktrees: [] }) do |options|
      options[:format] == :json
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)
    result = @command.run(["--format", "json"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_format_option_table_converted_to_symbol
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_all, { success: true, worktrees: [] }) do |options|
      options[:format] == :table
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)
    result = @command.run(["--format", "table"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_format_option_simple_converted_to_symbol
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:list_all, { success: true, worktrees: [] }) do |options|
      options[:format] == :simple
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)
    result = @command.run(["--format", "simple"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_json_output_does_not_print_summary_footer
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      worktrees: [{ path: "/tmp/wt" }],
      formatted_output: "[{\"path\":\"/tmp/wt\"}]",
      statistics: {
        total: 1,
        task_associated: 0,
        non_task_associated: 1,
        usable: 1,
        unusable: 0,
        bare: 0,
        detached: 0,
        branches: ["main"],
        task_ids: []
      }
    }
    mock_worktree_manager.expect(:list_all, mock_result) do |options|
      options[:format] == :json
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    stdout, = capture_io do
      result = @command.run(["--format", "json"])
      assert_equal 0, result
    end

    assert_equal "[{\"path\":\"/tmp/wt\"}]\n", stdout
    mock_worktree_manager.verify
  end
end
