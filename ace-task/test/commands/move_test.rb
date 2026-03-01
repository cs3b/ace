# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "tmpdir"

class MoveCommandTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-move-cmd-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    @tasks_dir = File.join(@tmpdir, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_dir)

    # Create a task
    @task_id = "8pp.t.q7w"
    @task_dir = File.join(@tasks_dir, "8pp.t.q7w-fix-login")
    FileUtils.mkdir_p(@task_dir)
    File.write(File.join(@task_dir, "8pp.t.q7w-fix-login.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: pending
      ---

      # Fix Login Bug
    CONTENT
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_move_to_archive
    output = capture_io do
      Ace::Task::TaskCLI.start(["move", "q7w", "--to", "archive"])
    end.first

    assert_match(/Task moved.*archive/, output)
    assert Dir.exist?(File.join(@tasks_dir, "_archive"))
  end

  def test_move_to_maybe
    output = capture_io do
      Ace::Task::TaskCLI.start(["move", "q7w", "--to", "maybe"])
    end.first

    assert_match(/Task moved.*maybe/, output)
  end

  def test_move_not_found_raises_error
    assert_raises(Ace::Core::CLI::Error) do
      capture_io do
        Ace::Task::TaskCLI.start(["move", "xxx", "--to", "archive"])
      end
    end
  end
end
