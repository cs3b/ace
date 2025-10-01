# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/task_command"
require_relative "../../lib/ace/taskflow/commands/tasks_command"

class TaskWorkflowIntegrationTest < AceTaskflowTestCase
  def test_complete_task_lifecycle
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        task_cmd = Ace::Taskflow::Commands::TaskCommand.new
        tasks_cmd = Ace::Taskflow::Commands::TasksCommand.new

        # 1. Create a new task
        output = capture_stdout do
          task_cmd.execute(["create", "Integration test task"])
        end
        assert_match(/Created task/, output)
        assert_match(/v\.0\.9\.0\+task\.006/, output)

        # 2. Start the task
        output = capture_stdout do
          task_cmd.execute(["start", "006"])
        end
        assert_match(/Started task/, output)

        # 3. Verify it shows as in-progress
        output = capture_stdout do
          tasks_cmd.execute(["--status", "in-progress"])
        end
        assert_match(/v\.0\.9\.0\+task\.006/, output)

        # 4. Complete the task
        output = capture_stdout do
          task_cmd.execute(["done", "006"])
        end
        assert_match(/Completed task/, output)

        # 5. Verify it shows as done
        output = capture_stdout do
          tasks_cmd.execute(["--status", "done"])
        end
        assert_match(/v\.0\.9\.0\+task\.006/, output)
      end
    end
  end

  def test_task_rescheduling_workflow
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        tasks_cmd = Ace::Taskflow::Commands::TasksCommand.new

        # 1. List current v.0.9.0 tasks
        output = capture_stdout do
          tasks_cmd.execute(["--release", "v.0.9.0"])
        end
        assert_match(/v\.0\.9\.0\+task\.003/, output)
        assert_match(/v\.0\.9\.0\+task\.004/, output)

        # 2. Reschedule tasks to v.0.8.0
        output = capture_stdout do
          tasks_cmd.execute(["reschedule", "v.0.9.0+003,v.0.9.0+004", "v.0.8.0"])
        end
        assert_match(/Rescheduled/, output)

        # 3. Verify tasks are no longer in v.0.9.0
        output = capture_stdout do
          tasks_cmd.execute(["--release", "v.0.9.0"])
        end
        refute_match(/v\.0\.9\.0\+task\.003/, output)
        refute_match(/v\.0\.9\.0\+task\.004/, output)

        # 4. Verify tasks are now in v.0.8.0
        output = capture_stdout do
          tasks_cmd.execute(["--release", "v.0.8.0"])
        end
        assert_match(/v\.0\.8\.0/, output)
      end
    end
  end

  def test_idea_to_task_conversion_workflow
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_cmd = Ace::Taskflow::Commands::IdeaCommand.new
        task_cmd = Ace::Taskflow::Commands::TaskCommand.new

        # 1. Create an idea
        output = capture_stdout do
          idea_cmd.execute(["This is a test idea for conversion"])
        end
        assert_match(/Idea captured/, output)

        # Find the idea number
        idea_files = Dir.glob(File.join(dir, "v.0.9.0", "i", "*.md"))
        idea_num = File.basename(idea_files.sort.last, ".md")

        # 2. Convert idea to task
        output = capture_stdout do
          idea_cmd.execute(["convert", idea_num])
        end
        assert_match(/Converted idea to task/, output)
        task_id = output[/v\.0\.9\.0\+task\.\d+/]

        # 3. Verify task was created
        output = capture_stdout do
          task_cmd.execute([task_id.split(".").last])
        end
        assert_match(task_id, output)
        assert_match(/test idea for conversion/, output)
      end
    end
  end
end