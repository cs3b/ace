# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "tmpdir"

class ListCommandTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-list-cmd-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    @tasks_dir = File.join(@tmpdir, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_dir)

    # Create two tasks
    create_fixture_task("8pp.t.q7w", "Fix Login Bug", status: "pending", priority: "high", tags: ["auth", "security"])
    create_fixture_task("8pp.t.r8x", "Add Dark Mode", status: "done", priority: "medium", tags: ["ui"])
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_list_defaults_to_root_tasks_only
    # Create a task in _maybe/ — should NOT appear in default list
    maybe_dir = File.join(@tasks_dir, "_maybe")
    create_fixture_task("8pp.t.s9y", "Maybe Task", status: "pending", root: maybe_dir)

    output = capture_io do
      Ace::Task::TaskCLI.start(["list"])
    end.first

    assert_match(/Fix Login Bug/, output)
    assert_match(/Add Dark Mode/, output)
    refute_match(/Maybe Task/, output)
  end

  def test_list_in_all_shows_everything
    # Create a task in _maybe/
    maybe_dir = File.join(@tasks_dir, "_maybe")
    create_fixture_task("8pp.t.s9y", "Maybe Task", status: "pending", root: maybe_dir)

    output = capture_io do
      Ace::Task::TaskCLI.start(["list", "--in", "all"])
    end.first

    assert_match(/Fix Login Bug/, output)
    assert_match(/Add Dark Mode/, output)
    assert_match(/Maybe Task/, output)
  end

  def test_list_filter_by_status
    output = capture_io do
      Ace::Task::TaskCLI.start(["list", "--status", "pending"])
    end.first

    assert_match(/Fix Login Bug/, output)
    refute_match(/Add Dark Mode/, output)
  end

  def test_list_filter_by_tags
    output = capture_io do
      Ace::Task::TaskCLI.start(["list", "--tags", "ui"])
    end.first

    refute_match(/Fix Login Bug/, output)
    assert_match(/Add Dark Mode/, output)
  end

  def test_list_filter_by_folder
    # Create a task in _maybe/
    maybe_dir = File.join(@tasks_dir, "_maybe")
    create_fixture_task("8pp.t.s9y", "Maybe Task", status: "pending", root: maybe_dir)

    output = capture_io do
      Ace::Task::TaskCLI.start(["list", "--in", "maybe"])
    end.first

    assert_match(/Maybe Task/, output)
    refute_match(/Fix Login Bug/, output)
  end

  def test_list_empty_shows_message
    FileUtils.rm_rf(@tasks_dir)
    FileUtils.mkdir_p(@tasks_dir)

    output = capture_io do
      Ace::Task::TaskCLI.start(["list"])
    end.first

    assert_match(/No tasks found/, output)
  end

  def test_list_shows_stats_line
    output = capture_io do
      Ace::Task::TaskCLI.start(["list"])
    end.first

    assert_match(/Tasks:.*total/, output)
  end

  def test_list_stats_reflects_filtered_items
    output = capture_io do
      Ace::Task::TaskCLI.start(["list", "--status", "pending"])
    end.first

    assert_match(/Tasks: ○ 1 • 1 total/, output)
  end

  private

  def create_fixture_task(id, title, status: "pending", priority: "medium", tags: [], root: nil)
    slug = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "")
    dir_name = "#{id}-#{slug}"
    base = root || @tasks_dir
    FileUtils.mkdir_p(base)
    dir_path = File.join(base, dir_name)
    FileUtils.mkdir_p(dir_path)

    tags_yaml = if tags.any?
      "\ntags:\n" + tags.map { |t| "  - #{t}" }.join("\n")
    else
      ""
    end

    content = <<~CONTENT
      ---
      id: #{id}
      status: #{status}
      priority: #{priority}#{tags_yaml}
      ---

      # #{title}
    CONTENT
    File.write(File.join(dir_path, "#{dir_name}.s.md"), content)
  end
end
