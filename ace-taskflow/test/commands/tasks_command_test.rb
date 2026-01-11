# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/tasks_command"

class TasksCommandTest < AceTaskflowTestCase
  # Note: TasksCommand must be created inside test directory context
  # so TaskManager finds the correct .ace-taskflow root path

  def test_list_all_tasks
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["all"]) # Use 'all' preset to show all tasks in current release
        end

        # Should show tasks from active release
        assert_match(/v\.0\.9\.0\+task\.001/, output)
        assert_match(/v\.0\.9\.0\+task\.002/, output)
        assert_match(/v\.0\.9\.0\+task\.003/, output)
        assert_match(/v\.0\.9\.0\+task\.004/, output)
        assert_match(/v\.0\.9\.0\+task\.005/, output)

        # Should show status
        assert_match(/_archive/, output)
        assert_match(/in-progress/, output)
        assert_match(/pending/, output)
      end
    end
  end

  def test_list_tasks_with_status_filter
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["pending"]) # Use 'pending' preset
        end

        # Should only show pending tasks
        assert_match(/v\.0\.9\.0\+task\.003/, output)
        assert_match(/v\.0\.9\.0\+task\.004/, output)
        assert_match(/v\.0\.9\.0\+task\.005/, output)

        # Should not show done or in-progress
        refute_match(/v\.0\.9\.0\+task\.001/, output)
        refute_match(/v\.0\.9\.0\+task\.002/, output)
      end
    end
  end

  def test_list_tasks_from_specific_release
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["all", "--release", "done/v.0.8.0"]) # Use 'all' preset with specific release context
        end

        # Should show v.0.8.0 tasks
        assert_match(/v\.0\.8\.0\+task\.001/, output)
        assert_match(/v\.0\.8\.0\+task\.002/, output)
        assert_match(/v\.0\.8\.0\+task\.003/, output)

        # Should not show v.0.9.0 tasks
        refute_match(/v\.0\.9\.0/, output)
      end
    end
  end

  def test_list_all_releases_tasks
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["all-releases"]) # Use 'all-releases' preset
        end

        # Should show tasks from all releases
        assert_match(/v\.0\.9\.0\+task\.001/, output)
        assert_match(/v\.0\.8\.0\+task\.001/, output)
        assert_match(/backlog\+task\.001/, output)
      end
    end
  end

  def test_list_backlog_tasks
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["--backlog"])
        end

        # Should show only backlog tasks
        assert_match(/backlog\+task\.001/, output)
        assert_match(/backlog\+task\.002/, output)

        # Should not show release tasks
        refute_match(/v\.0\.9\.0/, output)
        refute_match(/v\.0\.8\.0/, output)
      end
    end
  end

  def test_tasks_statistics
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["--stats"])
        end

        # Should show statistics
        assert_match(/Statistics/, output)
        assert_match(/Total:/, output)
        assert_match(/Done:/, output)
        assert_match(/In Progress:/, output)
        assert_match(/Pending:/, output)
      end
    end
  end

  def test_reschedule_tasks
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["reschedule", "v.0.9.0+task.003,v.0.9.0+task.004", "v.0.8.0"])
        end

        assert_match(/Rescheduled/, output)
        assert_match(/2 tasks/, output)

        # Verify tasks were moved
        old_file1 = File.join(dir, "v.0.9.0", "t", "003", "task.md")
        old_file2 = File.join(dir, "v.0.9.0", "t", "004", "task.md")
        refute File.exist?(old_file1)
        refute File.exist?(old_file2)

        new_files = Dir.glob(File.join(dir, "v.0.8.0", "t", "*", "task.md"))
        assert_equal 5, new_files.length # Original 3 + 2 moved
      end
    end
  end

  def test_reschedule_with_invalid_tasks
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["reschedule", "v.0.9.0+task.999", "v.0.8.0"])
        end

        assert_match(/not found/, output)
      end
    end
  end

  def test_list_with_count_limit
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["--count", "2"])
        end

        # Should only show 2 tasks
        lines = output.lines.select { |l| l.include?("+task.") }
        assert_equal 2, lines.length
      end
    end
  end

  def test_list_sorted_by_id
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["--sort", "id"])
        end

        task_lines = output.lines.select { |l| l.include?("+task.") }
        ids = task_lines.map { |l| l[/task\.(\d+)/, 1].to_i }

        # Should be sorted by ID
        assert_equal ids.sort, ids
      end
    end
  end

  def test_list_sorted_by_status
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["--sort", "status"])
        end

        lines = output.lines
        done_index = lines.index { |l| l.include?("done") }
        in_progress_index = lines.index { |l| l.include?("in-progress") }
        pending_index = lines.index { |l| l.include?("pending") }

        # Done should come before in-progress, in-progress before pending
        assert done_index < in_progress_index if done_index && in_progress_index
        assert in_progress_index < pending_index if in_progress_index && pending_index
      end
    end
  end

  def test_verbose_output
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["--verbose"])
        end

        # Should include additional details
        assert_match(/estimate/, output)
        assert_match(/dependencies/, output)
        assert_match(/sort/, output)
      end
    end
  end

  def test_no_tasks_message
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      # Remove all tasks
      FileUtils.rm_rf(Dir.glob(File.join(dir, "**/t")))

      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute([])
        end

        # Verify header is always shown (even with 0 tasks)
        assert_match(/v\.\d+\.\d+\.\d+:/, output, "Header line 1 (release info) should be present")
        assert_match(/Ideas:/, output, "Header line 2 (ideas stats) should be present")
        assert_match(/Tasks:/, output, "Header line 3 (tasks stats) should be present")
        assert_match(/={40}/, output, "Separator line should be present")

        # Verify empty message is shown after header
        assert_match(/No tasks found for preset/, output, "Empty message should be shown")
      end
    end
  end

  def test_export_to_json
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new
        output = capture_stdout do
          command.execute(["--format", "json"])
        end

        # Should output valid JSON
        require "json"
        data = JSON.parse(output)
        assert data.is_a?(Array)
        assert data.first.key?("id")
        assert data.first.key?("status")
        assert data.first.key?("priority")
      end
    end
  end

  def test_filter_glob_by_type_filters_correctly
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Test filtering task-related patterns
        glob = ["tasks/**.md", "ideas/**.md", "*.md"]
        result = command.send(:filter_glob_by_type, glob, "tasks")

        assert_equal ["tasks/**.md", "*.md"], result
        refute_includes result, "ideas/**.md"
      end
    end
  end

  def test_filter_glob_by_type_returns_nil_for_non_array
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        result = command.send(:filter_glob_by_type, "not an array", "tasks")
        assert_nil result
      end
    end
  end

  def test_filter_glob_by_type_returns_nil_for_nil
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        result = command.send(:filter_glob_by_type, nil, "tasks")
        assert_nil result
      end
    end
  end

  def test_filter_glob_by_type_preserves_patterns_without_slashes
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        glob = ["pattern1", "pattern2", "tasks/pattern3"]
        result = command.send(:filter_glob_by_type, glob, "tasks")

        assert_includes result, "pattern1"
        assert_includes result, "pattern2"
        assert_includes result, "tasks/pattern3"
      end
    end
  end

  # Tests for task 203: parent context display for orphan subtasks

  def test_display_parent_context_line_shows_context_indicator
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Setup parent task data - use id with full qualified reference format
        parent_data = {
          id: "v.0.9.0+task.202",
          task_number: "202",
          release: "v.0.9.0",
          title: "Rename Support Gems",
          status: "pending",
          path: ".ace-taskflow/v.0.9.0/tasks/202-task-refactor/202-rename-support-gems.s.md",
          is_orchestrator: true
        }

        # Capture output
        output = capture_stdout do
          command.send(:display_parent_context_line, parent_data)
        end

        # Verify exact output format with regex: Reference + Title + Orchestrator + [context]
        # Use flexible status icon pattern to handle icon mapping changes
        assert_match(/\Av\.0\.9\.0\+task\.202\s+[⚪🟡🔄🟢🔴]\s+Rename Support Gems \(Orchestrator\) \[context\]/, output.lines.first.strip,
          "Parent context line should match exact format: Reference + Status + Title + Orchestrator + [context]")
        # Verify no tree connector on parent (it's context, not a subtask)
        refute_match(/[├└]/, output, "Parent context line should not contain tree connectors")
        # Verify qualified reference is shown
        assert_includes output, "v.0.9.0+task.202", "Qualified reference should be shown"
        # Verify path is shown on second line
        assert_includes output, ".ace-taskflow/v.0.9.0/tasks/202-task-refactor/", "Path should be shown on second line"
      end
    end
  end

  def test_display_parent_context_line_without_path
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Parent task without path
        parent_data = {
          id: "v.0.9.0+task.202",
          task_number: "202",
          release: "v.0.9.0",
          title: "Test Parent",
          status: "in-progress",
          is_orchestrator: true
        }

        output = capture_stdout do
          command.send(:display_parent_context_line, parent_data)
        end

        # Should still show context indicator and basic info with exact format
        # Note: Status icon depends on status (pending=🟡, in-progress=🔄, done=🟢)
        assert_match(/\Av\.0\.9\.0\+task\.202\s+[⚪🟡🔄🟢🔴]\s+Test Parent \(Orchestrator\) \[context\]\z/, output.strip,
          "Should match exact format without path: Reference + Status + Title + Orchestrator + [context]")
        # Should not have path line (only one line total)
        lines = output.lines.select { |l| !l.strip.empty? }
        assert_equal 1, lines.length, "Should only have one line without path"
      end
    end
  end

  def test_display_subtask_line_with_connector
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        subtask_data = {
          id: "v.0.9.0+task.203",
          task_number: "203",
          release: "v.0.9.0",
          title: "Show parent context for orphan subtasks",
          status: "done",
          parent_id: "202"
        }

        # Test with middle connector (├─)
        output_middle = capture_stdout do
          command.send(:display_subtask_line, subtask_data, "├─")
        end

        assert_includes output_middle, "├─", "Should show middle connector"
        assert_includes output_middle, "v.0.9.0+task.203"
        assert_includes output_middle, "Show parent context for orphan subtasks"

        # Test with last connector (└─)
        output_last = capture_stdout do
          command.send(:display_subtask_line, subtask_data, "└─")
        end

        assert_includes output_last, "└─", "Should show last connector"
      end
    end
  end

  def test_orphan_subtask_scenario_integration
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Setup: parent task 202 exists but is NOT in the filtered results
        # Subtask 203 is in results, references parent 202 (orphan subtask scenario)
        tasks = [
          {
            id: "v.0.9.0+task.203",
            task_number: "203",
            release: "v.0.9.0",
            title: "Orphan subtask",
            status: "done",
            parent_id: "202",  # Parent not in results
            path: ".ace-taskflow/v.0.9.0/tasks/203-task-enhance/203-show-parent-context-for-orphan-subtasks.s.md"
          }
        ]

        # Mock manager to return parent task when asked
        parent_task = build_parent_task(
          id: 202,
          title: "Parent Orchestrator",
          path: ".ace-taskflow/v.0.9.0/tasks/202-task-refactor/202-rename-support-gems.s.md"
        )

        manager = command.task_manager
        manager.stub :show_task, parent_task do
          output = capture_stdout do
            # Invoke the actual method being tested
            command.send(:display_orphan_subtasks_with_context, tasks, [])
          end

          # Verify parent context is shown
          assert_includes output, "[context]", "Parent should be shown with context indicator"
          assert_includes output, "v.0.9.0+task.202", "Parent reference should be shown"
          assert_includes output, "Parent Orchestrator", "Parent title should be shown"

          # Verify orphan subtask is shown with connector
          assert_includes output, "v.0.9.0+task.203", "Orphan subtask reference should be shown"
          assert_includes output, "└─", "Subtask should have tree connector"
        end
      end
    end
  end

  def test_orphan_subtask_with_missing_parent
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Subtask with non-existent parent - manager returns nil
        tasks = [
          {
            id: "v.0.9.0+task.999",
            task_number: "999",
            release: "v.0.9.0",
            title: "Orphan with missing parent",
            status: "pending",
            parent_id: "888",  # Non-existent parent
            path: ".ace-taskflow/v.0.9.0/tasks/999-placeholder/task.999.md"
          }
        ]

        # Stub manager to return nil for parent (simulating missing task)
        manager = command.task_manager
        manager.stub :show_task, nil do
          # Should produce no output when parent is missing
          output = capture_stdout do
            command.send(:display_orphan_subtasks_with_context, tasks, [])
          end
          assert_empty output.strip, "Should produce no output when parent is missing"

          # In verbose mode, should log debug message to stderr
          command.instance_variable_set(:@options, { verbose: true })
          stdout_output, stderr_output = capture_subprocess_io do
            command.send(:display_orphan_subtasks_with_context, tasks, [])
          end
          assert_empty stdout_output.strip, "Should produce no stdout output"
          assert_includes stderr_output, "[DEBUG]", "Should output debug log to stderr"
          assert_includes stderr_output, "Parent task 888 not found", "Should mention missing parent ID"
        end
      end
    end
  end

  def test_orphan_subtasks_with_empty_list
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Empty orphan subtasks list
        output = capture_stdout do
          command.send(:display_orphan_subtasks_with_context, [], [])
        end

        # Should handle gracefully without error
        assert_empty output.strip, "Should produce no output for empty orphan list"
      end
    end
  end

  def test_multiple_orphan_subtasks_tree_connectors
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Multiple subtasks under the same parent - tests tree connector logic
        tasks = [
          {
            id: "v.0.9.0+task.203.01",
            task_number: "203.01",
            release: "v.0.9.0",
            title: "First orphan subtask",
            status: "pending",
            parent_id: "203",
            path: ".ace-taskflow/v.0.9.0/tasks/203-task-enhance/203.01-first-subtask.s.md"
          },
          {
            id: "v.0.9.0+task.203.02",
            task_number: "203.02",
            release: "v.0.9.0",
            title: "Second orphan subtask",
            status: "pending",
            parent_id: "203",
            path: ".ace-taskflow/v.0.9.0/tasks/203-task-enhance/203.02-second-subtask.s.md"
          },
          {
            id: "v.0.9.0+task.203.03",
            task_number: "203.03",
            release: "v.0.9.0",
            title: "Third orphan subtask",
            status: "pending",
            parent_id: "203",
            path: ".ace-taskflow/v.0.9.0/tasks/203-task-enhance/203.03-third-subtask.s.md"
          }
        ]

        # Mock manager to return parent task when asked
        parent_task = build_parent_task(
          id: 203,
          title: "Parent Orchestrator Task",
          path: ".ace-taskflow/v.0.9.0/tasks/203-task-enhance/203-parent-task.s.md"
        )

        manager = command.task_manager
        manager.stub :show_task, parent_task do
          output = capture_stdout do
            command.send(:display_orphan_subtasks_with_context, tasks, [])
          end

          # Verify parent context is shown
          assert_includes output, "[context]", "Parent should be shown with context indicator"
          assert_includes output, "v.0.9.0+task.203", "Parent reference should be shown"

          # Verify tree connectors: ├─ for non-last, └─ for last
          assert_includes output, "├─", "Non-last subtasks should have ├─ connector"
          assert_includes output, "└─", "Last subtask should have └─ connector"

          # Count occurrences to verify correct connector usage
          branch_count = output.scan("├─").count
          end_count = output.scan("└─").count
          assert_equal 2, branch_count, "Should have 2 branch connectors (├─) for first two subtasks"
          assert_equal 1, end_count, "Should have 1 end connector (└─) for last subtask"

          # Verify all subtasks are present
          assert_includes output, "203.01", "First subtask should be shown"
          assert_includes output, "203.02", "Second subtask should be shown"
          assert_includes output, "203.03", "Third subtask should be shown"
        end
      end
    end
  end

  def test_parent_context_line_without_orchestrator_marker
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Parent task that is NOT an orchestrator
        parent_data = {
          id: "v.0.9.0+task.202",
          task_number: "202",
          release: "v.0.9.0",
          title: "Regular Parent Task",
          status: "pending",
          is_orchestrator: false  # Not an orchestrator
        }

        output = capture_stdout do
          command.send(:display_parent_context_line, parent_data)
        end

        # Verify context indicator appears
        assert_includes output, "[context]", "Context indicator should be shown"
        # Verify NO orchestrator marker
        refute_includes output, "(Orchestrator)", "Should NOT show Orchestrator marker for non-orchestrator"
        assert_includes output, "Regular Parent Task", "Parent title should be shown"
      end
    end
  end

  def test_parent_context_not_counted_in_results
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::TasksCommand.new

        # Task list with 1 orphan subtask (parent not in list)
        tasks = [
          {
            id: "v.0.9.0+task.203",
            task_number: "203",
            release: "v.0.9.0",
            title: "Orphan subtask",
            status: "done",
            parent_id: "202",  # Parent not in results
            path: ".ace-taskflow/v.0.9.0/tasks/203-task-enhance/203-show-parent-context-for-orphan-subtasks.s.md"
          }
        ]

        # Mock manager to return parent task
        parent_task = build_parent_task(
          id: 202,
          title: "Parent Orchestrator",
          path: ".ace-taskflow/v.0.9.0/tasks/202-task-refactor/202-rename-support-gems.s.md"
        )

        manager = command.task_manager
        manager.stub :show_task, parent_task do
          output = capture_stdout do
            command.send(:display_orphan_subtasks_with_context, tasks, [])
          end

          # Verify parent context is shown
          assert_includes output, "[context]", "Parent should be shown with context indicator"
          assert_includes output, "v.0.9.0+task.202", "Parent reference should be shown"
          assert_includes output, "v.0.9.0+task.203", "Orphan subtask reference should be shown"

          # Verify that only the subtask count matters, not the parent context
          # The parent context is displayed but not counted as a result
          # This is verified by checking the output contains 1 task line with tree connector
          assert_includes output, "└─", "Subtask should have tree connector"
          # Count non-empty lines to verify parent doesn't inflate count
          lines = output.lines.map(&:strip).reject(&:empty?)
          # Should have: parent task line (2 lines: task + path) + subtask line = 3 lines
          # But the "count" of tasks is still 1 (just the subtask)
          assert_equal 3, lines.size, "Should show parent context (2 lines) + 1 subtask line"
          # The key verification: only 1 subtask is displayed, parent is marked as [context]
          assert_equal 1, output.scan("└─").size, "Should have exactly 1 subtask"
        end
      end
    end
  end
end
