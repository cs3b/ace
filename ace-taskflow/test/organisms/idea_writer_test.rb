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

    # Path is now a directory (bug fix: ideas always in subfolders)
    assert Dir.exist?(path), "Directory should be created"
    assert_includes path, @temp_dir, "Directory should be in temp directory"

    # Find the idea file inside the directory
    idea_files = Dir.glob(File.join(path, "*.s.md"))
    assert idea_files.any?, "Should have at least one .s.md file in directory"

    idea_file = idea_files.first
    file_content = File.read(idea_file)
    assert_includes file_content, content, "File should contain the idea content"
  end

  def test_uses_configured_directory
    custom_dir = File.join(@temp_dir, "custom", "ideas")
    @config["directory"] = custom_dir
    writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)

    content = "Test idea in custom directory"
    path = writer.write(content)

    # Path is now a directory
    assert Dir.exist?(path), "Directory should be created"
    assert_includes path, custom_dir, "Directory should be in custom directory"
    assert Dir.exist?(custom_dir), "Custom directory should be created"

    # Check that file exists inside the directory
    idea_files = Dir.glob(File.join(path, "*.s.md"))
    assert idea_files.any?, "Should have idea file in directory"
  end

  def test_creates_directory_if_not_exists
    nested_dir = File.join(@temp_dir, "deep", "nested", "ideas")
    @config["directory"] = nested_dir
    writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)

    content = "Test idea in nested directory"
    path = writer.write(content)

    assert Dir.exist?(nested_dir), "Nested directory should be created"
    assert Dir.exist?(path), "Idea directory should be created"

    # Check that file exists inside the directory
    idea_files = Dir.glob(File.join(path, "*.s.md"))
    assert idea_files.any?, "Should have idea file in directory"
  end

  def test_formats_idea_with_template
    content = "Template test idea"
    metadata = {
      title: "Template Test",
      timestamp: "2025-01-01 12:00:00"
    }

    path = @writer.write(content, metadata)

    # Path is now a directory, find the idea file inside
    idea_files = Dir.glob(File.join(path, "*.s.md"))
    assert idea_files.any?, "Should have idea file in directory"

    idea_file = idea_files.first
    file_content = File.read(idea_file)

    assert_includes file_content, "# Template Test", "Should include title from metadata"
    assert_includes file_content, content, "Should include content"
    assert_includes file_content, "2025-01-01 12:00:00", "Should include timestamp"
  end

  def test_extracts_title_from_content
    content = "This is a long idea that should be truncated for the title section of the generated filename"
    path = @writer.write(content)

    # Path is now a directory, the title should be in the directory name (after timestamp)
    dirname = File.basename(path)
    # Directory name format: YYYYMMDD-HHMMSS-{sanitized-title} or YYYYMMDD-HHMMSS-{folder-slug}
    # The sanitized title or slug should contain part of the content
    assert_match(/this-is-a-long-idea|enhance|idea/, dirname, "Directory name should contain sanitized title or slug")

    # Also check that file was created inside
    idea_files = Dir.glob(File.join(path, "*.s.md"))
    assert idea_files.any?, "Should have idea file in directory"
  end

  def test_raises_error_on_empty_content
    content = ""

    error = assert_raises(Ace::Taskflow::Organisms::IdeaWriterError) do
      @writer.write(content)
    end

    assert_match(/No content provided/, error.message)
  end
end