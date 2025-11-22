# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "open3"

class CLIEmbedSourceTest < AceTestCase
  def setup
    # Create a temporary directory for test files
    @test_dir = Dir.mktmpdir
    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    # Get path to ace-context executable
    @ace_context_bin = File.expand_path("../../exe/ace-context", __dir__)

    create_test_files
  end

  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_files
    # Create a sample file to reference (use absolute path for reliability)
    sample_path = File.join(@test_dir, "sample.md")
    File.write(sample_path, "Sample file content")

    # Create prompt file WITHOUT embed_document_source in frontmatter
    File.write(
      "prompt.md",
      <<~MARKDOWN
        ---
        context:
          files:
            - #{sample_path}
        ---
        This is the prompt content
      MARKDOWN
    )

    # Create prompt file WITH embed_document_source: false in frontmatter
    File.write(
      "prompt-no-embed.md",
      <<~MARKDOWN
        ---
        context:
          embed_document_source: false
          files:
            - #{sample_path}
        ---
        This is the prompt content with embed disabled
      MARKDOWN
    )
  end

  def run_ace_context(*args)
    stdout, stderr, status = Open3.capture3(@ace_context_bin, *args, chdir: @test_dir)
    [stdout, stderr, status]
  end

  def test_short_flag_enables_embedding
    stdout, stderr, status = run_ace_context("prompt.md", "-e")

    assert status.success?, "Command should succeed: #{stderr}"
    assert_match(/This is the prompt content/, stdout, "Should embed source content")
    assert_match(/Sample file content/, stdout, "Should embed referenced files")
  end

  def test_long_flag_enables_embedding
    stdout, stderr, status = run_ace_context("prompt.md", "--embed-source")

    assert status.success?, "Command should succeed: #{stderr}"
    assert_match(/This is the prompt content/, stdout, "Should embed source content")
    assert_match(/Sample file content/, stdout, "Should embed referenced files")
  end

  def test_flag_overrides_frontmatter_false
    stdout, stderr, status = run_ace_context("prompt-no-embed.md", "--embed-source")

    assert status.success?, "Command should succeed: #{stderr}"
    # CLI flag should override frontmatter setting
    assert_match(/This is the prompt content with embed disabled/, stdout,
                 "Should embed source content despite frontmatter saying false")
    assert_match(/Sample file content/, stdout, "Should embed referenced files")
  end

  def test_no_flag_respects_frontmatter_false
    stdout, stderr, status = run_ace_context("prompt-no-embed.md")

    assert status.success?, "Command should succeed: #{stderr}"
    # Should NOT embed source when frontmatter says false and no CLI flag
    refute_match(/This is the prompt content with embed disabled/, stdout,
                 "Should not embed source content when disabled in frontmatter")
    # Files should still be included in formatted output
    assert_match(/Sample file content/, stdout,
                 "Should still show file content in formatted output")
  end

  def test_flag_works_with_output_mode
    stdout, stderr, status = run_ace_context("prompt.md", "-e", "--output", "stdio")

    assert status.success?, "Command should succeed: #{stderr}"
    assert_match(/This is the prompt content/, stdout,
                 "Should embed source content with --output stdio")
  end

  def test_flag_works_with_minimal_frontmatter
    # Create a file with minimal frontmatter (no embed_document_source setting)
    File.write(
      "minimal.md",
      <<~MARKDOWN
        ---
        context:
          files:
            - #{File.join(@test_dir, "sample.md")}
        ---
        This is content with minimal frontmatter
      MARKDOWN
    )

    stdout, stderr, status = run_ace_context("minimal.md", "--embed-source")

    # Should not crash with NoMethodError on nil config
    assert status.success?, "Command should succeed with minimal frontmatter: #{stderr}"
    assert_match(/This is content with minimal frontmatter/, stdout,
                 "Should embed source content when flag is used")
    assert_match(/Sample file content/, stdout,
                 "Should also include referenced files")
  end
end
