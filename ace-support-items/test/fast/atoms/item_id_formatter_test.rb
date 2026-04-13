# frozen_string_literal: true

require "test_helper"

class ItemIdFormatterTest < AceSupportItemsTestCase
  Formatter = Ace::Support::Items::Atoms::ItemIdFormatter

  def test_split_creates_item_id_with_task_marker
    item_id = Formatter.split("8ppq7w", type_marker: "t")

    assert_equal "8ppq7w", item_id.raw_b36ts
    assert_equal "8pp", item_id.prefix
    assert_equal "t", item_id.type_marker
    assert_equal "q7w", item_id.suffix
    assert_nil item_id.subtask_char
    assert_equal "8pp.t.q7w", item_id.formatted_id
  end

  def test_split_creates_item_id_with_idea_marker
    item_id = Formatter.split("8ppq7w", type_marker: "i")

    assert_equal "8pp.i.q7w", item_id.formatted_id
  end

  def test_split_raises_for_non_6_char_input
    assert_raises(ArgumentError) { Formatter.split("short", type_marker: "t") }
    assert_raises(ArgumentError) { Formatter.split("toolong1", type_marker: "t") }
    assert_raises(ArgumentError) { Formatter.split(nil, type_marker: "t") }
  end

  def test_split_subtask
    item_id = Formatter.split_subtask("8ppq7w", type_marker: "t", subtask_char: "a")

    assert_equal "8pp.t.q7w.a", item_id.formatted_id
    assert_equal "a", item_id.subtask_char
    assert item_id.subtask?
  end

  def test_reconstruct_from_formatted_id
    raw = Formatter.reconstruct("8pp.t.q7w")
    assert_equal "8ppq7w", raw
  end

  def test_reconstruct_from_formatted_id_with_subtask
    raw = Formatter.reconstruct("8pp.t.q7w.a")
    assert_equal "8ppq7w", raw
  end

  def test_reconstruct_raises_for_invalid_format
    assert_raises(ArgumentError) { Formatter.reconstruct("invalid") }
    assert_raises(ArgumentError) { Formatter.reconstruct("8ppq7w") }
    assert_raises(ArgumentError) { Formatter.reconstruct("8pp.t.q7w.ab") }
  end

  def test_folder_name_with_slug
    assert_equal "8pp.t.q7w-fix-login", Formatter.folder_name("8pp.t.q7w", "fix-login")
  end

  def test_folder_name_without_slug
    assert_equal "8pp.t.q7w", Formatter.folder_name("8pp.t.q7w", nil)
    assert_equal "8pp.t.q7w", Formatter.folder_name("8pp.t.q7w", "")
  end
end
