# frozen_string_literal: true

require_relative "../../test_helper"

class TcFidelityValidatorTest < Minitest::Test
  TcFidelityValidator = Ace::Test::EndToEndRunner::Atoms::TcFidelityValidator
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestCase = Ace::Test::EndToEndRunner::Models::TestCase

  def test_valid_when_counts_match
    parsed = {test_cases: make_tcs(5)}
    scenario = make_scenario_with_tcs(5)

    result = TcFidelityValidator.validate(parsed, scenario)
    assert_nil result
  end

  def test_invalid_when_agent_reports_fewer_tcs
    parsed = {test_cases: make_tcs(3)}
    scenario = make_scenario_with_tcs(5)

    result = TcFidelityValidator.validate(parsed, scenario)
    refute_nil result
    assert_match(/fidelity mismatch/, result[:error])
    assert_match(/reported 3.*has 5/, result[:error])
    assert_equal 5, result[:expected_count]
    assert_equal 3, result[:reported_count]
  end

  def test_invalid_when_agent_reports_more_tcs
    parsed = {test_cases: make_tcs(7)}
    scenario = make_scenario_with_tcs(5)

    result = TcFidelityValidator.validate(parsed, scenario)
    refute_nil result
    assert_match(/reported 7.*has 5/, result[:error])
  end

  def test_valid_with_filtered_tc_ids
    parsed = {test_cases: make_tcs(2)}
    scenario = make_scenario_with_tcs(5)

    # Only 2 TCs were requested via filter
    result = TcFidelityValidator.validate(parsed, scenario, filtered_tc_ids: %w[TC-001 TC-003])
    assert_nil result
  end

  def test_invalid_with_filtered_tc_ids_mismatch
    parsed = {test_cases: make_tcs(1)}
    scenario = make_scenario_with_tcs(5)

    result = TcFidelityValidator.validate(parsed, scenario, filtered_tc_ids: %w[TC-001 TC-003])
    refute_nil result
    assert_match(/reported 1.*has 2/, result[:error])
  end

  def test_skips_validation_when_no_expected_ids
    parsed = {test_cases: make_tcs(3)}
    scenario = make_scenario_without_tcs

    result = TcFidelityValidator.validate(parsed, scenario)
    assert_nil result
  end

  def test_handles_nil_test_cases_in_parsed
    parsed = {test_cases: nil}
    scenario = make_scenario_with_tcs(3)

    result = TcFidelityValidator.validate(parsed, scenario)
    refute_nil result
    assert_equal 0, result[:reported_count]
  end

  def test_error_includes_expected_ids
    parsed = {test_cases: make_tcs(2)}
    scenario = make_scenario_with_tcs(3)

    result = TcFidelityValidator.validate(parsed, scenario)
    assert_includes result[:expected_ids], "TC-001"
    assert_includes result[:expected_ids], "TC-002"
    assert_includes result[:expected_ids], "TC-003"
  end

  private

  def make_tcs(count)
    count.times.map { |i| {id: "TC-#{format("%03d", i + 1)}", status: "pass"} }
  end

  def make_scenario_with_tcs(count)
    test_cases = count.times.map do |i|
      tc_id = "TC-#{format("%03d", i + 1)}"
      TestCase.new(tc_id: tc_id, title: "Test #{i + 1}", file_path: "/tmp/#{tc_id}.tc.md", content: "# #{tc_id}")
    end

    TestScenario.new(
      test_id: "TS-LINT-001",
      title: "Test Scenario",
      area: "lint",
      package: "ace-lint",
      file_path: "/tmp/TS-LINT-001",
      content: "# Test",
      test_cases: test_cases
    )
  end

  def make_scenario_without_tcs
    TestScenario.new(
      test_id: "TS-LINT-001",
      title: "MT Test",
      area: "lint",
      package: "ace-lint",
      file_path: "/tmp/TS-LINT-001/scenario.yml",
      content: "# Test without TC headers"
    )
  end
end
