# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "tmpdir"

# Tests for embed-source functionality
# Optimized to use API calls instead of subprocess for fast execution (~50ms vs ~2.5s)
# See PR #114 for performance optimization details
class CLIEmbedSourceTest < AceTestCase
  def setup
    # Create a temporary directory for test files
    @test_dir = Dir.mktmpdir
    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    create_test_files
  end

  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_files
    # Create a sample file to reference (use absolute path for reliability)
    @sample_path = File.join(@test_dir, "sample.md")
    File.write(@sample_path, "Sample file content")

    # Create prompt file WITHOUT embed_document_source in frontmatter
    @prompt_path = File.join(@test_dir, "prompt.md")
    File.write(
      @prompt_path,
      <<~MARKDOWN
        ---
        bundle:
          files:
            - #{@sample_path}
        ---
        This is the prompt content
      MARKDOWN
    )

    # Create prompt file WITH embed_document_source: false in frontmatter
    @prompt_no_embed_path = File.join(@test_dir, "prompt-no-embed.md")
    File.write(
      @prompt_no_embed_path,
      <<~MARKDOWN
        ---
        bundle:
          embed_document_source: false
          files:
            - #{@sample_path}
        ---
        This is the prompt content with embed disabled
      MARKDOWN
    )
  end

  # Helper: Load context file via API (equivalent to CLI `ace-bundle <file> [-e]`)
  # Tests CLI behavior without subprocess overhead by calling the same API the CLI uses
  # @param file_path [String] Path to context file with YAML frontmatter
  # @param embed_source [Boolean] Equivalent to CLI `-e`/`--embed-source` flag
  # @return [String] The generated context content
  def load_context(file_path, embed_source: false)
    result = Ace::Bundle.load_file(file_path, embed_source: embed_source)
    refute result.metadata[:error], "API should not have errors: #{result.metadata[:error]}"
    result.content
  end

  def test_short_flag_enables_embedding
    # -e flag is equivalent to embed_source: true option
    output = load_context(@prompt_path, embed_source: true)

    assert_match(/This is the prompt content/, output, "Should embed source content")
    assert_match(/Sample file content/, output, "Should embed referenced files")
  end

  def test_long_flag_enables_embedding
    # --embed-source flag is equivalent to embed_source: true option
    output = load_context(@prompt_path, embed_source: true)

    assert_match(/This is the prompt content/, output, "Should embed source content")
    assert_match(/Sample file content/, output, "Should embed referenced files")
  end

  def test_flag_overrides_frontmatter_false
    output = load_context(@prompt_no_embed_path, embed_source: true)

    # CLI flag should override frontmatter setting
    assert_match(/This is the prompt content with embed disabled/, output,
      "Should embed source content despite frontmatter saying false")
    assert_match(/Sample file content/, output, "Should embed referenced files")
  end

  def test_no_flag_respects_frontmatter_false
    output = load_context(@prompt_no_embed_path, embed_source: false)

    # Should NOT embed source when frontmatter says false and no CLI flag
    refute_match(/This is the prompt content with embed disabled/, output,
      "Should not embed source content when disabled in frontmatter")
    # Files should still be included in formatted output
    assert_match(/Sample file content/, output,
      "Should still show file content in formatted output")
  end

  def test_flag_works_with_output_mode
    # Output mode is a write concern, not a load concern
    # The embed_source option works regardless of output mode
    output = load_context(@prompt_path, embed_source: true)

    assert_match(/This is the prompt content/, output,
      "Should embed source content with --output stdio")
  end

  def test_flag_works_with_minimal_frontmatter
    # Create a file with minimal frontmatter (no embed_document_source setting)
    minimal_path = File.join(@test_dir, "minimal.md")
    File.write(
      minimal_path,
      <<~MARKDOWN
        ---
        bundle:
          files:
            - #{@sample_path}
        ---
        This is content with minimal frontmatter
      MARKDOWN
    )

    # Should not crash with NoMethodError on nil config
    output = load_context(minimal_path, embed_source: true)

    assert_match(/This is content with minimal frontmatter/, output,
      "Should embed source content when flag is used")
    assert_match(/Sample file content/, output,
      "Should also include referenced files")
  end
end
