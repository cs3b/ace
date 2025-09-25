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
        task = @manager.find_next_task

        assert task
        assert_equal "v.0.9.0+task.003", task.id
        assert_equal "pending", task.status
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
        task = @manager.find_next_task

        assert task
        assert_equal "v.0.9.0+task.004", task.id
      end
    end
  end

  def test_create_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        task = @manager.create_task("New task title", release: "v.0.9.0")

        assert task
        assert_equal "v.0.9.0+task.006", task.id
        assert_equal "New task title", task.title
        assert_equal "pending", task.status

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
        task = @manager.find_task("003")
        assert task

        updated = @manager.update_task_status(task, "in-progress")
        assert updated
        assert_equal "in-progress", updated.status

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
        task = @manager.find_task("003")
        assert task

        moved = @manager.move_task(task, "v.0.8.0")
        assert moved
        assert_equal "v.0.8.0+task.004", moved.id

        # Verify old file removed
        old_file = File.join(dir, "v.0.9.0", "t", "003", "task.md")
        refute File.exist?(old_file)

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
        # All tasks
        all_tasks = @manager.list_tasks
        assert_equal 5, all_tasks.length

        # Pending only
        pending = @manager.list_tasks(status: "pending")
        assert_equal 3, pending.length

        # Done only
        done = @manager.list_tasks(status: "done")
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
        task = @manager.find_task("004")
        assert task
        assert_equal ["v.0.9.0+task.003"], task.dependencies

        deps_met = @manager.dependencies_met?(task)
        refute deps_met # task.003 is pending
      end
    end
  end

  def test_bulk_reschedule
    with_test_project do |dir|
      Dir.chdir(dir) do
        task_ids = ["003", "004", "005"]
        moved = @manager.reschedule_tasks(task_ids, "v.0.8.0")

        assert_equal 3, moved.length
        moved.each do |task|
          assert_match(/v\.0\.8\.0\+task/, task.id)
        end

        # Verify files were moved
        old_files = Dir.glob(File.join(dir, "v.0.9.0", "t", "{003,004,005}", "*.md"))
        assert_equal 0, old_files.length
      end
    end
  end

  def test_find_task_by_qualified_reference
    with_test_project do |dir|
      Dir.chdir(dir) do
        task = @manager.find_task("v.0.8.0+001")

        assert task
        assert_equal "v.0.8.0+task.001", task.id
      end
    end
  end

  def test_statistics_calculation
    with_test_project do |dir|
      Dir.chdir(dir) do
        stats = @manager.calculate_statistics

        assert stats[:total] > 0
        assert stats[:done] > 0
        assert stats[:in_progress] > 0
        assert stats[:pending] > 0
        assert_equal stats[:total], stats[:done] + stats[:in_progress] + stats[:pending] + (stats[:blocked] || 0)
      end
    end
  end
end