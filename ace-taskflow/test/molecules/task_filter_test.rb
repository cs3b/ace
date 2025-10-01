# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_filter"

class TaskFilterTest < AceTaskflowTestCase
  def setup
    @filter = Ace::Taskflow::Molecules::TaskFilter
    @tasks = [
      { id: "task.001", status: "done", priority: "high", context: "v.0.9.0", dependencies: [] },
      { id: "task.002", status: "in-progress", priority: "medium", context: "v.0.9.0", dependencies: ["task.001"] },
      { id: "task.003", status: "pending", priority: "high", context: "v.0.9.0", dependencies: [] },
      { id: "task.004", status: "pending", priority: "low", context: "backlog", dependencies: [] },
      { id: "task.005", status: "blocked", priority: "medium", context: "v.0.8.0", dependencies: ["task.999"] }
    ]
  end

  def test_filter_by_status_single
    result = @filter.filter_by_status(@tasks, ["pending"])

    assert_equal 2, result.length
    assert result.all? { |t| t[:status] == "pending" }
  end

  def test_filter_by_status_multiple
    result = @filter.filter_by_status(@tasks, ["done", "in-progress"])

    assert_equal 2, result.length
    assert result.any? { |t| t[:status] == "done" }
    assert result.any? { |t| t[:status] == "in-progress" }
  end

  def test_filter_by_status_case_insensitive
    result = @filter.filter_by_status(@tasks, ["PENDING", "Done"])

    assert_equal 3, result.length
  end

  def test_filter_by_status_with_nil
    result = @filter.filter_by_status(@tasks, nil)

    assert_equal @tasks.length, result.length
  end

  def test_filter_by_priority_single
    result = @filter.filter_by_priority(@tasks, ["high"])

    assert_equal 2, result.length
    assert result.all? { |t| t[:priority] == "high" }
  end

  def test_filter_by_priority_multiple
    result = @filter.filter_by_priority(@tasks, ["high", "low"])

    assert_equal 3, result.length
  end

  def test_filter_by_context
    result = @filter.filter_by_context(@tasks, "v.0.9.0")

    assert_equal 3, result.length
    assert result.all? { |t| t[:context] == "v.0.9.0" }
  end

  def test_filter_by_context_backlog
    result = @filter.filter_by_context(@tasks, "backlog")

    assert_equal 1, result.length
    assert_equal "task.004", result.first[:id]
  end

  def test_filter_by_dependencies_with_dependencies
    result = @filter.filter_by_dependencies(@tasks, true)

    assert_equal 2, result.length
    assert result.all? { |t| !t[:dependencies].empty? }
  end

  def test_filter_by_dependencies_without_dependencies
    result = @filter.filter_by_dependencies(@tasks, false)

    assert_equal 3, result.length
    assert result.all? { |t| t[:dependencies].empty? }
  end

  def test_apply_filters_combined
    filters = {
      status: ["pending"],
      priority: ["high"]
    }
    result = @filter.apply_filters(@tasks, filters)

    assert_equal 1, result.length
    assert_equal "task.003", result.first[:id]
  end

  def test_apply_filters_with_context
    filters = {
      context: "v.0.9.0",
      status: ["pending", "in-progress"]
    }
    result = @filter.apply_filters(@tasks, filters)

    assert_equal 2, result.length
  end

  def test_apply_filters_with_empty_filters
    result = @filter.apply_filters(@tasks, {})

    assert_equal @tasks.length, result.length
  end

  def test_sort_tasks_by_priority
    result = @filter.sort_tasks(@tasks, :priority, true, false)

    assert_equal "high", result.first[:priority]
    assert_equal "low", result.last[:priority]
  end

  def test_sort_tasks_by_status
    result = @filter.sort_tasks(@tasks, :status, true, false)

    assert_equal "done", result.first[:status]
  end

  def test_sort_tasks_by_id
    result = @filter.sort_tasks(@tasks, :id, true, false)

    assert_equal "task.001", result.first[:id]
    assert_equal "task.005", result.last[:id]
  end

  def test_sort_tasks_descending
    result = @filter.sort_tasks(@tasks, :id, false, false)

    assert_equal "task.005", result.first[:id]
    assert_equal "task.001", result.last[:id]
  end

  def test_sort_tasks_by_context
    result = @filter.sort_tasks(@tasks, :context, true, false)

    # Should sort alphabetically: backlog, v.0.8.0, v.0.9.0
    contexts = result.map { |t| t[:context] }
    assert_equal "backlog", contexts.first
  end

  def test_matches_filter_string_with_field_value
    task = @tasks.first

    assert @filter.matches_filter_string?(task, "status:done")
    refute @filter.matches_filter_string?(task, "status:pending")
  end

  def test_matches_filter_string_with_negation
    task = @tasks.first

    assert @filter.matches_filter_string?(task, "status:!pending")
    refute @filter.matches_filter_string?(task, "status:!done")
  end

  def test_matches_filter_string_with_text_search
    task = { id: "task.001", title: "Implement dark mode", content: "Add dark theme" }

    assert @filter.matches_filter_string?(task, "dark")
    assert @filter.matches_filter_string?(task, "mode")
    refute @filter.matches_filter_string?(task, "light")
  end

  def test_matches_filter_string_case_insensitive
    task = { id: "task.001", title: "Implement Dark Mode" }

    assert @filter.matches_filter_string?(task, "dark")
    assert @filter.matches_filter_string?(task, "DARK")
  end

  def test_matches_filter_string_has_dependencies
    task_with_deps = @tasks[1]
    task_no_deps = @tasks[0]

    assert @filter.matches_filter_string?(task_with_deps, "has_dependencies:true")
    refute @filter.matches_filter_string?(task_no_deps, "has_dependencies:true")
  end

  def test_sort_tasks_by_sort_field_with_in_progress_priority
    tasks_with_sort = [
      { id: "task.001", status: "pending", sort: 300 },
      { id: "task.002", status: "in-progress", sort: 500 },
      { id: "task.003", status: "pending", sort: 100 }
    ]

    result = @filter.sort_tasks(tasks_with_sort, :sort, true, false)

    # in-progress should come first regardless of sort value
    assert_equal "task.002", result.first[:id]
    # Then sorted by sort value
    assert_equal "task.003", result[1][:id]
    assert_equal "task.001", result[2][:id]
  end
end
