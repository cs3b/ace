# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/field_argument_parser"

class FieldArgumentParserTest < Minitest::Test
  def setup
    @parser = Ace::Taskflow::Molecules::FieldArgumentParser
  end

  # ========================================
  # parse tests
  # ========================================

  def test_parse_simple_string_field
    result = @parser.parse(["priority=high"])

    assert_equal({ "priority" => "high" }, result)
  end

  def test_parse_quoted_string_field
    result = @parser.parse(['estimate="2 weeks"'])

    assert_equal({ "estimate" => "2 weeks" }, result)
  end

  def test_parse_integer_field
    result = @parser.parse(["count=42"])

    assert_equal({ "count" => 42 }, result)
  end

  def test_parse_boolean_true_field
    result = @parser.parse(["completed=true"])

    assert_equal({ "completed" => true }, result)
  end

  def test_parse_boolean_false_field
    result = @parser.parse(["completed=false"])

    assert_equal({ "completed" => false }, result)
  end

  def test_parse_array_field
    result = @parser.parse(["dependencies=[082, 083]"])

    assert_equal({ "dependencies" => [82, 83] }, result)
  end

  def test_parse_empty_array_field
    result = @parser.parse(["dependencies=[]"])

    assert_equal({ "dependencies" => [] }, result)
  end

  def test_parse_empty_value_field
    result = @parser.parse(["description="])

    assert_equal({ "description" => "" }, result)
  end

  def test_parse_nested_field
    result = @parser.parse(["worktree.branch=081-fix-auth"])

    assert_equal({ "worktree.branch" => "081-fix-auth" }, result)
  end

  def test_parse_deeply_nested_field
    result = @parser.parse(["a.b.c.d=value"])

    assert_equal({ "a.b.c.d" => "value" }, result)
  end

  def test_parse_multiple_fields
    result = @parser.parse([
      "priority=high",
      "estimate=1 week",
      "worktree.branch=090-task-update"
    ])

    expected = {
      "priority" => "high",
      "estimate" => "1 week",
      "worktree.branch" => "090-task-update"
    }
    assert_equal expected, result
  end

  def test_parse_field_with_equals_in_value
    result = @parser.parse(['note="x=y"'])

    assert_equal({ "note" => "x=y" }, result)
  end

  def test_parse_invalid_syntax_raises_error
    error = assert_raises(Ace::Taskflow::Molecules::FieldArgumentParser::ParseError) do
      @parser.parse(["invalid_no_equals"])
    end

    assert_match(/Invalid field syntax/, error.message)
  end

  def test_parse_float_field
    result = @parser.parse(["percentage=95.5"])

    assert_equal({ "percentage" => 95.5 }, result)
  end

  def test_parse_array_of_strings
    result = @parser.parse(["tags=[feature, refactor, bug]"])

    assert_equal({ "tags" => ["feature", "refactor", "bug"] }, result)
  end

  def test_parse_mixed_type_array
    result = @parser.parse(['data=[1, "hello", true]'])

    assert_equal({ "data" => [1, "hello", true] }, result)
  end

  # ========================================
  # type inference tests
  # ========================================

  def test_parse_with_type_inference
    field_args = [
      "count=42",
      "percentage=95.5",
      "completed=true",
      "name=test",
      'description="quoted string"'
    ]
    updates = @parser.parse(field_args)

    # Verify type inference
    assert_equal 42, updates["count"]
    assert_equal 95.5, updates["percentage"]
    assert_equal true, updates["completed"]
    assert_equal "test", updates["name"]
    assert_equal "quoted string", updates["description"]
  end

  def test_parse_special_characters
    result = @parser.parse([
      'title="Task: Update \'system\' config"',
      'path="/Users/name/My Documents/file.txt"'
    ])

    assert_equal "Task: Update 'system' config", result["title"]
    assert_equal "/Users/name/My Documents/file.txt", result["path"]
  end

  def test_parse_negative_numbers
    result = @parser.parse([
      "temperature=-42",
      "balance=-123.45"
    ])

    assert_equal(-42, result["temperature"])
    assert_equal(-123.45, result["balance"])
  end
end