# frozen_string_literal: true

require "test_helper"
require "ace/bundle/molecules/bundle_chunker"

class BundleChunkerTest < AceTestCase
  def setup
    @chunker = Ace::Bundle::Molecules::BundleChunker.new(10) # Small limit for testing
  end

  # Basic functionality tests

  def test_needs_chunking_returns_false_for_small_content
    content = "line 1\nline 2\nline 3"
    refute @chunker.needs_chunking?(content)
  end

  def test_needs_chunking_returns_true_for_large_content
    content = (1..15).map { |i| "line #{i}" }.join("\n")
    assert @chunker.needs_chunking?(content)
  end

  def test_needs_chunking_returns_false_for_nil
    refute @chunker.needs_chunking?(nil)
  end

  def test_needs_chunking_returns_false_for_empty
    refute @chunker.needs_chunking?("")
  end

  # Line-based chunking tests (no XML)

  def test_splits_plain_text_by_line_count
    content = (1..25).map { |i| "line #{i}" }.join("\n")
    lines = content.lines
    chunker = Ace::Bundle::Molecules::BundleChunker.new(10)

    chunks = chunker.send(:split_into_chunks, lines)

    assert_equal 3, chunks.size
    assert_includes chunks[0], "line 1"
    assert_includes chunks[0], "line 10"
    assert_includes chunks[1], "line 11"
  end

  # Semantic boundary chunking tests

  def test_splits_at_file_element_boundaries
    content = <<~XML
      # Header
      <file path="a.rb" language="ruby">
        line 1
        line 2
        line 3
      </file>
      <file path="b.rb" language="ruby">
        line 4
        line 5
        line 6
      </file>
    XML

    lines = content.lines
    chunker = Ace::Bundle::Molecules::BundleChunker.new(5) # Force split between files

    chunks = chunker.send(:split_into_chunks, lines)

    # Should split between files, not inside them
    assert chunks.size >= 2, "Expected at least 2 chunks"

    # Verify first file element is complete
    first_chunk = chunks[0]
    if first_chunk.include?('<file path="a.rb"')
      assert first_chunk.include?("</file>"), "First file element should be complete"
    end

    # Verify second file element is complete
    chunks.each do |chunk|
      if chunk.include?('<file path="b.rb"')
        assert chunk.include?("</file>"), "Second file element should be complete"
      end
    end
  end

  def test_splits_at_output_element_boundaries
    content = <<~XML
      <output command="cmd1">
        output line 1
        output line 2
      </output>
      <output command="cmd2">
        output line 3
        output line 4
      </output>
    XML

    lines = content.lines
    chunker = Ace::Bundle::Molecules::BundleChunker.new(4)

    chunks = chunker.send(:split_into_chunks, lines)

    # Verify each output element is complete
    chunks.each do |chunk|
      if chunk.include?('<output command="cmd1"')
        assert chunk.include?("</output>"), "First output element should be complete"
      end
      if chunk.include?('<output command="cmd2"')
        assert chunk.include?("</output>"), "Second output element should be complete"
      end
    end
  end

  def test_keeps_large_single_element_whole
    # Create a single file element that exceeds chunk limit
    large_content = (1..20).map { |i| "  line #{i}" }.join("\n")
    content = <<~XML
      <file path="large.rb" language="ruby">
      #{large_content}
      </file>
    XML

    lines = content.lines
    chunker = Ace::Bundle::Molecules::BundleChunker.new(5) # Much smaller than element

    chunks = chunker.send(:split_into_chunks, lines)

    # Should be a single chunk - we don't split elements even if they exceed limit
    assert_equal 1, chunks.size
    assert chunks[0].include?('<file path="large.rb"')
    assert chunks[0].include?("</file>")
    assert chunks[0].include?("line 20")
  end

  def test_mixed_content_with_files_and_outputs
    content = <<~XML
      # Project Context
      <file path="a.rb" language="ruby">code a</file>
      # Commands
      <output command="git status">status output</output>
    XML

    lines = content.lines
    chunker = Ace::Bundle::Molecules::BundleChunker.new(3)

    chunks = chunker.send(:split_into_chunks, lines)

    # All elements should be complete in their respective chunks
    all_content = chunks.join
    assert all_content.include?('<file path="a.rb"')
    assert all_content.include?("</file>")
    assert all_content.include?('<output command="git status"')
    assert all_content.include?("</output>")
  end

  # chunk_content integration tests

  def test_chunk_content_returns_single_file_for_small_content
    content = "line 1\nline 2\nline 3"
    result = @chunker.chunk_content(content, "/tmp/test")

    assert_equal false, result[:chunked]
    assert_equal 1, result[:total_chunks]
    assert_equal content, result[:content]
  end

  def test_chunk_content_returns_multiple_chunks_for_large_content
    content = (1..25).map { |i| "line #{i}" }.join("\n")
    result = @chunker.chunk_content(content, "/tmp/test")

    assert_equal true, result[:chunked]
    assert result[:total_chunks] > 1
    assert result[:chunk_files].any?
    assert result[:index_content].include?("Bundle Index")
  end

  # Edge case tests

  def test_handles_nested_looking_content_in_files
    # Content inside file might look like tags but shouldn't affect parsing
    content = <<~XML
      <file path="test.rb" language="ruby">
        # This looks like a tag: <file>
        # But it's inside the element
        puts "</file>" # This too
      </file>
    XML

    lines = content.lines
    chunks = @chunker.send(:split_into_chunks, lines)

    # Should be treated as a single block
    assert_equal 1, chunks.size
  end

  def test_handles_content_without_xml_elements
    content = "# Just markdown\n\nSome text here.\n\nMore text."
    lines = content.lines

    chunks = @chunker.send(:split_into_chunks, lines)

    # Falls back to line-based splitting
    assert chunks.any?
  end
end
