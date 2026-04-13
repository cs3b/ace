# frozen_string_literal: true

require "test_helper"
require "ace/task/molecules/task_doctor_fixer"

class TaskDoctorFixerTest < AceTaskTestCase
  Fixer = Ace::Task::Molecules::TaskDoctorFixer

  # --- can_fix? ---

  def test_can_fix_missing_status
    fixer = Fixer.new
    issue = {message: "Missing required field: status", location: "/tmp/test.md"}
    assert fixer.can_fix?(issue)
  end

  def test_can_fix_stale_backup
    fixer = Fixer.new
    issue = {message: "Stale backup file (safe to delete)", location: "/tmp/test.backup.md"}
    assert fixer.can_fix?(issue)
  end

  def test_cannot_fix_unknown_issue
    fixer = Fixer.new
    issue = {message: "Some unknown issue", location: "/tmp/test.md"}
    refute fixer.can_fix?(issue)
  end

  def test_cannot_fix_without_location
    fixer = Fixer.new
    issue = {message: "Missing required field: status"}
    refute fixer.can_fix?(issue)
  end

  # --- fix_missing_status (dry_run) ---

  def test_fix_missing_status_dry_run
    with_tasks_dir do |root|
      file = create_task_spec(root, "8pp.t.q7w", "fix-status", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        title: Test
        ---
      CONTENT

      fixer = Fixer.new(dry_run: true, root_dir: root)
      result = fixer.fix_issue({message: "Missing required field: status", location: file})
      assert result
      assert_equal 1, fixer.fixed_count

      # File should not be changed in dry-run
      content = File.read(file)
      refute_includes content, "status: pending"
    end
  end

  # --- fix_missing_status (real) ---

  def test_fix_missing_status_applies
    with_tasks_dir do |root|
      file = create_task_spec(root, "8pp.t.q7w", "fix-status", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        title: Test
        ---
      CONTENT

      fixer = Fixer.new(dry_run: false, root_dir: root)
      result = fixer.fix_issue({message: "Missing required field: status", location: file})
      assert result

      content = File.read(file)
      assert_includes content, "status"
    end
  end

  # --- fix_stale_backup ---

  def test_fix_stale_backup_deletes_file
    with_tasks_dir do |root|
      backup_file = File.join(root, "old.backup.md")
      File.write(backup_file, "old content")

      fixer = Fixer.new(dry_run: false, root_dir: root)
      result = fixer.fix_issue({message: "Stale backup file (safe to delete)", location: backup_file})
      assert result
      refute File.exist?(backup_file)
    end
  end

  def test_fix_stale_backup_dry_run_preserves_file
    with_tasks_dir do |root|
      backup_file = File.join(root, "old.backup.md")
      File.write(backup_file, "old content")

      fixer = Fixer.new(dry_run: true, root_dir: root)
      result = fixer.fix_issue({message: "Stale backup file (safe to delete)", location: backup_file})
      assert result
      assert File.exist?(backup_file)
    end
  end

  # --- fix_empty_directory ---

  def test_fix_empty_directory_removes_dir
    with_tasks_dir do |root|
      empty_dir = File.join(root, "empty")
      FileUtils.mkdir_p(empty_dir)

      fixer = Fixer.new(dry_run: false, root_dir: root)
      result = fixer.fix_issue({message: "Empty directory (safe to delete)", location: empty_dir})
      assert result
      refute Dir.exist?(empty_dir)
    end
  end

  def test_fix_empty_directory_skips_non_empty
    with_tasks_dir do |root|
      dir = File.join(root, "not-empty")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "file.txt"), "content")

      fixer = Fixer.new(dry_run: false, root_dir: root)
      result = fixer.fix_issue({message: "Empty directory (safe to delete)", location: dir})
      refute result
      assert Dir.exist?(dir)
    end
  end

  # --- fix_issues batch ---

  def test_fix_issues_returns_summary
    with_tasks_dir do |root|
      backup = File.join(root, "old.backup.md")
      File.write(backup, "content")

      issues = [
        {message: "Stale backup file (safe to delete)", location: backup},
        {message: "Unknown issue", location: "/tmp/unknown"}
      ]

      fixer = Fixer.new(dry_run: false, root_dir: root)
      results = fixer.fix_issues(issues)

      assert_equal 1, results[:fixed]
      assert_kind_of Array, results[:fixes_applied]
      assert_equal false, results[:dry_run]
    end
  end

  # --- fix_missing_id ---

  def test_fix_missing_id_extracts_from_folder
    with_tasks_dir do |root|
      file = create_task_spec(root, "8pp.t.q7w", "no-id-task", <<~CONTENT)
        ---
        status: pending
        title: Test
        ---
      CONTENT

      fixer = Fixer.new(dry_run: false, root_dir: root)
      result = fixer.fix_issue({message: "Missing required field: id", location: file})
      assert result

      content = File.read(file)
      assert_includes content, "8pp.t.q7w"
    end
  end

  # --- fix_missing_tags ---

  def test_fix_missing_tags
    with_tasks_dir do |root|
      file = create_task_spec(root, "8pp.t.q7w", "no-tags", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: pending
        title: Test
        ---
      CONTENT

      fixer = Fixer.new(dry_run: false, root_dir: root)
      result = fixer.fix_issue({message: "Missing recommended field: tags", location: file})
      assert result

      content = File.read(file)
      assert_includes content, "tags"
    end
  end

  # --- fix_move_to_archive ---

  def test_fix_move_to_archive_dry_run
    with_tasks_dir do |root|
      task_dir = create_task_fixture(root, id: "8pp.t.q7w", slug: "done-task", status: "done")
      spec_file = File.join(task_dir, "8pp.t.q7w-done-task.s.md")

      fixer = Fixer.new(dry_run: true, root_dir: root)
      result = fixer.fix_issue({message: "Task with terminal status 'done' not in _archive/", location: spec_file})
      assert result
      assert Dir.exist?(task_dir), "Task dir should still exist in dry-run"
    end
  end

  def test_fix_move_to_archive_moves_into_partitioned_archive_path
    with_tasks_dir do |root|
      task_dir = create_task_fixture(root, id: "8pp.t.q7w", slug: "done-task", status: "done")
      spec_file = File.join(task_dir, "8pp.t.q7w-done-task.s.md")

      fixer = Fixer.new(dry_run: false, root_dir: root)
      result = fixer.fix_issue({message: "Task with terminal status 'done' not in _archive/", location: spec_file})
      assert result

      archived_dirs = Dir.glob(File.join(root, "_archive", "**", "8pp.t.q7w-done-task"))
      assert_equal 1, archived_dirs.length
      refute Dir.exist?(task_dir), "Original task directory should be moved"
    end
  end

  def test_fix_move_to_archive_skips_subtask_when_siblings_not_terminal
    with_tasks_dir do |root|
      parent_dir = create_task_fixture(root, id: "8pp.t.abc", slug: "parent-task", status: "pending")

      sub_done_dir = File.join(parent_dir, "0-first-subtask")
      FileUtils.mkdir_p(sub_done_dir)
      sub_done_file = File.join(sub_done_dir, "8pp.t.abc.0-first-subtask.s.md")
      File.write(sub_done_file, <<~CONTENT)
        ---
        id: 8pp.t.abc.0
        status: done
        title: First subtask
        parent: 8pp.t.abc
        ---
      CONTENT

      sub_pending_dir = File.join(parent_dir, "1-second-subtask")
      FileUtils.mkdir_p(sub_pending_dir)
      File.write(File.join(sub_pending_dir, "8pp.t.abc.1-second-subtask.s.md"), <<~CONTENT)
        ---
        id: 8pp.t.abc.1
        status: pending
        title: Second subtask
        parent: 8pp.t.abc
        ---
      CONTENT

      fixer = Fixer.new(dry_run: false, root_dir: root)
      result = fixer.fix_issue({message: "Task with terminal status 'done' not in _archive/", location: sub_done_file})
      refute result

      assert Dir.exist?(parent_dir), "Parent should remain in place when siblings are not terminal"
      assert_equal 0, Dir.glob(File.join(root, "_archive", "**", "8pp.t.abc-parent-task")).length
    end
  end

  private

  def create_task_spec(root, id, slug, content)
    dir = File.join(root, "#{id}-#{slug}")
    FileUtils.mkdir_p(dir)
    file = File.join(dir, "#{id}-#{slug}.s.md")
    File.write(file, content)
    file
  end
end
