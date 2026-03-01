# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "tmpdir"

class ShowCommandTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-show-cmd-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    # Create a task first
    @tasks_dir = File.join(@tmpdir, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_dir)

    @task_dir = File.join(@tasks_dir, "8pp.t.q7w-fix-login")
    FileUtils.mkdir_p(@task_dir)
    File.write(File.join(@task_dir, "8pp.t.q7w-fix-login.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: pending
      ---

      # Fix Login Bug

      The login form is broken.
    CONTENT
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_show_by_full_id
    output = capture_io do
      Ace::Task::TaskCLI.start(["show", "8pp.t.q7w"])
    end.first

    assert_match(/8pp\.t\.q7w/, output)
    assert_match(/Fix Login Bug/, output)
    assert_match(/pending/, output)
  end

  def test_show_by_suffix_shortcut
    output = capture_io do
      Ace::Task::TaskCLI.start(["show", "q7w"])
    end.first

    assert_match(/8pp\.t\.q7w/, output)
  end

  def test_show_by_short_ref
    output = capture_io do
      Ace::Task::TaskCLI.start(["show", "t.q7w"])
    end.first

    assert_match(/8pp\.t\.q7w/, output)
  end

  def test_show_path_option
    output = capture_io do
      Ace::Task::TaskCLI.start(["show", "q7w", "--path"])
    end.first

    assert output.strip.end_with?(".s.md")
  end

  def test_show_content_option
    output = capture_io do
      Ace::Task::TaskCLI.start(["show", "q7w", "--content"])
    end.first

    assert_match(/# Fix Login Bug/, output)
    assert_match(/The login form is broken/, output)
  end

  def test_show_tree_option
    output = capture_io do
      Ace::Task::TaskCLI.start(["show", "q7w", "--tree"])
    end.first

    assert_match(/8pp\.t\.q7w/, output)
    assert_match(/Fix Login Bug/, output)
  end

  def test_show_not_found_raises_error
    assert_raises(Ace::Core::CLI::Error) do
      capture_io do
        Ace::Task::TaskCLI.start(["show", "xxx"])
      end
    end
  end
end
