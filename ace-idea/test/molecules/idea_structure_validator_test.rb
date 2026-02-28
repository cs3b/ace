# frozen_string_literal: true

require "test_helper"
require "ace/idea/molecules/idea_structure_validator"

class IdeaStructureValidatorTest < AceIdeaTestCase
  Validator = Ace::Idea::Molecules::IdeaStructureValidator

  # --- folder naming ---

  def test_valid_folder_naming_no_issues
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "abc123", slug: "good-idea")
      validator = Validator.new(root)
      issues = validator.validate
      folder_issues = issues.select { |i| i[:message].include?("Folder name") }
      assert_empty folder_issues
    end
  end

  def test_invalid_folder_naming
    with_ideas_dir do |root|
      bad_dir = File.join(root, "bad-folder-name")
      FileUtils.mkdir_p(bad_dir)
      File.write(File.join(bad_dir, "something.idea.s.md"), "---\nid: abc\n---\n")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Folder name does not match") }
    end
  end

  def test_special_folders_skipped_for_naming_check
    with_ideas_dir do |root|
      special = File.join(root, "_maybe")
      FileUtils.mkdir_p(special)
      create_idea_fixture(root, id: "abc123", slug: "maybe-idea", special_folder: "_maybe")

      validator = Validator.new(root)
      issues = validator.validate
      folder_issues = issues.select { |i| i[:message].include?("Folder name does not match") }
      assert_empty folder_issues
    end
  end

  # --- spec file checks ---

  def test_no_spec_file_in_folder
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-empty-idea")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "notes.md"), "Some notes")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("No .idea.s.md spec file") }
    end
  end

  def test_multiple_spec_files
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-multi")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-multi.idea.s.md"), "---\nid: abc123\n---\n")
      File.write(File.join(dir, "abc123-other.idea.s.md"), "---\nid: abc123\n---\n")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Multiple .idea.s.md") }
    end
  end

  # --- stale backups ---

  def test_detects_stale_backups
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "abc123", slug: "with-backup")
      File.write(File.join(root, "abc123-with-backup", "old.backup.md"), "backup")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Stale backup file") }
    end
  end

  # --- empty directories ---

  def test_detects_empty_directories
    with_ideas_dir do |root|
      empty_dir = File.join(root, "abc123-empty")
      FileUtils.mkdir_p(empty_dir)

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Empty directory") }
    end
  end

  # --- nonexistent root ---

  def test_nonexistent_root_dir
    validator = Validator.new("/tmp/nonexistent-ideas-root-#{rand(99999)}")
    issues = validator.validate
    assert issues.any? { |i| i[:type] == :error && i[:message].include?("does not exist") }
  end

  # --- category folders ---

  def test_skips_category_folders_with_only_subdirectories
    with_ideas_dir do |root|
      # Create a category folder with only subdirectories (no files)
      category = File.join(root, "20251013-category-folder")
      FileUtils.mkdir_p(category)
      # Add subdirectories but no files at the category level
      FileUtils.mkdir_p(File.join(category, "abc123-child-idea"))
      File.write(File.join(category, "abc123-child-idea", "abc123-child-idea.idea.s.md"), "---\nid: abc123\n---\n")

      validator = Validator.new(root)
      issues = validator.validate

      # Category folder should not be flagged for missing spec file
      category_issues = issues.select { |i| i[:location]&.include?("20251013-category-folder") }
      assert_empty category_issues, "Category folder should not be flagged"
    end
  end

  def test_does_not_skip_folder_with_files
    with_ideas_dir do |root|
      # Create a folder with both files and subdirectories
      folder = File.join(root, "badname-mixed-content")
      FileUtils.mkdir_p(folder)
      File.write(File.join(folder, "notes.txt"), "some notes")
      FileUtils.mkdir_p(File.join(folder, "subdir"))

      validator = Validator.new(root)
      issues = validator.validate

      # Should be flagged for bad naming
      assert issues.any? { |i| i[:message].include?("Folder name does not match") }
    end
  end

  def test_category_folder_in_archive
    with_ideas_dir do |root|
      archive = File.join(root, "_archive")
      FileUtils.mkdir_p(archive)

      # Category folder in archive
      category = File.join(archive, "20250101-old-category")
      FileUtils.mkdir_p(category)
      FileUtils.mkdir_p(File.join(category, "def456-archived-idea"))
      File.write(File.join(category, "def456-archived-idea", "def456-archived-idea.idea.s.md"),
                 "---\nid: def456\nstatus: done\n---\n")

      validator = Validator.new(root)
      issues = validator.validate

      # Category folder should not be flagged
      category_issues = issues.select { |i| i[:location]&.include?("20250101-old-category") && !i[:location]&.include?("def456") }
      assert_empty category_issues, "Archive category folder should not be flagged"
    end
  end
end
