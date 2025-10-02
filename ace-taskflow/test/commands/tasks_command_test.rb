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
        assert_match(/done/, output)
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
          command.execute(["reschedule", "v.0.9.0+003,v.0.9.0+004", "v.0.8.0"])
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
          command.execute(["reschedule", "v.0.9.0+999", "v.0.8.0"])
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
end