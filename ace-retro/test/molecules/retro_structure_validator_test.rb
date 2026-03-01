# frozen_string_literal: true

require "test_helper"
require "ace/retro/molecules/retro_structure_validator"

class RetroStructureValidatorTest < AceRetroTestCase
  Validator = Ace::Retro::Molecules::RetroStructureValidator

  def test_valid_structure_has_no_issues
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "good-retro")

      validator = Validator.new(root)
      issues = validator.validate
      errors = issues.select { |i| i[:type] == :error }
      assert_empty errors
    end
  end

  def test_nonexistent_root_returns_error
    validator = Validator.new("/tmp/nonexistent-#{rand(99999)}")
    issues = validator.validate
    assert_equal 1, issues.size
    assert_equal :error, issues.first[:type]
  end

  def test_detects_bad_folder_naming
    with_retros_dir do |root|
      bad = File.join(root, "not-valid-naming")
      FileUtils.mkdir_p(bad)
      File.write(File.join(bad, "test.retro.md"), "---\nid: abc\n---")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Folder name") }
    end
  end

  def test_detects_missing_retro_file
    with_retros_dir do |root|
      FileUtils.mkdir_p(File.join(root, "abc123-no-retro"))
      File.write(File.join(root, "abc123-no-retro", "readme.txt"), "no retro file here")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("No .retro.md file") }
    end
  end

  def test_detects_multiple_retro_files
    with_retros_dir do |root|
      dir = File.join(root, "abc123-multi")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "one.retro.md"), "---\nid: abc123\n---")
      File.write(File.join(dir, "two.retro.md"), "---\nid: abc123\n---")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Multiple .retro.md") }
    end
  end

  def test_detects_stale_backups
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "has-backup")
      File.write(File.join(root, "abc123-has-backup", "test.backup.md"), "stale")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Stale backup") }
    end
  end

  def test_detects_empty_directories
    with_retros_dir do |root|
      FileUtils.mkdir_p(File.join(root, "abc123-empty"))

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Empty directory") }
    end
  end

  def test_scans_special_folders
    with_retros_dir do |root|
      archive = File.join(root, "_archive")
      FileUtils.mkdir_p(archive)
      bad = File.join(archive, "not-valid")
      FileUtils.mkdir_p(bad)
      File.write(File.join(bad, "test.retro.md"), "---\nid: abc\n---")

      validator = Validator.new(root)
      issues = validator.validate
      assert issues.any? { |i| i[:message].include?("Folder name") }
    end
  end

  def test_accepts_valid_b36ts_archive_partition
    with_retros_dir do |root|
      create_retro_fixture(root, id: "def456", slug: "b36-archived", special_folder: "_archive/8o")

      validator = Validator.new(root)
      issues = validator.validate
      errors = issues.select { |i| i[:type] == :error }
      assert_empty errors, "Valid b36ts partition should not cause errors: #{errors.inspect}"
    end
  end

  def test_flags_invalid_archive_partition
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "archived-retro", special_folder: "_archive/2025-09")

      validator = Validator.new(root)
      issues = validator.validate
      errors = issues.select { |i| i[:type] == :error }
      assert errors.any? { |i| i[:message].include?("Invalid archive partition") },
        "Expected invalid archive partition error, got: #{errors.inspect}"
    end
  end
end
