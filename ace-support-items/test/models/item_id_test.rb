# frozen_string_literal: true

require "test_helper"

class ItemIdTest < AceSupportItemsTestCase
  def test_formatted_id_with_type_marker
    item_id = Ace::Support::Items::Models::ItemId.new(
      raw_b36ts: "8ppq7w",
      prefix: "8pp",
      type_marker: "t",
      suffix: "q7w",
      subtask_char: nil
    )

    assert_equal "8pp.t.q7w", item_id.formatted_id
    assert_equal "8pp.t.q7w", item_id.full_id
  end

  def test_formatted_id_with_subtask
    item_id = Ace::Support::Items::Models::ItemId.new(
      raw_b36ts: "8ppq7w",
      prefix: "8pp",
      type_marker: "t",
      suffix: "q7w",
      subtask_char: "a"
    )

    assert_equal "8pp.t.q7w.a", item_id.formatted_id
    assert item_id.subtask?
  end

  def test_not_subtask_when_no_subtask_char
    item_id = Ace::Support::Items::Models::ItemId.new(
      raw_b36ts: "8ppq7w",
      prefix: "8pp",
      type_marker: "t",
      suffix: "q7w",
      subtask_char: nil
    )

    refute item_id.subtask?
  end

  def test_to_h_includes_all_fields
    item_id = Ace::Support::Items::Models::ItemId.new(
      raw_b36ts: "8ppq7w",
      prefix: "8pp",
      type_marker: "t",
      suffix: "q7w",
      subtask_char: "a"
    )

    h = item_id.to_h
    assert_equal "8ppq7w", h[:raw_b36ts]
    assert_equal "8pp", h[:prefix]
    assert_equal "t", h[:type_marker]
    assert_equal "q7w", h[:suffix]
    assert_equal "a", h[:subtask_char]
    assert_equal "8pp.t.q7w.a", h[:formatted_id]
  end

  def test_idea_type_marker
    item_id = Ace::Support::Items::Models::ItemId.new(
      raw_b36ts: "8ppq7w",
      prefix: "8pp",
      type_marker: "i",
      suffix: "q7w",
      subtask_char: nil
    )

    assert_equal "8pp.i.q7w", item_id.formatted_id
  end
end
