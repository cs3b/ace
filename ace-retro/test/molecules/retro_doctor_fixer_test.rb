# frozen_string_literal: true

require "test_helper"
require "ace/retro/molecules/retro_doctor_fixer"

class RetroDoctorFixerTest < AceRetroTestCase
  Fixer = Ace::Retro::Molecules::RetroDoctorFixer

  def test_can_fix_missing_status
    fixer = Fixer.new
    issue = {type: :error, message: "Missing required field: status", location: "/tmp/test.md"}
    assert fixer.can_fix?(issue)
  end

  def test_can_fix_stale_backup
    fixer = Fixer.new
    issue = {type: :warning, message: "Stale backup file (safe to delete)", location: "/tmp/test.backup.md"}
    assert fixer.can_fix?(issue)
  end

  def test_cannot_fix_invalid_id
    fixer = Fixer.new
    issue = {type: :error, message: "Invalid retro ID format: 'bad'", location: "/tmp/test.md"}
    refute fixer.can_fix?(issue)
  end

  def test_cannot_fix_without_location
    fixer = Fixer.new
    issue = {type: :error, message: "Missing required field: status"}
    refute fixer.can_fix?(issue)
  end

  def test_dry_run_does_not_modify_files
    with_retros_dir do |root|
      dir = create_retro_fixture(root, id: "abc123", slug: "test-fix")
      file = Dir.glob(File.join(dir, "*.retro.md")).first
      original = File.read(file)

      fixer = Fixer.new(dry_run: true)
      issue = {type: :warning, message: "Missing recommended field: tags", location: file}
      fixer.fix_issue(issue)

      assert_equal original, File.read(file)
      assert_equal 1, fixer.fixed_count
    end
  end

  def test_fix_stale_backup_deletes_file
    with_retros_dir do |root|
      backup = File.join(root, "test.backup.md")
      File.write(backup, "stale content")

      fixer = Fixer.new
      issue = {type: :warning, message: "Stale backup file (safe to delete)", location: backup}
      fixer.fix_issue(issue)

      refute File.exist?(backup)
      assert_equal 1, fixer.fixed_count
    end
  end

  def test_fix_empty_directory_removes_dir
    with_retros_dir do |root|
      empty = File.join(root, "abc123-empty")
      FileUtils.mkdir_p(empty)

      fixer = Fixer.new
      issue = {type: :warning, message: "Empty directory (safe to delete)", location: empty}
      fixer.fix_issue(issue)

      refute Dir.exist?(empty)
      assert_equal 1, fixer.fixed_count
    end
  end

  def test_fix_issues_returns_summary
    fixer = Fixer.new(dry_run: true)
    issues = [
      {type: :warning, message: "Stale backup file (safe to delete)", location: "/tmp/nonexistent"}
    ]
    result = fixer.fix_issues(issues)

    assert result.key?(:fixed)
    assert result.key?(:skipped)
    assert result.key?(:fixes_applied)
    assert result.key?(:dry_run)
    assert result[:dry_run]
  end

  def test_fix_invalid_archive_partition
    with_retros_dir do |root|
      # Create a retro in an invalid calendar-month partition
      create_retro_fixture(root, id: "abc123", slug: "old-retro", status: "done",
        special_folder: "_archive/2025-09")

      fixer = Fixer.new(root_dir: root)
      issue = {
        type: :error,
        message: "Invalid archive partition '2025-09' (expected b36ts like '8o')",
        location: File.join(root, "_archive", "2025-09")
      }
      fixer.fix_issue(issue)

      # Retro should have moved to a b36ts partition (may be multi-level like 8p/y)
      b36_entries = Dir.glob(File.join(root, "_archive", "**", "abc123-old-retro"))
        .reject { |p| p.include?("2025-09") }
      assert_equal 1, b36_entries.size, "Expected retro in b36ts partition, found: #{b36_entries.inspect}"
      assert_equal 1, fixer.fixed_count

      # Old partition dir should be gone
      refute Dir.exist?(File.join(root, "_archive", "2025-09")),
        "Invalid partition directory should have been removed"
    end
  end

  def test_fix_move_to_archive
    with_retros_dir do |root|
      dir = create_retro_fixture(root, id: "abc123", slug: "done-retro", status: "done")
      file = Dir.glob(File.join(dir, "*.retro.md")).first

      fixer = Fixer.new(root_dir: root)
      issue = {type: :warning, message: "Retro with terminal status 'done' not in _archive/", location: file}
      fixer.fix_issue(issue)

      # Should be in _archive/{partition}/abc123-done-retro (date-partitioned)
      archive_entries = Dir.glob(File.join(root, "_archive", "**", "abc123-done-retro"))
      assert_equal 1, archive_entries.size, "Expected retro in _archive with date partition"
      assert_equal 1, fixer.fixed_count
    end
  end
end
