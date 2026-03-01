# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TaskLoaderTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-loader-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_loads_task_from_directory
    task_dir = File.join(@tmpdir, "8pp.t.q7w-fix-login")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "8pp.t.q7w-fix-login.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: pending
      ---

      # Fix Login Bug

      Something is broken.
    CONTENT

    loader = Ace::Task::Molecules::TaskLoader.new
    task = loader.load(task_dir, id: "8pp.t.q7w")

    assert_equal "8pp.t.q7w", task.id
    assert_equal "pending", task.status
    assert_equal "Fix Login Bug", task.title
    assert task.content.include?("Something is broken")
  end

  def test_returns_nil_for_empty_directory
    empty_dir = File.join(@tmpdir, "empty")
    FileUtils.mkdir_p(empty_dir)

    loader = Ace::Task::Molecules::TaskLoader.new
    task = loader.load(empty_dir, id: "8pp.t.q7w")

    assert_nil task
  end

  def test_loads_with_special_folder
    task_dir = File.join(@tmpdir, "8pp.t.q7w-archived")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "8pp.t.q7w-archived.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: done
      ---

      # Archived Task
    CONTENT

    loader = Ace::Task::Molecules::TaskLoader.new
    task = loader.load(task_dir, id: "8pp.t.q7w", special_folder: "_archive")

    assert_equal "_archive", task.special_folder
  end

  def test_loads_all_model_fields
    task_dir = File.join(@tmpdir, "8pp.t.q7w-fix-login")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "8pp.t.q7w-fix-login.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: in-progress
      priority: high
      estimate: 2h
      dependencies: [8pp.t.abc]
      tags: [auth, ui]
      ---

      # Fix Login Bug
    CONTENT

    loader = Ace::Task::Molecules::TaskLoader.new
    task = loader.load(task_dir, id: "8pp.t.q7w")

    assert_equal "in-progress", task.status
    assert_equal "high", task.priority
    assert_equal "2h", task.estimate
    assert_equal ["8pp.t.abc"], task.dependencies
    assert_equal ["auth", "ui"], task.tags
    assert_nil task.parent_id
    assert_equal [], task.subtasks
  end

  def test_loads_with_default_priority
    task_dir = File.join(@tmpdir, "8pp.t.q7w-fix-login")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "8pp.t.q7w-fix-login.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: pending
      ---

      # Task
    CONTENT

    loader = Ace::Task::Molecules::TaskLoader.new
    task = loader.load(task_dir, id: "8pp.t.q7w")

    assert_equal "medium", task.priority
    assert_equal [], task.dependencies
    assert_equal [], task.tags
  end

  def test_loads_subtask_with_parent_id
    task_dir = File.join(@tmpdir, "8pp.t.q7w.a-setup-db")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "8pp.t.q7w.a-setup-db.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w.a
      status: pending
      parent: 8pp.t.q7w
      ---

      # Setup Database
    CONTENT

    loader = Ace::Task::Molecules::TaskLoader.new
    task = loader.load(task_dir, id: "8pp.t.q7w.a")

    assert_equal "8pp.t.q7w", task.parent_id
    assert task.subtask?
  end

  def test_detects_subtask_dirs_in_parent
    # Create parent with subtask directories
    task_dir = File.join(@tmpdir, "8pp.t.q7w-fix-login")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "8pp.t.q7w-fix-login.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: pending
      ---

      # Fix Login
    CONTENT

    # Create subtask directory inside parent
    subtask_dir = File.join(task_dir, "8pp.t.q7w.a-setup-db")
    FileUtils.mkdir_p(subtask_dir)
    File.write(File.join(subtask_dir, "8pp.t.q7w.a-setup-db.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w.a
      status: pending
      parent: 8pp.t.q7w
      ---

      # Setup Database
    CONTENT

    loader = Ace::Task::Molecules::TaskLoader.new
    task = loader.load(task_dir, id: "8pp.t.q7w")

    assert task.has_subtasks?
    assert_equal 1, task.subtasks.length
    assert_equal "8pp.t.q7w.a", task.subtasks.first.id
    assert_equal "Setup Database", task.subtasks.first.title
  end

  def test_subtask_loading_can_be_disabled
    task_dir = File.join(@tmpdir, "8pp.t.q7w-fix-login")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "8pp.t.q7w-fix-login.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w
      status: pending
      ---

      # Fix Login
    CONTENT

    subtask_dir = File.join(task_dir, "8pp.t.q7w.a-setup-db")
    FileUtils.mkdir_p(subtask_dir)
    File.write(File.join(subtask_dir, "8pp.t.q7w.a-setup-db.s.md"), <<~CONTENT)
      ---
      id: 8pp.t.q7w.a
      status: pending
      parent: 8pp.t.q7w
      ---

      # Setup Database
    CONTENT

    loader = Ace::Task::Molecules::TaskLoader.new
    task = loader.load(task_dir, id: "8pp.t.q7w", load_subtasks: false)

    assert_equal [], task.subtasks
  end
end
