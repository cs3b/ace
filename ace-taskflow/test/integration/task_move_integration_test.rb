# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "ace/taskflow"
require "ace/taskflow/organisms/task_manager"
require "ace/taskflow/commands/task_command"

# Integration tests for task move command (Task 158 - regression tests)
# Tests task move --backlog functionality that was broken by Hash vs Configuration bug
class TaskMoveIntegrationTest < AceTaskflowTestCase
  def setup
    super
    @temp_dir = Dir.mktmpdir
    @project_root = File.join(@temp_dir, "test-project")
    FileUtils.mkdir_p(@project_root)

    # Setup ace-taskflow project structure
    taskflow_root = File.join(@project_root, ".ace-taskflow")
    config_dir = File.join(@project_root, ".ace", "taskflow")
    t_dir = File.join(taskflow_root, "v.0.9.0", "t")
    backlog_dir = File.join(taskflow_root, "_backlog", "t")
    FileUtils.mkdir_p([taskflow_root, config_dir, t_dir, backlog_dir])

    # Create config - only set root, task_dir comes from gem defaults (t/)
    File.write(File.join(config_dir, "config.yml"), <<~YAML)
      taskflow:
        root: .ace-taskflow
    YAML

    # Create active release
    release_dir = File.join(taskflow_root, "v.0.9.0")
    File.write(File.join(release_dir, ".active"), "")

    # Create a test task
    task_dir = File.join(t_dir, "141-test-task")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "141-test-task.s.md"), <<~MARKDOWN)
      ---
      id: v.0.9.0+task.141
      status: pending
      priority: medium
      estimate: 2h
      dependencies: []
      ---

      # Test Task for Move

      This is a test task for verifying the move --backlog command.
    MARKDOWN
  end

  def teardown
    super
  ensure
    FileUtils.rm_rf(@temp_dir) if @temp_dir
  end

  def test_move_task_to_backlog_via_organism
    TestFactory.with_stubbed_project_root(@project_root) do
      Dir.chdir(@project_root) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.move_task("141", "backlog")

        assert result[:success], "Move task to backlog should succeed: #{result[:message]}"

        # Verify task moved to backlog (may have new number)
        # The move_task method assigns a new task number based on all existing tasks
        backlog_tasks = Dir.glob(File.join(@project_root, ".ace-taskflow", "_backlog", "t", "*"))
        assert backlog_tasks.any?, "At least one task should be in backlog directory"

        # Verify original location is empty
        original_dir = File.join(@project_root, ".ace-taskflow", "v.0.9.0", "t", "141-test-task")
        refute Dir.exist?(original_dir), "Task should be removed from original location"
      end
    end
  end

  def test_move_task_to_backlog_via_command
    TestFactory.with_stubbed_project_root(@project_root) do
      Dir.chdir(@project_root) do
        Ace::Taskflow.reset_configuration!

        # Use the CLI command interface (execute dispatches to move_task)
        command = Ace::Taskflow::Commands::TaskCommand.new
        output = capture_stdout do
          command.execute(["move", "141", "--backlog"])
        end

        # Verify success message mentions backlog
        assert_match(/backlog/i, output)

        # Verify task is in backlog (may have new number)
        backlog_tasks = Dir.glob(File.join(@project_root, ".ace-taskflow", "_backlog", "t", "*"))
        assert backlog_tasks.any?, "At least one task should be in backlog directory after CLI command"
      end
    end
  end

  def test_move_backlog_uses_configuration_not_hash
    # Regression test for Task 158 bug:
    # The bug was @config.backlog_dir where @config was a Hash, not Configuration object
    # This test ensures we use Ace::Taskflow.configuration instead
    TestFactory.with_stubbed_project_root(@project_root) do
      Dir.chdir(@project_root) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new

        # The bug would cause NoMethodError: undefined method 'backlog_dir' for Hash
        # If this doesn't raise, the fix is working
        result = manager.move_task("141", "backlog")
        assert result[:success], "Move should succeed without NoMethodError: #{result[:message]}"
      end
    end
  end

  def test_move_task_with_subtasks_to_backlog
    # Test that moving a task with subtasks moves the entire directory structure
    TestFactory.with_stubbed_project_root(@project_root) do
      Dir.chdir(@project_root) do
        # Create subtask within the parent task directory
        subtask_dir = File.join(@project_root, ".ace-taskflow", "v.0.9.0", "t", "141-test-task")
        File.write(File.join(subtask_dir, "141.01-subtask.s.md"), <<~MARKDOWN)
          ---
          id: v.0.9.0+task.141.01
          status: pending
          priority: low
          ---

          # Subtask One

          This is a subtask.
        MARKDOWN

        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.move_task("141", "backlog")

        assert result[:success], "Move task with subtasks should succeed: #{result[:message]}"

        # Verify the entire task directory (including subtasks) moved
        backlog_tasks = Dir.glob(File.join(@project_root, ".ace-taskflow", "_backlog", "t", "*"))
        assert backlog_tasks.any?, "Task directory should be in backlog"

        # Check that the subtask file exists in the moved directory
        moved_task_dir = backlog_tasks.first
        subtask_files = Dir.glob(File.join(moved_task_dir, "*.s.md"))
        assert subtask_files.length >= 2, "Both parent task and subtask files should exist in moved directory"
      end
    end
  end

  def test_move_to_backlog_success_message_format
    # Verify exact success message format for CLI output stability
    TestFactory.with_stubbed_project_root(@project_root) do
      Dir.chdir(@project_root) do
        Ace::Taskflow.reset_configuration!

        command = Ace::Taskflow::Commands::TaskCommand.new
        output = capture_stdout do
          command.execute(["move", "141", "--backlog"])
        end

        # Success message should contain key information:
        # - Original task reference
        # - Destination (backlog)
        # - New location or confirmation of move
        assert_match(/141/, output, "Output should reference the original task number")
        assert_match(/backlog/i, output, "Output should mention backlog as destination")
        assert_match(/moved|success/i, output, "Output should indicate successful move")
      end
    end
  end
end

