# frozen_string_literal: true

require "test_helper"

class TaskIdFormatterTest < AceTaskTestCase
  Formatter = Ace::Task::Atoms::TaskIdFormatter

  def test_generate_returns_item_id_with_task_marker
    item_id = Formatter.generate(Time.utc(2026, 1, 15, 12, 0, 0))

    assert_equal "t", item_id.type_marker
    assert_equal 3, item_id.prefix.length
    assert_equal 3, item_id.suffix.length
    assert_equal 6, item_id.raw_b36ts.length
    assert item_id.formatted_id.include?(".t.")
  end

  def test_format_existing_b36ts
    item_id = Formatter.format("8ppq7w")

    assert_equal "8pp.t.q7w", item_id.formatted_id
    assert_equal "8ppq7w", item_id.raw_b36ts
  end

  def test_reconstruct_from_formatted_id
    raw = Formatter.reconstruct("8pp.t.q7w")
    assert_equal "8ppq7w", raw
  end

  def test_folder_name
    assert_equal "8pp.t.q7w-fix-login", Formatter.folder_name("8pp.t.q7w", "fix-login")
  end

  def test_spec_filename
    assert_equal "8pp.t.q7w-fix-login.s.md", Formatter.spec_filename("8pp.t.q7w", "fix-login")
  end
end
