# frozen_string_literal: true

require_relative "../../test_helper"

class ResultParserTest < Minitest::Test
  ResultParser = Ace::Test::EndToEndRunner::Atoms::ResultParser

  def test_parse_valid_json_response
    response = <<~JSON
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

    result = ResultParser.parse(response)
    assert_equal "TS-LINT-001", result[:test_id]
    assert_equal "pass", result[:status]
    assert_equal 1, result[:test_cases].size
    assert_equal "TC-001", result[:test_cases].first[:id]
    assert_equal "pass", result[:test_cases].first[:status]
    assert_equal "All tests passed", result[:summary]
  end

  def test_parse_json_without_fences
    response = '{"test_id": "TS-TEST-001", "status": "fail", "test_cases": [], "summary": "Failed"}'

    result = ResultParser.parse(response)
    assert_equal "TS-TEST-001", result[:test_id]
    assert_equal "fail", result[:status]
  end

  def test_parse_json_with_surrounding_text
    response = <<~TEXT
      Here are the results of the test execution:

      ```json
      {
        "test_id": "TS-TEST-001",
        "status": "partial",
        "test_cases": [
          {"id": "TC-001", "status": "pass"},
          {"id": "TC-002", "status": "fail", "actual": "Exit code 1"}
        ],
        "summary": "1/2 passed"
      }
      ```

      The second test case failed because...
    TEXT

    result = ResultParser.parse(response)
    assert_equal "partial", result[:status]
    assert_equal 2, result[:test_cases].size
  end

  def test_parse_no_json_raises
    assert_raises(ResultParser::ParseError) do
      ResultParser.parse("No JSON here, just plain text about tests")
    end
  end

  def test_parse_invalid_json_raises
    assert_raises(ResultParser::ParseError) do
      ResultParser.parse('```json\n{invalid json}\n```')
    end
  end

  def test_parse_missing_required_fields_raises
    response = '{"some_field": "value"}'
    assert_raises(ResultParser::ParseError) do
      ResultParser.parse(response)
    end
  end

  def test_parse_empty_string_raises
    assert_raises(ResultParser::ParseError) do
      ResultParser.parse("")
    end
  end

  def test_parse_nil_raises
    assert_raises(ResultParser::ParseError) do
      ResultParser.parse(nil)
    end
  end

  def test_normalize_test_cases_adds_defaults
    response = '{"test_id": "TS-TEST-001", "status": "pass", "test_cases": [{"id": "TC-001"}]}'
    result = ResultParser.parse(response)

    tc = result[:test_cases].first
    assert_equal "TC-001", tc[:id]
    assert_equal "", tc[:description]
    assert_equal "fail", tc[:status]  # default when not specified
    assert_equal "", tc[:actual]
    assert_equal "", tc[:notes]
  end

  def test_extract_json_from_code_fence
    text = "```json\n{\"key\": \"value\"}\n```"
    json = ResultParser.extract_json(text)
    assert_equal '{"key": "value"}', json
  end

  def test_extract_json_from_raw_json_payload
    text = '{"key": "value"}'
    json = ResultParser.extract_json(text)
    assert_equal '{"key": "value"}', json
  end

  def test_extract_json_returns_nil_for_no_json
    assert_nil ResultParser.extract_json("No JSON here")
  end

  def test_extract_json_ignores_brace_fragments_in_prose
    text = "Artifacts live under results/tc/{NN}/ and no JSON was returned."

    assert_nil ResultParser.extract_json(text)
  end

  # --- Status Downcasing ---

  def test_normalize_result_downcases_status
    response = '{"test_id": "TS-TEST-001", "status": "Pass", "test_cases": [], "summary": "OK"}'
    result = ResultParser.parse(response)
    assert_equal "pass", result[:status]
  end

  def test_normalize_result_downcases_uppercase_status
    response = '{"test_id": "TS-TEST-001", "status": "FAIL", "test_cases": [], "summary": "Failed"}'
    result = ResultParser.parse(response)
    assert_equal "fail", result[:status]
  end

  # --- TC-Level Parsing ---

  def test_parse_tc_valid_json
    response = <<~JSON
      ```json
      {
        "test_id": "TS-LINT-001",
        "tc_id": "TC-001",
        "status": "pass",
        "actual": "Exit code 0, StandardRB used",
        "notes": "No issues",
        "summary": "TC-001 passed"
      }
      ```
    JSON

    result = ResultParser.parse_tc(response)
    assert_equal "TS-LINT-001", result[:test_id]
    assert_equal "pass", result[:status]
    assert_equal 1, result[:test_cases].size
    assert_equal "TC-001", result[:test_cases].first[:id]
    assert_equal "pass", result[:test_cases].first[:status]
  end

  def test_parse_tc_normalizes_to_test_cases_array
    response = '{"test_id": "TS-LINT-001", "tc_id": "TC-002", "status": "fail", "actual": "Wrong exit code"}'

    result = ResultParser.parse_tc(response)
    assert_equal 1, result[:test_cases].size
    assert_equal "TC-002", result[:test_cases].first[:id]
    assert_equal "fail", result[:test_cases].first[:status]
    assert_equal "Wrong exit code", result[:test_cases].first[:actual]
  end

  def test_parse_includes_goal_criteria_for_multi_tc_results
    response = <<~JSON
      {
        "test_id": "TS-GOAL-001",
        "status": "partial",
        "test_cases": [
          {
            "id": "TC-001",
            "status": "fail",
            "criteria": [
              {"id": "C1", "description": "Commit created", "status": "pass", "evidence": "git log -1"},
              {"description": "Message quality", "status": "fail"}
            ]
          }
        ]
      }
    JSON

    result = ResultParser.parse(response)
    criteria = result[:test_cases].first[:criteria]

    assert_equal 2, criteria.size
    assert_equal "C1", criteria[0][:id]
    assert_equal "Commit created", criteria[0][:description]
    assert_equal "pass", criteria[0][:status]
    assert_equal "git log -1", criteria[0][:evidence]
    assert_equal "Message quality", criteria[1][:description]
    assert_equal "fail", criteria[1][:status]
  end

  def test_parse_tc_includes_goal_criteria
    response = <<~JSON
      {
        "test_id": "TS-GOAL-001",
        "tc_id": "TC-003",
        "status": "pass",
        "summary": "All criteria met",
        "criteria": [
          {"description": "Artifact exists", "status": "PASS", "evidence": "results/tc/03/out.txt"}
        ]
      }
    JSON

    result = ResultParser.parse_tc(response)
    criteria = result[:test_cases].first[:criteria]

    assert_equal 1, criteria.size
    assert_equal "Artifact exists", criteria[0][:description]
    assert_equal "pass", criteria[0][:status]
    assert_equal "results/tc/03/out.txt", criteria[0][:evidence]
  end

  def test_parse_tc_no_json_raises
    assert_raises(ResultParser::ParseError) do
      ResultParser.parse_tc("No JSON here, just plain text")
    end
  end

  def test_parse_tc_empty_raises
    assert_raises(ResultParser::ParseError) do
      ResultParser.parse_tc("")
    end
  end

  def test_parse_tc_falls_back_to_multi_tc_format
    response = <<~JSON
      ```json
      {
        "test_id": "TS-LINT-001",
        "status": "pass",
        "test_cases": [
          {"id": "TC-001", "status": "pass"},
          {"id": "TC-002", "status": "pass"}
        ],
        "summary": "All passed"
      }
      ```
    JSON

    result = ResultParser.parse_tc(response)
    assert_equal 2, result[:test_cases].size
    assert_equal "TC-001", result[:test_cases].first[:id]
  end
end
