# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/organisms/idea_writer"
require "tmpdir"

# Integration test for IdeaWriter with real filesystem operations
# Tests complete workflow: create directory, write file, verify content
class IdeaWriterIntegrationTest < AceTaskflowTestCase
  def test_complete_idea_workflow_with_filesystem
    Dir.mktmpdir do |temp_dir|
      config = {
        "directory" => File.join(temp_dir, "ideas"),
        "template" => "# %{title}\n\n%{content}\n\n---\nCaptured: %{timestamp}",
        "formatting" => {
          "timestamp_format" => "%Y-%m-%d %H:%M:%S"
        }
      }

      writer = Ace::Taskflow::Organisms::IdeaWriter.new(config)

      # Mock LLM for predictable slug generation
      mock_slug_resp = mock_slug_response(
        folder_slug: "integration-test",
        file_slug: "complete-workflow"
      )

      mock_llm_query(response_text: mock_slug_resp) do
        content = "This is an integration test idea for the complete workflow"
        metadata = {
          title: "Integration Test",
          timestamp: "2025-01-01 12:00:00"
        }

        # Execute write
        path = writer.write(content, metadata)

        # Verify it returns the file path
        assert File.exist?(path), "Idea file should exist"
        assert_match(/integration-test\/complete-workflow\.s\.md$/, path, "Should return full file path")

        # Verify directory was created
        folder_path = File.dirname(path)
        assert Dir.exist?(folder_path), "Idea directory should exist"
        assert_match(/integration-test$/, folder_path, "Directory should contain folder slug")

        # Verify file content (path is now the file path)
        file_content = File.read(path)
        assert_includes file_content, "# Integration Test", "Should include title"
        assert_includes file_content, content, "Should include original content"
        assert_includes file_content, "2025-01-01 12:00:00", "Should include timestamp"
        assert_match(/Captured:/, file_content, "Should include template footer")
      end
    end
  end

  def test_llm_enhanced_content_workflow
    Dir.mktmpdir do |temp_dir|
      config = {
        "directory" => File.join(temp_dir, "enhanced-ideas")
      }

      writer = Ace::Taskflow::Organisms::IdeaWriter.new(config)

      # Simulate LLM-enhanced content (with frontmatter)
      enhanced_content = <<~CONTENT
        ---
        title: LLM Enhanced Idea
        filename_suggestion: llm-enhanced-test
        enhanced_at: 2025-01-01 12:00:00
        ---

        # LLM Enhanced Idea

        ## Problem
        Testing LLM-enhanced content in integration test.

        ## Solution
        Verify that enhanced content is written correctly.
      CONTENT

      mock_slug_resp = mock_slug_response(
        folder_slug: "llm-enhanced",
        file_slug: "test-idea"
      )

      mock_llm_query(response_text: mock_slug_resp) do
        path = writer.write(enhanced_content)

        # Verify file path is returned
        assert File.exist?(path), "Idea file should exist"
        assert_match(/llm-enhanced\/test-idea\.s\.md$/, path, "Should return full file path")

        # Verify directory structure
        folder_path = File.dirname(path)
        assert Dir.exist?(folder_path)
        assert_match(/llm-enhanced$/, folder_path)

        # Verify content was written as-is (no template applied)
        file_content = File.read(path)
        # Enhanced content should be preserved (starts with frontmatter)
        assert file_content.start_with?("---\n"), "Should preserve frontmatter"
        assert_includes file_content, "# LLM Enhanced Idea"
        assert_includes file_content, "## Problem"
        assert_includes file_content, "## Solution"
      end
    end
  end

  def test_error_handling_with_filesystem
    Dir.mktmpdir do |temp_dir|
      config = {
        "directory" => File.join(temp_dir, "ideas")
      }

      writer = Ace::Taskflow::Organisms::IdeaWriter.new(config)

      # Test empty content error
      error = assert_raises(Ace::Taskflow::Organisms::IdeaWriterError) do
        writer.write("")
      end

      assert_match(/No content provided/, error.message)

      # Verify no files were created
      assert !Dir.exist?(config["directory"]) || Dir.empty?(config["directory"]),
             "No files should be created on error"
    end
  end
end
