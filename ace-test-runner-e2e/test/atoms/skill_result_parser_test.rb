# frozen_string_literal: true

require_relative "../test_helper"

class SkillResultParserTest < Minitest::Test
  SkillResultParser = Ace::Test::EndToEndRunner::Atoms::SkillResultParser
  ResultParser = Ace::Test::EndToEndRunner::Atoms::ResultParser

  # --- Markdown Parsing ---

  def test_parse_full_markdown_contract
    text = <<~MD
      - **Test ID**: TS-LINT-001
      - **Status**: pass
      - **Passed**: 8
      - **Failed**: 0
      - **Total**: 8
      - **Report Paths**: 8p5jo2-lint-ts001-reports/*
      - **Issues**: None
    MD

    result = SkillResultParser.parse(text)

    assert_equal "TS-LINT-001", result[:test_id]
    assert_equal "pass", result[:status]
    assert_equal 8, result[:test_cases].size
    assert(result[:test_cases].all? { |tc| tc[:status] == "pass" })
    assert_equal "8/8 passed", result[:summary]
    assert_equal "", result[:observations]
  end

  def test_parse_markdown_with_failures
    text = <<~MD
      - **Test ID**: TS-REVIEW-002
      - **Status**: partial
      - **Passed**: 3
      - **Failed**: 2
      - **Total**: 5
      - **Report Paths**: abc123-review-mt002-reports/*
      - **Issues**: TC-004 timed out, TC-005 unexpected exit code
    MD

    result = SkillResultParser.parse(text)

    assert_equal "TS-REVIEW-002", result[:test_id]
    assert_equal "partial", result[:status]
    assert_equal 5, result[:test_cases].size
    assert_equal 3, result[:test_cases].count { |tc| tc[:status] == "pass" }
    assert_equal 2, result[:test_cases].count { |tc| tc[:status] == "fail" }
    assert_equal "3/5 passed", result[:summary]
    assert_equal "TC-004 timed out, TC-005 unexpected exit code", result[:observations]
  end

  def test_parse_markdown_with_all_failures
    text = <<~MD
      - **Test ID**: TS-TEST-001
      - **Status**: fail
      - **Passed**: 0
      - **Failed**: 3
      - **Total**: 3
      - **Report Paths**: xyz789-test-ts001-reports/*
      - **Issues**: All test cases failed due to missing dependency
    MD

    result = SkillResultParser.parse(text)

    assert_equal "fail", result[:status]
    assert_equal 3, result[:test_cases].size
    assert(result[:test_cases].all? { |tc| tc[:status] == "fail" })
    assert_equal "0/3 passed", result[:summary]
  end

  def test_parse_markdown_embedded_in_longer_text
    text = <<~MD
      I've completed the E2E test execution. Here are the results:

      - **Test ID**: TS-LINT-001
      - **Status**: pass
      - **Passed**: 4
      - **Failed**: 0
      - **Total**: 4
      - **Report Paths**: ts1234-lint-ts001-reports/*
      - **Issues**: None

      The test ran successfully in the sandbox environment.
    MD

    result = SkillResultParser.parse(text)

    assert_equal "TS-LINT-001", result[:test_id]
    assert_equal "pass", result[:status]
    assert_equal 4, result[:test_cases].size
  end

  # --- JSON Fallback ---

  def test_parse_falls_back_to_json
    json_response = <<~JSON
      ```json
      {
        "test_id": "TS-LINT-001",
        "status": "pass",
        "test_cases": [
          {"id": "TC-001", "description": "Valid file", "status": "pass", "actual": "Exit 0", "notes": ""}
        ],
        "summary": "All tests passed"
      }
      ```
    JSON

    result = SkillResultParser.parse(json_response)

    assert_equal "TS-LINT-001", result[:test_id]
    assert_equal "pass", result[:status]
    assert_equal 1, result[:test_cases].size
    assert_equal "TC-001", result[:test_cases].first[:id]
  end

  # --- Error Cases ---

  def test_parse_empty_string_raises
    assert_raises(ResultParser::ParseError) do
      SkillResultParser.parse("")
    end
  end

  def test_parse_nil_raises
    assert_raises(ResultParser::ParseError) do
      SkillResultParser.parse(nil)
    end
  end

  def test_parse_no_recognizable_format_raises
    assert_raises(ResultParser::ParseError) do
      SkillResultParser.parse("Just some random text with no structure")
    end
  end

  # --- Normalization ---

  def test_normalized_test_cases_have_sequential_ids
    text = <<~MD
      - **Test ID**: TS-TEST-001
      - **Status**: partial
      - **Passed**: 2
      - **Failed**: 1
      - **Total**: 3
      - **Report Paths**: abc-test-ts001-reports/*
      - **Issues**: One failure
    MD

    result = SkillResultParser.parse(text)

    assert_equal "TC-001", result[:test_cases][0][:id]
    assert_equal "pass", result[:test_cases][0][:status]
    assert_equal "TC-002", result[:test_cases][1][:id]
    assert_equal "pass", result[:test_cases][1][:status]
    assert_equal "TC-003", result[:test_cases][2][:id]
    assert_equal "fail", result[:test_cases][2][:status]
  end

  def test_normalized_issues_none_becomes_empty
    text = <<~MD
      - **Test ID**: TS-TEST-001
      - **Status**: pass
      - **Passed**: 1
      - **Failed**: 0
      - **Total**: 1
      - **Report Paths**: abc-reports/*
      - **Issues**: None
    MD

    result = SkillResultParser.parse(text)
    assert_equal "", result[:observations]
  end

  def test_normalized_issues_preserved_when_not_none
    text = <<~MD
      - **Test ID**: TS-TEST-001
      - **Status**: fail
      - **Passed**: 0
      - **Failed**: 1
      - **Total**: 1
      - **Report Paths**: abc-reports/*
      - **Issues**: Permission denied on lint command
    MD

    result = SkillResultParser.parse(text)
    assert_equal "Permission denied on lint command", result[:observations]
  end

  # --- Case-Insensitive Status Normalization ---

  def test_normalize_status_downcases_capitalized
    text = <<~MD
      - **Test ID**: TS-TEST-001
      - **Status**: Pass
      - **Passed**: 3
      - **Failed**: 0
      - **Total**: 3
      - **Report Paths**: abc-reports/*
      - **Issues**: None
    MD

    result = SkillResultParser.parse(text)
    assert_equal "pass", result[:status]
  end

  def test_normalize_status_downcases_uppercase
    text = <<~MD
      - **Test ID**: TS-TEST-001
      - **Status**: PASS
      - **Passed**: 3
      - **Failed**: 0
      - **Total**: 3
      - **Report Paths**: abc-reports/*
      - **Issues**: None
    MD

    result = SkillResultParser.parse(text)
    assert_equal "pass", result[:status]
  end

  def test_normalize_status_downcases_fail
    text = <<~MD
      - **Test ID**: TS-TEST-001
      - **Status**: FAIL
      - **Passed**: 0
      - **Failed**: 1
      - **Total**: 1
      - **Report Paths**: abc-reports/*
      - **Issues**: Something broke
    MD

    result = SkillResultParser.parse(text)
    assert_equal "fail", result[:status]
  end

  # --- TC-Level Parsing ---

  def test_parse_tc_markdown_contract
    text = <<~MD
      - **Test ID**: TS-LINT-001
      - **TC ID**: TC-001
      - **Status**: pass
      - **Report Paths**: 8xyz12-lint-ts001-tc001-reports/*
      - **Issues**: None
    MD

    result = SkillResultParser.parse_tc(text)

    assert_equal "TS-LINT-001", result[:test_id]
    assert_equal "pass", result[:status]
    assert_equal 1, result[:test_cases].size
    assert_equal "TC-001", result[:test_cases].first[:id]
    assert_equal "pass", result[:test_cases].first[:status]
  end

  def test_parse_tc_status_fail
    text = <<~MD
      - **Test ID**: TS-LINT-001
      - **TC ID**: TC-002
      - **Status**: fail
      - **Report Paths**: 8xyz12-lint-ts001-tc002-reports/*
      - **Issues**: Wrong exit code
    MD

    result = SkillResultParser.parse_tc(text)
    assert_equal "fail", result[:status]
    assert_equal "TC-002", result[:test_cases].first[:id]
  end

  def test_parse_tc_issues_none_becomes_empty
    text = <<~MD
      - **Test ID**: TS-LINT-001
      - **TC ID**: TC-001
      - **Status**: pass
      - **Report Paths**: reports/*
      - **Issues**: None
    MD

    result = SkillResultParser.parse_tc(text)
    assert_equal "", result[:observations]
  end

  def test_parse_tc_issues_preserved
    text = <<~MD
      - **Test ID**: TS-LINT-001
      - **TC ID**: TC-001
      - **Status**: fail
      - **Report Paths**: reports/*
      - **Issues**: StandardRB not found in PATH
    MD

    result = SkillResultParser.parse_tc(text)
    assert_equal "StandardRB not found in PATH", result[:observations]
  end

  def test_parse_tc_falls_back_to_multi_tc_parse
    text = <<~MD
      - **Test ID**: TS-LINT-001
      - **Status**: pass
      - **Passed**: 2
      - **Failed**: 0
      - **Total**: 2
      - **Report Paths**: abc-reports/*
      - **Issues**: None
    MD

    result = SkillResultParser.parse_tc(text)
    assert_equal "TS-LINT-001", result[:test_id]
    assert_equal 2, result[:test_cases].size
  end

  def test_parse_tc_empty_raises
    assert_raises(ResultParser::ParseError) do
      SkillResultParser.parse_tc("")
    end
  end

  # --- Verifier Parsing ---

  def test_parse_verifier_contract_with_failed_categories
    text = <<~MD
      - **Test ID**: TS-B36TS-001
      - **Status**: partial
      - **TCs Passed**: 6
      - **TCs Failed**: 2
      - **TCs Total**: 8
      - **Score**: 0.75
      - **Verdict**: partial
      - **Failed TCs**: TC-003:test-spec-error, TC-007:tool-bug
      - **Issues**: None
    MD

    result = SkillResultParser.parse_verifier(text)

    assert_equal "TS-B36TS-001", result[:test_id]
    assert_equal "partial", result[:status]
    assert_equal 8, result[:test_cases].size
    failed_cases = result[:test_cases].select { |tc| tc[:status] == "fail" }
    assert_equal 2, failed_cases.size
    assert_equal "TC-003", failed_cases[0][:id]
    assert_equal "test-spec-error", failed_cases[0][:category]
    assert_equal "TC-007", failed_cases[1][:id]
    assert_equal "tool-bug", failed_cases[1][:category]
  end

  def test_parse_verifier_falls_back_to_standard_parse_when_verifier_fields_missing
    text = <<~MD
      - **Test ID**: TS-LINT-001
      - **Status**: pass
      - **Passed**: 1
      - **Failed**: 0
      - **Total**: 1
      - **Issues**: None
    MD

    result = SkillResultParser.parse_verifier(text)
    assert_equal "TS-LINT-001", result[:test_id]
    assert_equal "pass", result[:status]
    assert_equal 1, result[:test_cases].size
  end

  def test_parse_tc_nil_raises
    assert_raises(ResultParser::ParseError) do
      SkillResultParser.parse_tc(nil)
    end
  end

  def test_parse_verifier_failed_tcs_without_category
    text = <<~MD
      - **Test ID**: TS-B36TS-001
      - **Status**: partial
      - **TCs Passed**: 7
      - **TCs Failed**: 1
      - **TCs Total**: 8
      - **Score**: 0.875
      - **Verdict**: partial
      - **Failed TCs**: TC-003
      - **Issues**: None
    MD

    result = SkillResultParser.parse_verifier(text)
    failed_cases = result[:test_cases].select { |tc| tc[:status] == "fail" }
    assert_equal 1, failed_cases.size
    assert_equal "TC-003", failed_cases[0][:id]
    assert_equal "unknown", failed_cases[0][:category]
  end

  def test_parse_verifier_no_duplicate_tc_ids
    text = <<~MD
      - **Test ID**: TS-TEST-001
      - **Status**: partial
      - **TCs Passed**: 6
      - **TCs Failed**: 2
      - **TCs Total**: 8
      - **Score**: 0.75
      - **Verdict**: partial
      - **Failed TCs**: TC-003:test-spec-error, TC-007:tool-bug
      - **Issues**: None
    MD

    result = SkillResultParser.parse_verifier(text)
    ids = result[:test_cases].map { |tc| tc[:id] }
    assert_equal ids.uniq.size, ids.size, "Expected no duplicate TC IDs but found: #{ids.tally.select { |_, v| v > 1 }}"
  end

  def test_parse_verifier_minimal_pass_evidence_line
    text = "PASS Evidence: - `notes/inbox/` is empty: `find notes/inbox -type f` returned no files."

    result = SkillResultParser.parse_verifier(text)

    assert_equal "pass", result[:status]
    assert_equal 1, result[:test_cases].size
    assert_equal "pass", result[:test_cases].first[:status]
    assert_includes result[:summary], "notes/inbox/"
    assert_includes result[:observations], "notes/inbox/"
  end

  def test_parse_tc_result_has_single_test_case
    text = <<~MD
      - **Test ID**: TS-LINT-001
      - **TC ID**: TC-003
      - **Status**: pass
      - **Report Paths**: reports/*
      - **Issues**: None
    MD

    result = SkillResultParser.parse_tc(text)
    assert_equal 1, result[:test_cases].size
  end
end
