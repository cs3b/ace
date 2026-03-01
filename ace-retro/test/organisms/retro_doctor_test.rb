# frozen_string_literal: true

require "test_helper"
require "ace/retro/organisms/retro_doctor"
require "ace/retro/molecules/retro_doctor_fixer"

class RetroDoctorTest < AceRetroTestCase
  Doctor = Ace::Retro::Organisms::RetroDoctor

  # --- basic diagnosis ---

  def test_healthy_retros_pass
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "good-retro", status: "active", tags: ["test"])
      doctor = Doctor.new(root)
      results = doctor.run_diagnosis

      assert results[:valid]
      assert_equal 100, results[:health_score]
      assert_empty results[:issues].select { |i| i[:type] == :error }
    end
  end

  def test_empty_root_passes
    with_retros_dir do |root|
      doctor = Doctor.new(root)
      results = doctor.run_diagnosis

      assert results[:valid]
      assert_equal 100, results[:health_score]
    end
  end

  def test_nonexistent_root_fails
    doctor = Doctor.new("/tmp/nonexistent-root-#{rand(99999)}")
    results = doctor.run_diagnosis

    refute results[:valid]
    assert_equal 0, results[:health_score]
  end

  # --- structure issues ---

  def test_detects_bad_folder_naming
    with_retros_dir do |root|
      bad = File.join(root, "not-valid")
      FileUtils.mkdir_p(bad)
      File.write(File.join(bad, "not-valid.retro.md"), <<~CONTENT)
        ---
        id: abc123
        status: active
        title: Bad folder
        type: standard
        created_at: 2026-02-28 12:00:00
        tags: []
        ---
      CONTENT

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:issues].any? { |i| i[:message].include?("Folder name") }
    end
  end

  def test_detects_empty_directories
    with_retros_dir do |root|
      FileUtils.mkdir_p(File.join(root, "abc123-empty"))

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:issues].any? { |i| i[:message].include?("Empty directory") }
    end
  end

  # --- frontmatter issues ---

  def test_detects_missing_required_fields
    with_retros_dir do |root|
      dir = File.join(root, "abc123-no-status")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-no-status.retro.md"), <<~CONTENT)
        ---
        id: abc123
        title: Missing status
        type: standard
        created_at: 2026-02-28 12:00:00
        tags: []
        ---
      CONTENT

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:issues].any? { |i| i[:message].include?("Missing required field: status") }
    end
  end

  def test_detects_invalid_status
    with_retros_dir do |root|
      dir = File.join(root, "abc123-bad-status")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-bad-status.retro.md"), <<~CONTENT)
        ---
        id: abc123
        status: draft
        title: Bad status
        type: standard
        created_at: 2026-02-28 12:00:00
        tags: []
        ---
      CONTENT

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:issues].any? { |i| i[:message].include?("Invalid status value") }
    end
  end

  # --- scope issues ---

  def test_detects_done_not_in_archive
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "done-root", status: "done")

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:issues].any? { |i| i[:message].include?("not in _archive") }
    end
  end

  def test_detects_archive_non_terminal
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "active-archive",
                          status: "active", special_folder: "_archive")

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:issues].any? { |i| i[:message].include?("in _archive/ but status") }
    end
  end

  # --- health score ---

  def test_health_score_decreases_with_errors
    with_retros_dir do |root|
      dir = File.join(root, "abc123-broken")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-broken.retro.md"), <<~CONTENT)
        ---
        status: invalid
        title: No id
        ---
      CONTENT

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:health_score] < 100
    end
  end

  # --- specific check ---

  def test_specific_check_frontmatter
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "test-retro")

      doctor = Doctor.new(root, check: "frontmatter")
      results = doctor.run_diagnosis
      assert results[:valid]
    end
  end

  def test_specific_check_structure
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "test-retro")

      doctor = Doctor.new(root, check: "structure")
      results = doctor.run_diagnosis
      assert results[:valid]
    end
  end

  def test_specific_check_scope
    with_retros_dir do |root|
      create_retro_fixture(root, id: "abc123", slug: "test-retro")

      doctor = Doctor.new(root, check: "scope")
      results = doctor.run_diagnosis
      assert results[:valid]
    end
  end

  def test_unknown_check_type
    with_retros_dir do |root|
      doctor = Doctor.new(root, check: "nonexistent")
      results = doctor.run_diagnosis
      assert results[:issues].any? { |i| i[:message].include?("Unknown check type") }
    end
  end

  # --- auto_fixable? ---

  def test_auto_fixable_missing_status
    with_retros_dir do |root|
      doctor = Doctor.new(root)
      issue = { type: :error, message: "Missing required field: status", location: "/tmp/test.md" }
      assert doctor.auto_fixable?(issue)
    end
  end

  def test_auto_fixable_stale_backup
    with_retros_dir do |root|
      doctor = Doctor.new(root)
      issue = { type: :warning, message: "Stale backup file (safe to delete)", location: "/tmp/test.backup.md" }
      assert doctor.auto_fixable?(issue)
    end
  end

  def test_not_auto_fixable_invalid_id_format
    with_retros_dir do |root|
      doctor = Doctor.new(root)
      issue = { type: :error, message: "Invalid retro ID format: 'bad'", location: "/tmp/test.md" }
      refute doctor.auto_fixable?(issue)
    end
  end

  # --- stats ---

  def test_stats_track_retros_scanned
    with_retros_dir do |root|
      create_retro_fixture(root, id: "aaa111", slug: "first")
      create_retro_fixture(root, id: "bbb222", slug: "second")

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert_equal 2, results[:stats][:retros_scanned]
    end
  end

  def test_results_include_duration
    with_retros_dir do |root|
      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:duration] >= 0
    end
  end

  def test_results_include_root_path
    with_retros_dir do |root|
      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert_equal root, results[:root_path]
    end
  end
end
