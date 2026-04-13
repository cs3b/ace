# frozen_string_literal: true

require "test_helper"

class TaskModelTest < AceTaskTestCase
  def test_shortcut_returns_last_three_chars
    task = build_task(id: "8pp.t.q7w")
    assert_equal "q7w", task.shortcut
  end

  def test_shortcut_returns_nil_when_no_id
    task = build_task(id: nil)
    assert_nil task.shortcut
  end

  def test_subtask_returns_true_when_parent_id_set
    task = build_task(parent_id: "8pp.t.q7w")
    assert task.subtask?
  end

  def test_subtask_returns_false_when_no_parent_id
    task = build_task(parent_id: nil)
    refute task.subtask?
  end

  def test_has_subtasks_returns_true_when_subtasks_present
    subtask = build_task(id: "8pp.t.q7w.a")
    task = build_task(subtasks: [subtask])
    assert task.has_subtasks?
  end

  def test_has_subtasks_returns_false_when_empty
    task = build_task(subtasks: [])
    refute task.has_subtasks?
  end

  def test_has_subtasks_returns_false_when_nil
    task = build_task(subtasks: nil)
    refute task.has_subtasks?
  end

  def test_to_s_shows_id_and_title
    task = build_task(id: "8pp.t.q7w", title: "Fix login bug")
    assert_equal "Task(8pp.t.q7w: Fix login bug)", task.to_s
  end

  def test_all_fields_initialized
    task = Ace::Task::Models::Task.new(
      id: "8pp.t.q7w",
      status: "pending",
      title: "Test",
      priority: "high",
      estimate: "2h",
      dependencies: ["8pp.t.abc"],
      tags: ["auth"],
      content: "# Test",
      path: "/tmp/test",
      file_path: "/tmp/test/spec.s.md",
      special_folder: nil,
      created_at: Time.utc(2026, 1, 15),
      subtasks: [],
      parent_id: nil,
      metadata: {}
    )

    assert_equal "8pp.t.q7w", task.id
    assert_equal "high", task.priority
    assert_equal "2h", task.estimate
    assert_equal ["8pp.t.abc"], task.dependencies
    assert_equal ["auth"], task.tags
    assert_equal [], task.subtasks
    assert_nil task.parent_id
  end

  private

  def build_task(**overrides)
    defaults = {
      id: "8pp.t.q7w",
      status: "pending",
      title: "Test task",
      priority: "medium",
      estimate: nil,
      dependencies: [],
      tags: [],
      content: "# Test",
      path: "/tmp/test",
      file_path: "/tmp/test/spec.s.md",
      special_folder: nil,
      created_at: nil,
      subtasks: [],
      parent_id: nil,
      metadata: {}
    }
    Ace::Task::Models::Task.new(**defaults.merge(overrides))
  end
end
