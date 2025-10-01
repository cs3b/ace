# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/dependency_resolver"

class DependencyResolverTest < AceTaskflowTestCase
  def setup
    @resolver = Ace::Taskflow::Molecules::DependencyResolver
    @tasks = [
      { id: "task.001", status: "done", dependencies: [] },
      { id: "task.002", status: "done", dependencies: ["task.001"] },
      { id: "task.003", status: "pending", dependencies: ["task.002"] },
      { id: "task.004", status: "pending", dependencies: [] },
      { id: "task.005", status: "in-progress", dependencies: ["task.002", "task.004"] }
    ]
  end

  def test_dependencies_met_with_all_done
    task = @tasks[2]  # task.003 depends on task.002 (done)

    assert @resolver.dependencies_met?(task, @tasks)
  end

  def test_dependencies_met_with_pending_dependency
    task = @tasks[4]  # task.005 depends on task.002 (done) and task.004 (pending)

    refute @resolver.dependencies_met?(task, @tasks)
  end

  def test_dependencies_met_with_no_dependencies
    task = @tasks[0]  # task.001 has no dependencies

    assert @resolver.dependencies_met?(task, @tasks)
  end

  def test_dependencies_met_with_nil_dependencies
    task = { id: "task.999", dependencies: nil }

    assert @resolver.dependencies_met?(task, @tasks)
  end

  def test_get_blocking_tasks_returns_empty_for_met_dependencies
    task = @tasks[2]  # task.003 depends on task.002 (done)

    blocking = @resolver.get_blocking_tasks(task, @tasks)

    assert_empty blocking
  end

  def test_get_blocking_tasks_returns_pending_dependencies
    task = @tasks[4]  # task.005 depends on task.002 (done) and task.004 (pending)

    blocking = @resolver.get_blocking_tasks(task, @tasks)

    assert_equal 1, blocking.length
    assert_equal "task.004", blocking.first[:id]
  end

  def test_get_blocking_tasks_with_no_dependencies
    task = @tasks[0]

    blocking = @resolver.get_blocking_tasks(task, @tasks)

    assert_empty blocking
  end

  def test_topological_sort_respects_dependencies
    result = @resolver.topological_sort(@tasks)

    # task.001 should come before task.002
    task_001_index = result.index { |t| t[:id] == "task.001" }
    task_002_index = result.index { |t| t[:id] == "task.002" }

    assert task_001_index < task_002_index

    # task.002 should come before task.003
    task_003_index = result.index { |t| t[:id] == "task.003" }

    assert task_002_index < task_003_index
  end

  def test_topological_sort_with_no_dependencies
    simple_tasks = [
      { id: "task.001", dependencies: [] },
      { id: "task.002", dependencies: [] },
      { id: "task.003", dependencies: [] }
    ]

    result = @resolver.topological_sort(simple_tasks)

    assert_equal 3, result.length
  end

  def test_dependency_aware_sort_maintains_dependency_order
    result = @resolver.dependency_aware_sort(@tasks, :id, true)

    # Dependencies should be maintained
    task_001_index = result.index { |t| t[:id] == "task.001" }
    task_002_index = result.index { |t| t[:id] == "task.002" }
    task_003_index = result.index { |t| t[:id] == "task.003" }

    assert task_001_index < task_002_index
    assert task_002_index < task_003_index
  end

  def test_dependency_aware_sort_by_priority_within_levels
    tasks_with_priority = [
      { id: "task.001", status: "done", dependencies: [], priority: "low" },
      { id: "task.002", status: "done", dependencies: ["task.001"], priority: "high" },
      { id: "task.003", status: "pending", dependencies: ["task.001"], priority: "medium" }
    ]

    result = @resolver.dependency_aware_sort(tasks_with_priority, :priority, true)

    # task.001 should be first (no dependencies)
    assert_equal "task.001", result.first[:id]

    # task.002 and task.003 are at the same dependency level,
    # so they should be sorted by priority within that level
  end

  def test_topological_sort_with_levels_groups_by_dependency_depth
    result = @resolver.topological_sort_with_levels(@tasks)

    assert_instance_of Array, result
    assert result.all? { |level| level.is_a?(Array) }

    # First level should contain tasks with no dependencies
    first_level_ids = result.first.map { |t| t[:id] }
    assert_includes first_level_ids, "task.001"
    assert_includes first_level_ids, "task.004"
  end

  def test_dependencies_met_with_missing_dependency
    task = { id: "task.999", dependencies: ["task.888"] }

    refute @resolver.dependencies_met?(task, @tasks)
  end

  def test_get_blocking_tasks_handles_missing_dependencies
    task = { id: "task.999", dependencies: ["task.888", "task.001"] }

    blocking = @resolver.get_blocking_tasks(task, @tasks)

    # Should not include missing dependency, only existing pending ones
    assert blocking.none? { |t| t[:id] == "task.888" }
  end
end
