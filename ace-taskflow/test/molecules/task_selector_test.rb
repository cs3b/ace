# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_selector"

class TaskSelectorTest < Minitest::Test
  def test_select_next_returns_nil_for_empty_list
    assert_nil Ace::Taskflow::Molecules::TaskSelector.select_next([])
  end

  def test_select_next_returns_nil_for_nil_input
    assert_nil Ace::Taskflow::Molecules::TaskSelector.select_next(nil)
  end

  def test_select_next_prioritizes_in_progress_over_pending
    tasks = [
      { id: "task.001", status: "pending", sort: 1 },
      { id: "task.002", status: "in-progress", sort: 2 }
    ]

    result = Ace::Taskflow::Molecules::TaskSelector.select_next(tasks)

    assert_equal "task.002", result[:id]
  end

  def test_select_next_returns_first_in_progress_when_multiple
    tasks = [
      { id: "task.001", status: "in-progress" },
      { id: "task.002", status: "in-progress" },
      { id: "task.003", status: "pending" }
    ]

    result = Ace::Taskflow::Molecules::TaskSelector.select_next(tasks)

    assert_equal "task.001", result[:id]
  end

  def test_select_next_sorts_pending_by_sort_value
    tasks = [
      { id: "task.001", status: "pending", sort: 100 },
      { id: "task.002", status: "pending", sort: 50 },
      { id: "task.003", status: "pending", sort: 75 }
    ]

    result = Ace::Taskflow::Molecules::TaskSelector.select_next(tasks)

    assert_equal "task.002", result[:id]
  end

  def test_select_next_prioritizes_tasks_with_sort_over_without
    tasks = [
      { id: "task.001", status: "pending", sort: nil },
      { id: "task.002", status: "pending", sort: 100 }
    ]

    result = Ace::Taskflow::Molecules::TaskSelector.select_next(tasks)

    assert_equal "task.002", result[:id]
  end

  def test_select_next_sorts_by_task_number_when_no_sort
    tasks = [
      { id: "v.0.9.0+task.005", status: "pending" },
      { id: "v.0.9.0+task.002", status: "pending" },
      { id: "v.0.9.0+task.008", status: "pending" }
    ]

    result = Ace::Taskflow::Molecules::TaskSelector.select_next(tasks)

    assert_equal "v.0.9.0+task.002", result[:id]
  end

  def test_select_next_ignores_done_tasks
    tasks = [
      { id: "task.001", status: "done" },
      { id: "task.002", status: "pending" }
    ]

    result = Ace::Taskflow::Molecules::TaskSelector.select_next(tasks)

    assert_equal "task.002", result[:id]
  end

  def test_select_next_ignores_blocked_tasks
    tasks = [
      { id: "task.001", status: "blocked" },
      { id: "task.002", status: "pending" }
    ]

    result = Ace::Taskflow::Molecules::TaskSelector.select_next(tasks)

    assert_equal "task.002", result[:id]
  end

  def test_select_next_returns_nil_when_only_done_and_blocked
    tasks = [
      { id: "task.001", status: "done" },
      { id: "task.002", status: "blocked" }
    ]

    result = Ace::Taskflow::Molecules::TaskSelector.select_next(tasks)

    assert_nil result
  end

  def test_extract_task_number_from_full_id
    assert_equal 42, Ace::Taskflow::Molecules::TaskSelector.extract_task_number("v.0.9.0+task.042")
  end

  def test_extract_task_number_from_simple_id
    assert_equal 7, Ace::Taskflow::Molecules::TaskSelector.extract_task_number("task.007")
  end

  def test_extract_task_number_returns_max_for_invalid
    # "invalid".to_i returns 0, not 999999
    assert_equal 0, Ace::Taskflow::Molecules::TaskSelector.extract_task_number("invalid")
  end

  def test_extract_task_number_handles_nil
    assert_equal 999999, Ace::Taskflow::Molecules::TaskSelector.extract_task_number(nil)
  end
end
