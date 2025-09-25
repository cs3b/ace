# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/task_command"

class TaskCommandTest < AceTaskflowTestCase
  def setup
    @command = Ace::Taskflow::Commands::TaskCommand.new
  end

  def test_next_task_selection
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute([])
        end

        # Should select the first pending task
        assert_match(/v\.0\.9\.0\+task\.003/, output)
        assert_match(/pending/, output)
      end
    end
  end

  def test_next_task_with_no_pending_tasks
    with_test_project do |dir|
      # Mark all tasks as done
      Dir.glob(File.join(dir, "**", "*.md")).each do |file|
        content = File.read(file)
        if content.include?("status:")
          File.write(file, content.gsub(/status: \w+/, "status: done"))
        end
      end

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute
        end

        assert_match(/No pending tasks found/, output)
      end
    end
  end

  def test_show_specific_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["001"])
        end

        assert_match(/v\.0\.9\.0\+task\.001/, output)
        assert_match(/done/, output)
      end
    end
  end

  def test_show_task_with_content_flag
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["001", "--content"])
        end

        assert_match(/Sample Task/, output)
        assert_match(/Planning Steps/, output)
        assert_match(/Execution Steps/, output)
      end
    end
  end

  def test_show_task_with_path_flag
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["001", "--path"])
        end

        assert_match(%r{v\.0\.9\.0/t/001/task\.md}, output)
        refute_match(/Sample Task/, output)
      end
    end
  end

  def test_create_new_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["create", "New test task"])
        end

        assert_match(/Created task/, output)
        assert_match(/v\.0\.9\.0\+task\.006/, output)

        # Verify file was created
        task_file = File.join(dir, "v.0.9.0", "t", "006", "new-test-task.md")
        assert File.exist?(task_file)

        content = File.read(task_file)
        assert_match(/New test task/, content)
        assert_match(/status: pending/, content)
      end
    end
  end

  def test_create_task_in_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["create", "Backlog task", "--backlog"])
        end

        assert_match(/Created task/, output)
        assert_match(/backlog\+task\.011/, output)

        # Verify file was created in backlog
        task_file = Dir.glob(File.join(dir, "backlog", "t", "011", "*.md")).first
        assert task_file
        assert File.exist?(task_file)
      end
    end
  end

  def test_start_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["start", "003"])
        end

        assert_match(/Started task/, output)
        assert_match(/v\.0\.9\.0\+task\.003/, output)

        # Verify status was updated
        task_file = File.join(dir, "v.0.9.0", "t", "003", "task.md")
        content = File.read(task_file)
        assert_match(/status: in-progress/, content)
      end
    end
  end

  def test_complete_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["done", "002"])
        end

        assert_match(/Completed task/, output)
        assert_match(/v\.0\.9\.0\+task\.002/, output)

        # Verify status was updated
        task_file = File.join(dir, "v.0.9.0", "t", "002", "task.md")
        content = File.read(task_file)
        assert_match(/status: done/, content)
      end
    end
  end

  def test_move_task_to_different_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["move", "003", "v.0.8.0"])
        end

        assert_match(/Moved task/, output)
        assert_match(/v\.0\.8\.0\+task\.004/, output)

        # Verify old file doesn't exist
        old_file = File.join(dir, "v.0.9.0", "t", "003", "task.md")
        refute File.exist?(old_file)

        # Verify new file exists
        new_file = File.join(dir, "v.0.8.0", "t", "004", "task.md")
        assert File.exist?(new_file)
      end
    end
  end

  def test_invalid_task_reference
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["999"])
        end

        assert_match(/Task not found/, output)
      end
    end
  end

  def test_next_task_with_blocked_tasks
    with_test_project do |dir|
      # Mark task 003 as blocked
      task_file = File.join(dir, "v.0.9.0", "t", "003", "task.md")
      content = File.read(task_file)
      File.write(task_file, content.gsub(/status: pending/, "status: blocked"))

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute
        end

        # Should skip blocked task and select next pending
        assert_match(/v\.0\.9\.0\+task\.004/, output)
      end
    end
  end

  def test_task_with_qualified_reference
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["v.0.8.0+001"])
        end

        assert_match(/v\.0\.8\.0\+task\.001/, output)
      end
    end
  end

  def test_task_with_current_reference
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["current+002"])
        end

        assert_match(/v\.0\.9\.0\+task\.002/, output)
      end
    end
  end

  def test_task_dependencies_check
    with_test_project do |dir|
      # Add dependencies to task 004
      task_file = File.join(dir, "v.0.9.0", "t", "004", "task.md")
      content = File.read(task_file)
      File.write(task_file, content.gsub(/dependencies: \[\]/, "dependencies: [v.0.9.0+task.003]"))

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["004"])
        end

        assert_match(/Dependencies/, output)
        assert_match(/v\.0\.9\.0\+task\.003/, output)
      end
    end
  end
end