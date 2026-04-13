# frozen_string_literal: true

require "test_helper"

class ItemIdParserTest < AceSupportItemsTestCase
  Parser = Ace::Support::Items::Atoms::ItemIdParser

  def test_parse_full_format
    item_id = Parser.parse("8pp.t.q7w")

    assert_equal "8ppq7w", item_id.raw_b36ts
    assert_equal "8pp", item_id.prefix
    assert_equal "t", item_id.type_marker
    assert_equal "q7w", item_id.suffix
    assert_nil item_id.subtask_char
  end

  def test_parse_subtask_format
    item_id = Parser.parse("8pp.t.q7w.a")

    assert_equal "8ppq7w", item_id.raw_b36ts
    assert_equal "8pp", item_id.prefix
    assert_equal "t", item_id.type_marker
    assert_equal "q7w", item_id.suffix
    assert_equal "a", item_id.subtask_char
    assert item_id.subtask?
  end

  def test_parse_short_format
    item_id = Parser.parse("t.q7w")

    assert_nil item_id.raw_b36ts
    assert_nil item_id.prefix
    assert_equal "t", item_id.type_marker
    assert_equal "q7w", item_id.suffix
  end

  def test_parse_suffix_only
    item_id = Parser.parse("q7w")

    assert_nil item_id.raw_b36ts
    assert_nil item_id.prefix
    assert_nil item_id.type_marker
    assert_equal "q7w", item_id.suffix
  end

  def test_parse_suffix_with_default_marker
    item_id = Parser.parse("q7w", default_marker: "t")

    assert_equal "t", item_id.type_marker
    assert_equal "q7w", item_id.suffix
  end

  def test_parse_raw_6_char_b36ts
    item_id = Parser.parse("8ppq7w")

    assert_equal "8ppq7w", item_id.raw_b36ts
    assert_equal "8pp", item_id.prefix
    assert_equal "q7w", item_id.suffix
    assert_nil item_id.type_marker
  end

  def test_parse_raw_with_default_marker
    item_id = Parser.parse("8ppq7w", default_marker: "t")

    assert_equal "8ppq7w", item_id.raw_b36ts
    assert_equal "t", item_id.type_marker
  end

  def test_parse_returns_nil_for_empty
    assert_nil Parser.parse("")
    assert_nil Parser.parse(nil)
  end

  def test_parse_case_insensitive
    item_id = Parser.parse("8PP.T.Q7W")

    assert_equal "8ppq7w", item_id.raw_b36ts
    assert_equal "t", item_id.type_marker
  end

  def test_parse_with_whitespace
    item_id = Parser.parse("  8pp.t.q7w  ")

    assert_equal "8ppq7w", item_id.raw_b36ts
    assert_equal "8pp.t.q7w", item_id.formatted_id
  end

  def test_parse_idea_marker
    item_id = Parser.parse("8pp.i.q7w")

    assert_equal "i", item_id.type_marker
    assert_equal "8pp.i.q7w", item_id.formatted_id
  end
end
