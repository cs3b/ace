# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_activity_analyzer"
require_relative "../../lib/ace/taskflow/molecules/task_filter"

class TaskActivityAnalyzerTest < AceTaskflowTestCase
  def setup
    super
    @analyzer = Ace::Taskflow::Molecules::TaskActivityAnalyzer.new
    @filter = Ace::Taskflow::Molecules::TaskFilter
  end

  # --- categorize_activities tests ---

  def test_categorize_activities_returns_empty_result_for_nil_tasks
    result = @analyzer.categorize_activities(nil)

    assert_equal [], result[:recently_done]
    assert_equal [], result[:in_progress]
    assert_equal [], result[:up_next]
  end

  def test_categorize_activities_returns_empty_result_for_empty_tasks
    result = @analyzer.categorize_activities([])

    assert_equal [], result[:recently_done]
    assert_equal [], result[:in_progress]
    assert_equal [], result[:up_next]
  end

  def test_categorize_activities_returns_all_three_categories
    with_temp_task_files do |tasks|
      result = @analyzer.categorize_activities(tasks)

      assert_includes result.keys, :recently_done
      assert_includes result.keys, :in_progress
      assert_includes result.keys, :up_next
    end
  end

  def test_categorize_activities_excludes_current_task_from_in_progress
    tasks = [
      make_task(id: "v.0.9.0+task.001", status: "in-progress"),
      make_task(id: "v.0.9.0+task.002", status: "in-progress")
    ]

    result = @analyzer.categorize_activities(tasks, current_task_id: "v.0.9.0+task.001")

    assert_equal 1, result[:in_progress].length
    assert_equal "v.0.9.0+task.002", result[:in_progress].first[:id]
  end

  def test_categorize_activities_respects_recently_done_limit
    with_temp_task_files(count: 5, status: "done") do |tasks|
      result = @analyzer.categorize_activities(tasks, recently_done_limit: 2)

      assert_equal 2, result[:recently_done].length
    end
  end

  def test_categorize_activities_respects_up_next_limit
    tasks = (1..5).map do |i|
      make_task(id: "task.#{format('%03d', i)}", status: "pending")
    end

    result = @analyzer.categorize_activities(tasks, up_next_limit: 2)

    assert_equal 2, result[:up_next].length
  end

  # --- find_recently_done tests ---

  def test_find_recently_done_filters_to_done_status
    with_temp_task_files do |tasks|
      # Only done tasks should be returned
      result = @analyzer.find_recently_done(tasks, 10)

      assert result.all? { |t| t[:status] == "done" }
    end
  end

  def test_find_recently_done_respects_limit
    with_temp_task_files(count: 5, status: "done") do |tasks|
      result = @analyzer.find_recently_done(tasks, 3)

      assert_equal 3, result.length
    end
  end

  def test_find_recently_done_returns_empty_when_no_done_tasks
    tasks = [
      make_task(id: "task.001", status: "pending"),
      make_task(id: "task.002", status: "in-progress")
    ]

    result = @analyzer.find_recently_done(tasks, 3)

    assert_equal [], result
  end

  def test_find_recently_done_includes_completed_status
    # Test that "completed" status is included alongside "done"
    Dir.mktmpdir do |tmpdir|
      done_file = File.join(tmpdir, "task.001.md")
      completed_file = File.join(tmpdir, "task.002.md")
      File.write(done_file, "---\nid: task.001\nstatus: done\n---\n# Done Task")
      File.write(completed_file, "---\nid: task.002\nstatus: completed\n---\n# Completed Task")

      tasks = [
        make_task(id: "task.001", status: "done", path: done_file, title: "Done Task"),
        make_task(id: "task.002", status: "completed", path: completed_file, title: "Completed Task")
      ]

      result = @analyzer.find_recently_done(tasks, 10)

      # Both done and completed tasks should be returned
      assert_equal 2, result.length
      statuses = result.map { |t| t[:status] }
      assert_includes statuses, "done"
      assert_includes statuses, "completed"
    end
  end

  def test_find_recently_done_returns_empty_when_limit_zero
    # Test short-circuit optimization
    with_temp_task_files(count: 5, status: "done") do |tasks|
      result = @analyzer.find_recently_done(tasks, 0)

      assert_equal [], result
    end
  end

  def test_find_recently_done_returns_old_tasks
    # Test that old tasks are still returned (no date filtering)
    Dir.mktmpdir do |tmpdir|
      old_task_file = File.join(tmpdir, "task.001.md")
      File.write(old_task_file, "---\nid: task.001\nstatus: done\n---\n# Old Task")

      # Simulate an old file by backdating its mtime (30 days ago)
      old_time = Time.now - (30 * 24 * 60 * 60)
      File.utime(old_time, old_time, old_task_file)

      tasks = [
        make_task(id: "task.001", status: "done", path: old_task_file, title: "Old Completed Task")
      ]

      result = @analyzer.find_recently_done(tasks, 3)

      # Should return the task regardless of age
      assert_equal 1, result.length
      assert_equal "task.001", result.first[:id]
    end
  end

  def test_find_recently_done_enriches_tasks_with_completed_at
    # Test that returned tasks have :completed_at populated from file mtime
    Dir.mktmpdir do |tmpdir|
      task_file = File.join(tmpdir, "task.001.md")
      File.write(task_file, "---\nid: task.001\nstatus: done\n---\n# Task")

      tasks = [
        make_task(id: "task.001", status: "done", path: task_file)
      ]

      result = @analyzer.find_recently_done(tasks, 3)

      # Should have :completed_at populated with file mtime
      assert_equal 1, result.length
      assert result.first[:completed_at].is_a?(Time)
    end
  end

  def test_find_recently_done_sorts_by_mtime_not_dependency_order
    # Test that recently done tasks are sorted by file mtime, NOT dependency order
    # This is the fix for: recently done subtask not showing when it has a dependency
    #
    # Scenario: Task B depends on Task A
    # - Task A (dependency): modified 1 hour ago
    # - Task B (dependent): modified 5 minutes ago (more recent!)
    # Expected: Task B should appear FIRST (most recent), regardless of dependency
    Dir.mktmpdir do |tmpdir|
      # Create two done tasks where task.002 depends on task.001
      task_001_file = File.join(tmpdir, "task.001.md")
      task_002_file = File.join(tmpdir, "task.002.md")

      File.write(task_001_file, "---\nid: task.001\nstatus: done\n---\n# Task 001")
      File.write(task_002_file, "---\nid: task.002\nstatus: done\ndependencies:\n  - task.001\n---\n# Task 002")

      # Set task.001 to be older (1 hour ago)
      older_time = Time.now - 3600
      File.utime(older_time, older_time, task_001_file)

      # Set task.002 to be more recent (5 minutes ago)
      recent_time = Time.now - 300
      File.utime(recent_time, recent_time, task_002_file)

      tasks = [
        make_task(id: "task.001", status: "done", path: task_001_file, dependencies: []),
        make_task(id: "task.002", status: "done", path: task_002_file, dependencies: ["task.001"])
      ]

      result = @analyzer.find_recently_done(tasks, 10)

      # The more recently modified task (task.002) should appear FIRST
      # even though it depends on task.001
      assert_equal 2, result.length
      assert_equal "task.002", result.first[:id], "Recently done should be sorted by mtime, not dependency order"
      assert_equal "task.001", result.last[:id]
    end
  end

  # --- find_in_progress tests ---

  def test_find_in_progress_filters_to_in_progress_status
    tasks = [
      make_task(id: "task.001", status: "in-progress"),
      make_task(id: "task.002", status: "pending"),
      make_task(id: "task.003", status: "done")
    ]

    result = @analyzer.find_in_progress(tasks)

    assert_equal 1, result.length
    assert_equal "task.001", result.first[:id]
  end

  def test_find_in_progress_returns_all_without_current_task
    tasks = [
      make_task(id: "task.001", status: "in-progress"),
      make_task(id: "task.002", status: "in-progress")
    ]

    result = @analyzer.find_in_progress(tasks)

    assert_equal 2, result.length
  end

  def test_find_in_progress_excludes_current_task
    tasks = [
      make_task(id: "task.001", status: "in-progress"),
      make_task(id: "task.002", status: "in-progress")
    ]

    result = @analyzer.find_in_progress(tasks, "task.001")

    assert_equal 1, result.length
    assert_equal "task.002", result.first[:id]
  end

  def test_find_in_progress_returns_empty_when_no_in_progress
    tasks = [
      make_task(id: "task.001", status: "pending"),
      make_task(id: "task.002", status: "done")
    ]

    result = @analyzer.find_in_progress(tasks)

    assert_equal [], result
  end

  # --- find_up_next tests ---

  def test_find_up_next_filters_to_pending_status
    tasks = [
      make_task(id: "task.001", status: "pending"),
      make_task(id: "task.002", status: "in-progress"),
      make_task(id: "task.003", status: "done")
    ]

    result = @analyzer.find_up_next(tasks, 10)

    assert_equal 1, result.length
    assert_equal "task.001", result.first[:id]
  end

  def test_find_up_next_respects_limit
    tasks = (1..5).map do |i|
      make_task(id: "task.#{format('%03d', i)}", status: "pending")
    end

    result = @analyzer.find_up_next(tasks, 2)

    assert_equal 2, result.length
  end

  def test_find_up_next_sorts_by_sort_field
    tasks = [
      make_task(id: "task.003", status: "pending", sort: 3),
      make_task(id: "task.001", status: "pending", sort: 1),
      make_task(id: "task.002", status: "pending", sort: 2)
    ]

    result = @analyzer.find_up_next(tasks, 10)

    assert_equal "task.001", result[0][:id]
    assert_equal "task.002", result[1][:id]
    assert_equal "task.003", result[2][:id]
  end

  def test_find_up_next_returns_empty_when_no_pending
    tasks = [
      make_task(id: "task.001", status: "in-progress"),
      make_task(id: "task.002", status: "done")
    ]

    result = @analyzer.find_up_next(tasks, 3)

    assert_equal [], result
  end

  def test_find_up_next_excludes_drafts_by_default
    tasks = [
      make_task(id: "task.001", status: "pending"),
      make_task(id: "task.002", status: "draft")
    ]

    result = @analyzer.find_up_next(tasks, 10)

    assert_equal 1, result.length
    assert_equal "task.001", result.first[:id]
  end

  def test_find_up_next_includes_drafts_when_requested
    tasks = [
      make_task(id: "task.001", status: "pending"),
      make_task(id: "task.002", status: "draft")
    ]

    result = @analyzer.find_up_next(tasks, 10, include_drafts: true)

    assert_equal 2, result.length
  end

  def test_find_up_next_returns_empty_when_limit_zero
    # Test short-circuit optimization
    tasks = (1..5).map do |i|
      make_task(id: "task.#{format('%03d', i)}", status: "pending")
    end

    result = @analyzer.find_up_next(tasks, 0)

    assert_equal [], result
  end

  # --- class method tests ---

  def test_class_method_delegates_to_instance
    tasks = [
      make_task(id: "task.001", status: "done"),
      make_task(id: "task.002", status: "in-progress"),
      make_task(id: "task.003", status: "pending")
    ]

    result = Ace::Taskflow::Molecules::TaskActivityAnalyzer.categorize_activities(tasks)

    assert_includes result.keys, :recently_done
    assert_includes result.keys, :in_progress
    assert_includes result.keys, :up_next
  end

  private

  # Create a task hash with sensible defaults
  def make_task(overrides = {})
    base = {
      id: "v.0.9.0+task.001",
      title: "Test Task",
      status: "pending",
      priority: "medium",
      estimate: "2h",
      dependencies: []
    }
    base.merge(overrides)
  end

  # Helper to create temporary task files for testing filter_recent
  # Creates actual files so that File.mtime works
  def with_temp_task_files(count: 3, status: nil)
    Dir.mktmpdir do |tmpdir|
      tasks = []

      # Create tasks with different statuses if not specified
      statuses = status ? [status] * count : %w[done in-progress pending]

      count.times do |i|
        task_status = statuses[i % statuses.length]
        task_id = "task.#{format('%03d', i + 1)}"
        task_file = File.join(tmpdir, "#{task_id}.md")

        # Write a minimal task file
        File.write(task_file, "---\nid: #{task_id}\nstatus: #{task_status}\n---\n# Task #{i + 1}")

        tasks << make_task(
          id: task_id,
          status: task_status,
          path: task_file
        )
      end

      yield tasks
    end
  end

  # Performance test for large releases
  # Note: This test is disabled by default as it can be slow
  # Run with: TEST_PERF=1 ace-test test/molecules/task_activity_analyzer_test.rb
  def test_performance_large_release
    return unless ENV["TEST_PERF"]

    require "benchmark"

    # Simulate a large release with 150 tasks using with_temp_tasks helper
    with_temp_tasks(150, done_count: 50, in_progress_count: 25, pending_count: 75) do |tasks|
      time = Benchmark.realtime do
        result = @analyzer.categorize_activities(
          tasks,
          current_task_id: nil,
          recently_done_limit: 10,
          up_next_limit: 10,
          include_drafts: false
        )

        # Verify result is still correct
        assert_equal 10, result[:recently_done].length
        assert_equal 25, result[:in_progress].length
        assert_equal 10, result[:up_next].length
      end

      # Performance assertion: should complete in under 1 second for 150 tasks
      # This is a soft limit - adjust if tests run on slower hardware
      assert time < 1.0, "Categorization took #{time.round(3)}s, expected < 1.0s for 150 tasks"
    end
  end

  # Helper to create temporary tasks with specific status distribution
  # Used for performance testing with larger task sets
  def with_temp_tasks(total_count, done_count:, in_progress_count:, pending_count:)
    Dir.mktmpdir do |tmpdir|
      tasks = []
      task_num = 1

      # Create done tasks
      done_count.times do
        task_id = "task.#{format('%03d', task_num)}"
        task_file = File.join(tmpdir, "#{task_id}.md")
        File.write(task_file, "---\nid: #{task_id}\nstatus: done\n---\n# Task #{task_num}")
        tasks << make_task(id: task_id, status: "done", path: task_file)
        task_num += 1
      end

      # Create in-progress tasks
      in_progress_count.times do
        task_id = "task.#{format('%03d', task_num)}"
        task_file = File.join(tmpdir, "#{task_id}.md")
        File.write(task_file, "---\nid: #{task_id}\nstatus: in-progress\n---\n# Task #{task_num}")
        tasks << make_task(id: task_id, status: "in-progress", path: task_file)
        task_num += 1
      end

      # Create pending tasks
      pending_count.times do
        task_id = "task.#{format('%03d', task_num)}"
        task_file = File.join(tmpdir, "#{task_id}.md")
        File.write(task_file, "---\nid: #{task_id}\nstatus: pending\n---\n# Task #{task_num}")
        tasks << make_task(id: task_id, status: "pending", path: task_file)
        task_num += 1
      end

      yield tasks
    end
  end
end
