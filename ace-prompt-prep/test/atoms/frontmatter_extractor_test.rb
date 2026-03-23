# frozen_string_literal: true

require "test_helper"
require "ace/prompt_prep/atoms/frontmatter_extractor"

class FrontmatterExtractorTest < Minitest::Test
  def test_extract_valid_frontmatter
    content = <<~MARKDOWN
      ---
      title: Test
      tags:
        - ruby
        - testing
      ---
      This is the body content.
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    assert result[:has_frontmatter]
    assert_equal "Test", result[:frontmatter]["title"]
    assert_equal ["ruby", "testing"], result[:frontmatter]["tags"]
    assert_equal "This is the body content.\n", result[:body]
    assert_nil result[:error]
  end

  def test_extract_no_frontmatter
    content = "Just plain content without frontmatter."

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    refute result[:has_frontmatter]
    assert_empty result[:frontmatter]
    assert_equal content, result[:body]
    assert_nil result[:error]
  end

  def test_extract_empty_frontmatter
    content = <<~MARKDOWN
      ---
      ---
      Body content here.
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    assert result[:has_frontmatter]
    assert_empty result[:frontmatter]
    assert_equal "Body content here.\n", result[:body]
    assert_nil result[:error]
  end

  def test_extract_invalid_yaml
    content = <<~MARKDOWN
      ---
      invalid: [unclosed
      ---
      Body content.
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    refute result[:has_frontmatter]
    assert_equal content, result[:body]
    assert_match(/Invalid YAML/, result[:error])
  end

  def test_extract_unclosed_frontmatter
    content = <<~MARKDOWN
      ---
      title: Test
      This is content without closing delimiter.
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    refute result[:has_frontmatter]
    assert_equal content, result[:body]
  end

  def test_extract_empty_content
    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract("")

    refute result[:has_frontmatter]
    assert_empty result[:frontmatter]
    assert_empty result[:body]
  end

  def test_extract_nil_content
    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(nil)

    refute result[:has_frontmatter]
    assert_empty result[:frontmatter]
    assert_empty result[:body]
  end

  def test_extract_frontmatter_only_no_body
    content = <<~MARKDOWN
      ---
      title: Only frontmatter
      ---
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    assert result[:has_frontmatter]
    assert_equal "Only frontmatter", result[:frontmatter]["title"]
    assert_empty result[:body]
  end

  def test_extract_body_with_dashes
    content = <<~MARKDOWN
      ---
      title: Test
      ---
      Body content.

      ---

      This should be in the body, not treated as frontmatter.
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    assert result[:has_frontmatter]
    assert_equal "Test", result[:frontmatter]["title"]
    assert_includes result[:body], "---"
    assert_includes result[:body], "This should be in the body"
  end

  def test_extract_complex_nested_yaml
    content = <<~MARKDOWN
      ---
      context:
        files:
          - README.md
          - src/main.rb
        commands:
          - git status
        presets:
          - project
      metadata:
        author: Test User
      ---
      Review this code.
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    assert result[:has_frontmatter]
    assert_equal ["README.md", "src/main.rb"], result[:frontmatter]["context"]["files"]
    assert_equal ["git status"], result[:frontmatter]["context"]["commands"]
    assert_equal ["project"], result[:frontmatter]["context"]["presets"]
    assert_equal "Test User", result[:frontmatter]["metadata"]["author"]
    assert_equal "Review this code.\n", result[:body]
  end

  def test_extract_frontmatter_with_special_characters
    content = <<~MARKDOWN
      ---
      title: "Test: Special & Characters"
      description: >
        This is a multi-line
        description with special chars: @#$%
      ---
      Body content.
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    assert result[:has_frontmatter]
    assert_equal "Test: Special & Characters", result[:frontmatter]["title"]
    assert_includes result[:frontmatter]["description"], "multi-line"
    assert_equal "Body content.\n", result[:body]
  end

  def test_extract_returns_raw_frontmatter
    content = <<~MARKDOWN
      ---
      context:
        presets: []
        files: []
      ---
      Body content.
    MARKDOWN

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    assert result[:has_frontmatter]
    assert_includes result[:raw_frontmatter], "context:"
    assert_includes result[:raw_frontmatter], "presets: []"
    assert_includes result[:raw_frontmatter], "files: []"
    # Verify raw_frontmatter preserves exact YAML formatting
    refute_includes result[:raw_frontmatter], "---"
  end

  def test_extract_no_frontmatter_returns_nil_raw
    content = "Just plain content."

    result = Ace::PromptPrep::Atoms::FrontmatterExtractor.extract(content)

    refute result[:has_frontmatter]
    assert_nil result[:raw_frontmatter]
  end
end
