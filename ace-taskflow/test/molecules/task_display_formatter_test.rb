# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_display_formatter"

class TaskDisplayFormatterTest < Minitest::Test
  def test_status_icon_for_draft
    assert_equal "⚫", Ace::Taskflow::Molecules::TaskDisplayFormatter.status_icon("draft")
  end

  def test_status_icon_for_pending
    assert_equal "⚪", Ace::Taskflow::Molecules::TaskDisplayFormatter.status_icon("pending")
  end

  def test_status_icon_for_in_progress
    assert_equal "🟡", Ace::Taskflow::Molecules::TaskDisplayFormatter.status_icon("in-progress")
  end

  def test_status_icon_for_done
    assert_equal "🟢", Ace::Taskflow::Molecules::TaskDisplayFormatter.status_icon("done")
  end

  def test_status_icon_for_blocked
    assert_equal "🔴", Ace::Taskflow::Molecules::TaskDisplayFormatter.status_icon("blocked")
  end

  def test_status_icon_for_skipped
    assert_equal "🔴", Ace::Taskflow::Molecules::TaskDisplayFormatter.status_icon("skipped")
  end

  def test_status_icon_for_unknown
    assert_equal "?", Ace::Taskflow::Molecules::TaskDisplayFormatter.status_icon("unknown")
  end

  def test_status_icon_handles_uppercase
    assert_equal "⚪", Ace::Taskflow::Molecules::TaskDisplayFormatter.status_icon("PENDING")
  end

  def test_format_task_line_with_full_data
    task = {
      id: "v.0.9.0+task.001",
      qualified_reference: "v.0.9.0+task.001",
      task_number: "001",
      status: "pending",
      title: "Implement feature X"
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_task_line(task)

    assert_includes result, "v.0.9.0+task.001"
    assert_includes result, "⚪"
    assert_includes result, "Implement feature X"
  end

  def test_format_task_line_with_minimal_data
    task = {
      id: "task.001",
      status: "done"
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_task_line(task)

    assert_includes result, "task.001"
    assert_includes result, "🟢"
    assert_includes result, "Untitled"
  end

  def test_format_task_details_with_estimate_only
    task = {
      estimate: "4h",
      dependencies: []
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_task_details(task)

    assert_includes result, "Estimate: 4h"
    refute_includes result, "Dependencies"
  end

  def test_format_task_details_with_dependencies_only
    task = {
      estimate: "TBD",
      dependencies: ["task.001", "task.002"]
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_task_details(task)

    assert_includes result, "Dependencies: task.001, task.002"
    refute_includes result, "Estimate"
  end

  def test_format_task_details_with_both
    task = {
      estimate: "2h",
      dependencies: ["task.001"]
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_task_details(task)

    assert_includes result, "Estimate: 2h"
    assert_includes result, "Dependencies: task.001"
    assert_includes result, "|"  # Separator
  end

  def test_format_task_details_returns_nil_when_no_details
    task = {
      estimate: "TBD",
      dependencies: []
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_task_details(task)

    assert_nil result
  end

  def test_format_list_item
    task = {
      task_number: "001",
      id: "v.0.9.0+task.001",
      title: "My Task"
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_list_item(task)

    assert_equal "001 My Task", result
  end

  def test_format_list_item_uses_id_fallback
    task = {
      id: "task.001",
      title: "My Task"
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_list_item(task)

    assert_equal "task.001 My Task", result
  end

  def test_group_by_context
    tasks = [
      { id: "task.001", context: "v.0.9.0" },
      { id: "task.002", context: "v.0.9.0" },
      { id: "task.003", context: "backlog" }
    ]

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.group_by_context(tasks)

    assert_equal 2, result["v.0.9.0"].length
    assert_equal 1, result["backlog"].length
  end

  def test_group_by_context_handles_missing_context
    tasks = [
      { id: "task.001" },
      { id: "task.002", context: "v.0.9.0" }
    ]

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.group_by_context(tasks)

    assert_equal 1, result["unknown"].length
    assert_equal 1, result["v.0.9.0"].length
  end

  def test_format_grouped_with_line_formatter
    grouped = {
      "v.0.9.0" => [
        { id: "task.001", status: "pending", title: "Task 1" }
      ]
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_grouped(grouped, :line)

    assert_includes result, "v.0.9.0:"
    assert_includes result, "task.001"
    assert_includes result, "⚪"
  end

  def test_format_grouped_with_list_formatter
    grouped = {
      "backlog" => [
        { task_number: "001", id: "backlog+task.001", title: "Task 1" }
      ]
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_grouped(grouped, :list)

    assert_includes result, "backlog:"
    assert_includes result, "001 Task 1"
  end

  def test_format_full_task_with_complete_data
    task = {
      id: "v.0.9.0+task.001",
      task_number: "001",
      title: "Implement feature",
      status: "in-progress",
      priority: "high",
      estimate: "4h",
      dependencies: ["task.002", "task.003"],
      path: "/path/to/task.md",
      content: "# Task Content\n\nDetails here"
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_full_task(task)

    assert_includes result, "Task: v.0.9.0+task.001"
    assert_includes result, "Title: Implement feature"
    assert_includes result, "Status: 🟡 in-progress"
    assert_includes result, "Priority: high"
    assert_includes result, "Estimate: 4h"
    assert_includes result, "Dependencies: task.002, task.003"
    assert_includes result, "Path: /path/to/task.md"
    assert_includes result, "--- Content ---"
    assert_includes result, "# Task Content"
  end

  def test_format_full_task_with_minimal_data
    task = {
      task_number: "001",
      title: "Simple task",
      status: "pending",
      priority: "normal"
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_full_task(task)

    assert_includes result, "Task: 001"
    assert_includes result, "Title: Simple task"
    assert_includes result, "Estimate: TBD"
    refute_includes result, "Dependencies:"
    refute_includes result, "Path:"
  end

  def test_format_full_task_without_dependencies
    task = {
      id: "task.001",
      title: "Solo task",
      status: "done",
      priority: "low",
      dependencies: []
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_full_task(task)

    refute_includes result, "Dependencies:"
  end

  def test_format_task_path_with_path
    task = { path: "/Users/test/project/.ace-taskflow/v.0.9.0/t/001/task.md" }
    root = "/Users/test/project"

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_task_path(task, root)

    assert_includes result, ".ace-taskflow"
    assert_includes result, "task.md"
  end

  def test_format_task_path_without_path
    task = {}

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_task_path(task)

    assert_equal "# Task has no path", result
  end

  def test_format_confirmation_with_started_action
    message = "Task 001 started successfully"
    action = "Started"

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_confirmation(message, action)

    assert_includes result, "Task 001 started successfully"
    assert_includes result, "Started at:"
    assert_match /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, result
  end

  def test_format_confirmation_with_completed_action
    message = "Task 042 completed"
    action = "Completed"

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_confirmation(message, action)

    assert_includes result, "Task 042 completed"
    assert_includes result, "Completed at:"
  end
end
