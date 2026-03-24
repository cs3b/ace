# frozen_string_literal: true

require_relative "../test_helper"

class TestResultTest < Minitest::Test
  TestResult = Ace::Test::EndToEndRunner::Models::TestResult

  def test_success
    result = create_result(status: "pass")
    assert result.success?
    refute result.failed?
  end

  def test_failure
    result = create_result(status: "fail")
    refute result.success?
    assert result.failed?
  end

  def test_error_is_failed
    result = create_result(status: "error")
    assert result.failed?
  end

  def test_partial_is_failed
    result = create_result(status: "partial")
    refute result.success?
    assert result.failed?
  end

  def test_passed_count
    result = create_result(test_cases: [
      {id: "TC-001", status: "pass"},
      {id: "TC-002", status: "fail"},
      {id: "TC-003", status: "pass"}
    ])
    assert_equal 2, result.passed_count
  end

  def test_failed_count
    result = create_result(test_cases: [
      {id: "TC-001", status: "pass"},
      {id: "TC-002", status: "fail"},
      {id: "TC-003", status: "fail"}
    ])
    assert_equal 2, result.failed_count
  end

  def test_total_count
    result = create_result(test_cases: [
      {id: "TC-001", status: "pass"},
      {id: "TC-002", status: "fail"}
    ])
    assert_equal 2, result.total_count
  end

  def test_duration
    started = Time.now
    completed = started + 45.5
    result = create_result(started_at: started, completed_at: completed)
    assert_in_delta 45.5, result.duration, 0.01
  end

  def test_duration_display_seconds
    started = Time.now
    completed = started + 32.1
    result = create_result(started_at: started, completed_at: completed)
    assert_equal "32.1s", result.duration_display
  end

  def test_duration_display_minutes
    started = Time.now
    completed = started + 125
    result = create_result(started_at: started, completed_at: completed)
    assert_equal "2m 5s", result.duration_display
  end

  def test_empty_test_cases_defaults
    result = create_result(test_cases: [])
    assert_equal 0, result.passed_count
    assert_equal 0, result.failed_count
    assert_equal 0, result.total_count
  end

  def test_failed_test_case_ids_with_failures
    result = create_result(test_cases: [
      {id: "TC-001", status: "pass"},
      {id: "TC-002", status: "fail"},
      {id: "TC-003", status: "fail"}
    ])
    assert_equal ["TC-002", "TC-003"], result.failed_test_case_ids
  end

  def test_failed_test_case_ids_all_passing
    result = create_result(test_cases: [
      {id: "TC-001", status: "pass"},
      {id: "TC-002", status: "pass"}
    ])
    assert_equal [], result.failed_test_case_ids
  end

  def test_failed_test_case_ids_empty_test_cases
    result = create_result(test_cases: [])
    assert_equal [], result.failed_test_case_ids
  end

  def test_with_report_dir_returns_new_result
    result = create_result(status: "pass", summary: "All good")
    new_result = result.with_report_dir("/tmp/reports")

    assert_equal "/tmp/reports", new_result.report_dir
    assert_nil result.report_dir
    assert_equal result.test_id, new_result.test_id
    assert_equal result.status, new_result.status
    assert_equal result.summary, new_result.summary
  end

  private

  def create_result(overrides = {})
    defaults = {
      test_id: "TS-TEST-001",
      status: "pass",
      test_cases: [],
      summary: "Test summary"
    }
    TestResult.new(**defaults.merge(overrides))
  end
end
