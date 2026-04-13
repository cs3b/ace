# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "tmpdir"

class StatusCommandTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-status-cmd-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    @tasks_dir = File.join(@tmpdir, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_status_shows_up_next_section
    create_fixture_task("8pp.t.a1a", "First Task", status: "pending")
    create_fixture_task("8pp.t.b2b", "Second Task", status: "pending")

    output = capture_io do
      Ace::Task::TaskCLI.start(["status"])
    end.first

    assert_match(/Up Next:/, output)
    assert_match(/First Task/, output)
    assert_match(/Second Task/, output)
  end

  def test_status_shows_stats_line
    create_fixture_task("8pp.t.a1a", "Pending Task", status: "pending")
    create_fixture_task("8pp.t.b2b", "Done Task", status: "done")

    output = capture_io do
      Ace::Task::TaskCLI.start(["status"])
    end.first

    assert_match(/Tasks:.*total/, output)
  end

  def test_status_shows_recently_done_section
    create_fixture_task("8pp.t.a1a", "Completed Task", status: "done")

    output = capture_io do
      Ace::Task::TaskCLI.start(["status"])
    end.first

    assert_match(/Recently Done:/, output)
    assert_match(/Completed Task/, output)
    assert_match(/\((?:just now|\d+\w+ ago)\)/, output)
  end

  def test_status_up_next_excludes_special_folder_tasks
    create_fixture_task("8pp.t.a1a", "Root Task", status: "pending")
    maybe_dir = File.join(@tasks_dir, "_maybe")
    create_fixture_task("8pp.t.b2b", "Maybe Task", status: "pending", root: maybe_dir)

    output = capture_io do
      Ace::Task::TaskCLI.start(["status"])
    end.first

    # Up Next section should only have root task
    up_next_section = output.split("Tasks:").first
    assert_match(/Root Task/, up_next_section)
    refute_match(/Maybe Task/, up_next_section)
  end

  def test_status_up_next_limit_from_cli_option
    create_fixture_task("8pp.t.a1a", "Task One", status: "pending")
    create_fixture_task("8pp.t.b2b", "Task Two", status: "pending")
    create_fixture_task("8pp.t.c3c", "Task Three", status: "pending")

    output = capture_io do
      Ace::Task::TaskCLI.start(["status", "--up-next-limit", "1"])
    end.first

    up_next_section = output.split("Tasks:").first
    assert_match(/Task One/, up_next_section)
    refute_match(/Task Three/, up_next_section)
  end

  def test_status_recently_done_limit_from_cli_option
    3.times do |i|
      create_fixture_task("8pp.t.d#{i}d", "Done Task #{i}", status: "done")
    end

    output = capture_io do
      Ace::Task::TaskCLI.start(["status", "--recently-done-limit", "1"])
    end.first

    done_section = output.split("Recently Done:").last
    # Only 1 done task should appear
    done_lines = done_section.lines.select { |l| l.include?("Done Task") }
    assert_equal 1, done_lines.length
  end

  def test_status_empty_shows_none_messages
    output = capture_io do
      Ace::Task::TaskCLI.start(["status"])
    end.first

    assert_match(/Up Next:/, output)
    assert_match(/\(none\)/, output)
    assert_match(/Recently Done:/, output)
  end

  def test_status_recently_done_includes_archive_tasks
    create_fixture_task("8pp.t.a1a", "Root Done", status: "done")
    archive_dir = File.join(@tasks_dir, "_archive")
    create_fixture_task("8pp.t.b2b", "Archived Done", status: "done", root: archive_dir)

    output = capture_io do
      Ace::Task::TaskCLI.start(["status"])
    end.first

    done_section = output.split("Recently Done:").last
    assert_match(/Root Done/, done_section)
    assert_match(/Archived Done/, done_section)
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
