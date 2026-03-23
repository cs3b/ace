# frozen_string_literal: true

require_relative "../test_helper"

class JsonParserTest < AceModelsTestCase
  def test_parse_valid_json
    json = '{"key": "value", "number": 42}'
    result = Ace::Support::Models::Atoms::JsonParser.parse(json)

    assert_equal "value", result["key"]
    assert_equal 42, result["number"]
  end

  def test_parse_invalid_json_raises_error
    assert_raises Ace::Support::Models::ApiError do
      Ace::Support::Models::Atoms::JsonParser.parse("not valid json")
    end
  end

  def test_to_json_basic
    data = {"key" => "value"}
    result = Ace::Support::Models::Atoms::JsonParser.to_json(data)

    assert_equal '{"key":"value"}', result
  end

  def test_to_json_pretty
    data = {"key" => "value"}
    result = Ace::Support::Models::Atoms::JsonParser.to_json(data, pretty: true)

    assert_includes result, "\n"
    assert_includes result, "key"
    assert_includes result, "value"
  end
end
