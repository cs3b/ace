# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class PlainMarkdownLoadTest < AceTestCase
  def setup
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir
  end

  def test_loads_workflow_file_via_wfi_protocol
    # Resolve wfi:// protocol to file path using ace-nav SDK
    require "ace/support/nav"
    engine = Ace::Support::Nav::Organisms::NavigationEngine.new
    file_path = engine.resolve("wfi://commit")

    # Skip if workflow doesn't exist
    unless file_path && File.exist?(file_path)
      skip "wfi://commit could not be resolved - E2E test requires ace-nav protocol resolution"
    end

    # Load via ace-bundle API (load_auto handles protocol resolution)
    result = Ace::Bundle.load_auto("wfi://commit", compressor_source_scope: "per-source", compressor_mode: "exact")

    # Should return content, not error
    refute_nil result.content, "Expected content to be returned"
    refute result.metadata[:error], "Expected no error, got: #{result.metadata[:error]}"

    # Content should be compressed (command-only sections now compress post-format)
    assert result.metadata[:compressed], "Expected wfi://commit to be compressed"
    assert_includes result.content, "FILE|", "Expected compressed FILE| markers"
  end

  def test_loads_wfi_content_directly
    # Test ace-bundle can load workflow content without ace-nav dependency
    # This provides test coverage even when ace-nav CLI is not available

    # Create a temporary workflow file to simulate wfi:// protocol content
    temp_workflow = File.join(@temp_dir, "test-workflow.wf.md")

    content = <<~MARKDOWN
      ---
      name: test-workflow
      description: Test workflow for isolated testing
      allowed-tools:
        - Read
        - Bash
      ---

      # Test Workflow

      This is a test workflow file for testing ace-bundle without ace-nav.
    MARKDOWN

    File.write(temp_workflow, content)

    result = Ace::Bundle.load_file(temp_workflow, compressor_source_scope: "per-source", compressor_mode: "exact")

    # Content should be compressed
    refute_nil result.content, "Expected content to be returned"
    assert result.metadata[:compressed], "Expected content to be compressed"
    assert_includes result.content, "FILE|", "Expected compressed FILE| markers"

    # Should have metadata from frontmatter (set before compression)
    assert_equal "test-workflow", result.metadata[:name]
    assert_equal "Test workflow for isolated testing", result.metadata[:description]
    assert_equal temp_workflow, result.metadata[:source]
  end

  def test_loads_plain_markdown_file_by_path
    # Create a temporary markdown file with metadata-only frontmatter
    temp_file = File.join(@temp_dir, "test-plain-markdown.md")

    content = <<~MARKDOWN
      ---
      title: Test Document
      author: Test Author
      version: 1.0
      ---

      # Test Document

      This is a plain markdown file with metadata frontmatter.

      ## Section 1

      Some content here.
    MARKDOWN

    File.write(temp_file, content)

    result = Ace::Bundle.load_file(temp_file, compressor_source_scope: "per-source", compressor_mode: "exact")

    # Content should be compressed
    refute_nil result.content
    assert result.metadata[:compressed], "Expected content to be compressed"
    assert_includes result.content, "FILE|", "Expected compressed FILE| markers"

    # Should preserve metadata (set before compression)
    assert_equal "Test Document", result.metadata[:title]
    assert_equal "Test Author", result.metadata[:author]
    assert_equal 1.0, result.metadata[:version]
    assert_equal temp_file, result.metadata[:source]
  end

  def test_loads_workflow_without_frontmatter
    temp_file = File.join(@temp_dir, "selfimprove.wf.md")
    content = <<~MARKDOWN
      # Self-Improve Workflow

      ## Goal

      Improve the workflow after incidents.
    MARKDOWN
    File.write(temp_file, content)

    result = Ace::Bundle.load_file(temp_file, compressor_source_scope: "per-source", compressor_mode: "exact")

    refute_nil result.content, "Expected content for non-frontmatter workflow"
    assert result.metadata[:compressed], "Expected content to be compressed"
    assert_includes result.content, "FILE|", "Expected compressed FILE| markers"
    assert_equal temp_file, result.metadata[:source]
    refute result.metadata[:error], "Expected no loader error"
  end

  def test_context_config_still_works
    # Files with context: key should still be processed as templates
    temp_file = File.join(@temp_dir, "test-context-config.md")

    # Create a sample file to reference
    sample_file = File.join(@temp_dir, "sample.txt")
    File.write(sample_file, "Sample content for context test")

    content = <<~MARKDOWN
      ---
      bundle:
        files:
          - #{sample_file}
      ---
    MARKDOWN

    File.write(temp_file, content)

    # This should trigger template processing, not plain markdown fallback
    result = Ace::Bundle.load_file(temp_file, compressor_source_scope: "per-source", compressor_mode: "exact")

    # Should have processed files - content should contain sample file content
    refute result.metadata[:error], "Expected no error, got: #{result.metadata[:error]}"
    # Should contain the sample file content (template processing worked)
    assert_includes result.content.to_s, "Sample content for context test",
      "Should include referenced file content"
  end

  def test_template_keys_still_work
    # Files with files: key should still be processed as templates
    temp_file = File.join(@temp_dir, "test-template-keys.md")

    # Create a sample file to reference
    sample_file = File.join(@temp_dir, "sample.txt")
    File.write(sample_file, "Sample content for template test")

    content = <<~MARKDOWN
      ---
      files:
        - #{sample_file}
      ---
    MARKDOWN

    File.write(temp_file, content)

    result = Ace::Bundle.load_file(temp_file, compressor_source_scope: "per-source", compressor_mode: "exact")

    # Should trigger template processing
    refute result.metadata[:error], "Expected no error, got: #{result.metadata[:error]}"
    # Should contain the sample file content (template processing worked)
    assert_includes result.content.to_s, "Sample content for template test",
      "Should include referenced file content"
  end

  def test_large_plain_markdown_loads_correctly
    # Large plain markdown files should load completely and be compressed
    temp_file = File.join(@temp_dir, "test-large-plain-markdown.md")

    lines = ["---", "title: Large Document", "---", "", "# Large Document", ""]
    600.times { |i| lines << "Line #{i + 1}: Lorem ipsum dolor sit amet." }

    File.write(temp_file, lines.join("\n"))

    result = Ace::Bundle.load_file(temp_file, compressor_source_scope: "per-source", compressor_mode: "exact")

    refute_nil result.content
    assert result.metadata[:compressed], "Expected content to be compressed"
    assert result.content.lines.count < 500, "Expected compressed output to be smaller than 606-line original"
    assert_equal "Large Document", result.metadata[:title]
  end
end
