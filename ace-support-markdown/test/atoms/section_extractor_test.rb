# frozen_string_literal: true

require_relative "../test_helper"

class SectionExtractorTest < Minitest::Test
  include TestHelpers

  def setup
    @extractor = Ace::Support::Markdown::Atoms::SectionExtractor
    @body = <<~MARKDOWN
      # Main Title

      Introduction paragraph.

      ## Section 1

      Content of section 1.

      ### Subsection 1.1

      Content of subsection 1.1.

      ## Section 2

      Content of section 2.

      ## References

      - Reference 1
      - Reference 2
    MARKDOWN
  end

  def test_extract_section_found
    result = @extractor.extract(@body, "References")

    assert result[:found], "Section should be found"
    assert_includes result[:section_content], "Reference 1"
    assert_includes result[:section_content], "Reference 2"
    assert_empty result[:errors]
  end

  def test_extract_section_not_found
    result = @extractor.extract(@body, "Nonexistent Section")

    refute result[:found], "Section should not be found"
    assert_nil result[:section_content]
    assert_includes result[:errors].first, "Section not found"
  end

  def test_extract_section_with_subsections
    result = @extractor.extract(@body, "Section 1")

    assert result[:found]
    assert_includes result[:section_content], "Content of section 1"
    assert_includes result[:section_content], "Subsection 1.1"
    assert_includes result[:section_content], "subsection 1.1"
  end

  def test_extract_section_empty_content
    result = @extractor.extract("", "Section")

    refute result[:found]
    assert_includes result[:errors].first, "Empty content"
  end

  def test_extract_section_nil_heading
    result = @extractor.extract(@body, nil)

    refute result[:found]
    assert_includes result[:errors].first, "Heading text required"
  end

  def test_extract_all_sections
    sections = @extractor.extract_all(@body)

    assert_equal 5, sections.length
    assert_equal "Main Title", sections[0][:heading]
    assert_equal 1, sections[0][:level]
    assert_equal "Section 1", sections[1][:heading]
    assert_equal 2, sections[1][:level]
    assert_equal "Subsection 1.1", sections[2][:heading]
    assert_equal 3, sections[2][:level]
    assert_equal "References", sections[4][:heading]
  end

  def test_extract_all_empty_content
    sections = @extractor.extract_all("")

    assert_empty sections
  end

  def test_exact_string_matching
    # Should not match partial strings
    result = @extractor.extract(@body, "Section")

    refute result[:found], "Should require exact match, not partial"
  end

  def test_case_sensitive_matching
    result = @extractor.extract(@body, "section 1")

    refute result[:found], "Should be case sensitive"
  end
end
