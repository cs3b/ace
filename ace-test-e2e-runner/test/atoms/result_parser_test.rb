# frozen_string_literal: true

require_relative "../test_helper"

class ResultParserTest < Minitest::Test
  ResultParser = Ace::Test::EndToEndRunner::Atoms::ResultParser

  def test_parse_valid_json_response
    response = <<~JSON
      ```json
      {
        "test_id": "MT-LINT-001",
        "status": "pass",
        "test_cases": [
          {"id": "TC-001", "description": "Valid file", "status": "pass", "actual": "Exit 0", "notes": ""}
        ],
        "summary": "All tests passed"
      }
      ```
    JSON

    result = ResultParser.parse(response)
    assert_equal "MT-LINT-001", result[:test_id]
    assert_equal "pass", result[:status]
    assert_equal 1, result[:test_cases].size
    assert_equal "TC-001", result[:test_cases].first[:id]
    assert_equal "pass", result[:test_cases].first[:status]
    assert_equal "All tests passed", result[:summary]
  end

  def test_parse_json_without_fences
    response = '{"test_id": "MT-TEST-001", "status": "fail", "test_cases": [], "summary": "Failed"}'

    result = ResultParser.parse(response)
    assert_equal "MT-TEST-001", result[:test_id]
    assert_equal "fail", result[:status]
  end

  def test_parse_json_with_surrounding_text
    response = <<~TEXT
      Here are the results of the test execution:

      ```json
      {
        "test_id": "MT-TEST-001",
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
    response = '{"test_id": "MT-TEST-001", "status": "pass", "test_cases": [{"id": "TC-001"}]}'
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

  def test_extract_json_from_raw
    text = 'Some text {"key": "value"} more text'
    json = ResultParser.extract_json(text)
    assert_equal '{"key": "value"}', json
  end

  def test_extract_json_returns_nil_for_no_json
    assert_nil ResultParser.extract_json("No JSON here")
  end
end
