# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/task_manager"

class TaskManagerTest < AceTaskflowTestCase
  # Note: TaskManager must be created inside test directory context
  # so it finds the correct .ace-taskflow root path

  def test_find_next_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new
        task = manager.get_next_task(release: "v.0.9.0")

        assert task
        # "next" preset includes in-progress tasks, so 002 (in-progress) comes first
        assert_equal "v.0.9.0+task.002", task[:id]
        assert_equal "in-progress", task[:status]
      end
    end
  end

  def test_find_next_task_skips_blocked
    with_test_project do |dir|
      # Mark task 002 (in-progress) and 003 (pending) as blocked
      task_002 = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "002", "task.002.s.md")
      File.write(task_002, File.read(task_002).gsub(/status: in-progress/, "status: blocked"))

      task_003 = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "003", "task.003.s.md")
      File.write(task_003, File.read(task_003).gsub(/status: pending/, "status: blocked"))

      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new
        task = manager.get_next_task(release: "current")

        assert task
        assert_equal "v.0.9.0+task.004", task[:id]
      end
    end
  end

  def test_create_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.create_task("New task title", release: "v.0.9.0")

        assert result[:success]
        # Test fixtures have: v.0.9.0 (5 tasks), v.0.8.0 (3 tasks), backlog (10 tasks)
        # Global max is 010, so next task should be 011
        assert_equal "v.0.9.0+task.011", result[:task_id]

        # Verify file was created (directory includes slug: "011-task-new-title")
        # Use config's task_dir (defaults to "t") instead of hardcoded "tasks"
        task_dir = Ace::Taskflow.configuration.task_dir
        task_file = Dir.glob(File.join(dir, ".ace-taskflow", "v.0.9.0", task_dir, "011-*", "*.s.md")).first
        assert task_file, "Task file should exist in #{task_dir}/011-* directory"
        assert File.exist?(task_file)
      end
    end
  end

  def test_update_task_status
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create TaskManager inside test directory context
        manager = Ace::Taskflow::Organisms::TaskManager.new

        result = manager.update_task_status("003", "in-progress")
        assert result[:success]

        # Verify file was updated
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "003", "task.003.s.md")
        content = File.read(task_file)
        assert_match(/status: in-progress/, content)
      end
    end
  end

  def test_move_task_to_release
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.move_task("003", "v.0.8.0")
        assert result[:success]

        # Verify old directory removed (moved)
        old_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "003")
        refute Dir.exist?(old_dir)

        # Verify new file created
        new_file = Dir.glob(File.join(dir, ".ace-taskflow", "_archive", "v.0.8.0", "t", "004", "*.s.md")).first
        assert new_file
        assert File.exist?(new_file)
      end
    end
  end

  def test_list_tasks_with_filters
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new

        # All tasks from current context
        all_tasks = manager.list_tasks(release: "current")
        assert_equal 5, all_tasks.length

        # Pending only
        pending = manager.list_tasks(release: "current", filters: { status: ["pending"] })
        assert_equal 3, pending.length

        # Done only
        done = manager.list_tasks(release: "current", filters: { status: ["done"] })
        assert_equal 1, done.length
      end
    end
  end

  def test_task_dependencies_validation
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      # Add dependencies to task 004 (needs quotes for YAML)
      task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "004", "task.004.s.md")
      content = File.read(task_file)
      File.write(task_file, content.gsub(/dependencies: \[\]/, 'dependencies: ["v.0.9.0+task.003"]'))

      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new
        task = manager.show_task("004")
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
        manager = Ace::Taskflow::Organisms::TaskManager.new
        task = manager.show_task("v.0.8.0+task.001")

        assert task
        assert_equal "v.0.8.0+task.001", task[:id]
      end
    end
  end

  def test_statistics_calculation
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new
        stats = manager.get_statistics(release: "all")

        assert stats[:total] > 0
        assert stats[:done] > 0
        assert stats[:in_progress] > 0
        assert stats[:pending] > 0
      end
    end
  end

  # Tests for subtask creation (122.03)

  def test_create_subtask_under_orchestrator
    with_orchestrator_project do |dir|
      Dir.chdir(dir) do
        # Reset configuration for clean test
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.create_subtask("121", "New Subtask Title", metadata: {})

        assert result[:success], "Should successfully create subtask: #{result[:message]}"
        assert_match(/v\.0\.9\.0\+task\.121\.03/, result[:task_id])

        # Verify file was created in parent directory
        subtask_file = Dir.glob(File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-*", "121.03-*.s.md")).first
        assert subtask_file, "Subtask file should be created in parent directory"
        assert File.exist?(subtask_file)

        # Verify frontmatter
        content = File.read(subtask_file)
        assert_match(/parent: v\.0\.9\.0\+task\.121/, content)
        assert_match(/dependencies:/, content)
        # Should depend on previous subtask (121.02)
        assert_match(/v\.0\.9\.0\+task\.121\.02/, content)
      end
    end
  end

  def test_create_first_subtask_has_no_dependencies
    with_orchestrator_only_project do |dir|
      Dir.chdir(dir) do
        # Reset configuration for clean test
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.create_subtask("121", "First Subtask", metadata: {})

        assert result[:success], "Should create first subtask: #{result[:message]}"
        assert_match(/121\.01/, result[:task_id])

        # Verify file was created
        subtask_file = Dir.glob(File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-*", "121.01-*.s.md")).first
        assert subtask_file, "Subtask file should be created"

        # First subtask should have empty dependencies
        content = File.read(subtask_file)
        assert_match(/parent: v\.0\.9\.0\+task\.121/, content)
        assert_match(/dependencies: \[\]/, content)
      end
    end
  end

  def test_create_subtask_rejects_subtask_of_subtask
    with_orchestrator_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.create_subtask("121.01", "Nested Subtask", metadata: {})

        refute result[:success], "Should reject creating subtask of subtask"
        assert_match(/one level deep/, result[:message])
      end
    end
  end

  def test_create_subtask_parent_not_found
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.create_subtask("999", "Orphan Subtask", metadata: {})

        refute result[:success], "Should fail when parent not found"
        assert_match(/not found/, result[:message])
      end
    end
  end

  def test_create_subtask_parent_not_orchestrator
    with_regular_task_project do |dir|
      Dir.chdir(dir) do
        # Reset configuration for clean test
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        # Task 123 is a regular task, not an orchestrator (no .00 file, no subtasks)
        result = manager.create_subtask("123", "Subtask Under Regular", metadata: {})

        assert result[:success], "Should auto-convert parent and create subtask: #{result[:message]}"
        assert_match(/Converted task.*123.*orchestrator/, result[:message])
        assert_match(/Created subtask/, result[:message])
        assert_match(/\.02/, result[:task_id])

        subtask_file = result[:path]
        assert File.exist?(subtask_file), "Expected new subtask file to exist"
        content = File.read(subtask_file)
        assert_match(/parent: v\.0\.9\.0\+task\.123/, content)
      end
    end
  end

  # Tests for complete_task lifecycle (122.07 - Review Feedback)

  def test_complete_subtask_does_not_move_folder
    with_orchestrator_project_one_pending do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        # Complete the first subtask (second still pending) - folder should NOT move
        result = manager.complete_task("121.01")

        assert result[:success], "Should complete subtask: #{result[:message]}"
        assert_match(/Subtask.*marked as done/, result[:message])

        # Verify subtask status updated
        subtask_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-hierarchical-test", "121.01-first-subtask.s.md")
        content = File.read(subtask_file)
        assert_match(/status: done/, content)

        # Verify parent folder NOT moved to _archive/
        parent_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-hierarchical-test")
        assert Dir.exist?(parent_dir), "Parent folder should NOT be moved when other subtasks still pending"

        # Verify done directory doesn't contain the orchestrator
        done_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "_archive", "121-hierarchical-test")
        refute Dir.exist?(done_dir), "Orchestrator should NOT be in _archive/ yet"
      end
    end
  end

  def test_complete_last_subtask_auto_completes_orchestrator
    with_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        # First mark subtask 02 as done (01 is already done in fixture)
        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.complete_task("121.02")

        assert result[:success], "Should complete subtask: #{result[:message]}"

        # Orchestrator should be auto-completed and moved to _archive/ (inside t/_archive/)
        done_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "_archive")
        orchestrator_in_done = Dir.glob(File.join(done_dir, "*121*")).first

        assert orchestrator_in_done, "Orchestrator should be moved to t/_archive/ when all subtasks complete"

        # Verify orchestrator status is done
        orchestrator_file = Dir.glob(File.join(done_dir, "*121*", "121-orchestrator.s.md")).first
        assert orchestrator_file, "Orchestrator file should exist in _archive/"
        content = File.read(orchestrator_file)
        assert_match(/status: done/, content)
      end
    end
  end

  def test_complete_orchestrator_with_pending_subtasks_does_not_move
    with_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        # Subtask 02 is still pending in fixture
        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.complete_task("121")

        assert result[:success], "Should mark orchestrator as done"
        assert_match(/still pending/, result[:message])
        assert_match(/1 subtask/, result[:message])

        # Verify orchestrator marked as done
        orchestrator_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-hierarchical-test", "121-orchestrator.s.md")
        content = File.read(orchestrator_file)
        assert_match(/status: done/, content)

        # Verify folder NOT moved to _archive/
        parent_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-hierarchical-test")
        assert Dir.exist?(parent_dir), "Folder should NOT be moved when subtasks pending"
      end
    end
  end

  def test_complete_single_task_moves_to_done
    with_regular_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.complete_task("123")

        assert result[:success], "Should complete task: #{result[:message]}"
        assert_match(/moved to _archive/, result[:message])

        # Verify task moved to _archive/ (inside t/_archive/)
        done_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "_archive")
        task_in_done = Dir.glob(File.join(done_dir, "*123*")).first
        assert task_in_done, "Task should be moved to t/_archive/"

        # Verify original location is empty
        original_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "123-regular-task")
        refute Dir.exist?(original_dir), "Task should be moved from original location"
      end
    end
  end

  def test_complete_task_blocks_when_success_criteria_unresolved
    with_regular_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "123-regular-task", "123-regular-task.s.md")
        content = File.read(task_file)
        content += <<~SECTIONS

          ## Success Criteria

          - [ ] Criterion one unresolved
          - [x] Criterion two done
        SECTIONS
        File.write(task_file, content)

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.complete_task("123")

        refute result[:success], "Expected completion gate to block unresolved checklist items"
        assert_match(/Completion blocked/, result[:message])
        assert_match(/Success Criteria/, result[:message])
        assert_match(/--allow-incomplete/, result[:message])

        content_after = File.read(task_file)
        assert_match(/status: pending/, content_after)

        archive_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "_archive")
        task_in_archive = Dir.glob(File.join(archive_dir, "*123*")).first
        refute task_in_archive, "Task should not move to archive when gate blocks completion"
      end
    end
  end

  def test_complete_task_allow_incomplete_bypasses_gate
    with_regular_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "123-regular-task", "123-regular-task.s.md")
        content = File.read(task_file)
        content += <<~SECTIONS

          ## Success Criteria

          - [ ] Criterion one unresolved
        SECTIONS
        File.write(task_file, content)

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.complete_task("123", allow_incomplete: true)

        assert result[:success], "Expected override to bypass completion gate"
        assert_match(/moved to _archive/, result[:message])
        assert_match(/Bypassed completion gate/, result[:warning])

        archive_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "_archive")
        task_in_archive = Dir.glob(File.join(archive_dir, "*123*")).first
        assert task_in_archive, "Task should move to archive when override is used"
      end
    end
  end

  def test_all_subtasks_terminal_returns_true_when_all_done
    with_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        # Mark subtask 02 as done (01 is already done)
        subtask_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-hierarchical-test", "121.02-second-subtask.s.md")
        content = File.read(subtask_file)
        File.write(subtask_file, content.gsub(/status: pending/, "status: done"))

        manager = Ace::Taskflow::Organisms::TaskManager.new
        orchestrator = manager.show_task("121")

        # Use send to access private method
        result = manager.send(:all_subtasks_terminal?, orchestrator)
        assert result, "Should return true when all subtasks are done"
      end
    end
  end

  def test_all_subtasks_terminal_returns_false_with_pending
    with_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        orchestrator = manager.show_task("121")

        # Subtask 02 is pending in fixture
        result = manager.send(:all_subtasks_terminal?, orchestrator)
        refute result, "Should return false when subtask is pending"
      end
    end
  end

  def test_all_subtasks_terminal_returns_true_for_empty_subtasks
    with_orchestrator_only_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        orchestrator = manager.show_task("121")

        result = manager.send(:all_subtasks_terminal?, orchestrator)
        assert result, "Should return true when no subtasks exist"
      end
    end
  end

  def test_count_pending_subtasks_accuracy
    with_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        orchestrator = manager.show_task("121")

        # Fixture has 2 subtasks: 01 (done), 02 (pending)
        count = manager.send(:count_pending_subtasks, orchestrator)
        assert_equal 1, count, "Should count 1 pending subtask"
      end
    end
  end

  private

  # Create a test project with orchestrator that has existing subtasks
  def with_orchestrator_project
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        # Setup basic structure
        taskflow_root = File.join(dir, ".ace-taskflow")
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), "taskflow:\n  root: .ace-taskflow\n")

        # Create release with .active marker
        release_dir = File.join(taskflow_root, "v.0.9.0")
        FileUtils.mkdir_p(release_dir)
        File.write(File.join(release_dir, ".active"), "")

        # Create orchestrator directory and files
        task_dir = File.join(release_dir, "t", "121-hierarchical-test")
        FileUtils.mkdir_p(task_dir)

        # Create orchestrator file (121.00)
        orchestrator_content = <<~CONTENT
---
id: v.0.9.0+task.121
status: in-progress
priority: high
estimate: 8h
dependencies: []
subtasks:
  - v.0.9.0+task.121.01
  - v.0.9.0+task.121.02
---

# 121 - Hierarchical Test Task (Orchestrator)
        CONTENT
        File.write(File.join(task_dir, "121-orchestrator.s.md"), orchestrator_content)

        # Create subtask 01
        subtask01_content = <<~CONTENT
---
id: v.0.9.0+task.121.01
status: done
priority: high
estimate: 2h
dependencies: []
parent: v.0.9.0+task.121
---

# 121.01 - First Subtask
        CONTENT
        File.write(File.join(task_dir, "121.01-first-subtask.s.md"), subtask01_content)

        # Create subtask 02
        subtask02_content = <<~CONTENT
---
id: v.0.9.0+task.121.02
status: pending
priority: medium
estimate: 3h
dependencies:
  - v.0.9.0+task.121.01
parent: v.0.9.0+task.121
---

# 121.02 - Second Subtask
        CONTENT
        File.write(File.join(task_dir, "121.02-second-subtask.s.md"), subtask02_content)

        yield dir
      end
    end
  end

  # Create a test project with orchestrator where BOTH subtasks are pending
  # Used to test that completing one subtask doesn't move the folder
  def with_orchestrator_project_one_pending
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        # Setup basic structure
        taskflow_root = File.join(dir, ".ace-taskflow")
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), "taskflow:\n  root: .ace-taskflow\n")

        # Create release with .active marker
        release_dir = File.join(taskflow_root, "v.0.9.0")
        FileUtils.mkdir_p(release_dir)
        File.write(File.join(release_dir, ".active"), "")

        # Create orchestrator directory and files
        task_dir = File.join(release_dir, "t", "121-hierarchical-test")
        FileUtils.mkdir_p(task_dir)

        # Create orchestrator file (121.00)
        orchestrator_content = <<~CONTENT
---
id: v.0.9.0+task.121
status: in-progress
priority: high
estimate: 8h
dependencies: []
subtasks:
  - v.0.9.0+task.121.01
  - v.0.9.0+task.121.02
---

# 121 - Hierarchical Test Task (Orchestrator)
        CONTENT
        File.write(File.join(task_dir, "121-orchestrator.s.md"), orchestrator_content)

        # Create subtask 01 - PENDING (not done)
        subtask01_content = <<~CONTENT
---
id: v.0.9.0+task.121.01
status: pending
priority: high
estimate: 2h
dependencies: []
parent: v.0.9.0+task.121
---

# 121.01 - First Subtask
        CONTENT
        File.write(File.join(task_dir, "121.01-first-subtask.s.md"), subtask01_content)

        # Create subtask 02 - PENDING
        subtask02_content = <<~CONTENT
---
id: v.0.9.0+task.121.02
status: pending
priority: medium
estimate: 3h
dependencies:
  - v.0.9.0+task.121.01
parent: v.0.9.0+task.121
---

# 121.02 - Second Subtask
        CONTENT
        File.write(File.join(task_dir, "121.02-second-subtask.s.md"), subtask02_content)

        yield dir
      end
    end
  end

  # Create project with orchestrator but no subtasks yet
  def with_orchestrator_only_project
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        # Setup basic structure
        taskflow_root = File.join(dir, ".ace-taskflow")
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), "taskflow:\n  root: .ace-taskflow\n")

        # Create release with .active marker
        release_dir = File.join(taskflow_root, "v.0.9.0")
        FileUtils.mkdir_p(release_dir)
        File.write(File.join(release_dir, ".active"), "")

        # Create orchestrator directory with only the orchestrator file
        task_dir = File.join(release_dir, "t", "121-orchestrator-only")
        FileUtils.mkdir_p(task_dir)

        orchestrator_content = <<~CONTENT
---
id: v.0.9.0+task.121
status: pending
priority: high
estimate: 8h
dependencies: []
---

# 121 - Orchestrator Only Task
        CONTENT
        File.write(File.join(task_dir, "121-orchestrator.s.md"), orchestrator_content)

        yield dir
      end
    end
  end

  # Create project with regular (non-orchestrator) task
  def with_regular_task_project
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        # Setup basic structure
        taskflow_root = File.join(dir, ".ace-taskflow")
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), "taskflow:\n  root: .ace-taskflow\n")

        # Create release with .active marker
        release_dir = File.join(taskflow_root, "v.0.9.0")
        FileUtils.mkdir_p(release_dir)
        File.write(File.join(release_dir, ".active"), "")

        # Create regular task directory (no orchestrator or subtask files)
        task_dir = File.join(release_dir, "t", "123-regular-task")
        FileUtils.mkdir_p(task_dir)

        # Regular task file (123-something.s.md, no subtask files in directory)
        task_content = <<~CONTENT
---
id: v.0.9.0+task.123
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# 123 - Regular Task

This is a regular task, not an orchestrator.
        CONTENT
        File.write(File.join(task_dir, "123-regular-task.s.md"), task_content)

        yield dir
      end
    end
  end

  # Tests for reopen_task (undone command)
  def test_reopen_single_task_from_archive
    with_regular_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new

        # First complete the task (moves to archive)
        complete_result = manager.complete_task("123")
        assert complete_result[:success], "Should complete task"

        # Verify it's in archive
        archive_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "_archive")
        task_in_archive = Dir.glob(File.join(archive_dir, "*123*")).first
        assert task_in_archive, "Task should be in archive"

        # Now reopen the task
        reopen_result = manager.reopen_task("123")
        assert reopen_result[:success], "Should reopen task: #{reopen_result[:message]}"
        assert_match(/restored from _archive/, reopen_result[:message])

        # Verify task is back in active tasks directory
        active_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t")
        task_in_active = Dir.glob(File.join(active_dir, "*123*")).reject { |p| p.include?("_archive") }.first
        assert task_in_active, "Task should be restored to active tasks"

        # Verify task is no longer in archive
        task_still_in_archive = Dir.glob(File.join(archive_dir, "*123*")).first
        refute task_still_in_archive, "Task should not be in archive anymore"

        # Verify status was updated to in-progress
        task_file = Dir.glob(File.join(task_in_active, "*.s.md")).first
        content = File.read(task_file)
        assert_match(/status: in-progress/, content)
      end
    end
  end

  def test_reopen_task_not_in_archive_updates_status_only
    with_regular_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new

        # Update task to done status without moving to archive
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "123-regular-task", "123-regular-task.s.md")
        content = File.read(task_file)
        File.write(task_file, content.gsub(/status: pending/, "status: done"))

        # Now reopen the task (should only update status since not in archive)
        reopen_result = manager.reopen_task("123")
        assert reopen_result[:success], "Should reopen task: #{reopen_result[:message]}"
        assert_match(/set to in-progress/, reopen_result[:message])

        # Verify status was updated
        content_after = File.read(task_file)
        assert_match(/status: in-progress/, content_after)

        # Verify task is still in same location (not moved)
        assert File.exist?(task_file), "Task should still be in original location"
      end
    end
  end

  def test_reopen_subtask_updates_status_only
    with_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new

        # Mark subtask as done
        subtask_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-hierarchical-test", "121.01-first-subtask.s.md")
        content = File.read(subtask_file)
        File.write(subtask_file, content.gsub(/status: done/, "status: done")) # Already done in fixture

        # Reopen the subtask
        reopen_result = manager.reopen_task("121.01")
        assert reopen_result[:success], "Should reopen subtask: #{reopen_result[:message]}"
        assert_match(/reopened and set to in-progress/, reopen_result[:message])

        # Verify status was updated
        content_after = File.read(subtask_file)
        assert_match(/status: in-progress/, content_after)

        # Verify subtask file is still in same location (not moved)
        assert File.exist?(subtask_file), "Subtask should remain in orchestrator directory"
      end
    end
  end

  def test_reopen_task_not_found
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::TaskManager.new

        result = manager.reopen_task("999")
        refute result[:success]
        assert_match(/not found/, result[:message])
      end
    end
  end

  # Tests for resolve_release_path (Task 158 - backlog fix regression test)

  def test_resolve_release_path_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.send(:resolve_release_path, "backlog")

        # Should return path to backlog directory using configuration
        expected_backlog_dir = Ace::Taskflow.configuration.backlog_dir
        assert_equal File.join(dir, ".ace-taskflow", expected_backlog_dir), result
      end
    end
  end

  def test_resolve_release_path_current
    with_test_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.send(:resolve_release_path, "current")

        # Should return path to active release (v.0.9.0 in fixture)
        assert_match(/v\.0\.9\.0/, result)
      end
    end
  end

  def test_resolve_release_path_all
    with_test_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.send(:resolve_release_path, "all")

        # Should return root path
        assert_equal File.join(dir, ".ace-taskflow"), result
      end
    end
  end
end
