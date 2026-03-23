# frozen_string_literal: true

require "test_helper"

class FieldArgumentParserTest < AceSupportItemsTestCase
  def test_parses_simple_string_value
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["status=done"])
    assert_equal({"status" => "done"}, result)
  end

  def test_parses_boolean_true
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["active=true"])
    assert_equal({"active" => true}, result)
  end

  def test_parses_boolean_false
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["active=false"])
    assert_equal({"active" => false}, result)
  end

  def test_parses_integer
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["count=42"])
    assert_equal({"count" => 42}, result)
  end

  def test_parses_float
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["score=3.14"])
    assert_equal({"score" => 3.14}, result)
  end

  def test_parses_array
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["tags=[ux,design]"])
    assert_equal({"tags" => ["ux", "design"]}, result)
  end

  def test_parses_empty_array
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["tags=[]"])
    assert_equal({"tags" => []}, result)
  end

  def test_parses_multiple_fields
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["status=done", "title=Hello"])
    assert_equal({"status" => "done", "title" => "Hello"}, result)
  end

  def test_raises_on_invalid_syntax
    assert_raises(Ace::Support::Items::Atoms::FieldArgumentParser::ParseError) do
      Ace::Support::Items::Atoms::FieldArgumentParser.parse(["no-equals-sign"])
    end
  end

  def test_strips_quoted_strings
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(['title="My Idea"'])
    assert_equal({"title" => "My Idea"}, result)
  end

  def test_parses_empty_value
    result = Ace::Support::Items::Atoms::FieldArgumentParser.parse(["note="])
    assert_equal({"note" => ""}, result)
  end
end
