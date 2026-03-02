# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "tmpdir"

class CreateCommandTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-create-cmd-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_create_outputs_task_id
    output = capture_io do
      Ace::Task::TaskCLI.start(["create", "Fix login bug"])
    end.first

    assert_match(/Created task [0-9a-z]{3}\.t\.[0-9a-z]{3}/, output)
    assert_match(/Path:/, output)
  end

  def test_create_dry_run_does_not_write
    output = capture_io do
      Ace::Task::TaskCLI.start(["create", "Dry run task", "--dry-run"])
    end.first

    assert_match(/Would create task/, output)
    assert_match(/Title:.*Dry run task/, output)
    refute Dir.exist?(File.join(@tmpdir, ".ace-tasks"))
  end

  def test_create_dry_run_with_options
    output = capture_io do
      Ace::Task::TaskCLI.start(["create", "Test task", "--dry-run", "--priority", "high", "--tags", "auth,security"])
    end.first

    assert_match(/Would create task/, output)
    assert_match(/Priority: high/, output)
    assert_match(/Tags:.*auth/, output)
  end

  def test_create_creates_directory_structure
    capture_io do
      Ace::Task::TaskCLI.start(["create", "Real task"])
    end

    tasks_dir = File.join(@tmpdir, ".ace-tasks")
    assert Dir.exist?(tasks_dir)

    # Should have one task directory
    entries = Dir.entries(tasks_dir).reject { |e| e.start_with?(".") }
    assert_equal 1, entries.length
    assert entries.first.match?(/^[0-9a-z]{3}\.t\.[0-9a-z]{3}-real-task$/)
  end

  def test_create_with_priority_and_tags
    output = capture_io do
      Ace::Task::TaskCLI.start(["create", "Important bug", "--priority", "high", "--tags", "bug,critical"])
    end.first

    assert_match(/Created task/, output)

    # Find the created task file and verify frontmatter
    tasks_dir = File.join(@tmpdir, ".ace-tasks")
    task_dirs = Dir.entries(tasks_dir).reject { |e| e.start_with?(".") }
    task_dir = File.join(tasks_dir, task_dirs.first)
    spec_file = Dir.glob(File.join(task_dir, "*.s.md")).first
    content = File.read(spec_file)

    assert_match(/priority: high/, content)
    assert_match(/bug/, content)
    assert_match(/critical/, content)
  end

  def test_create_with_git_commit_calls_committer
    commit_args = nil
    Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**kwargs) { commit_args = kwargs; true }) do
      capture_io do
        Ace::Task::TaskCLI.start(["create", "Git commit task", "--git-commit"])
      end
    end

    refute_nil commit_args, "Expected GitCommitter.commit to be called"
    assert_equal 1, commit_args[:paths].length
    assert_match(/\.ace-tasks/, commit_args[:paths].first)
    assert_match(/create task/, commit_args[:intention])
  end

  def test_create_without_git_commit_does_not_call_committer
    commit_called = false
    Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**_kwargs) { commit_called = true }) do
      capture_io do
        Ace::Task::TaskCLI.start(["create", "No commit task"])
      end
    end

    refute commit_called, "Expected GitCommitter.commit NOT to be called"
  end

  def test_create_dry_run_with_git_commit_does_not_call_committer
    commit_called = false
    Ace::Support::Items::Molecules::GitCommitter.stub(:commit, ->(**_kwargs) { commit_called = true }) do
      capture_io do
        Ace::Task::TaskCLI.start(["create", "Dry run gc task", "--dry-run", "--git-commit"])
      end
    end

    refute commit_called, "Expected GitCommitter.commit NOT to be called during dry-run"
  end
end
