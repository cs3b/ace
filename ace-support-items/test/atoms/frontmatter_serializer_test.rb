# frozen_string_literal: true

require "test_helper"

class FrontmatterSerializerTest < AceSupportItemsTestCase
  FS = Ace::Support::Items::Atoms::FrontmatterSerializer

  # --- serialize ---

  def test_serialize_produces_yaml_block
    frontmatter = {
      "id" => "8ppq7w",
      "status" => "pending",
      "title" => "Dark mode",
      "tags" => [],
      "created_at" => "2026-02-28 12:00:00"
    }
    result = FS.serialize(frontmatter)

    assert result.start_with?("---")
    assert result.end_with?("---")
    assert_includes result, "id: 8ppq7w"
    assert_includes result, "status: pending"
    assert_includes result, "title: Dark mode"
    assert_includes result, "tags: []"
    assert_includes result, 'created_at: "2026-02-28 12:00:00"'
  end

  def test_serialize_empty_array
    result = FS.serialize("tags" => [])
    assert_includes result, "tags: []"
  end

  def test_serialize_array_with_values
    result = FS.serialize("tags" => ["ux", "design"])
    assert_includes result, "tags: [ux, design]"
  end

  def test_serialize_quotes_yaml_ambiguous_values
    result = FS.serialize("flag" => "true")
    assert_includes result, 'flag: "true"'
  end

  def test_serialize_quotes_false
    result = FS.serialize("flag" => "false")
    assert_includes result, 'flag: "false"'
  end

  def test_serialize_quotes_null
    result = FS.serialize("val" => "null")
    assert_includes result, 'val: "null"'
  end

  def test_serialize_quotes_numeric_string
    result = FS.serialize("val" => "42")
    assert_includes result, 'val: "42"'
  end

  def test_serialize_quotes_special_characters
    result = FS.serialize("desc" => "API: Review #1")
    assert_includes result, 'desc: "API: Review #1"'
  end

  def test_serialize_quotes_empty_string
    result = FS.serialize("val" => "")
    assert_includes result, 'val: ""'
  end

  def test_serialize_escapes_backslash_and_quotes
    result = FS.serialize("val" => 'say "hello"')
    assert_includes result, 'val: "say \\"hello\\"'
  end

  def test_serialize_plain_string_unquoted
    result = FS.serialize("title" => "Dark mode support")
    assert_includes result, "title: Dark mode support"
  end

  def test_serialize_non_string_values
    result = FS.serialize("count" => 42, "active" => true)
    assert_includes result, "count: 42"
    assert_includes result, "active: true"
  end

  # --- rebuild ---

  def test_rebuild_combines_frontmatter_and_body
    frontmatter = { "id" => "8ppq7w", "status" => "pending" }
    body = "# My Idea\n\nSome content."

    result = FS.rebuild(frontmatter, body)

    assert result.start_with?("---")
    assert_includes result, "id: 8ppq7w"
    assert_includes result, "---\n\n# My Idea\n\nSome content."
  end
end
