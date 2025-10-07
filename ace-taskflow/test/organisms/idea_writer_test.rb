# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/organisms/idea_writer"

class IdeaWriterTest < AceTestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @config = {
      "directory" => @temp_dir,
      "template" => "# %{title}\n\n%{content}\n\n---\nCaptured: %{timestamp}",
      "formatting" => {
        "timestamp_format" => "%Y-%m-%d %H:%M:%S"
      }
    }
    @writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_writes_idea_to_file
    content = "This is a test idea"
    path = @writer.write(content)

    assert File.exist?(path), "File should be created"
    assert_includes path, @temp_dir, "File should be in temp directory"
    assert_match(/\.md$/, path, "File should have .md extension")

    file_content = File.read(path)
    assert_includes file_content, content, "File should contain the idea content"
  end

  def test_uses_configured_directory
    custom_dir = File.join(@temp_dir, "custom", "ideas")
    @config["directory"] = custom_dir
    writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)

    content = "Test idea in custom directory"
    path = writer.write(content)

    assert File.exist?(path), "File should be created"
    assert_includes path, custom_dir, "File should be in custom directory"
    assert Dir.exist?(custom_dir), "Custom directory should be created"
  end

  def test_creates_directory_if_not_exists
    nested_dir = File.join(@temp_dir, "deep", "nested", "ideas")
    @config["directory"] = nested_dir
    writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)

    content = "Test idea in nested directory"
    path = writer.write(content)

    assert Dir.exist?(nested_dir), "Nested directory should be created"
    assert File.exist?(path), "File should be created"
  end

  def test_formats_idea_with_template
    content = "Template test idea"
    metadata = {
      title: "Template Test",
      timestamp: "2025-01-01 12:00:00"
    }

    path = @writer.write(content, metadata)
    file_content = File.read(path)

    assert_includes file_content, "# Template Test", "Should include title from metadata"
    assert_includes file_content, content, "Should include content"
    assert_includes file_content, "2025-01-01 12:00:00", "Should include timestamp"
  end

  def test_extracts_title_from_content
    content = "This is a long idea that should be truncated for the title section of the generated filename"
    path = @writer.write(content)

    # The title should be extracted and sanitized for the filename
    basename = File.basename(path)
    assert_match(/this-is-a-long-idea/, basename, "Filename should contain sanitized title")
  end

  def test_raises_error_on_empty_content
    content = ""

    error = assert_raises(Ace::Taskflow::Organisms::IdeaWriterError) do
      @writer.write(content)
    end

    assert_match(/No content provided/, error.message)
  end
end