# frozen_string_literal: true

require "test_helper"

class FrontmatterParserTest < AceSupportItemsTestCase
  FP = Ace::Support::Items::Atoms::FrontmatterParser

  # --- parse_frontmatter ---

  def test_parse_frontmatter_extracts_yaml
    content = "---\nstatus: pending\ntitle: My Idea\n---\n\n# My Idea\n"
    result = FP.parse_frontmatter(content)

    assert_equal "pending", result["status"]
    assert_equal "My Idea", result["title"]
  end

  def test_parse_frontmatter_returns_empty_for_nil
    assert_equal({}, FP.parse_frontmatter(nil))
  end

  def test_parse_frontmatter_returns_empty_for_empty
    assert_equal({}, FP.parse_frontmatter(""))
  end

  def test_parse_frontmatter_returns_empty_without_delimiters
    assert_equal({}, FP.parse_frontmatter("No frontmatter here"))
  end

  def test_parse_frontmatter_returns_empty_without_closing_delimiter
    assert_equal({}, FP.parse_frontmatter("---\nstatus: pending\nNo closing"))
  end

  def test_parse_frontmatter_handles_yaml_error
    content = "---\n: invalid: yaml: [\n---\n\nbody"
    assert_equal({}, FP.parse_frontmatter(content))
  end

  def test_parse_frontmatter_permits_date_and_time
    content = "---\ncreated_at: 2026-02-28 12:00:00\n---\n\nbody"
    result = FP.parse_frontmatter(content)
    refute_nil result["created_at"]
  end

  def test_parse_frontmatter_with_arrays
    content = "---\ntags: [ux, design]\n---\n\nbody"
    result = FP.parse_frontmatter(content)
    assert_equal ["ux", "design"], result["tags"]
  end

  # --- extract_body ---

  def test_extract_body_returns_content_after_frontmatter
    content = "---\nstatus: pending\n---\n\n# My Idea\n\nBody text."
    result = FP.extract_body(content)
    assert_equal "\n# My Idea\n\nBody text.", result
  end

  def test_extract_body_returns_empty_for_nil
    assert_equal "", FP.extract_body(nil)
  end

  def test_extract_body_returns_empty_for_empty
    assert_equal "", FP.extract_body("")
  end

  def test_extract_body_returns_original_without_frontmatter
    content = "Just plain text"
    assert_equal content, FP.extract_body(content)
  end

  def test_extract_body_returns_original_without_closing_delimiter
    content = "---\nstatus: pending\nNo closing"
    assert_equal content, FP.extract_body(content)
  end

  # --- parse (tuple) ---

  def test_parse_returns_tuple
    content = "---\nstatus: pending\ntitle: Test\n---\n\n# Test\n\nBody."
    frontmatter, body = FP.parse(content)

    assert_instance_of Hash, frontmatter
    assert_equal "pending", frontmatter["status"]
    assert_equal "Test", frontmatter["title"]
    assert_includes body, "# Test"
    assert_includes body, "Body."
  end

  def test_parse_returns_empty_hash_and_original_for_no_frontmatter
    content = "Just text"
    frontmatter, body = FP.parse(content)

    assert_equal({}, frontmatter)
    assert_equal content, body
  end

  def test_parse_returns_empty_hash_and_empty_for_nil
    frontmatter, body = FP.parse(nil)

    assert_equal({}, frontmatter)
    assert_equal "", body
  end
end
