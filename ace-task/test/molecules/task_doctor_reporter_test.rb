# frozen_string_literal: true

require "test_helper"
require "json"
require "ace/task/molecules/task_doctor_reporter"

class TaskDoctorReporterTest < AceTaskTestCase
  Reporter = Ace::Task::Molecules::TaskDoctorReporter

  def setup
    @healthy_results = {
      valid: true,
      health_score: 100,
      issues: [],
      stats: { tasks_scanned: 5, folders_checked: 5, errors: 0, warnings: 0, info: 0 },
      duration: 0.05,
      root_path: "/tmp/test"
    }

    @unhealthy_results = {
      valid: false,
      health_score: 70,
      issues: [
        { type: :error, message: "Missing required field: id", location: "/tmp/test/spec.md" },
        { type: :warning, message: "Stale backup file", location: "/tmp/test/old.backup.md" }
      ],
      stats: { tasks_scanned: 3, folders_checked: 3, errors: 1, warnings: 1, info: 0 },
      duration: 0.1,
      root_path: "/tmp/test"
    }
  end

  # --- terminal format ---

  def test_terminal_healthy_output
    output = Reporter.format_results(@healthy_results, format: :terminal, colors: false)
    assert_includes output, "Task Health Check"
    assert_includes output, "All tasks healthy"
    assert_includes output, "100/100"
  end

  def test_terminal_unhealthy_output
    output = Reporter.format_results(@unhealthy_results, format: :terminal, colors: false)
    assert_includes output, "Issues Found:"
    assert_includes output, "Missing required field: id"
    assert_includes output, "Stale backup file"
  end

  # --- json format ---

  def test_json_format_valid_json
    output = Reporter.format_results(@healthy_results, format: :json)
    parsed = JSON.parse(output)
    assert_equal 100, parsed["health_score"]
    assert_equal true, parsed["valid"]
    assert_empty parsed["errors"]
  end

  def test_json_format_categorizes_issues
    output = Reporter.format_results(@unhealthy_results, format: :json)
    parsed = JSON.parse(output)
    assert_equal 1, parsed["errors"].size
    assert_equal 1, parsed["warnings"].size
  end

  # --- summary format ---

  def test_summary_healthy
    output = Reporter.format_results(@healthy_results, format: :summary, colors: false)
    assert_includes output, "Excellent"
    assert_includes output, "100/100"
  end

  def test_summary_unhealthy
    output = Reporter.format_results(@unhealthy_results, format: :summary, colors: false)
    assert_includes output, "70/100"
  end

  # --- fix results ---

  def test_format_fix_results_with_fixes
    fix_results = {
      fixed: 2,
      skipped: 1,
      dry_run: false,
      fixes_applied: [
        { file: "/tmp/test/spec.md", description: "Fixed ID", timestamp: Time.now }
      ]
    }
    output = Reporter.format_fix_results(fix_results, colors: false)
    assert_includes output, "Fixed: 2 issues"
    assert_includes output, "Skipped: 1"
  end

  def test_format_fix_results_dry_run
    fix_results = {
      fixed: 1,
      skipped: 0,
      dry_run: true,
      fixes_applied: []
    }
    output = Reporter.format_fix_results(fix_results, colors: false)
    assert_includes output, "DRY RUN"
  end

  # --- verbose ---

  def test_terminal_truncates_warnings_without_verbose
    many_warnings = (1..15).map do |i|
      { type: :warning, message: "Warning #{i}", location: "/tmp/test/file#{i}.md" }
    end
    results = @healthy_results.merge(
      issues: many_warnings,
      stats: { tasks_scanned: 15, folders_checked: 15, errors: 0, warnings: 15, info: 0 }
    )
    output = Reporter.format_results(results, format: :terminal, verbose: false, colors: false)
    assert_includes output, "more warnings (use --verbose to see all)"
  end

  def test_terminal_shows_all_warnings_with_verbose
    many_warnings = (1..15).map do |i|
      { type: :warning, message: "Warning #{i}", location: "/tmp/test/file#{i}.md" }
    end
    results = @healthy_results.merge(
      issues: many_warnings,
      stats: { tasks_scanned: 15, folders_checked: 15, errors: 0, warnings: 15, info: 0 }
    )
    output = Reporter.format_results(results, format: :terminal, verbose: true, colors: false)
    refute_includes output, "more warnings"
    assert_includes output, "Warning 15"
  end
end
