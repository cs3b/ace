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
    # Resolve wfi:// protocol to file path using ace-nav
    # This is an E2E test that requires ace-nav to be installed
    # Use CommandExecutor to resolve protocol (testable, mockable)
    result = Ace::Core::Atoms::CommandExecutor.execute("ace-nav wfi://commit")
    file_path = result[:stdout].strip

    # Skip if ace-nav not available or workflow doesn't exist
    # Note: This is a genuine E2E test validating ace-nav protocol resolution.
    # For isolated testing of ace-bundle without ace-nav, see test_loads_wfi_content_directly.
    unless result[:success] && File.exist?(file_path)
      skip "ace-nav CLI not available - E2E test requires ace-nav for wfi:// protocol resolution"
    end

    # Load via ace-bundle API (load_auto handles protocol resolution)
    result = Ace::Bundle.load_auto("wfi://commit")

    # Should return content, not error
    refute_nil result.content, "Expected content to be returned"
    refute result.metadata[:error], "Expected no error, got: #{result.metadata[:error]}"

    # Content should include the workflow frontmatter and body
    assert_includes result.content, "---", "Expected frontmatter markers"
    assert_includes result.content, "# Commit Workflow", "Expected workflow heading"
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

    # Load the file directly via ace-bundle
    result = Ace::Bundle.load_file(temp_workflow)

    # Should return content with frontmatter preserved
    refute_nil result.content, "Expected content to be returned"
    assert_includes result.content, "# Test Workflow", "Expected workflow heading"
    assert_includes result.content, "---", "Expected frontmatter markers"

    # Should have metadata from frontmatter
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

    result = Ace::Bundle.load_file(temp_file)

    # Should return content
    refute_nil result.content
    assert_includes result.content, "# Test Document"
    assert_includes result.content, "title: Test Document"

    # Should preserve metadata
    assert_equal "Test Document", result.metadata[:title]
    assert_equal "Test Author", result.metadata[:author]
    assert_equal 1.0, result.metadata[:version]
    assert_equal temp_file, result.metadata[:source]
  end

  def test_context_config_still_works
    # Files with context: key should still be processed as templates
    temp_file = File.join(@temp_dir, "test-context-config.md")

    # Create a sample file to reference
    sample_file = File.join(@temp_dir, "sample.txt")
    File.write(sample_file, "Sample content for context test")

    content = <<~MARKDOWN
      ---
      context:
        files:
          - #{sample_file}
      ---
    MARKDOWN

    File.write(temp_file, content)

    # This should trigger template processing, not plain markdown fallback
    result = Ace::Bundle.load_file(temp_file)

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

    result = Ace::Bundle.load_file(temp_file)

    # Should trigger template processing
    refute result.metadata[:error], "Expected no error, got: #{result.metadata[:error]}"
    # Should contain the sample file content (template processing worked)
    assert_includes result.content.to_s, "Sample content for template test",
                    "Should include referenced file content"
  end

  def test_large_plain_markdown_loads_correctly
    # Large plain markdown files should load completely
    temp_file = File.join(@temp_dir, "test-large-plain-markdown.md")

    lines = ["---", "title: Large Document", "---", "", "# Large Document", ""]
    600.times { |i| lines << "Line #{i + 1}: Lorem ipsum dolor sit amet." }

    File.write(temp_file, lines.join("\n"))

    # Load directly (should get content)
    result = Ace::Bundle.load_file(temp_file)

    refute_nil result.content
    assert result.content.lines.count > 500, "Expected > 500 lines in content"
    assert_equal "Large Document", result.metadata[:title]
  end
end
