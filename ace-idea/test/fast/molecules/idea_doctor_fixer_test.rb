# frozen_string_literal: true

require "test_helper"
require "ace/idea/molecules/idea_doctor_fixer"

class IdeaDoctorFixerTest < AceIdeaTestCase
  Fixer = Ace::Idea::Molecules::IdeaDoctorFixer

  # --- dry run ---

  def test_dry_run_does_not_modify_files
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-test")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-test.idea.s.md")
      File.write(file, "---\nid: abc123\ntitle: Test\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n")
      original = File.read(file)

      fixer = Fixer.new(dry_run: true)
      issue = {type: :warning, message: "Missing required field: status", location: file}
      fixer.fix_issue(issue)

      assert_equal original, File.read(file)
      assert_equal 1, fixer.fixed_count
    end
  end

  # --- fix missing status ---

  def test_fix_missing_status
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-test")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-test.idea.s.md")
      File.write(file, "---\nid: abc123\ntitle: Test\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n")

      fixer = Fixer.new
      issue = {type: :warning, message: "Missing required field: status", location: file}
      result = fixer.fix_issue(issue)

      assert result
      content = File.read(file)
      assert_includes content, "status"
      assert_includes content, "pending"
    end
  end

  # --- fix missing title ---

  def test_fix_missing_title_from_heading
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-my-idea")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-my-idea.idea.s.md")
      File.write(file, "---\nid: abc123\nstatus: pending\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n\n# Great Idea\n\nContent here.\n")

      fixer = Fixer.new
      issue = {type: :warning, message: "Missing required field: title", location: file}
      fixer.fix_issue(issue)

      content = File.read(file)
      assert_includes content, "Great Idea"
    end
  end

  def test_fix_missing_title_from_slug
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-dark-mode")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-dark-mode.idea.s.md")
      File.write(file, "---\nid: abc123\nstatus: pending\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n\nSome content.\n")

      fixer = Fixer.new
      issue = {type: :warning, message: "Missing required field: title", location: file}
      fixer.fix_issue(issue)

      content = File.read(file)
      assert_includes content, "title"
    end
  end

  # --- fix missing id ---

  def test_fix_missing_id_from_folder
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-test-idea")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-test-idea.idea.s.md")
      File.write(file, "---\nstatus: pending\ntitle: Test\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n")

      fixer = Fixer.new
      issue = {type: :error, message: "Missing required field: id", location: file}
      fixer.fix_issue(issue)

      content = File.read(file)
      assert_includes content, "abc123"
    end
  end

  # --- fix tags ---

  def test_fix_tags_not_array
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-test")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-test.idea.s.md")
      File.write(file, "---\nid: abc123\nstatus: pending\ntitle: Test\ntags: not-array\ncreated_at: 2026-02-28 12:00:00\n---\n")

      fixer = Fixer.new
      issue = {type: :warning, message: "Field 'tags' is not an array", location: file}
      fixer.fix_issue(issue)

      content = File.read(file)
      # Tags should now be an array (empty)
      assert_match(/tags.*\[\]/, content)
    end
  end

  def test_fix_remove_location_field
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-test")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-test.idea.s.md")
      File.write(file, "---\nid: abc123\nstatus: pending\ntitle: Test\nlocation: archived\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n")

      fixer = Fixer.new
      issue = {type: :warning, message: "Derived field 'location' should not be stored in frontmatter", location: file}
      fixer.fix_issue(issue)

      content = File.read(file)
      refute_includes content, "location:"
    end
  end

  # --- fix missing created_at ---

  def test_fix_missing_created_at
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-test")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-test.idea.s.md")
      File.write(file, "---\nid: abc123\nstatus: pending\ntitle: Test\ntags: []\n---\n")

      fixer = Fixer.new
      issue = {type: :warning, message: "Missing recommended field: created_at", location: file}
      fixer.fix_issue(issue)

      content = File.read(file)
      assert_includes content, "created_at"
    end
  end

  # --- fix stale backup ---

  def test_fix_stale_backup
    with_ideas_dir do |root|
      backup = File.join(root, "old.backup.md")
      File.write(backup, "old content")

      fixer = Fixer.new
      issue = {type: :warning, message: "Stale backup file (safe to delete)", location: backup}
      fixer.fix_issue(issue)

      refute File.exist?(backup)
      assert_equal 1, fixer.fixed_count
    end
  end

  # --- fix empty directory ---

  def test_fix_empty_directory
    with_ideas_dir do |root|
      empty = File.join(root, "abc123-empty")
      FileUtils.mkdir_p(empty)

      fixer = Fixer.new
      issue = {type: :warning, message: "Empty directory (safe to delete)", location: empty}
      fixer.fix_issue(issue)

      refute Dir.exist?(empty)
      assert_equal 1, fixer.fixed_count
    end
  end

  def test_empty_directory_not_removed_if_has_files
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-not-empty")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "notes.txt"), "content")

      fixer = Fixer.new
      issue = {type: :warning, message: "Empty directory (safe to delete)", location: dir}
      fixer.fix_issue(issue)

      assert Dir.exist?(dir)
      assert_equal 1, fixer.skipped_count
    end
  end

  # --- fix scope: move to archive ---

  def test_fix_move_to_archive
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "abc123", slug: "done-idea", status: "done")

      fixer = Fixer.new(root_dir: root)
      issue = {
        type: :warning,
        message: "Idea with terminal status 'done' not in _archive/",
        location: File.join(idea_dir, "abc123-done-idea.idea.s.md")
      }
      fixer.fix_issue(issue)

      assert Dir.exist?(File.join(root, "_archive", "abc123-done-idea"))
      refute Dir.exist?(idea_dir)
      assert_equal 1, fixer.fixed_count
    end
  end

  # --- fix scope: update archive status ---

  def test_fix_archive_status
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "abc123", slug: "pending-archive",
        status: "pending", special_folder: "_archive")
      file = File.join(idea_dir, "abc123-pending-archive.idea.s.md")

      fixer = Fixer.new(root_dir: root)
      issue = {
        type: :warning,
        message: "Idea in _archive/ but status is 'pending'",
        location: file
      }
      fixer.fix_issue(issue)

      content = File.read(file)
      assert_includes content, "done"
    end
  end

  # --- can_fix? ---

  def test_can_fix_returns_true_for_fixable
    fixer = Fixer.new
    assert fixer.can_fix?({type: :warning, message: "Missing required field: status", location: "/tmp/x"})
    assert fixer.can_fix?({type: :warning, message: "Stale backup file (safe to delete)", location: "/tmp/x"})
    assert fixer.can_fix?({type: :warning, message: "Empty directory (safe to delete)", location: "/tmp/x"})
    assert fixer.can_fix?({type: :warning, message: "Derived field 'location' should not be stored in frontmatter", location: "/tmp/x"})
  end

  def test_can_fix_returns_false_for_unfixable
    fixer = Fixer.new
    refute fixer.can_fix?({type: :error, message: "Invalid idea ID format: 'bad'", location: "/tmp/x"})
    refute fixer.can_fix?({type: :error, message: "YAML syntax error", location: "/tmp/x"})
  end

  # --- fix missing opening delimiter ---

  def test_fix_missing_opening_delimiter
    with_ideas_dir do |root|
      dir = File.join(root, "abc123-no-delimiter")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "abc123-no-delimiter.idea.s.md")
      # File with content but no opening ---
      File.write(file, "# My Great Idea\n\nSome content here.\n\n---\nCaptured: 2025-11-02 10:49:53\n")

      fixer = Fixer.new
      issue = {type: :error, message: "Missing opening '---' delimiter", location: file}
      result = fixer.fix_issue(issue)

      assert result
      content = File.read(file)
      assert content.start_with?("---\n")
      assert_includes content, "id: abc123"
      assert_includes content, "title: My Great Idea"
      assert_includes content, "status: pending"
    end
  end

  def test_fix_missing_opening_delimiter_extracts_title_from_h1
    with_ideas_dir do |root|
      dir = File.join(root, "def456-extract-title")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "def456-extract-title.idea.s.md")
      # File with H1 to extract title from
      File.write(file, "# Extracted Title\n\nBody content.\n")

      fixer = Fixer.new
      issue = {type: :error, message: "Missing opening '---' delimiter", location: file}
      fixer.fix_issue(issue)

      content = File.read(file)
      assert_includes content, "title: Extracted Title"
    end
  end

  def test_fix_missing_opening_delimiter_fallback_to_folder_slug
    with_ideas_dir do |root|
      dir = File.join(root, "ghi789-slug-name-here")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "ghi789-slug-name-here.idea.s.md")
      # File without H1
      File.write(file, "Just some content without a heading.\n")

      fixer = Fixer.new
      issue = {type: :error, message: "Missing opening '---' delimiter", location: file}
      fixer.fix_issue(issue)

      content = File.read(file)
      assert_includes content, "title:"
    end
  end

  # --- fix folder naming ---

  def test_fix_folder_naming_date_prefix
    with_ideas_dir do |root|
      # Folder with date prefix like 20251013-slug
      dir = File.join(root, "20251013-ace-packages-review")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "20251013-ace-packages-review.idea.s.md")
      File.write(file, "---\nid: invalid\nstatus: pending\ntitle: Review\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n\nContent.\n")

      fixer = Fixer.new
      issue = {type: :error, message: "Folder name does not match '{id}-{slug}' convention: '20251013-ace-packages-review'", location: dir}
      result = fixer.fix_issue(issue)

      assert result
      # New folder should exist with valid b36ts ID
      new_dirs = Dir.glob(File.join(root, "*")).select { |d| File.directory?(d) && File.basename(d).match?(/^[0-9a-z]{6}-ace-packages-review$/) }
      refute_empty new_dirs, "Expected new folder with valid ID prefix"

      new_dir = new_dirs.first
      new_spec = File.join(new_dir, "#{File.basename(new_dir)}.idea.s.md")
      assert File.exist?(new_spec), "Expected spec file in new location"

      content = File.read(new_spec)
      # ID should have been updated to new valid b36ts ID
      assert_match(/id: [0-9a-z]{6}/, content)
    end
  end

  def test_fix_folder_naming_issue_timestamp_prefix
    with_ideas_dir do |root|
      # Folder with issue number + timestamp like 056-20250930-105556-slug
      dir = File.join(root, "056-20250930-105556-my-feature-idea")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "056-20250930-105556-my-feature-idea.idea.s.md")
      File.write(file, "---\nid: old-id\nstatus: pending\ntitle: Feature\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n\nContent.\n")

      fixer = Fixer.new
      issue = {type: :error, message: "Folder name does not match '{id}-{slug}' convention: '056-20250930-105556-my-feature-idea'", location: dir}
      fixer.fix_issue(issue)

      # New folder should exist with valid b36ts ID
      new_dirs = Dir.glob(File.join(root, "*")).select { |d| File.directory?(d) && File.basename(d).match?(/^[0-9a-z]{6}-my-feature-idea$/) }
      refute_empty new_dirs, "Expected new folder with valid ID prefix"
    end
  end

  def test_fix_folder_naming_seven_digit_prefix
    with_ideas_dir do |root|
      # Folder with 7-digit prefix like 2025111-slug (not a valid b36ts ID)
      dir = File.join(root, "2025111-another-idea")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "2025111-another-idea.idea.s.md")
      File.write(file, "---\nid: bad\nstatus: pending\ntitle: Another\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n\nContent.\n")

      fixer = Fixer.new
      issue = {type: :error, message: "Folder name does not match '{id}-{slug}' convention: '2025111-another-idea'", location: dir}
      fixer.fix_issue(issue)

      # New folder should exist with valid b36ts ID
      new_dirs = Dir.glob(File.join(root, "*")).select { |d| File.directory?(d) && File.basename(d).match?(/^[0-9a-z]{6}-another-idea$/) }
      refute_empty new_dirs, "Expected new folder with valid ID prefix"
    end
  end

  def test_fix_folder_naming_preserves_attachments
    with_ideas_dir do |root|
      dir = File.join(root, "20251013-with-attachments")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "20251013-with-attachments.idea.s.md")
      File.write(file, "---\nid: old\nstatus: pending\ntitle: With Files\ntags: []\ncreated_at: 2026-02-28 12:00:00\n---\n\nContent.\n")
      attachment = File.join(dir, "diagram.png")
      File.write(attachment, "fake image data")

      fixer = Fixer.new
      issue = {type: :error, message: "Folder name does not match '{id}-{slug}' convention: '20251013-with-attachments'", location: dir}
      fixer.fix_issue(issue)

      # Attachment should be preserved in new folder
      new_dirs = Dir.glob(File.join(root, "*")).select { |d| File.directory?(d) && File.basename(d).match?(/^[0-9a-z]{6}-with-attachments$/) }
      refute_empty new_dirs
      new_dir = new_dirs.first
      assert File.exist?(File.join(new_dir, "diagram.png")), "Attachment should be preserved"
    end
  end

  def test_fix_folder_naming_skips_if_no_spec_file
    with_ideas_dir do |root|
      dir = File.join(root, "20251013-no-spec")
      FileUtils.mkdir_p(dir)
      # No spec file, just a notes file
      File.write(File.join(dir, "notes.txt"), "notes")

      fixer = Fixer.new
      issue = {type: :error, message: "Folder name does not match '{id}-{slug}' convention: '20251013-no-spec'", location: dir}
      result = fixer.fix_issue(issue)

      refute result
      assert_equal 1, fixer.skipped_count
      # Folder should still exist
      assert Dir.exist?(dir)
    end
  end

  # --- can_fix for new patterns ---

  def test_can_fix_opening_delimiter
    fixer = Fixer.new
    assert fixer.can_fix?({type: :error, message: "Missing opening '---' delimiter", location: "/tmp/x"})
  end

  def test_can_fix_folder_naming
    fixer = Fixer.new
    assert fixer.can_fix?({type: :error, message: "Folder name does not match '{id}-{slug}' convention: 'bad'", location: "/tmp/x"})
  end

  def test_can_fix_requires_location
    fixer = Fixer.new
    refute fixer.can_fix?({type: :warning, message: "Stale backup file (safe to delete)"})
  end

  # --- batch fix ---

  def test_fix_issues_batch
    with_ideas_dir do |root|
      backup1 = File.join(root, "a.backup.md")
      backup2 = File.join(root, "b.backup.md")
      File.write(backup1, "old")
      File.write(backup2, "old")

      fixer = Fixer.new
      issues = [
        {type: :warning, message: "Stale backup file (safe to delete)", location: backup1},
        {type: :warning, message: "Stale backup file (safe to delete)", location: backup2},
        {type: :error, message: "Invalid idea ID format", location: "/tmp/unfixable"}
      ]

      results = fixer.fix_issues(issues)
      assert_equal 2, results[:fixed]
      assert_equal 0, results[:skipped]
      refute results[:dry_run]
    end
  end
end
