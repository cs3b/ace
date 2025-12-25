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

  def test_group_by_release
    tasks = [
      { id: "task.001", release: "v.0.9.0" },
      { id: "task.002", release: "v.0.9.0" },
      { id: "task.003", release: "backlog" }
    ]

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.group_by_release(tasks)

    assert_equal 2, result["v.0.9.0"].length
    assert_equal 1, result["backlog"].length
  end

  def test_group_by_release_handles_missing_context
    tasks = [
      { id: "task.001" },
      { id: "task.002", release: "v.0.9.0" }
    ]

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.group_by_release(tasks)

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

  # --- format_relative_time tests ---

  def test_format_relative_time_returns_unknown_for_nil
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(nil)

    assert_equal "unknown", result
  end

  def test_format_relative_time_returns_just_now_for_recent
    now = Time.now
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(now - 30, now)

    assert_equal "just now", result
  end

  def test_format_relative_time_returns_minutes_ago
    now = Time.now
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(now - (5 * 60), now)

    assert_equal "5m ago", result
  end

  def test_format_relative_time_boundary_at_60_seconds
    # Boundary test: exactly 60 seconds should transition from "just now" to "1m ago"
    now = Time.now
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(now - 60, now)

    assert_equal "1m ago", result
  end

  def test_format_relative_time_returns_hours_ago
    now = Time.now
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(now - (3 * 60 * 60), now)

    assert_equal "3h ago", result
  end

  def test_format_relative_time_returns_days_ago
    now = Time.now
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(now - (2 * 24 * 60 * 60), now)

    assert_equal "2d ago", result
  end

  def test_format_relative_time_returns_days_for_two_weeks
    now = Time.now
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(now - (14 * 24 * 60 * 60), now)

    assert_equal "14d ago", result
  end

  def test_format_relative_time_returns_months_ago
    now = Time.now
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(now - (60 * 24 * 60 * 60), now)

    assert_equal "2mo ago", result
  end

  def test_format_relative_time_returns_years_ago
    now = Time.now
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(now - (400 * 24 * 60 * 60), now)

    assert_equal "1y ago", result
  end

  def test_format_relative_time_returns_unknown_for_non_time_type
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time("not a time")

    assert_equal "unknown", result
  end

  def test_format_relative_time_returns_unknown_for_integer
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(12345)

    assert_equal "unknown", result
  end

  def test_format_relative_time_returns_just_now_for_future_time
    now = Time.now
    future = now + 3600 # 1 hour in the future

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_relative_time(future, now)

    assert_equal "just now", result
  end

  # --- format_activity_section tests ---

  def test_format_activity_section_returns_empty_for_nil
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_section(nil)

    assert_equal "", result
  end

  def test_format_activity_section_includes_all_sections
    activity = {
      recently_done: [],
      in_progress: [],
      up_next: []
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_section(activity)

    assert_includes result, "## Task Activity"
    assert_includes result, "### Recently Done"
    assert_includes result, "### In Progress"
    assert_includes result, "### Up Next"
  end

  def test_format_activity_section_shows_empty_messages
    activity = {
      recently_done: [],
      in_progress: [],
      up_next: []
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_section(activity)

    assert_includes result, "No recently completed tasks"
    assert_includes result, "No other tasks in progress"
    assert_includes result, "No pending tasks"
  end

  def test_format_activity_section_formats_recently_done_tasks
    activity = {
      recently_done: [
        { id: "v.0.9.0+task.140.02", title: "Update ace-taskflow" }
      ],
      in_progress: [],
      up_next: []
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_section(activity, show_time: false)

    assert_includes result, "- 140.02: Update ace-taskflow"
  end

  def test_format_activity_section_formats_in_progress_tasks
    activity = {
      recently_done: [],
      in_progress: [
        { id: "v.0.9.0+task.143", title: "Unified configuration" }
      ],
      up_next: []
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_section(activity)

    assert_includes result, "- 143: Unified configuration"
  end

  def test_format_activity_section_formats_up_next_tasks
    activity = {
      recently_done: [],
      in_progress: [],
      up_next: [
        { id: "v.0.9.0+task.140.03", title: "Update ace-review" }
      ]
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_section(activity)

    assert_includes result, "- 140.03: Update ace-review"
  end

  def test_format_activity_section_shows_worktree_indicator
    activity = {
      recently_done: [],
      in_progress: [
        { id: "v.0.9.0+task.143", title: "Config work", worktree: { branch: "143-config" } }
      ],
      up_next: []
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_section(activity)

    assert_includes result, "(@worktree)"
  end

  # --- format_activity_task_line tests ---

  def test_format_activity_task_line_basic
    task = { id: "v.0.9.0+task.140", title: "Add git context" }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_task_line(task)

    assert_equal "140: Add git context", result
  end

  def test_format_activity_task_line_with_worktree
    task = { id: "v.0.9.0+task.140", title: "Add git context", worktree: { branch: "140-git" } }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_task_line(task, show_worktree: true)

    assert_includes result, "(@worktree)"
  end

  def test_format_activity_task_line_handles_missing_title
    task = { id: "v.0.9.0+task.140" }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_task_line(task)

    assert_includes result, "Untitled"
  end

  def test_format_activity_task_line_with_completed_at
    now = Time.now
    task = {
      id: "v.0.9.0+task.140",
      title: "Completed task",
      completed_at: now - (2 * 60 * 60) # 2 hours ago
    }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.format_activity_task_line(
      task,
      show_time: true
    )

    assert_includes result, "140: Completed task"
    assert_includes result, "(done 2h ago)"
  end

  # --- extract_task_number tests ---

  def test_extract_task_number_from_full_id
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.extract_task_number("v.0.9.0+task.140.02")

    assert_equal "140.02", result
  end

  def test_extract_task_number_from_simple_id
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.extract_task_number("v.0.9.0+task.140")

    assert_equal "140", result
  end

  def test_extract_task_number_returns_nil_for_invalid
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.extract_task_number("invalid")

    assert_nil result
  end

  def test_extract_task_number_returns_nil_for_nil
    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.extract_task_number(nil)

    assert_nil result
  end

  # --- has_worktree? tests ---

  def test_has_worktree_returns_false_for_no_worktree
    task = { id: "task.001" }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.has_worktree?(task)

    refute result
  end

  def test_has_worktree_returns_true_for_worktree_hash
    task = { id: "task.001", worktree: { branch: "001-feature" } }

    result = Ace::Taskflow::Molecules::TaskDisplayFormatter.has_worktree?(task)

    assert result
  end
end
