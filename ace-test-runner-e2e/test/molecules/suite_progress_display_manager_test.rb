# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

class SuiteProgressDisplayManagerTest < Minitest::Test
  SuiteProgressDisplayManager = Ace::Test::EndToEndRunner::Molecules::SuiteProgressDisplayManager

  def setup
    @output = StringIO.new
    @queue = [
      {package: "ace-lint", test_file: "/path/to/TS-LINT-001-basic/scenario.yml"},
      {package: "ace-review", test_file: "/path/to/TS-REVIEW-001-pr/scenario.yml"}
    ]
    @display = SuiteProgressDisplayManager.new(
      @queue, output: @output, use_color: false, pkg_width: 12, name_width: 25
    )
  end

  def test_show_header_clears_screen_and_renders_waiting_rows
    @display.show_header(2, 2)
    out = @output.string

    # ANSI clear screen
    assert_match(/\033\[H\033\[J/, out, "should clear screen")
    # Double separator
    assert_match(/\u2550{65}/, out, "should include double separator")
    # Title
    assert_match(/ACE E2E Test Suite - Running 2 tests across 2 packages/, out)
    # Waiting rows
    assert_match(/waiting/, out, "should show waiting state for rows")
    # Footer
    assert_match(/Active: 0/, out)
    assert_match(/Completed: 0/, out)
    assert_match(/Waiting: 2/, out)
  end

  def test_test_started_changes_row_to_running
    @display.show_header(2, 2)
    @output.truncate(0)
    @output.rewind

    @display.test_started("ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml")
    out = @output.string

    assert_match(/running/, out, "should show running state")
    assert_match(/Active: 1/, out)
    assert_match(/Waiting: 1/, out)
  end

  def test_test_completed_changes_row_to_completed
    @display.show_header(2, 2)
    @display.test_started("ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml")
    @output.truncate(0)
    @output.rewind

    result = {status: "pass", passed_cases: 5, total_cases: 5, test_name: "TS-LINT-001-basic"}
    @display.test_completed(result, "ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml", 10.2)
    out = @output.string

    assert_match(/\u2713/, out, "should show check icon for pass")
    assert_match(%r{5/5 cases}, out, "should include case counts")
    assert_match(/Completed: 1/, out)
  end

  def test_test_completed_shows_fail_icon
    @display.show_header(2, 2)
    @display.test_started("ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml")
    @output.truncate(0)
    @output.rewind

    result = {status: "fail", passed_cases: 2, total_cases: 5, test_name: "TS-LINT-001-basic"}
    @display.test_completed(result, "ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml", 8.0)
    out = @output.string

    assert_match(/\u2717/, out, "should show X icon for fail")
  end

  def test_refresh_is_callable_without_error
    @display.show_header(2, 2)
    @display.test_started("ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml")

    # Should not raise
    @display.refresh
  end

  def test_show_summary_outputs_after_table
    @display.show_header(2, 2)
    result1 = {status: "pass", passed_cases: 5, total_cases: 5, test_name: "TS-LINT-001-basic"}
    result2 = {status: "fail", passed_cases: 2, total_cases: 4, test_name: "TS-REVIEW-001-pr"}
    @display.test_completed(result1, "ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml", 10.0)
    @display.test_completed(result2, "ace-review", "/path/to/TS-REVIEW-001-pr/scenario.yml", 15.0)
    @output.truncate(0)
    @output.rewind

    results = {
      total: 2, passed: 1, failed: 1, errors: 0,
      packages: {
        "ace-lint" => [{status: "pass", test_name: "TS-LINT-001-basic", passed_cases: 5, total_cases: 5}],
        "ace-review" => [{status: "fail", test_name: "TS-REVIEW-001-pr", passed_cases: 2, total_cases: 4}]
      }
    }
    @display.show_summary(results, 25.0)
    out = @output.string

    assert_match(/Duration:/, out)
    assert_match(/Tests:/, out)
    assert_match(/SOME TESTS FAILED/, out)
  end

  def test_refresh_throttles_to_4hz
    @display.show_header(2, 2)
    @display.test_started("ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml")
    @output.truncate(0)
    @output.rewind

    # First refresh after start should produce output (enough time has passed)
    @display.refresh
    refute_empty @output.string, "first refresh should have produced output"

    @output.truncate(0)
    @output.rewind

    # Immediate second refresh should be throttled (no output)
    @display.refresh
    assert_empty @output.string, "second refresh within 250ms should be throttled"
  end

  def test_completed_without_cases
    @display.show_header(2, 2)
    @display.test_started("ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml")
    @output.truncate(0)
    @output.rewind

    result = {status: "pass", passed_cases: nil, total_cases: nil, test_name: "TS-LINT-001-basic"}
    @display.test_completed(result, "ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml", 5.0)
    out = @output.string

    refute_match(/cases/, out, "should not include cases when nil")
  end
end
