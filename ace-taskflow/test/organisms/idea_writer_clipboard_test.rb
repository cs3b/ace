# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/idea_writer"
require "fileutils"
require "tmpdir"

class IdeaWriterClipboardTest < AceTaskflowTestCase
  def setup
    # Use in-memory config (no real filesystem)
    @config = {
      "directory" => "/test/ideas",
      "template" => "%{content}"
    }
    @writer = Ace::Taskflow::Organisms::IdeaWriter.new(@config)
    @original_clipboard = Clipboard
    @written_files = []
    @mkdir_calls = []
  end

  def teardown
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Object.const_set(:Clipboard, @original_clipboard) if defined?(@original_clipboard)
  ensure
    $VERBOSE = old_verbose
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
    mock_slug_resp = mock_slug_response(folder_slug: "test", file_slug: "content")

    mock_filesystem do
      mock_llm_query(response_text: mock_slug_resp) do
        path = @writer.write("main content", clipboard: false)

        assert path
        assert_match(%r{/test/ideas/}, path)

        # Verify file was written with correct content
        write_call = @written_files.first
        assert write_call
        assert_match(/main content/, write_call[:content])
        refute_match(/should not appear/, write_call[:content])
      end
    end
  end

  # Test that --clipboard flag is not set, clipboard is ignored
  def test_clipboard_ignored_when_flag_not_set
    mock_clipboard("should be ignored")
    mock_slug_resp = mock_slug_response(folder_slug: "test", file_slug: "content")

    mock_filesystem do
      mock_llm_query(response_text: mock_slug_resp) do
        path = @writer.write("main content")

        assert path

        # Verify file was written with correct content
        write_call = @written_files.first
        assert write_call
        assert_match(/main content/, write_call[:content])
        refute_match(/should be ignored/, write_call[:content])
      end
    end
  end

  private

  def mock_clipboard(text_content)
    mock = Module.new do
      define_singleton_method(:paste) { text_content }
    end
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Object.send(:remove_const, :Clipboard) if defined?(Clipboard)
    Object.const_set(:Clipboard, mock)
  ensure
    $VERBOSE = old_verbose
  end

  def mock_clipboard_files(file_paths)
    # Mock clipboard to return file paths (one per line)
    content = file_paths.join("\n")
    mock_clipboard(content)
  end

  def mock_filesystem
    # Capture instance variables for closure
    written_files = @written_files
    mkdir_calls = @mkdir_calls

    # Mock FileUtils.mkdir_p
    FileUtils.stub :mkdir_p, ->(path) { mkdir_calls << path } do
      # Mock SafeFileWriter.write
      original_write = Ace::Support::Markdown::Organisms::SafeFileWriter.method(:write)

      Ace::Support::Markdown::Organisms::SafeFileWriter.define_singleton_method(:write) do |path, content, **options|
        written_files << { path: path, content: content, options: options }
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
