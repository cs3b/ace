# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_directory_mover"

class TaskDirectoryMoverTest < AceTaskflowTestCase
  def setup
    @mover = Ace::Taskflow::Molecules::TaskDirectoryMover.new
  end

  def test_move_to_anyday
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test task directory structure
        tasks_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t")
        task_dir = File.join(tasks_dir, "001-test-task")
        FileUtils.mkdir_p(task_dir)
        task_file = File.join(task_dir, "001-test-task.s.md")
        File.write(task_file, "---\nid: v.0.9.0+task.001\nstatus: pending\n---\n# Test Task")

        # Move to deferred
        result = @mover.move_to_anyday(task_file)

        assert result[:success], "Should succeed: #{result[:message]}"
        expected_path = File.join(tasks_dir, "_anyday", "001-test-task", "001-test-task.s.md")
        assert_equal expected_path, result[:new_path]
        assert File.exist?(expected_path), "Deferred task file should exist"
        refute Dir.exist?(task_dir), "Original task directory should not exist"
      end
    end
  end

  def test_move_to_anyday_idempotent
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test task directory structure already in deferred
        tasks_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t")
        deferred_dir = File.join(tasks_dir, "_anyday", "001-test-task")
        FileUtils.mkdir_p(deferred_dir)
        task_file = File.join(deferred_dir, "001-test-task.s.md")
        File.write(task_file, "---\nid: v.0.9.0+task.001\nstatus: deferred\n---\n# Test Task")

        # Move to deferred again (should be idempotent)
        result = @mover.move_to_anyday(task_file)

        assert result[:success], "Should succeed: #{result[:message]}"
        assert_match(/already in _anyday/, result[:message])
        assert_equal task_file, result[:new_path]
        assert File.exist?(task_file), "Task file should still exist"
      end
    end
  end

  def test_move_to_anyday_with_nil_path
    result = @mover.move_to_anyday(nil)
    refute result[:success]
    assert_match(/not provided/i, result[:message])
  end

  def test_move_to_anyday_with_nonexistent_path
    result = @mover.move_to_anyday("/nonexistent/path")
    refute result[:success]
    assert_match(/not found/i, result[:message])
  end

  def test_restore_from_anyday
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create deferred task directory
        tasks_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t")
        deferred_dir = File.join(tasks_dir, "_anyday", "001-test-task")
        FileUtils.mkdir_p(deferred_dir)
        task_file = File.join(deferred_dir, "001-test-task.s.md")
        File.write(task_file, "---\nid: v.0.9.0+task.001\nstatus: deferred\n---\n# Test Task")

        # Restore from deferred
        result = @mover.restore_from_anyday(task_file)

        assert result[:success], "Should succeed: #{result[:message]}"
        expected_path = File.join(tasks_dir, "001-test-task", "001-test-task.s.md")
        assert_equal expected_path, result[:new_path]
        assert File.exist?(expected_path), "Restored task file should exist"
        refute Dir.exist?(deferred_dir), "Deferred directory should not exist"
      end
    end
  end

  def test_restore_from_anyday_with_nil_path
    result = @mover.restore_from_anyday(nil)
    refute result[:success]
    assert_match(/not provided/i, result[:message])
  end

  def test_restore_from_anyday_with_nonexistent_path
    result = @mover.restore_from_anyday("/nonexistent/path")
    refute result[:success]
    assert_match(/not found/i, result[:message])
  end

  def test_restore_from_anyday_with_non_anyday_path
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create task in regular location (not deferred)
        tasks_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t")
        task_dir = File.join(tasks_dir, "001-test-task")
        FileUtils.mkdir_p(task_dir)
        task_file = File.join(task_dir, "001-test-task.s.md")
        File.write(task_file, "---\nid: v.0.9.0+task.001\nstatus: pending\n---\n# Test Task")

        # Try to restore from deferred (should fail)
        result = @mover.restore_from_anyday(task_file)

        refute result[:success]
        assert_match(/not in _anyday/i, result[:message])
      end
    end
  end

  def test_restore_from_anyday_with_target_already_exists
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create both deferred task and existing target task
        tasks_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t")

        # Deferred task
        deferred_dir = File.join(tasks_dir, "_anyday", "001-test-task")
        FileUtils.mkdir_p(deferred_dir)
        deferred_file = File.join(deferred_dir, "001-test-task.s.md")
        File.write(deferred_file, "---\nid: v.0.9.0+task.001\nstatus: deferred\n---\n# Deferred Task")

        # Existing target task
        task_dir = File.join(tasks_dir, "001-test-task")
        FileUtils.mkdir_p(task_dir)
        task_file = File.join(task_dir, "001-test-task.s.md")
        File.write(task_file, "---\nid: v.0.9.0+task.001\nstatus: pending\n---\n# Existing Task")

        # Try to restore (should fail due to conflict)
        result = @mover.restore_from_anyday(deferred_file)

        refute result[:success]
        assert_match(/already exists/i, result[:message])
      end
    end
  end
end
