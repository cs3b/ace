# frozen_string_literal: true

require_relative "../test_helper"

class MarkdownParserTest < AceCompressorTestCase
  def setup
    super
    @parser = Ace::Compressor::Atoms::MarkdownParser.new
  end

  def test_parses_headings_and_text_blocks
    input = <<~MD
      # Title

      Intro paragraph.

      ## Details
      Detail paragraph line one.
      Detail line two.
    MD

    blocks = @parser.call(input)

    assert_equal :heading, blocks[0][:type]
    assert_equal "Title", blocks[0][:text]
    assert_equal :text, blocks[1][:type]
    assert_equal "Intro paragraph.", blocks[1][:text]
    assert_equal :heading, blocks[2][:type]
    assert_equal 2, blocks[2][:level]
    assert_equal :text, blocks[3][:type]
    assert_equal "Detail paragraph line one. Detail line two.", blocks[3][:text]
  end

  def test_strips_frontmatter
    input = <<~MD
      ---
      title: Test
      ---

      # Heading
      Body text.
    MD

    blocks = @parser.call(input)

    assert_equal "Heading", blocks[0][:text]
    assert_equal "Body text.", blocks[1][:text]
  end

  def test_returns_empty_for_blank_content
    assert_equal [], @parser.call("\n  \n")
  end
end
