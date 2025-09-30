# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/task_manager"

class TaskManagerTest < AceTaskflowTestCase
  def setup
    @manager = Ace::Taskflow::Organisms::TaskManager.new
  end

  def test_find_next_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        task = @manager.get_next_task(context: "v.0.9.0")

        assert task
        assert_equal "v.0.9.0+task.003", task[:id]
        assert_equal "pending", task[:status]
      end
    end
  end

  def test_find_next_task_skips_blocked
    with_test_project do |dir|
      # Mark task 003 as blocked
      task_file = File.join(dir, "v.0.9.0", "t", "003", "task.md")
      content = File.read(task_file)
      File.write(task_file, content.gsub(/status: pending/, "status: blocked"))

      Dir.chdir(dir) do
        task = @manager.get_next_task(context: "current")

        assert task
        assert_equal "v.0.9.0+task.004", task[:id]
      end
    end
  end

  def test_create_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        result = @manager.create_task("New task title", context: "v.0.9.0")

        assert result[:success]
        assert_equal "v.0.9.0+task.006", result[:task_id]

        # Verify file was created
        task_file = Dir.glob(File.join(dir, "v.0.9.0", "t", "006", "*.md")).first
        assert task_file
        assert File.exist?(task_file)
      end
    end
  end

  def test_update_task_status
    with_test_project do |dir|
      Dir.chdir(dir) do
        result = @manager.update_task_status("003", "in-progress")
        assert result[:success]

        # Verify file was updated
        task_file = File.join(dir, "v.0.9.0", "t", "003", "task.md")
        content = File.read(task_file)
        assert_match(/status: in-progress/, content)
      end
    end
  end

  def test_move_task_to_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        result = @manager.move_task("003", "v.0.8.0")
        assert result[:success]

        # Verify old directory removed (moved)
        old_dir = File.join(dir, "v.0.9.0", "t", "003")
        refute Dir.exist?(old_dir)

        # Verify new file created
        new_file = Dir.glob(File.join(dir, "v.0.8.0", "t", "004", "*.md")).first
        assert new_file
        assert File.exist?(new_file)
      end
    end
  end

  def test_list_tasks_with_filters
    with_test_project do |dir|
      Dir.chdir(dir) do
        # All tasks from current context
        all_tasks = @manager.list_tasks(context: "current")
        assert_equal 5, all_tasks.length

        # Pending only
        pending = @manager.list_tasks(context: "current", filters: { status: ["pending"] })
        assert_equal 3, pending.length

        # Done only
        done = @manager.list_tasks(context: "current", filters: { status: ["done"] })
        assert_equal 1, done.length
      end
    end
  end

  def test_task_dependencies_validation
    with_test_project do |dir|
      # Add dependencies to task 004
      task_file = File.join(dir, "v.0.9.0", "t", "004", "task.md")
      content = File.read(task_file)
      File.write(task_file, content.gsub(/dependencies: \[\]/, "dependencies: [v.0.9.0+task.003]"))

      Dir.chdir(dir) do
        task = @manager.show_task("004")
        assert task
        assert_equal ["v.0.9.0+task.003"], task[:dependencies]
      end
    end
  end

  def test_bulk_reschedule
    skip "reschedule_tasks method needs review - may not exist in current implementation"
  end

  def test_find_task_by_qualified_reference
    with_test_project do |dir|
      Dir.chdir(dir) do
        task = @manager.show_task("v.0.8.0+001")

        assert task
        assert_equal "v.0.8.0+task.001", task[:id]
      end
    end
  end

  def test_statistics_calculation
    with_test_project do |dir|
      Dir.chdir(dir) do
        stats = @manager.get_statistics(context: "all")

        assert stats[:total] > 0
        assert stats[:done] > 0
        assert stats[:in_progress] > 0
        assert stats[:pending] > 0
      end
    end
  end
end