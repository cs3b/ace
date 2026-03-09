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

  def test_emits_context_pack_3_records
    path = File.join(@tmp, "input.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "H|ContextPack/3|exact"
    assert_includes output, "FILE|#{path}"
    assert_includes output, "SEC|vision"
    assert_includes output, "SUMMARY|Agents can run CLI commands"
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

    earlier_file = output.index("FILE|#{earlier}")
    later_file = output.index("FILE|#{later}")
    earlier_section = output.index("SEC|earlier")
    later_section = output.index("SEC|later")
    assert earlier_file
    assert later_file
    assert earlier_section
    assert later_section
    assert_operator earlier_file, :<, earlier_section
    assert_operator earlier_section, :<, later_file
    assert_operator later_file, :<, later_section
    assert_operator earlier_section, :<, later_section
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

    assert_includes output, "U|image-only|![Load](chart.png)"
  end

  def test_fenced_code_emits_cmd_record
    path = File.join(@tmp, "code.md")
    File.write(path, "# Snippet\n\n```bash\nace-git-commit -i \"fix auth bug\"\n```")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "CMD|ace-git-commit -i \"fix auth bug\""
    refute_includes output, "B|"
  end

  def test_fenced_file_list_emits_files_record
    path = File.join(@tmp, "files.md")
    File.write(path, <<~MD)
      ## Example: ace-git-commit

      ```
      .ace-defaults/git/commit.yml
      handbook/prompts/git-commit.system.md
      exe/ace-git-commit
      ```
    MD

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "EXAMPLE|tool=ace-git-commit"
    assert_includes output, "FILES|ace-git-commit|[.ace-defaults/git/commit.yml,handbook/prompts/git-commit.system.md,exe/ace-git-commit]"
  end

  def test_prose_example_line_emits_example_record
    path = File.join(@tmp, "example.md")
    File.write(path, "# How It Works\n\n**Example: `ace-git-commit`**\n")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "EXAMPLE|tool=ace-git-commit"
    refute_includes output, "FACT|Example: ace-git-commit"
  end

  def test_table_lines_are_preserved_as_table_record
    path = File.join(@tmp, "table.md")
    File.write(path, "# Table\n\n| Name | Value |\n|---|---|\n| must | 42 |\n")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "TABLE|cols=Name,Value|rows=must>42"
    assert_includes output, "must"
    assert_includes output, "42"
  end

  def test_list_lines_are_encoded_as_array_records
    path = File.join(@tmp, "list.md")
    File.write(path, "# Problems\n\n- Context bloat\n- No isolation boundary\n")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "PROBLEMS|[context_bloat,no_isolation_boundary]"
  end

  def test_rules_and_facts_are_semantic
    path = File.join(@tmp, "policy.md")
    File.write(path, "# Policy\n\nAgents can run CLI commands and read files.\n\nTeams must not remove controls.\n")

    output = Ace::Compressor::Organisms::ExactCompressor.new([path]).call

    assert_includes output, "RULE|Agents can run CLI commands and read files."
    assert_includes output, "RULE|Teams must not remove controls."
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
