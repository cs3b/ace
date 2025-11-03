# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/organisms/idea_writer"

# Pure unit tests for IdeaWriter - no filesystem operations
class IdeaWriterUnitTest < AceTaskflowTestCase
  def setup
    @config = {
      "directory" => "/test/ideas",
      "template" => "# %{title}\n\n%{content}\n\n---\nCaptured: %{timestamp}",
      "formatting" => {
        "timestamp_format" => "%Y-%m-%d %H:%M:%S"
      }
    }
    @writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)

    # Track all FileUtils and SafeFileWriter calls
    @mkdir_calls = []
    @write_calls = []
  end

  def test_generates_correct_path_with_timestamp_and_slug
    mock_slug_resp = mock_slug_response(folder_slug: "test-idea", file_slug: "test-content")

    mock_filesystem do
      mock_llm_query(response_text: mock_slug_resp) do
        content = "This is a test idea"
        path = @writer.write(content)

        # Verify path format: /test/ideas/YYYYMMDD-HHMMSS-test-idea
        assert_match(%r{^/test/ideas/\d{8}-\d{6}-test-idea$}, path)

        # Verify directory was created
        assert @mkdir_calls.include?(path), "Should create idea directory"

        # Verify file was written
        assert @write_calls.any? { |call| call[:path].include?("test-content.s.md") }
      end
    end
  end

  def test_uses_configured_directory
    custom_config = @config.merge("directory" => "/custom/ideas")
    writer = Ace::Taskflow::Organisms::IdeaWriter.new(custom_config)

    mock_slug_resp = mock_slug_response(folder_slug: "custom-dir", file_slug: "test-idea")

    mock_filesystem do
      mock_llm_query(response_text: mock_slug_resp) do
        path = writer.write("Test content")

        # Verify path uses custom directory
        assert_match(%r{^/custom/ideas/\d{8}-\d{6}-custom-dir$}, path)
      end
    end
  end

  def test_creates_nested_directory_structure
    mock_slug_resp = mock_slug_response(folder_slug: "nested-idea", file_slug: "test-content")

    mock_filesystem do
      mock_llm_query(response_text: mock_slug_resp) do
        path = @writer.write("Test content")

        # Verify mkdir_p was called (creates parent directories)
        assert @mkdir_calls.any?, "Should call mkdir_p"
        assert_match(/nested-idea$/, path)
      end
    end
  end

  def test_formats_content_with_template
    mock_slug_resp = mock_slug_response(folder_slug: "template-test", file_slug: "test-idea")

    mock_filesystem do
      mock_llm_query(response_text: mock_slug_resp) do
        content = "Template test idea"
        metadata = {
          title: "Template Test",
          timestamp: "2025-01-01 12:00:00"
        }

        @writer.write(content, metadata)

        # Verify content was formatted
        write_call = @write_calls.first
        assert write_call, "Should write file"

        formatted_content = write_call[:content]
        assert_includes formatted_content, "# Template Test"
        assert_includes formatted_content, content
        assert_includes formatted_content, "2025-01-01 12:00:00"
      end
    end
  end

  def test_extracts_title_from_content
    mock_slug_resp = mock_slug_response(folder_slug: "long-idea", file_slug: "truncated-title")

    mock_filesystem do
      mock_llm_query(response_text: mock_slug_resp) do
        content = "This is a long idea that should be truncated for title"
        path = @writer.write(content)

        # Verify path contains folder slug
        assert_match(/long-idea$/, path)

        # Verify file slug is used in filename
        write_call = @write_calls.first
        assert_match(/truncated-title\.s\.md$/, write_call[:path])
      end
    end
  end

  def test_raises_error_on_empty_content
    error = assert_raises(Ace::Taskflow::Organisms::IdeaWriterError) do
      @writer.write("")
    end

    assert_match(/No content provided/, error.message)
  end

  def test_handles_llm_enhanced_content_skips_template
    # LLM-enhanced content already has frontmatter
    enhanced_content = <<~CONTENT
      ---
      title: Enhanced Title
      ---

      # Enhanced Title

      ## Problem
      Test problem
    CONTENT

    mock_slug_resp = mock_slug_response(folder_slug: "enhanced", file_slug: "test")

    mock_filesystem do
      mock_llm_query(response_text: mock_slug_resp) do
        path = @writer.write(enhanced_content)

        write_call = @write_calls.first
        # Content should be returned as-is (no template applied)
        assert_equal enhanced_content, write_call[:content]
      end
    end
  end

  private

  # Mock filesystem operations
  def mock_filesystem
    # Capture instance variables in local variables for closure
    write_calls = @write_calls
    mkdir_calls = @mkdir_calls

    # Mock FileUtils.mkdir_p
    FileUtils.stub :mkdir_p, ->(path) { mkdir_calls << path } do
      # Mock SafeFileWriter.write
      original_write = Ace::Support::Markdown::Organisms::SafeFileWriter.method(:write)

      Ace::Support::Markdown::Organisms::SafeFileWriter.define_singleton_method(:write) do |path, content, **options|
        write_calls << { path: path, content: content, options: options }
        path
      end

      begin
        yield
      ensure
        # Restore original write method
        Ace::Support::Markdown::Organisms::SafeFileWriter.define_singleton_method(:write, original_write)
      end
    end
  end
end
