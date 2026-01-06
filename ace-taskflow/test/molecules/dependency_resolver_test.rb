# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/dependency_resolver"
require "tmpdir"

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

  def test_apply_standard_sort_by_modified_ascending
    # Use fixed times to prevent test flakiness from timing variations
    base_time = Time.new(2026, 1, 6, 12, 0, 0)
    tasks = [
      { id: "task.003", modified: base_time - 3600 },  # 1 hour ago
      { id: "task.001", modified: base_time - 7200 },  # 2 hours ago
      { id: "task.002", modified: base_time }           # Base time (newest)
    ]

    result = @resolver.send(:apply_standard_sort, tasks, :modified, true)

    # Ascending order: oldest to newest
    assert_equal "task.001", result[0][:id]
    assert_equal "task.003", result[1][:id]
    assert_equal "task.002", result[2][:id]
  end

  def test_apply_standard_sort_by_modified_descending
    # Use fixed times to prevent test flakiness from timing variations
    base_time = Time.new(2026, 1, 6, 12, 0, 0)
    tasks = [
      { id: "task.003", modified: base_time - 3600 },  # 1 hour ago
      { id: "task.001", modified: base_time - 7200 },  # 2 hours ago
      { id: "task.002", modified: base_time }           # Base time (newest)
    ]

    result = @resolver.send(:apply_standard_sort, tasks, :modified, false)

    # Descending order: newest to oldest
    assert_equal "task.002", result[0][:id]
    assert_equal "task.003", result[1][:id]
    assert_equal "task.001", result[2][:id]
  end

  def test_apply_standard_sort_by_modified_with_nil_modified
    # Use fixed times to prevent test flakiness from timing variations
    base_time = Time.new(2026, 1, 6, 12, 0, 0)
    tasks = [
      { id: "task.003", modified: base_time - 3600 },
      { id: "task.001", modified: nil },              # No modified time
      { id: "task.002", modified: base_time }
    ]

    result = @resolver.send(:apply_standard_sort, tasks, :modified, false)

    # Tasks with nil modified should come last (treated as DEFAULT_MODIFIED_TIME)
    assert_equal "task.002", result[0][:id]
    assert_equal "task.003", result[1][:id]
    assert_equal "task.001", result[2][:id]
  end

  def test_apply_standard_sort_by_modified_with_path_fallback
    # Test that tasks with :path but no :modified key use File.mtime as fallback
    Dir.mktmpdir do |tmpdir|
      # Create test files with different modification times
      file1 = File.join(tmpdir, "task.001.md")
      file2 = File.join(tmpdir, "task.002.md")
      file3 = File.join(tmpdir, "task.003.md")

      File.write(file1, "task 1")
      File.write(file2, "task 2")
      File.write(file3, "task 3")

      # Set specific mtimes (file1 oldest, file3 newest)
      base_time = Time.new(2026, 1, 6, 12, 0, 0)
      File.utime(base_time - 7200, base_time - 7200, file1)  # 2 hours ago
      File.utime(base_time - 3600, base_time - 3600, file2)  # 1 hour ago
      File.utime(base_time, base_time, file3)                 # Base time

      tasks = [
        { id: "task.002", path: file2 },  # No :modified key, has :path
        { id: "task.001", path: file1 },  # No :modified key, has :path
        { id: "task.003", path: file3 }   # No :modified key, has :path
      ]

      result = @resolver.send(:apply_standard_sort, tasks, :modified, false)

      # Descending order: newest to oldest (based on file mtime)
      assert_equal "task.003", result[0][:id]
      assert_equal "task.002", result[1][:id]
      assert_equal "task.001", result[2][:id]
    end
  end

  def test_apply_standard_sort_by_modified_with_missing_path
    # Tasks with :path pointing to non-existent files should use DEFAULT_MODIFIED_TIME
    base_time = Time.new(2026, 1, 6, 12, 0, 0)
    tasks = [
      { id: "task.002", modified: base_time },
      { id: "task.001", path: "/nonexistent/path/task.001.md" },  # Missing file
      { id: "task.003", modified: base_time - 3600 }
    ]

    result = @resolver.send(:apply_standard_sort, tasks, :modified, false)

    # task.001 with missing file should come last (DEFAULT_MODIFIED_TIME = Time.at(0))
    assert_equal "task.002", result[0][:id]
    assert_equal "task.003", result[1][:id]
    assert_equal "task.001", result[2][:id]
  end

  def test_dependency_aware_sort_by_modified_within_levels
    # Use fixed times to prevent test flakiness from timing variations
    base_time = Time.new(2026, 1, 6, 12, 0, 0)
    tasks_with_dependencies = [
      { id: "task.001", status: "done", dependencies: [], modified: base_time - 7200 },
      { id: "task.002", status: "done", dependencies: ["task.001"], modified: base_time - 3600 },
      { id: "task.003", status: "done", dependencies: ["task.001"], modified: base_time }
    ]

    result = @resolver.dependency_aware_sort(tasks_with_dependencies, :modified, false)

    # task.001 should be first (no dependencies)
    assert_equal "task.001", result[0][:id]

    # task.002 and task.003 are at same dependency level, sorted by modified (newest first)
    task_002_index = result.index { |t| t[:id] == "task.002" }
    task_003_index = result.index { |t| t[:id] == "task.003" }

    assert task_003_index < task_002_index, "task.003 (newer) should come before task.002"
  end
end
