# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/status_command"

# Integration test for full ace-taskflow status end-to-end flow
# Verifies CLI -> TaskflowContextLoader -> TaskActivityAnalyzer -> TaskDisplayFormatter chain
class CliStatusActivityIntegrationTest < AceTaskflowTestCase
  def setup
    super
    @command = Ace::Taskflow::Commands::StatusCommand.new
  end

  def test_status_command_returns_activity_sections
    # Create a mock context that simulates full pipeline output
    mock_context = {
      task: nil,
      release: {
        name: "v.0.9.0",
        progress: 50,
        done_tasks: 5,
        total_tasks: 10,
        codename: "Test Release"
      },
      task_activity: {
        recently_done: [
          { id: "v.0.9.0+task.001", title: "First completed", completed_at: Time.now - 3600 }
        ],
        in_progress: [
          { id: "v.0.9.0+task.002", title: "Currently working" }
        ],
        up_next: [
          { id: "v.0.9.0+task.003", title: "Coming next" }
        ]
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      # Verify all activity sections are present
      assert_includes output, "## Task Activity"
      assert_includes output, "### Recently Done"
      assert_includes output, "### In Progress"
      assert_includes output, "### Up Next"

      # Verify task references are formatted correctly (without version prefix)
      assert_includes output, "001: First completed"
      assert_includes output, "002: Currently working"
      assert_includes output, "003: Coming next"

      # Verify relative time formatting
      assert_includes output, "(done"
    end
  end

  def test_status_command_handles_empty_activity
    mock_context = {
      task: nil,
      release: {
        name: "v.0.9.0",
        progress: 0,
        done_tasks: 0,
        total_tasks: 0
      },
      task_activity: {
        recently_done: [],
        in_progress: [],
        up_next: []
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      # Verify empty state messages (using constants from TaskDisplayFormatter)
      assert_includes output, "No recently completed tasks"
      assert_includes output, "No other tasks in progress"
      assert_includes output, "No pending tasks"
    end
  end

  def test_status_command_json_includes_activity
    mock_context = {
      task: nil,
      release: { name: "v.0.9.0" },
      task_activity: {
        recently_done: [{ id: "v.0.9.0+task.001", title: "Done task" }],
        in_progress: [],
        up_next: []
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute(["--json"]) }.first

      require "json"
      parsed = JSON.parse(output)

      assert parsed.key?("task_activity")
      assert_equal 1, parsed["task_activity"]["recently_done"].length
      assert_equal "Done task", parsed["task_activity"]["recently_done"].first["title"]
    end
  end

  def test_status_command_with_cli_overrides
    # Track what options are passed to the loader
    options_received = nil
    mock_context = {
      task: nil,
      release: { name: "v.0.9.0" },
      task_activity: { recently_done: [], in_progress: [], up_next: [] }
    }

    loader_mock = lambda do |options|
      options_received = options
      mock_context
    end

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, loader_mock do
      capture_io do
        @command.execute([
          "--recently-done-limit", "5",
          "--up-next-limit", "10",
          "--include-drafts"
        ])
      end
    end

    assert_equal 5, options_received[:recently_done_limit]
    assert_equal 10, options_received[:up_next_limit]
    assert_equal true, options_received[:include_drafts]
  end

  # --- Zero-limit display tests ---

  def test_status_command_hides_recently_done_section_when_limit_zero
    mock_context = {
      task: nil,
      release: { name: "v.0.9.0", done_tasks: 5, total_tasks: 10 },
      task_activity: {
        recently_done: [{ id: "v.0.9.0+task.001", title: "Should not appear" }],
        in_progress: [],
        up_next: []
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute(["--recently-done-limit", "0"]) }.first

      # Recently Done section should be completely absent (not even "No recently...")
      refute_includes output, "Recently Done"
      refute_includes output, "Should not appear"
      # In Progress and Up Next should still show
      assert_includes output, "In Progress"
      assert_includes output, "Up Next"
    end
  end

  def test_status_command_hides_up_next_section_when_limit_zero
    mock_context = {
      task: nil,
      release: { name: "v.0.9.0", done_tasks: 5, total_tasks: 10 },
      task_activity: {
        recently_done: [],
        in_progress: [],
        up_next: [{ id: "v.0.9.0+task.001", title: "Should not appear" }]
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute(["--up-next-limit", "0"]) }.first

      # Up Next section should be completely absent
      refute_includes output, "Up Next"
      refute_includes output, "Should not appear"
      # Recently Done and In Progress should still show
      assert_includes output, "Recently Done"
      assert_includes output, "In Progress"
    end
  end

  def test_status_command_hides_both_sections_when_both_limits_zero
    mock_context = {
      task: nil,
      release: { name: "v.0.9.0", done_tasks: 5, total_tasks: 10 },
      task_activity: {
        recently_done: [{ id: "v.0.9.0+task.001", title: "Done task" }],
        in_progress: [{ id: "v.0.9.0+task.002", title: "Working" }],
        up_next: [{ id: "v.0.9.0+task.003", title: "Next task" }]
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io do
        @command.execute(["--recently-done-limit", "0", "--up-next-limit", "0"])
      end.first

      # Both sections should be absent
      refute_includes output, "Recently Done"
      refute_includes output, "Up Next"
      # In Progress should still show (no limit for that)
      assert_includes output, "In Progress"
      assert_includes output, "Working"
    end
  end

  # --- --no-include-activity flag tests ---

  def test_status_command_hides_activity_section_with_no_include_activity_flag
    mock_context = {
      task: nil,
      release: { name: "v.0.9.0", done_tasks: 5, total_tasks: 10 },
      task_activity: {
        recently_done: [{ id: "v.0.9.0+task.001", title: "Done task" }],
        in_progress: [{ id: "v.0.9.0+task.002", title: "Working" }],
        up_next: [{ id: "v.0.9.0+task.003", title: "Next task" }]
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute(["--no-include-activity"]) }.first

      # Entire activity section should be absent
      refute_includes output, "Task Activity"
      refute_includes output, "Recently Done"
      refute_includes output, "In Progress"
      refute_includes output, "Up Next"

      # Release should still show
      assert_includes output, "v.0.9.0"
    end
  end

  def test_status_command_json_excludes_activity_with_no_include_activity_flag
    mock_context = {
      task: nil,
      release: { name: "v.0.9.0" },
      task_activity: {
        recently_done: [{ id: "v.0.9.0+task.001", title: "Done task" }],
        in_progress: [],
        up_next: []
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute(["--json", "--no-include-activity"]) }.first

      require "json"
      parsed = JSON.parse(output)

      # task_activity key should not be present
      refute parsed.key?("task_activity")
      # Other keys should still be present
      assert parsed.key?("release")
    end
  end

  def test_status_command_includes_activity_by_default
    mock_context = {
      task: nil,
      release: { name: "v.0.9.0", done_tasks: 5, total_tasks: 10 },
      task_activity: {
        recently_done: [{ id: "v.0.9.0+task.001", title: "Done task" }],
        in_progress: [],
        up_next: []
      }
    }

    Ace::Taskflow::Organisms::TaskflowContextLoader.stub :load, mock_context do
      output = capture_io { @command.execute([]) }.first

      # Activity section should be present by default
      assert_includes output, "Task Activity"
      assert_includes output, "Recently Done"
    end
  end
end
