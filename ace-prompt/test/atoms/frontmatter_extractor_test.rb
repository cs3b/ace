# frozen_string_literal: true

require "test_helper"
require "ace/prompt/atoms/frontmatter_extractor"

class FrontmatterExtractorTest < Ace::Prompt::TestCase
  def test_extract_with_frontmatter
    text = <<~TEXT
      ---
      key: value
      ---
      Content here
    TEXT

    frontmatter, content = Ace::Prompt::Atoms::FrontmatterExtractor.extract(text)

    assert_equal({"key" => "value"}, frontmatter)
    assert_equal "Content here\n", content
  end

  def test_extract_without_frontmatter
    text = "Just content"

    frontmatter, content = Ace::Prompt::Atoms::FrontmatterExtractor.extract(text)

    assert_equal({}, frontmatter)
    assert_equal "Just content", content
  end

  def test_extract_with_invalid_yaml
    text = <<~TEXT
      ---
      invalid: yaml: syntax
      ---
      Content
    TEXT

    frontmatter, content = Ace::Prompt::Atoms::FrontmatterExtractor.extract(text)

    assert_equal({}, frontmatter)
    assert_equal text, content
  end

  def test_has_frontmatter_returns_true
    text = "---\nkey: value\n---\nContent"

    assert Ace::Prompt::Atoms::FrontmatterExtractor.has_frontmatter?(text)
  end

  def test_has_frontmatter_returns_false
    text = "Just content"

    refute Ace::Prompt::Atoms::FrontmatterExtractor.has_frontmatter?(text)
  end
end
