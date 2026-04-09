# frozen_string_literal: true

require_relative "../test_helper"

class SuiteReportPromptBuilderTest < Minitest::Test
  SuiteReportPromptBuilder = Ace::Test::EndToEndRunner::Atoms::SuiteReportPromptBuilder

  def setup
    @builder = SuiteReportPromptBuilder.new
  end

  def test_system_prompt_exists_and_is_non_empty
    assert SuiteReportPromptBuilder.const_defined?(:SYSTEM_PROMPT)
    refute_empty SuiteReportPromptBuilder::SYSTEM_PROMPT
  end

  def test_system_prompt_mentions_required_sections
    prompt = SuiteReportPromptBuilder::SYSTEM_PROMPT
    assert_match(/Summary Table/, prompt)
    assert_match(/Failed Tests/, prompt)
    assert_match(/Friction Analysis/, prompt)
    assert_match(/Improvement Suggestions/, prompt)
    assert_match(/Positive Observations/, prompt)
  end

  def test_prompt_includes_package_and_timestamp
    results_data = [make_result_data("TS-TEST-001", "Test One", "pass")]

    prompt = @builder.build(results_data,
      package: "ace-lint",
      timestamp: "abc123",
      overall_status: "pass",
      executed_at: "2025-01-01T00:00:00Z")

    assert_match(/ace-lint/, prompt)
    assert_match(/abc123/, prompt)
    assert_match(/2025-01-01T00:00:00Z/, prompt)
  end

  def test_prompt_includes_test_data
    results_data = [
      make_result_data("TS-TEST-001", "First Test", "pass", passed: 3, total: 3),
      make_result_data("TS-TEST-002", "Second Test", "fail", passed: 1, failed: 1, total: 2)
    ]

    prompt = @builder.build(results_data,
      package: "ace-lint",
      timestamp: "ts1234",
      overall_status: "partial",
      executed_at: "2025-01-01T00:00:00Z")

    assert_match(/TS-TEST-001/, prompt)
    assert_match(/First Test/, prompt)
    assert_match(/TS-TEST-002/, prompt)
    assert_match(/Second Test/, prompt)
    assert_match(/4\/5 test cases passed/, prompt)
  end

  def test_prompt_includes_summary_content_when_present
    results_data = [
      make_result_data("TS-TEST-001", "Test One", "pass",
        summary_content: "## Summary\nAll tests passed successfully.")
    ]

    prompt = @builder.build(results_data,
      package: "ace-lint",
      timestamp: "ts1234",
      overall_status: "pass",
      executed_at: "2025-01-01T00:00:00Z")

    assert_match(/Summary Report/, prompt)
    assert_match(/All tests passed successfully/, prompt)
  end

  def test_prompt_includes_experience_content_when_present
    results_data = [
      make_result_data("TS-TEST-001", "Test One", "pass",
        experience_content: "## Experience\nSmooth execution, no friction.")
    ]

    prompt = @builder.build(results_data,
      package: "ace-lint",
      timestamp: "ts1234",
      overall_status: "pass",
      executed_at: "2025-01-01T00:00:00Z")

    assert_match(/Experience Report/, prompt)
    assert_match(/Smooth execution, no friction/, prompt)
  end

  def test_prompt_omits_nil_content_fields
    results_data = [
      make_result_data("TS-TEST-001", "Test One", "pass",
        summary_content: nil, experience_content: nil)
    ]

    prompt = @builder.build(results_data,
      package: "ace-lint",
      timestamp: "ts1234",
      overall_status: "pass",
      executed_at: "2025-01-01T00:00:00Z")

    refute_match(/Summary Report/, prompt)
    refute_match(/Experience Report/, prompt)
  end

  def test_prompt_includes_test_cases
    test_cases = [
      {id: "TC-001", description: "Check output", status: "pass"},
      {id: "TC-002", description: "Verify format", status: "fail"}
    ]
    results_data = [
      make_result_data("TS-TEST-001", "Test One", "fail",
        passed: 1, failed: 1, total: 2, test_cases: test_cases)
    ]

    prompt = @builder.build(results_data,
      package: "ace-lint",
      timestamp: "ts1234",
      overall_status: "fail",
      executed_at: "2025-01-01T00:00:00Z")

    assert_match(/TC-001.*Check output.*pass/, prompt)
    assert_match(/TC-002.*Verify format.*fail/, prompt)
  end

  def test_prompt_includes_canonical_failed_tc_ids_for_failed_results
    test_cases = [
      {id: "TC-001", description: "Check output", status: "pass"},
      {id: "TC-002", description: "Verify format", status: "fail"},
      {id: "TC-003", description: "Inspect state", status: "fail"}
    ]
    results_data = [
      make_result_data("TS-TEST-001", "Test One", "fail",
        passed: 1, failed: 2, total: 3, test_cases: test_cases)
    ]

    prompt = @builder.build(results_data,
      package: "ace-lint",
      timestamp: "ts1234",
      overall_status: "fail",
      executed_at: "2025-01-01T00:00:00Z")

    assert_match(/Canonical Failed TC IDs:/, prompt)
    assert_match(/- TC-002/, prompt)
    assert_match(/- TC-003/, prompt)
    assert_match(/Use these failed TC IDs verbatim/, prompt)
  end

  def test_prompt_includes_report_dir_name
    results_data = [
      make_result_data("TS-TEST-001", "Test One", "pass",
        report_dir_name: "ts1234-lint-ts001-reports")
    ]

    prompt = @builder.build(results_data,
      package: "ace-lint",
      timestamp: "ts1234",
      overall_status: "pass",
      executed_at: "2025-01-01T00:00:00Z")

    assert_match(/ts1234-lint-ts001-reports/, prompt)
  end

  private

  def make_result_data(test_id, title, status,
    passed: 1, failed: 0, total: 1,
    test_cases: [], report_dir_name: nil,
    summary_content: nil, experience_content: nil)
    {
      test_id: test_id,
      title: title,
      status: status,
      passed: passed,
      failed: failed,
      total: total,
      test_cases: test_cases,
      report_dir_name: report_dir_name,
      summary_content: summary_content,
      experience_content: experience_content
    }
  end
end
