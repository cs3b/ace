# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "tmpdir"

class UpdateCommandTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-update-cmd-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    @tasks_dir = File.join(@tmpdir, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_dir)

    # Create a task
    @task_dir = File.join(@tasks_dir, "8pp.t.q7w-fix-login")
    FileUtils.mkdir_p(@task_dir)
    @task_file = File.join(@task_dir, "8pp.t.q7w-fix-login.s.md")
    File.write(@task_file, <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: pending
      priority: medium
      tags:
        - auth
      ---

      # Fix Login Bug
    CONTENT
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_update_set_status
    output = capture_io do
      Ace::Task::TaskCLI.start(["update", "q7w", "--set", "status=done"])
    end.first

    assert_match(/Task updated/, output)

    content = File.read(@task_file)
    assert_match(/status: done/, content)
  end

  def test_update_set_multiple_fields
    output = capture_io do
      Ace::Task::TaskCLI.start(["update", "q7w", "--set", "status=done,priority=high"])
    end.first

    assert_match(/Task updated/, output)

    content = File.read(@task_file)
    assert_match(/status: done/, content)
    assert_match(/priority: high/, content)
  end

  def test_update_add_tag
    output = capture_io do
      Ace::Task::TaskCLI.start(["update", "q7w", "--add", "tags=security"])
    end.first

    assert_match(/Task updated/, output)

    content = File.read(@task_file)
    assert_match(/security/, content)
    assert_match(/auth/, content)
  end

  def test_update_remove_tag
    output = capture_io do
      Ace::Task::TaskCLI.start(["update", "q7w", "--remove", "tags=auth"])
    end.first

    assert_match(/Task updated/, output)

    content = File.read(@task_file)
    refute_match(/- auth/, content)
  end

  def test_update_no_operations_raises_error
    assert_raises(Ace::Core::CLI::Error) do
      capture_io do
        Ace::Task::TaskCLI.start(["update", "q7w"])
      end
    end
  end

  def test_update_not_found_raises_error
    assert_raises(Ace::Core::CLI::Error) do
      capture_io do
        Ace::Task::TaskCLI.start(["update", "xxx", "--set", "status=done"])
      end
    end
  end
end
