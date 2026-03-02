# frozen_string_literal: true

require "test_helper"

class TaskDisplayFormatterTest < AceTaskTestCase
  def build_task(**overrides)
    defaults = {
      id: "8pp.t.q7w",
      status: "pending",
      title: "Fix login bug",
      priority: "medium",
      estimate: nil,
      dependencies: [],
      tags: [],
      content: "",
      path: "/tmp/tasks/8pp.t.q7w-fix-login-bug",
      file_path: "/tmp/tasks/8pp.t.q7w-fix-login-bug/8pp.t.q7w-fix-login-bug.s.md",
      special_folder: nil,
      created_at: Time.utc(2026, 1, 15),
      subtasks: [],
      parent_id: nil,
      metadata: {}
    }
    Ace::Task::Models::Task.new(**defaults.merge(overrides))
  end

  # --- format (show) ---

  def test_format_shows_status_symbol_and_id_and_title
    task = build_task
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "○ "
    assert_includes output, "8pp.t.q7w"
    assert_includes output, "Fix login bug"
  end

  def test_format_shows_done_status_symbol
    task = build_task(status: "done")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "✓ "
  end

  def test_format_shows_in_progress_status_symbol
    task = build_task(status: "in-progress")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "▶ "
  end

  def test_format_shows_priority_symbol_for_high
    task = build_task(priority: "high")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "! "
  end

  def test_format_shows_priority_symbol_for_critical
    task = build_task(priority: "critical")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "‼ "
  end

  def test_format_shows_metadata_line
    task = build_task(priority: "high", estimate: "2h")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "status: pending"
    assert_includes output, "priority: high"
    assert_includes output, "estimate: 2h"
  end

  def test_format_shows_tags
    task = build_task(tags: ["auth", "security"])
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "tags: auth, security"
  end

  def test_format_shows_dependencies
    task = build_task(dependencies: ["8pp.t.abc", "8pp.t.def"])
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "depends: 8pp.t.abc, 8pp.t.def"
  end

  def test_format_shows_special_folder
    task = build_task(special_folder: "_maybe")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "folder: _maybe"
  end

  def test_format_shows_parent_id_for_subtask
    task = build_task(parent_id: "8pp.t.q7w")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "parent: 8pp.t.q7w"
  end

  def test_format_shows_subtasks
    subtask = build_task(id: "8pp.t.q7w.a", title: "Setup DB", status: "done")
    task = build_task(subtasks: [subtask])
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "Subtasks:"
    assert_includes output, "✓ 8pp.t.q7w.a  Setup DB"
  end

  def test_format_shows_content_when_requested
    task = build_task(content: "## Details\n\nSome important info")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task, show_content: true)

    assert_includes output, "## Details"
    assert_includes output, "Some important info"
  end

  def test_format_hides_content_by_default
    task = build_task(content: "## Details\n\nSome important info")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    refute_includes output, "## Details"
  end

  def test_format_omits_empty_optional_fields
    task = build_task(tags: [], dependencies: [], special_folder: nil, parent_id: nil, subtasks: [])
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    refute_includes output, "tags:"
    refute_includes output, "depends:"
    refute_includes output, "folder:"
    refute_includes output, "parent:"
    refute_includes output, "Subtasks:"
  end

  # --- format_list ---

  def test_format_list_shows_compact_items
    tasks = [
      build_task(id: "8pp.t.q7w", title: "First task", status: "done"),
      build_task(id: "8pp.t.abc", title: "Second task", status: "pending")
    ]
    output = Ace::Task::Molecules::TaskDisplayFormatter.format_list(tasks)

    assert_includes output, "✓ "
    assert_includes output, "8pp.t.q7w"
    assert_includes output, "First task"
    assert_includes output, "○ "
    assert_includes output, "8pp.t.abc"
    assert_includes output, "Second task"
  end

  def test_format_list_returns_message_for_empty_list
    output = Ace::Task::Molecules::TaskDisplayFormatter.format_list([])

    assert_equal "No tasks found.", output
  end

  def test_format_list_shows_tags_inline
    tasks = [build_task(tags: ["api", "urgent"])]
    output = Ace::Task::Molecules::TaskDisplayFormatter.format_list(tasks)

    assert_includes output, "[api, urgent]"
  end

  def test_format_list_shows_special_folder
    tasks = [build_task(special_folder: "_backlog")]
    output = Ace::Task::Molecules::TaskDisplayFormatter.format_list(tasks)

    assert_includes output, "(_backlog)"
  end

  def test_format_list_shows_subtask_count
    subtask = build_task(id: "8pp.t.q7w.a", title: "Sub")
    tasks = [build_task(subtasks: [subtask])]
    output = Ace::Task::Molecules::TaskDisplayFormatter.format_list(tasks)

    assert_includes output, "+1"
  end

  def test_format_unknown_status_defaults_to_circle
    task = build_task(status: "unknown-status")
    output = Ace::Task::Molecules::TaskDisplayFormatter.format(task)

    assert_includes output, "○ "
  end

  # --- format_list stats line ---

  def test_format_list_includes_stats_line
    tasks = [
      build_task(id: "8pp.t.q7w", title: "First", status: "pending"),
      build_task(id: "8pp.t.abc", title: "Second", status: "done"),
      build_task(id: "8pp.t.def", title: "Third", status: "done")
    ]
    output = Ace::Task::Molecules::TaskDisplayFormatter.format_list(tasks)

    assert_includes output, "Tasks: ○ 1 | ✓ 2 • 3 total • 67% complete"
  end

  def test_format_list_stats_line_omits_zero_counts
    tasks = [
      build_task(status: "pending"),
      build_task(status: "pending")
    ]
    output = Ace::Task::Molecules::TaskDisplayFormatter.format_list(tasks)

    assert_includes output, "Tasks: ○ 2 • 2 total"
    refute_includes output, "▶"
    refute_includes output, "✓ 0"
  end

  def test_format_list_stats_line_separated_by_blank_line
    tasks = [build_task(status: "pending")]
    output = Ace::Task::Molecules::TaskDisplayFormatter.format_list(tasks)

    assert_match(/\n\nTasks:/, output)
  end

  # --- format_stats_line ---

  def test_format_stats_line
    tasks = [
      build_task(status: "pending"),
      build_task(status: "in-progress"),
      build_task(status: "done"),
      build_task(status: "done"),
      build_task(status: "done")
    ]
    line = Ace::Task::Molecules::TaskDisplayFormatter.format_stats_line(tasks)

    assert_equal "Tasks: ○ 1 | ▶ 1 | ✓ 3 • 5 total • 60% complete", line
  end
end
