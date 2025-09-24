# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/atoms/task_reference_parser"

class TaskReferenceParserTest < Minitest::Test
  def setup
    @parser = Ace::Taskflow::Atoms::TaskReferenceParser
  end

  def test_parse_qualified_reference
    result = @parser.parse("v.0.9.0+018")

    assert_equal "v.0.9.0", result[:context]
    assert_equal "018", result[:number]
    assert result[:qualified]
    assert_equal "v.0.9.0+018", result[:original]
  end

  def test_parse_backlog_reference
    result = @parser.parse("backlog+025")

    assert_equal "backlog", result[:context]
    assert_equal "025", result[:number]
    assert result[:qualified]
  end

  def test_parse_simple_reference
    result = @parser.parse("018")

    assert_equal "current", result[:context]
    assert_equal "018", result[:number]
    refute result[:qualified]
  end

  def test_parse_task_dot_reference
    result = @parser.parse("task.018")

    assert_equal "current", result[:context]
    assert_equal "018", result[:number]
    refute result[:qualified]
  end

  def test_parse_current_reference
    result = @parser.parse("current+018")

    assert_equal "current", result[:context]
    assert_equal "018", result[:number]
    assert result[:qualified]
  end

  def test_parse_invalid_reference
    assert_nil @parser.parse("invalid")
    assert_nil @parser.parse("")
    assert_nil @parser.parse(nil)
  end

  def test_valid_predicate
    assert @parser.valid?("v.0.9.0+018")
    assert @parser.valid?("backlog+025")
    assert @parser.valid?("018")
    assert @parser.valid?("task.018")

    refute @parser.valid?("invalid")
    refute @parser.valid?("")
  end

  def test_qualified_predicate
    assert @parser.qualified?("v.0.9.0+018")
    assert @parser.qualified?("backlog+025")
    assert @parser.qualified?("current+018")

    refute @parser.qualified?("018")
    refute @parser.qualified?("task.018")
  end

  def test_release_context_predicate
    assert @parser.release_context?("v.0.9.0")
    assert @parser.release_context?("v.0.10.0-beta")

    refute @parser.release_context?("backlog")
    refute @parser.release_context?("current")
    refute @parser.release_context?("018")
  end

  def test_format_qualified_reference
    assert_equal "v.0.9.0+018", @parser.format("v.0.9.0", "18", qualified: true)
    assert_equal "backlog+025", @parser.format("backlog", 25, qualified: true)
    assert_equal "current+018", @parser.format("current", 18, qualified: true)
    assert_equal "018", @parser.format("current", 18, qualified: false)
  end

  def test_convert_reference_formats
    assert_equal "current+018", @parser.convert("018", :qualified)
    assert_equal "current+018", @parser.convert("018", :qualified, context: "current")
    assert_equal "v.0.9.0+018", @parser.convert("018", :qualified, context: "v.0.9.0")
    assert_equal "018", @parser.convert("v.0.9.0+018", :simple)
    assert_nil @parser.convert("invalid", :qualified)
  end

  def test_extract_references_from_text
    text = "See tasks v.0.9.0+018 and backlog+025, also task.003"
    references = @parser.extract_references(text)

    assert_includes references, "v.0.9.0+018"
    assert_includes references, "backlog+025"
    assert_includes references, "task.003"
  end
end