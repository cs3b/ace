# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/status_command"

class StatusCommandTest < AceTaskflowTestCase
  def setup
    super
    @command = Ace::Taskflow::Commands::StatusCommand.new
  end

  def test_execute_returns_zero_on_success
    mock_context = create_mock_context

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      result = capture_io do
        exit_code = @command.execute([])
        assert_equal 0, exit_code
      end
    end
  end

  def test_execute_outputs_markdown_by_default
    mock_context = create_mock_context

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      assert_includes output, "# Taskflow Status"
      # Only taskflow info (release, task) - no git state
      # Release line format: "v.0.9.0: X/Y tasks • Codename"
      assert_includes output, "v.0.9.0:"
      assert_includes output, "tasks"
      refute_includes output, "Branch:"
      refute_includes output, "## Repository"
      refute_includes output, "| Field |"  # No tables
    end
  end

  def test_execute_outputs_json_when_requested
    mock_context = create_mock_context

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute(["--json"]) }.first

      # Should be valid JSON
      require "json"
      parsed = JSON.parse(output)

      # No repository key - only task and release
      refute parsed.key?("repository")
      assert parsed.key?("task")
      assert parsed.key?("release")
    end
  end

  def test_execute_outputs_task_info_when_present
    mock_context = create_mock_context(
      task: {
        id: "v.0.9.0+task.140",
        title: "Test Feature",
        status: "in-progress",
        path: "/path/to/task.s.md",
        priority: "high",
        estimate: "4h"
      }
    )

    # Mock the TaskCommand invocation to avoid real ace-taskflow task command
    # Uses direct TaskCommand call (not subprocess) for better performance
    mock_task_output = "  Task: v.0.9.0+task.140 🟡 Test Feature\n    Path: /path/to/task.s.md\n    Estimate: 4h | Priority: high\n"

    @command.stub :fetch_task_output, mock_task_output do
      Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
        output = capture_io { @command.execute([]) }.first

        assert_includes output, "v.0.9.0+task.140"
        assert_includes output, "Test Feature"
        assert_includes output, "[🟡]"
        assert_includes output, "Estimate: 4h"
      end
    end
  end

  def test_execute_handles_no_task
    mock_context = create_mock_context(task: nil)

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      assert_includes output, "No task pattern detected"
    end
  end

  def test_execute_outputs_release_info
    mock_context = create_mock_context(
      release: {
        name: "v.0.9.0",
        progress: 75,
        done_tasks: 15,
        total_tasks: 20,
        codename: "Test Release"
      }
    )

    # Release header is formatted inline by status_command (no StatsFormatter needed)
    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      # Release header includes done/total as promised in CHANGELOG
      assert_includes output, "v.0.9.0:"
      assert_includes output, "15/20 tasks"
      assert_includes output, "Test Release"
    end
  end

  def test_execute_handles_no_release
    mock_context = create_mock_context(release: nil)

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      # When release is nil, we just don't show it (no message)
      refute_includes output, "**Release:**"
    end
  end

  def test_help_option_shows_usage
    output, err = capture_io do
      exit_code = @command.execute(["--help"])
      assert_equal 0, exit_code, "--help should exit with code 0"
    end

    assert_includes output, "Usage: ace-taskflow status"
    # No longer includes --no-pr (PR is now in ace-git context)
    assert_includes output, "--json"
    assert_includes output, "ace-git context"  # Reference to git context command
    assert_empty err, "--help should not print errors"
  end

  def test_execute_returns_one_on_error
    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, -> { raise "Test error" } do
      result = capture_io do
        exit_code = @command.execute([])
        assert_equal 1, exit_code
      end
    end
  end

  def test_execute_handles_malformed_task_id
    # Test edge case: task ID doesn't match expected pattern (v.X.Y+task.NN)
    mock_context = create_mock_context(
      task: {
        id: "invalid-task-id",  # Malformed ID
        title: "Invalid Task",
        status: "pending",
        path: "/path/to/invalid.s.md"
      }
    )

    # Mock fetch_task_output to return empty (simulating task not found)
    @command.stub :fetch_task_output, "" do
      Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
        output = capture_io { @command.execute([]) }.first

        # Should show the task header but indicate invalid reference
        assert_includes output, "## Task: invalid-task-id"
        assert_includes output, "Error: Invalid task reference"
      end
    end
  end

  def test_execute_shows_parent_task_for_subtasks
    # Test that parent field is used when present (subtask behavior)
    mock_context = create_mock_context(
      task: {
        id: "v.0.9.0+task.140.02",  # Subtask ID
        title: "Subtask Feature",
        status: "in-progress",
        path: "/path/to/subtask.s.md",
        parent: "140"  # Parent task reference
      }
    )

    # Mock fetch_task_output to track what ref was passed
    fetch_called_with = nil
    mock_output = "  Task: v.0.9.0+task.140 🟡 Parent Task\n    Path: /path/to/parent.s.md\n"

    @command.stub :fetch_task_output, ->(ref) {
      fetch_called_with = ref
      mock_output
    } do
      Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
        output = capture_io { @command.execute([]) }.first

        # Should use parent reference ("140") instead of extracting from ID
        assert_equal "140", fetch_called_with
        assert_includes output, "Subtask Feature"
        assert_includes output, "Parent Task"
      end
    end
  end

  def test_execute_outputs_task_activity_section
    mock_context = create_mock_context(
      task_activity: {
        recently_done: [
          { id: "v.0.9.0+task.001", title: "Completed task" }
        ],
        in_progress: [
          { id: "v.0.9.0+task.143", title: "Other work" }
        ],
        up_next: [
          { id: "v.0.9.0+task.140.03", title: "Next task" }
        ]
      }
    )

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      assert_includes output, "## Task Activity"
      assert_includes output, "### Recently Done"
      assert_includes output, "001: Completed task"
      assert_includes output, "### In Progress"
      assert_includes output, "143: Other work"
      assert_includes output, "### Up Next"
      assert_includes output, "140.03: Next task"
    end
  end

  def test_execute_outputs_empty_messages_for_no_activity
    mock_context = create_mock_context(
      task_activity: {
        recently_done: [],
        in_progress: [],
        up_next: []
      }
    )

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      assert_includes output, "No recently completed tasks"
      assert_includes output, "No other tasks in progress"
      assert_includes output, "No pending tasks"
    end
  end

  def test_json_output_includes_task_activity
    mock_context = create_mock_context(
      task_activity: {
        recently_done: [{ id: "v.0.9.0+task.001", title: "Done task" }],
        in_progress: [],
        up_next: []
      }
    )

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute(["--json"]) }.first

      require "json"
      parsed = JSON.parse(output)

      assert parsed.key?("task_activity")
      assert_kind_of Array, parsed["task_activity"]["recently_done"]
      assert_equal 1, parsed["task_activity"]["recently_done"].length
    end
  end

  # --- CLI override flags propagation tests ---

  def test_execute_passes_recently_done_limit_to_loader
    # Verify CLI flags propagate through to TaskflowContextLoader
    options_received = nil

    loader_mock = lambda do |options|
      options_received = options
      create_mock_context
    end

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, loader_mock do
      capture_io { @command.execute(["--recently-done-limit", "5"]) }
    end

    assert_equal 5, options_received[:recently_done_limit]
  end

  def test_execute_passes_up_next_limit_to_loader
    options_received = nil

    loader_mock = lambda do |options|
      options_received = options
      create_mock_context
    end

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, loader_mock do
      capture_io { @command.execute(["--up-next-limit", "10"]) }
    end

    assert_equal 10, options_received[:up_next_limit]
  end

  def test_execute_passes_include_drafts_to_loader
    options_received = nil

    loader_mock = lambda do |options|
      options_received = options
      create_mock_context
    end

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, loader_mock do
      capture_io { @command.execute(["--include-drafts"]) }
    end

    assert_equal true, options_received[:include_drafts]
  end

  def test_execute_passes_zero_limit_to_loader
    # Verify that explicit 0 values are passed through (not collapsed to config default)
    options_received = nil

    loader_mock = lambda do |options|
      options_received = options
      create_mock_context
    end

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, loader_mock do
      capture_io { @command.execute(["--recently-done-limit", "0"]) }
    end

    assert_equal 0, options_received[:recently_done_limit]
  end

  # Create mock context hash for testing
  private

  def create_mock_context(overrides = {})
    {
      task: overrides.key?(:task) ? overrides[:task] : nil,
      release: overrides.key?(:release) ? overrides[:release] : {
        name: "v.0.9.0",
        progress: 50,
        done_tasks: 5,
        total_tasks: 10
      },
      task_activity: overrides.key?(:task_activity) ? overrides[:task_activity] : {
        recently_done: [],
        in_progress: [],
        up_next: []
      }
    }
  end
end
