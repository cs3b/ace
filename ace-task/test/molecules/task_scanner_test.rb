# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TaskScannerTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-scanner-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_scan_finds_primary_task_folders
    create_task_folder("8pp.t.q7w-fix-login")
    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)

    results = scanner.scan
    assert_equal 1, results.length
    assert_equal "8pp.t.q7w", results.first.id
  end

  def test_scan_excludes_subtask_folders
    create_task_folder("8pp.t.q7w-fix-login")
    create_task_folder("8pp.t.q7w.a-setup-db")

    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)
    results = scanner.scan

    assert_equal 1, results.length
    assert_equal "8pp.t.q7w", results.first.id
  end

  def test_scan_all_includes_subtask_folders
    create_task_folder("8pp.t.q7w-fix-login")
    create_task_folder("8pp.t.q7w.a-setup-db")

    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)
    results = scanner.scan_all

    assert_equal 2, results.length
  end

  def test_scan_subtasks_finds_children
    parent_dir = create_task_folder("8pp.t.q7w-fix-login")
    create_subtask_folder(parent_dir, "8pp.t.q7w.a-setup-db")
    create_subtask_folder(parent_dir, "8pp.t.q7w.b-run-tests")

    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)
    results = scanner.scan_subtasks(parent_dir, parent_id: "8pp.t.q7w")

    assert_equal 2, results.length
    assert_equal "8pp.t.q7w.a", results[0].id
    assert_equal "8pp.t.q7w.b", results[1].id
  end

  def test_scan_subtasks_ignores_unrelated_folders
    parent_dir = create_task_folder("8pp.t.q7w-fix-login")
    create_subtask_folder(parent_dir, "8pp.t.q7w.a-setup-db")
    # Create an unrelated folder inside parent
    other = File.join(parent_dir, "notes")
    FileUtils.mkdir_p(other)
    File.write(File.join(other, "notes.s.md"), "---\nid: notes\n---\n")

    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)
    results = scanner.scan_subtasks(parent_dir, parent_id: "8pp.t.q7w")

    assert_equal 1, results.length
    assert_equal "8pp.t.q7w.a", results.first.id
  end

  def test_scan_subtasks_returns_empty_for_no_subtasks
    parent_dir = create_task_folder("8pp.t.q7w-fix-login")
    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)
    results = scanner.scan_subtasks(parent_dir, parent_id: "8pp.t.q7w")
    assert_empty results
  end

  def test_scan_in_special_folder
    maybe_dir = File.join(@tmpdir, "_maybe")
    FileUtils.mkdir_p(maybe_dir)
    create_task_in_dir(maybe_dir, "8pp.t.q7w-fix-login")

    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)
    results = scanner.scan

    assert_equal 1, results.length
    assert_equal "_maybe", results.first.special_folder
  end

  def test_root_exists_returns_false_for_missing_dir
    scanner = Ace::Task::Molecules::TaskScanner.new("/nonexistent/dir")
    refute scanner.root_exists?
  end

  private

  def create_task_folder(folder_name, root: @tmpdir)
    path = File.join(root, folder_name)
    FileUtils.mkdir_p(path)
    File.write(File.join(path, "#{folder_name}.s.md"), "---\nid: #{folder_name.split("-").first}\nstatus: pending\n---\n")
    path
  end

  def create_task_in_dir(dir, folder_name)
    path = File.join(dir, folder_name)
    FileUtils.mkdir_p(path)
    File.write(File.join(path, "#{folder_name}.s.md"), "---\nid: #{folder_name.split("-").first}\nstatus: pending\n---\n")
    path
  end

  def create_subtask_folder(parent_dir, folder_name)
    path = File.join(parent_dir, folder_name)
    FileUtils.mkdir_p(path)
    File.write(File.join(path, "#{folder_name}.s.md"), "---\nid: #{folder_name.split("-").first}\nstatus: pending\n---\n")
    path
  end
end
