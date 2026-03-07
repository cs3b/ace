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

  def test_parses_lists
    input = <<~MD
      # Heading

      - first item
      - second item
    MD

    blocks = @parser.call(input)

    assert_equal :list, blocks[1][:type]
    assert_equal ["first item", "second item"], blocks[1][:items]
    assert_equal false, blocks[1][:ordered]
  end

  def test_parses_numbered_lists
    input = <<~MD
      # Steps

      1. first
      2. second
    MD

    blocks = @parser.call(input)

    assert_equal :list, blocks[1][:type]
    assert_equal %w[first second], blocks[1][:items]
    assert_equal true, blocks[1][:ordered]
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

  def test_ignores_quote_marker_only_lines
    input = <<~MD
      > Quote starts
      >
      > quote continues

      After quote.
    MD

    blocks = @parser.call(input)

    assert_equal :text, blocks[0][:type]
    assert_equal "> Quote starts", blocks[0][:text]
    assert_equal :text, blocks[1][:type]
    assert_equal "> quote continues", blocks[1][:text]
  end

  def test_parses_fenced_code
    input = <<~MD
      # Example

      ```ruby
      puts 1
      puts 2
      ```
    MD

    blocks = @parser.call(input)

    assert_equal :fenced_code, blocks[1][:type]
    assert_equal "ruby", blocks[1][:language]
    assert_match("puts 1", blocks[1][:content])
    assert_match("puts 2", blocks[1][:content])
  end

  def test_parses_tables
    input = <<~MD
      # Table

      | Name | Value |
      |---|---|
      | must | 42 |
    MD

    blocks = @parser.call(input)

    assert_equal :table, blocks[1][:type]
    assert_equal "| Name | Value |", blocks[1][:rows][0]
    assert_equal "|---|---|", blocks[1][:rows][1]
    assert_equal "| must | 42 |", blocks[1][:rows][2]
  end

  def test_returns_empty_for_blank_content
    assert_equal [], @parser.call("\n  \n")
  end
end
