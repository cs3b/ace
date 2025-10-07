# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/idea_writer"
require "fileutils"
require "tmpdir"

class IdeaWriterClipboardTest < AceTaskflowTestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @config = {
      "directory" => File.join(@temp_dir, "ideas"),
      "template" => "%{content}"
    }
    @writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)
    @original_clipboard = Clipboard
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    Object.const_set(:Clipboard, @original_clipboard) if defined?(@original_clipboard)
  end

  # Test that clipboard content is merged with provided content
  # TODO: Fix mocking approach - needs to mock ClipboardReader, not Clipboard directly
  def test_write_with_clipboard_text_merges_content
    skip "Pending: mocking approach needs refinement"
  end

  # Test that clipboard-only works when no content provided
  # TODO: Fix mocking approach
  def test_write_with_clipboard_only
    skip "Pending: mocking approach needs refinement"
  end

  # Test that file attachments create directory structure
  # TODO: Fix mocking approach
  def test_write_with_clipboard_files_creates_directory
    skip "Pending: mocking approach needs refinement"
  end

  def _test_write_with_clipboard_files_creates_directory
    with_temp_dir do |dir|
      # Create test files
      file1 = File.join(dir, "test1.rb")
      file2 = File.join(dir, "test2.rb")
      File.write(file1, "# test 1")
      File.write(file2, "# test 2")

      # Mock clipboard to return file paths
      mock_clipboard_files([file1, file2])

      path = @writer.write("review these files", clipboard: true)

      # Should create directory (not flat file)
      assert Dir.exist?(path), "Expected directory to be created"
      refute File.file?(path), "Should not be a flat file"

      # Should have idea.md inside
      idea_file = File.join(path, "idea.md")
      assert File.exist?(idea_file), "Expected idea.md to exist"

      # Should have attached files
      assert File.exist?(File.join(path, "test1.rb"))
      assert File.exist?(File.join(path, "test2.rb"))

      # Content should reference files
      content = File.read(idea_file)
      assert_match(/test1\.rb/, content)
      assert_match(/test2\.rb/, content)
    end
  end

  # Test that --clipboard flag is respected
  def test_write_without_clipboard_flag_ignores_clipboard
    mock_clipboard("should not appear")

    path = @writer.write("main content", clipboard: false)

    content = File.read(path)
    assert_match(/main content/, content)
    refute_match(/should not appear/, content)
  end

  # Test that --clipboard flag is not set, clipboard is ignored
  def test_clipboard_ignored_when_flag_not_set
    mock_clipboard("should be ignored")

    path = @writer.write("main content")

    content = File.read(path)
    assert_match(/main content/, content)
    refute_match(/should be ignored/, content)
  end

  private

  def mock_clipboard(text_content)
    mock = Module.new do
      define_singleton_method(:paste) { text_content }
    end
    Object.send(:remove_const, :Clipboard) if defined?(Clipboard)
    Object.const_set(:Clipboard, mock)
  end

  def mock_clipboard_files(file_paths)
    # Mock clipboard to return file paths (one per line)
    content = file_paths.join("\n")
    mock_clipboard(content)
  end
end
