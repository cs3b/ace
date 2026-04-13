# frozen_string_literal: true

require_relative "../../test_helper"

class DisplayHelpersTest < Minitest::Test
  DisplayHelpers = Ace::Test::EndToEndRunner::Atoms::DisplayHelpers
  TestResult = Ace::Test::EndToEndRunner::Models::TestResult

  def test_status_icon_pass
    assert_equal "\u2713", DisplayHelpers.status_icon(true)
  end

  def test_status_icon_fail
    assert_equal "\u2717", DisplayHelpers.status_icon(false)
  end

  def test_format_elapsed_short
    assert_equal "  1.5s", DisplayHelpers.format_elapsed(1.5)
  end

  def test_format_elapsed_long
    assert_equal " 35.4s", DisplayHelpers.format_elapsed(35.4)
  end

  def test_format_elapsed_zero
    assert_equal "  0.0s", DisplayHelpers.format_elapsed(0)
  end

  def test_format_duration_under_60
    assert_equal "10.70s", DisplayHelpers.format_duration(10.7)
  end

  def test_format_duration_over_60
    assert_equal "1m 50s", DisplayHelpers.format_duration(110)
  end

  def test_format_duration_exact_minute
    assert_equal "2m 0s", DisplayHelpers.format_duration(120)
  end

  def test_tc_count_display_with_cases
    result = TestResult.new(
      test_id: "TS-TEST-001",
      status: "fail",
      test_cases: [
        {id: "TC-001", status: "pass"},
        {id: "TC-002", status: "fail"}
      ]
    )

    assert_equal "  1/2 cases", DisplayHelpers.tc_count_display(result)
  end

  def test_tc_count_display_no_cases
    result = TestResult.new(test_id: "TS-TEST-001", status: "error")

    assert_equal "", DisplayHelpers.tc_count_display(result)
  end

  def test_separator
    assert_equal "=" * 65, DisplayHelpers.separator
  end

  def test_color_with_color_enabled
    result = DisplayHelpers.color("hello", :green, use_color: true)
    assert_equal "\033[32mhello\033[0m", result
  end

  def test_color_with_color_disabled
    result = DisplayHelpers.color("hello", :green, use_color: false)
    assert_equal "hello", result
  end

  def test_color_red
    result = DisplayHelpers.color("fail", :red, use_color: true)
    assert_equal "\033[31mfail\033[0m", result
  end

  # Suite-level formatting tests

  def test_double_separator
    assert_equal "\u2550" * 65, DisplayHelpers.double_separator
    assert_equal 65, DisplayHelpers.double_separator.length
  end

  def test_format_suite_duration_under_60
    assert_equal "45.3s", DisplayHelpers.format_suite_duration(45.3)
  end

  def test_format_suite_duration_over_60
    assert_equal "4m 25s", DisplayHelpers.format_suite_duration(265)
  end

  def test_format_suite_duration_exact_minute
    assert_equal "2m 00s", DisplayHelpers.format_suite_duration(120)
  end

  def test_format_suite_elapsed_short
    result = DisplayHelpers.format_suite_elapsed(45.3)
    assert_equal "  45.3s", result
    assert_equal 7, result.length
  end

  def test_format_suite_elapsed_minutes
    result = DisplayHelpers.format_suite_elapsed(265)
    assert_equal " 4m 25s", result
    assert_equal 7, result.length
  end

  def test_format_suite_test_line
    line = DisplayHelpers.format_suite_test_line(
      "\u2713", 265, "ace-bundle", "TS-BUNDLE-001-section-workflow", "5/5 cases",
      pkg_width: 12, name_width: 35
    )
    assert_includes line, "\u2713"
    assert_includes line, "4m 25s"
    assert_includes line, "ace-bundle"
    assert_includes line, "TS-BUNDLE-001-section-workflow"
    assert_includes line, "5/5 cases"
  end

  def test_format_suite_summary_all_passed
    lines = DisplayHelpers.format_suite_summary(
      {total: 5, passed: 5, failed: 0, errors: 0, duration: 265, failed_details: []},
      use_color: false
    )
    text = lines.join("\n")
    assert_includes text, "Duration:"
    assert_includes text, "4m 25s"
    assert_includes text, "5 passed, 0 failed"
    assert_includes text, "\u2713 ALL TESTS PASSED"
    refute_includes text, "Failed tests:"
  end

  def test_format_suite_summary_with_case_counts
    lines = DisplayHelpers.format_suite_summary(
      {
        total: 3, passed: 2, failed: 1, errors: 0, duration: 90,
        total_cases: 13, passed_cases: 8,
        failed_details: []
      },
      use_color: false
    )
    text = lines.join("\n")
    assert_includes text, "Test cases:  8 passed, 5 failed (62%)"
    assert_includes text, "2 passed, 1 failed"
  end

  def test_format_suite_summary_omits_case_line_when_zero
    lines = DisplayHelpers.format_suite_summary(
      {
        total: 1, passed: 1, failed: 0, errors: 0, duration: 10,
        total_cases: 0, passed_cases: 0,
        failed_details: []
      },
      use_color: false
    )
    text = lines.join("\n")
    refute_includes text, "Test cases:"
  end

  def test_format_suite_summary_with_failures
    lines = DisplayHelpers.format_suite_summary(
      {
        total: 5, passed: 3, failed: 2, errors: 0, duration: 120,
        failed_details: [
          {package: "ace-lint", test_name: "TS-LINT-002", cases: "3/5 cases"}
        ]
      },
      use_color: false
    )
    text = lines.join("\n")
    assert_includes text, "Failed tests:"
    assert_includes text, "ace-lint/TS-LINT-002: 3/5 cases"
    assert_includes text, "3 passed, 2 failed"
    assert_includes text, "\u2717 SOME TESTS FAILED"
  end
end
