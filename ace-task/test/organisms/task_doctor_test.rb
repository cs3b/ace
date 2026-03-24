# frozen_string_literal: true

require "test_helper"
require "ace/task/organisms/task_doctor"

class TaskDoctorTest < AceTaskTestCase
  Doctor = Ace::Task::Organisms::TaskDoctor

  # --- healthy directory ---

  def test_healthy_directory_returns_valid
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "good-task")
      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:valid]
      assert_equal 100, results[:health_score]
      assert_empty results[:issues].select { |i| i[:type] == :error }
    end
  end

  # --- nonexistent root ---

  def test_nonexistent_root_returns_invalid
    doctor = Doctor.new("/tmp/nonexistent-tasks-#{rand(99999)}")
    results = doctor.run_diagnosis
    refute results[:valid]
    assert_equal 0, results[:health_score]
    assert results[:issues].any? { |i| i[:message].include?("not found") }
  end

  # --- nil root ---

  def test_nil_root_returns_invalid
    doctor = Doctor.new(nil)
    results = doctor.run_diagnosis
    refute results[:valid]
    assert_equal 0, results[:health_score]
  end

  # --- specific checks ---

  def test_specific_check_structure
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test-task")
      doctor = Doctor.new(root, check: "structure")
      results = doctor.run_diagnosis
      assert results[:valid]
    end
  end

  def test_specific_check_frontmatter
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test-task")
      doctor = Doctor.new(root, check: "frontmatter")
      results = doctor.run_diagnosis
      assert results[:valid]
    end
  end

  def test_specific_check_scope
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test-task")
      doctor = Doctor.new(root, check: "scope")
      results = doctor.run_diagnosis
      assert results[:valid]
    end
  end

  def test_unknown_check_type_adds_error
    with_tasks_dir do |root|
      doctor = Doctor.new(root, check: "bogus")
      results = doctor.run_diagnosis
      refute results[:valid]
      assert results[:issues].any? { |i| i[:message].include?("Unknown check type") }
    end
  end

  # --- health score calculation ---

  def test_health_score_decreases_with_errors
    with_tasks_dir do |root|
      bad_dir = File.join(root, "bad-folder-name")
      FileUtils.mkdir_p(bad_dir)
      File.write(File.join(bad_dir, "something.s.md"), "---\nid: bad\n---\n")

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:health_score] < 100
    end
  end

  def test_health_score_clamped_to_zero
    with_tasks_dir do |root|
      # Create many bad folders to push score below 0
      20.times do |i|
        bad_dir = File.join(root, "bad-folder-#{i}")
        FileUtils.mkdir_p(bad_dir)
        File.write(File.join(bad_dir, "bad.s.md"), "no frontmatter")
      end

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:health_score] >= 0
    end
  end

  # --- stats ---

  def test_stats_populated
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "task-a")
      create_task_fixture(root, id: "8pp.t.q8x", slug: "task-b")

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:stats][:tasks_scanned] >= 0
      assert results[:stats][:folders_checked] >= 0
      assert results[:duration] >= 0
    end
  end

  # --- auto_fixable? ---

  def test_auto_fixable_returns_true_for_fixable_issue
    with_tasks_dir do |root|
      doctor = Doctor.new(root)
      issue = {type: :warning, message: "Stale backup file (safe to delete)", location: "/tmp/test.md"}
      assert doctor.auto_fixable?(issue)
    end
  end

  def test_auto_fixable_returns_false_for_info
    with_tasks_dir do |root|
      doctor = Doctor.new(root)
      issue = {type: :info, message: "Stale backup file (safe to delete)", location: "/tmp/test.md"}
      refute doctor.auto_fixable?(issue)
    end
  end

  def test_auto_fixable_returns_false_for_unknown_issue
    with_tasks_dir do |root|
      doctor = Doctor.new(root)
      issue = {type: :error, message: "Some unrecognized issue"}
      refute doctor.auto_fixable?(issue)
    end
  end

  # --- scope issues ---

  def test_detects_scope_inconsistency
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "done-task", status: "done")

      doctor = Doctor.new(root)
      results = doctor.run_diagnosis
      assert results[:issues].any? { |i| i[:message].include?("not in _archive") }
    end
  end
end
