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

  def test_update_move_to_archive
    output = capture_io do
      Ace::Task::TaskCLI.start(["update", "q7w", "--move-to", "archive"])
    end.first

    assert_match(/Task updated.*archive/, output)
    assert Dir.exist?(File.join(@tasks_dir, "_archive"))
  end

  def test_update_set_and_move_to
    output = capture_io do
      Ace::Task::TaskCLI.start(["update", "q7w", "--set", "status=done", "--move-to", "archive"])
    end.first

    assert_match(/Task updated.*archive/, output)
    # Verify status was updated
    spec_files = Dir.glob(File.join(@tasks_dir, "_archive", "**", "*.s.md"))
    assert_equal 1, spec_files.length
    content = File.read(spec_files.first)
    assert_match(/status: done/, content)
  end

  def test_update_move_to_next
    # First move to maybe
    capture_io do
      Ace::Task::TaskCLI.start(["update", "q7w", "--move-to", "maybe"])
    end

    # Then move back to root via "next"
    output = capture_io do
      Ace::Task::TaskCLI.start(["update", "q7w", "--move-to", "next"])
    end.first

    assert_match(/Task updated.*root/, output)
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

  def test_update_with_git_commit_calls_committer
    commit_args = nil
    Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**kwargs) { commit_args = kwargs; true }) do
      capture_io do
        Ace::Task::TaskCLI.start(["update", "q7w", "--set", "status=done", "--git-commit"])
      end
    end

    refute_nil commit_args, "Expected GitCommitter.commit to be called"
    assert_equal 1, commit_args[:paths].length
    assert_match(/\.ace-tasks/, commit_args[:paths].first)
    assert_match(/update task/, commit_args[:intention])
  end

  def test_update_without_git_commit_does_not_call_committer
    commit_called = false
    Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**_kwargs) { commit_called = true }) do
      capture_io do
        Ace::Task::TaskCLI.start(["update", "q7w", "--set", "status=done"])
      end
    end

    refute commit_called, "Expected GitCommitter.commit NOT to be called"
  end
end
