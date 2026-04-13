# frozen_string_literal: true

require_relative "../../test_helper"
require "stringio"

class SuiteSimpleDisplayManagerTest < Minitest::Test
  SuiteSimpleDisplayManager = Ace::Test::EndToEndRunner::Molecules::SuiteSimpleDisplayManager

  def setup
    @output = StringIO.new
    @queue = [
      {package: "ace-lint", test_file: "/path/to/TS-LINT-001-basic/scenario.yml"},
      {package: "ace-review", test_file: "/path/to/TS-REVIEW-001-pr/scenario.yml"}
    ]
    @display = SuiteSimpleDisplayManager.new(
      @queue, output: @output, use_color: false, pkg_width: 12, name_width: 25
    )
  end

  def test_show_header_outputs_separator_and_title
    @display.show_header(2, 2)
    out = @output.string

    assert_match(/\u2550{65}/, out, "should include double separator")
    assert_match(/ACE E2E Test Suite - Running 2 tests across 2 packages/, out)
  end

  def test_test_started_is_noop
    @display.test_started("ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml")
    assert_equal "", @output.string
  end

  def test_test_completed_outputs_columnar_line_for_pass
    result = {status: "pass", passed_cases: 5, total_cases: 5, test_name: "TS-LINT-001-basic"}
    @display.test_completed(result, "ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml", 12.3)
    out = @output.string

    assert_match(/\u2713/, out, "should include check icon for pass")
    assert_match(/12\.3s/, out, "should include elapsed time")
    assert_match(/ace-lint/, out, "should include package name")
    assert_match(/TS-LINT-001-basic/, out, "should include test name")
    assert_match(%r{5/5 cases}, out, "should include case counts")
  end

  def test_test_completed_outputs_columnar_line_for_fail
    result = {status: "fail", passed_cases: 3, total_cases: 5, test_name: "TS-LINT-001-basic"}
    @display.test_completed(result, "ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml", 8.7)
    out = @output.string

    assert_match(/\u2717/, out, "should include X icon for fail")
    assert_match(%r{3/5 cases}, out, "should include case counts")
  end

  def test_test_completed_omits_cases_when_zero
    result = {status: "pass", passed_cases: nil, total_cases: nil, test_name: "TS-LINT-001-basic"}
    @display.test_completed(result, "ace-lint", "/path/to/TS-LINT-001-basic/scenario.yml", 5.0)
    out = @output.string

    refute_match(/cases/, out, "should not include cases when total is nil")
  end

  def test_refresh_is_noop
    @display.refresh
    assert_equal "", @output.string
  end

  def test_show_summary_outputs_formatted_summary
    results = {
      total: 2, passed: 1, failed: 1, errors: 0,
      packages: {
        "ace-lint" => [
          {status: "pass", test_name: "TS-LINT-001-basic", passed_cases: 5, total_cases: 5}
        ],
        "ace-review" => [
          {status: "fail", test_name: "TS-REVIEW-001-pr", passed_cases: 2, total_cases: 4}
        ]
      }
    }
    @display.show_summary(results, 30.5)
    out = @output.string

    assert_match(/Duration:/, out)
    assert_match(/Tests:/, out)
    assert_match(/1 passed, 1 failed/, out)
    assert_match(/SOME TESTS FAILED/, out)
    assert_match(/Failed tests:/, out)
    assert_match(%r{ace-review/TS-REVIEW-001-pr}, out)
  end

  def test_show_summary_all_passed
    results = {
      total: 2, passed: 2, failed: 0, errors: 0,
      packages: {
        "ace-lint" => [
          {status: "pass", test_name: "TS-LINT-001-basic", passed_cases: 5, total_cases: 5}
        ]
      }
    }
    @display.show_summary(results, 20.0)
    out = @output.string

    assert_match(/ALL TESTS PASSED/, out)
    refute_match(/Failed tests:/, out)
  end
end
