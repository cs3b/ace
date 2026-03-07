# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../test_helper"

class ExactCompressorTest < AceCompressorTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_compressor_organism")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_emits_context_pack_records_for_single_file
    path = File.join(@tmp, "input.md")
    File.write(path, "# H1\n\nParagraph text")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "H|ContextPack/2|exact"
    assert_match(%r{S\|1\|.*input\.md}, output)
    assert_includes output, "M|1|1|H1"
    assert_includes output, "F|1|Paragraph text"
  end

  def test_raises_for_empty_input
    path = File.join(@tmp, "empty.md")
    File.write(path, "")

    error = assert_raises(Ace::Compressor::Error) do
      Ace::Compressor::Organisms::ExactCompressor.new([path]).call
    end

    assert_includes error.message, "Exact mode requires content"
  end

  def test_merges_multiple_files_with_deterministic_order
    later = File.join(@tmp, "z.md")
    earlier = File.join(@tmp, "a.md")
    File.write(later, "# Later\n\nL")
    File.write(earlier, "# Earlier\n\nE")

    output = Ace::Compressor::Organisms::ExactCompressor.new([later, earlier]).call

    assert_match(%r{S\|1\|.*a\.md}, output)
    assert_match(%r{S\|2\|.*z\.md}, output)
    earlier_index = output.index("M|1|1|Earlier")
    later_index = output.index("M|2|1|Later")
    assert earlier_index
    assert later_index
    assert_operator earlier_index, :<, later_index
  end

  def test_directory_with_no_supported_files_raises
    dir = File.join(@tmp, "no_docs")
    FileUtils.mkdir_p(dir)
    File.binwrite(File.join(dir, "image.dat"), "\x00\x00")

    error = assert_raises(Ace::Compressor::Error) do
      Ace::Compressor::Organisms::ExactCompressor.new([dir]).call
    end

    assert_includes error.message, "Directory has no supported markdown/text sources"
  end

  def test_image_only_reference_emits_unresolved_record
    path = File.join(@tmp, "image_only.md")
    File.write(path, "# Chart\n\n![Load](chart.png)")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "U|1|image-only|![Load](chart.png)"
  end

  def test_fenced_code_emits_fallback_record
    path = File.join(@tmp, "code.md")
    File.write(path, "# Snippet\n\n```ruby\nputs 42\n```")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "B|1|fenced-code|```ruby puts 42 ```"
  end

  def test_table_lines_are_preserved_as_table_fact
    path = File.join(@tmp, "table.md")
    File.write(path, "# Table\n\n| Name | Value |\n|---|---|\n| must | 42 |\n")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "T|1|\\| Name \\| Value \\| \\|\\|ROW\\|\\| \\|---\\|---\\| \\|\\|ROW\\|\\| \\| must \\| 42 \\|"
    assert_includes output, "must"
    assert_includes output, "42"
  end

  def test_compact_format_avoids_verbose_record_fields
    path = File.join(@tmp, "policy.md")
    File.write(path, "# Policy\n\nTeams must not remove controls.\n\nOnly allow 42 retries.")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    refute_includes output, "src="
    refute_includes output, "id="
    refute_includes output, "sec="
  end
end
