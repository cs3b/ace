# frozen_string_literal: true

require_relative "../test_helper"

class FrontmatterExtractorTest < Minitest::Test
  include TestHelpers

  def setup
    @extractor = Ace::Support::Markdown::Atoms::FrontmatterExtractor
  end

  def test_extract_valid_frontmatter
    result = @extractor.extract(sample_markdown)

    assert result[:valid], "Should be valid"
    assert_equal "test.001", result[:frontmatter]["id"]
    assert_equal "pending", result[:frontmatter]["status"]
    assert_equal "high", result[:frontmatter]["priority"]
    assert_includes result[:body], "# Test Document"
    assert_empty result[:errors]
  end

  def test_extract_no_frontmatter
    content = "# Just a title\n\nSome content."
    result = @extractor.extract(content)

    refute result[:valid], "Should be invalid"
    assert_empty result[:frontmatter]
    assert_equal content, result[:body]
    assert_includes result[:errors].first, "No frontmatter found"
  end

  def test_extract_missing_closing_delimiter
    content = "---\nid: test\nstatus: pending\n\n# Content"
    result = @extractor.extract(content)

    refute result[:valid], "Should be invalid"
    assert_includes result[:errors].first, "Missing closing '---' delimiter"
  end

  def test_extract_invalid_yaml
    content = "---\nid: test\n  invalid: : yaml\n---\n\nContent"
    result = @extractor.extract(content)

    refute result[:valid], "Should be invalid"
    assert_includes result[:errors].first, "YAML syntax error"
  end

  def test_extract_empty_content
    result = @extractor.extract("")

    refute result[:valid], "Should be invalid"
    assert_includes result[:errors].first, "Empty content"
  end

  def test_extract_nil_content
    result = @extractor.extract(nil)

    refute result[:valid], "Should be invalid"
    assert_includes result[:errors].first, "Empty content"
  end

  def test_frontmatter_only
    frontmatter = @extractor.frontmatter_only(sample_markdown)

    assert_equal "test.001", frontmatter["id"]
    assert_equal "pending", frontmatter["status"]
  end

  def test_body_only
    body = @extractor.body_only(sample_markdown)

    assert_includes body, "# Test Document"
    refute_includes body, "id: test.001"
  end

  def test_has_frontmatter
    assert @extractor.has_frontmatter?(sample_markdown)
    refute @extractor.has_frontmatter?("# Just content")
  end

  def test_extract_frontmatter_with_special_values
    content = <<~MARKDOWN
      ---
      date: 2025-10-18
      nested:
        key: value
      list:
        - item1
        - item2
      ---

      Content
    MARKDOWN

    result = @extractor.extract(content)

    assert result[:valid]
    # YAML.safe_load parses dates into Date objects
    assert_instance_of Date, result[:frontmatter]["date"]
    assert_equal Date.new(2025, 10, 18), result[:frontmatter]["date"]
    assert_equal "value", result[:frontmatter]["nested"]["key"]
    assert_equal ["item1", "item2"], result[:frontmatter]["list"]
  end

  def test_extract_frontmatter_not_hash
    content = "---\n- item1\n- item2\n---\n\nContent"
    result = @extractor.extract(content)

    refute result[:valid]
    assert_includes result[:errors].first, "must be a hash"
  end
end
