# frozen_string_literal: true

require "test_helper"
require "ace/task/molecules/task_structure_validator"

class TaskStructureValidatorTest < AceTaskTestCase
  Validator = Ace::Task::Molecules::TaskStructureValidator

  # --- folder naming ---

  def test_valid_folder_naming_no_issues
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "good-task")
      validator = Validator.new(root)
      issues = validator.validate
      folder_issues = issues.select { |i| i[:message].include?("Folder name") }
      assert_empty folder_issues
    end
  end

  def test_invalid_folder_naming
    with_tasks_dir do |root|
      bad_dir = File.join(root, "bad-folder-name")
      FileUtils.mkdir_p(bad_dir)
      File.write(File.join(bad_dir, "something.s.md"), "---\nid: abc\n---\n")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Folder name does not match") }
    end
  end

  def test_special_folders_skipped_for_naming_check
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "maybe-task", special_folder: "_maybe")

      validator = Validator.new(root)
      issues = validator.validate
      folder_issues = issues.select { |i| i[:message].include?("Folder name does not match") }
      assert_empty folder_issues
    end
  end

  # --- spec file checks ---

  def test_no_spec_file_in_folder
    with_tasks_dir do |root|
      dir = File.join(root, "8pp.t.q7w-empty-task")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "notes.md"), "Some notes")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("No .s.md spec file") }
    end
  end

  def test_multiple_spec_files
    with_tasks_dir do |root|
      dir = File.join(root, "8pp.t.q7w-multi")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "8pp.t.q7w-multi.s.md"), "---\nid: 8pp.t.q7w\n---\n")
      File.write(File.join(dir, "8pp.t.q7w-other.s.md"), "---\nid: 8pp.t.q7w\n---\n")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Multiple .s.md") }
    end
  end

  def test_idea_files_excluded_from_spec_check
    with_tasks_dir do |root|
      dir = File.join(root, "8pp.t.q7w-with-idea")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-something.idea.s.md"), "---\nid: abc123\n---\n")

      validator = Validator.new(root)
      issues = validator.validate
      spec_issues = issues.select { |i| i[:message].include?("No .s.md spec file") }
      assert spec_issues.any?, "Should flag missing spec file even if .idea.s.md exists"
    end
  end

  # --- stale backups ---

  def test_detects_stale_backups
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "with-backup")
      File.write(File.join(root, "8pp.t.q7w-with-backup", "old.backup.md"), "backup")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Stale backup file") }
    end
  end

  # --- empty directories ---

  def test_detects_empty_directories
    with_tasks_dir do |root|
      empty_dir = File.join(root, "8pp.t.q7w-empty")
      FileUtils.mkdir_p(empty_dir)

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Empty directory") }
    end
  end

  # --- nonexistent root ---

  def test_nonexistent_root_dir
    validator = Validator.new("/tmp/nonexistent-tasks-root-#{rand(99999)}")
    issues = validator.validate
    assert issues.any? { |i| i[:type] == :error && i[:message].include?("does not exist") }
  end

  # --- category folders ---

  def test_skips_category_folders_with_only_subdirectories
    with_tasks_dir do |root|
      category = File.join(root, "20251013-category-folder")
      FileUtils.mkdir_p(category)
      child = File.join(category, "8pp.t.q7w-child-task")
      FileUtils.mkdir_p(child)
      File.write(File.join(child, "8pp.t.q7w-child-task.s.md"), "---\nid: 8pp.t.q7w\n---\n")

      validator = Validator.new(root)
      issues = validator.validate

      category_issues = issues.select { |i| i[:location]&.include?("20251013-category-folder") && !i[:location]&.include?("8pp.t.q7w") }
      assert_empty category_issues, "Category folder should not be flagged"
    end
  end
end
