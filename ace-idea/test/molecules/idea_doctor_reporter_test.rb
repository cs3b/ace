# frozen_string_literal: true

require "test_helper"
require "json"
require "ace/idea/molecules/idea_doctor_reporter"

class IdeaDoctorReporterTest < AceIdeaTestCase
  Reporter = Ace::Idea::Molecules::IdeaDoctorReporter

  def healthy_results
    {
      valid: true,
      health_score: 100,
      issues: [],
      stats: { ideas_scanned: 5, folders_checked: 5, errors: 0, warnings: 0, info: 0 },
      duration: 0.05,
      root_path: "/tmp/test"
    }
  end

  def unhealthy_results
    {
      valid: false,
      health_score: 70,
      issues: [
        { type: :error, message: "Missing required field: id", location: "/tmp/test/abc.md" },
        { type: :warning, message: "Stale backup file", location: "/tmp/test/old.backup.md" },
        { type: :warning, message: "Empty directory", location: "/tmp/test/empty" }
      ],
      stats: { ideas_scanned: 3, folders_checked: 3, errors: 1, warnings: 2, info: 0 },
      duration: 0.1,
      root_path: "/tmp/test"
    }
  end

  # --- terminal format ---

  def test_terminal_format_healthy
    output = Reporter.format_results(healthy_results, format: :terminal, colors: false)
    assert_includes output, "Idea Health Check"
    assert_includes output, "All ideas healthy"
    assert_includes output, "100/100"
  end

  def test_terminal_format_with_issues
    output = Reporter.format_results(unhealthy_results, format: :terminal, colors: false)
    assert_includes output, "Issues Found"
    assert_includes output, "Missing required field: id"
    assert_includes output, "Stale backup file"
  end

  def test_terminal_format_shows_duration
    output = Reporter.format_results(healthy_results, format: :terminal, colors: false)
    assert_includes output, "Completed in"
  end

  # --- JSON format ---

  def test_json_format
    output = Reporter.format_results(unhealthy_results, format: :json)
    parsed = JSON.parse(output)

    assert_equal 70, parsed["health_score"]
    refute parsed["valid"]
    assert_equal 1, parsed["errors"].size
    assert_equal 2, parsed["warnings"].size
  end

  def test_json_format_healthy
    output = Reporter.format_results(healthy_results, format: :json)
    parsed = JSON.parse(output)

    assert_equal 100, parsed["health_score"]
    assert parsed["valid"]
    assert_empty parsed["errors"]
  end

  # --- summary format ---

  def test_summary_format_healthy
    output = Reporter.format_results(healthy_results, format: :summary, colors: false)
    assert_includes output, "Excellent"
    assert_includes output, "100/100"
  end

  def test_summary_format_with_issues
    output = Reporter.format_results(unhealthy_results, format: :summary, colors: false)
    assert_includes output, "70/100"
    assert_includes output, "Errors: 1"
    assert_includes output, "Warnings: 2"
  end

  # --- fix results ---

  def test_format_fix_results
    fix_results = {
      fixed: 2,
      skipped: 1,
      fixes_applied: [
        { file: "/tmp/test.md", description: "Added missing status" },
        { file: "/tmp/old.backup.md", description: "Deleted stale backup" }
      ],
      dry_run: false
    }

    output = Reporter.format_fix_results(fix_results, colors: false)
    assert_includes output, "Auto-Fix Applied"
    assert_includes output, "Fixed: 2"
    assert_includes output, "Skipped: 1"
    assert_includes output, "Added missing status"
  end

  def test_format_fix_results_dry_run
    fix_results = {
      fixed: 2,
      skipped: 0,
      fixes_applied: [],
      dry_run: true
    }

    output = Reporter.format_fix_results(fix_results, colors: false)
    assert_includes output, "DRY RUN"
  end

  # --- verbose ---

  def test_verbose_shows_all_warnings
    many_warnings = (1..15).map do |i|
      { type: :warning, message: "Warning #{i}", location: "/tmp/w#{i}" }
    end
    results = {
      valid: true,
      health_score: 70,
      issues: many_warnings,
      stats: { ideas_scanned: 15, folders_checked: 15, errors: 0, warnings: 15, info: 0 },
      duration: 0.1,
      root_path: "/tmp/test"
    }

    # Without verbose: should truncate
    output = Reporter.format_results(results, format: :terminal, verbose: false, colors: false)
    assert_includes output, "more warnings"

    # With verbose: should show all
    output_verbose = Reporter.format_results(results, format: :terminal, verbose: true, colors: false)
    assert_includes output_verbose, "Warning 15"
    refute_includes output_verbose, "more warnings"
  end

  # --- health score display ---

  def test_health_score_excellent
    results = healthy_results.merge(health_score: 95)
    output = Reporter.format_results(results, format: :terminal, colors: false)
    assert_includes output, "Excellent"
  end

  def test_health_score_poor
    results = healthy_results.merge(health_score: 30)
    output = Reporter.format_results(results, format: :terminal, colors: false)
    assert_includes output, "Poor"
  end
end
