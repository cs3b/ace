# frozen_string_literal: true

require "test_helper"

class ExactCompressorCompressTextTest < AceCompressorTestCase
  def setup
    @compressor = Ace::Compressor::Organisms::ExactCompressor.new([], mode_label: "exact")
  end

  def test_compress_text_returns_contextpack_records
    content = "# Hello\n\nThis is a summary paragraph.\n"
    result = @compressor.compress_text(content, label: "docs/readme.md")

    assert_includes result, "FILE|docs/readme.md"
    assert_includes result, "SEC|hello"
    assert_includes result, "FACT|This is a summary paragraph."
  end

  def test_compress_text_does_not_include_header
    content = "# Title\n\nSome text.\n"
    result = @compressor.compress_text(content, label: "test.md")

    refute result.start_with?("H|ContextPack")
  end

  def test_compress_text_returns_original_for_empty_content
    result = @compressor.compress_text("", label: "empty.md")
    assert_equal "", result

    result = @compressor.compress_text("   ", label: "whitespace.md")
    assert_equal "   ", result
  end

  def test_compress_text_returns_original_when_no_blocks_after_parse
    # Content that is only frontmatter gets stripped by parser
    content = "---\ntitle: test\n---\n"
    result = @compressor.compress_text(content, label: "frontmatter-only.md")
    assert_equal content, result
  end

  def test_compress_text_handles_code_blocks
    content = "# Config\n\n```ruby\ndef hello\n  puts 'hi'\nend\n```\n"
    result = @compressor.compress_text(content, label: "code.md")

    assert_includes result, "FILE|code.md"
    assert_includes result, "CODE|ruby|"
  end

  def test_compress_text_unwraps_nested_contextpack_fenced_markdown
    content = <<~MARKDOWN
      # Project Context

      ## Files

      ### docs/vision.md
      ```markdown
      H|ContextPack/3|exact
      FILE|docs/vision.md
      SEC|vision
      SUMMARY|Agents can run CLI commands
      ```
    MARKDOWN

    result = @compressor.compress_text(content, label: "bundle/project.md")

    assert_includes result, "FILE|bundle/project.md"
    assert_includes result, "SEC|files"
    assert_includes result, "SEC|docs_vision_md"
    assert_includes result, "FILE|docs/vision.md"
    assert_includes result, "SUMMARY|Agents can run CLI commands"
    refute_includes result, "CODE|markdown|FILE\\|docs/vision.md"
    refute_includes result, "H|ContextPack/3|exact"
  end

  def test_module_level_compress_text
    content = "# Test\n\nA fact about testing.\n"
    result = Ace::Compressor.compress_text(content, label: "test.md")

    assert_includes result, "FILE|test.md"
  end

  def test_module_level_compress_text_supports_agent_mode
    fake = Class.new do
      def compress_sources(_sources)
        "H|ContextPack/3|agent\nFILE|test.md\nSUMMARY|agent output"
      end
    end

    Ace::Compressor::Organisms::AgentCompressor.stub(:new, ->(*) { fake.new }) do
      result = Ace::Compressor.compress_text("# Test\n\nA fact.\n", label: "test.md", mode: "agent")

      assert_includes result, "FILE|test.md"
      assert_includes result, "SUMMARY|agent output"
      refute result.start_with?("H|ContextPack")
    end
  end

  def test_module_level_compress_text_rejects_unsupported_mode
    assert_raises(Ace::Compressor::Error) do
      Ace::Compressor.compress_text("# Test", label: "t.md", mode: "compact")
    end
  end
end
