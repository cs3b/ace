# frozen_string_literal: true

require "test_helper"

class TestResultTest < Minitest::Test
  def setup
    @result = Ace::TestRunner::Models::TestResult.new(
      passed: 10,
      failed: 2,
      skipped: 1,
      errors: 0,
      assertions: 25,
      duration: 1.5
    )
  end

  def test_calculates_total_tests
    assert_equal 13, @result.total_tests
  end

  def test_determines_success_status
    refute @result.success?

    successful_result = Ace::TestRunner::Models::TestResult.new(
      passed: 10,
      failed: 0,
      errors: 0
    )
    assert successful_result.success?
  end

  def test_checks_for_failures
    assert @result.has_failures?

    no_failures = Ace::TestRunner::Models::TestResult.new(passed: 10)
    refute no_failures.has_failures?
  end

  def test_calculates_pass_rate
    assert_in_delta 76.92, @result.pass_rate, 0.01
  end

  def test_handles_zero_tests_for_pass_rate
    empty_result = Ace::TestRunner::Models::TestResult.new
    assert_equal 0.0, empty_result.pass_rate
  end

  def test_generates_summary_line
    expected = "✅ 10 passed, ❌ 2 failed, ⚠️ 1 skipped"
    assert_equal expected, @result.summary_line
  end

  def test_summary_line_with_no_tests
    empty_result = Ace::TestRunner::Models::TestResult.new
    assert_equal "No tests executed", empty_result.summary_line
  end

  def test_converts_to_hash
    hash = @result.to_h
    assert_equal 10, hash[:passed]
    assert_equal 2, hash[:failed]
    assert_equal 13, hash[:total_tests]
    assert_in_delta 76.92, hash[:pass_rate], 0.01
    refute hash[:success]
  end

  def test_converts_to_json
    json = @result.to_json
    parsed = JSON.parse(json, symbolize_names: true)
    assert_equal 10, parsed[:passed]
    assert_equal 2, parsed[:failed]
  end

  def test_checks_for_skips
    assert @result.has_skips?

    no_skips = Ace::TestRunner::Models::TestResult.new(passed: 10)
    refute no_skips.has_skips?
  end

  def test_checks_for_deprecations
    refute @result.has_deprecations?

    @result.deprecations = ["Warning 1", "Warning 2"]
    assert @result.has_deprecations?
  end
end