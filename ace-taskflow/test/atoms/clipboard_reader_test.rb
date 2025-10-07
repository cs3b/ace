# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/atoms/clipboard_reader"

class ClipboardReaderTest < AceTaskflowTestCase
  def setup
    @original_clipboard = Clipboard
    # Stub macos_clipboard_available? to force fallback to gem Clipboard
    @original_macos_available = Ace::Taskflow::Atoms::ClipboardReader.singleton_method(:macos_clipboard_available?) rescue nil
    Ace::Taskflow::Atoms::ClipboardReader.define_singleton_method(:macos_clipboard_available?) { false }
  end

  def teardown
    # Restore original Clipboard module
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Object.const_set(:Clipboard, @original_clipboard) if defined?(@original_clipboard)

    # Restore macos_clipboard_available?
    if @original_macos_available
      Ace::Taskflow::Atoms::ClipboardReader.define_singleton_method(:macos_clipboard_available?, @original_macos_available)
    end
  ensure
    $VERBOSE = old_verbose
  end

  def test_read_text_content
    mock_clipboard("Simple text content")

    result = Ace::Taskflow::Atoms::ClipboardReader.read

    assert result[:success]
    assert_equal :text, result[:type]
    assert_equal "Simple text content", result[:content]
    assert_empty result[:files]
  end

  def test_read_empty_clipboard
    mock_clipboard("")

    result = Ace::Taskflow::Atoms::ClipboardReader.read

    refute result[:success]
    assert_match(/empty/i, result[:error])
  end

  def test_read_whitespace_only_clipboard
    mock_clipboard("   \n  \t  \n   ")

    result = Ace::Taskflow::Atoms::ClipboardReader.read

    refute result[:success]
    assert_match(/empty/i, result[:error])
  end

  def test_read_binary_content
    # Create a string with null bytes (binary indicator)
    binary_content = "text\x00binary"
    mock_clipboard(binary_content)

    result = Ace::Taskflow::Atoms::ClipboardReader.read

    refute result[:success]
    assert_match(/binary/i, result[:error])
  end

  def test_read_content_too_large
    # Create content larger than MAX_CONTENT_SIZE (100KB)
    large_content = "x" * (101 * 1024)
    mock_clipboard(large_content)

    result = Ace::Taskflow::Atoms::ClipboardReader.read

    refute result[:success]
    assert_match(/too large/i, result[:error])
  end

  def test_read_single_file_path
    with_temp_dir do |dir|
      # Create a test file
      test_file = File.join(dir, "test.rb")
      File.write(test_file, "# test")

      mock_clipboard(test_file)

      result = Ace::Taskflow::Atoms::ClipboardReader.read

      assert result[:success]
      assert_equal :files, result[:type]
      assert_equal [test_file], result[:files]
    end
  end

  def test_read_multiple_file_paths
    with_temp_dir do |dir|
      # Create test files
      file1 = File.join(dir, "file1.rb")
      file2 = File.join(dir, "file2.rb")
      File.write(file1, "# file1")
      File.write(file2, "# file2")

      clipboard_content = "#{file1}\n#{file2}"
      mock_clipboard(clipboard_content)

      result = Ace::Taskflow::Atoms::ClipboardReader.read

      assert result[:success]
      assert_equal :files, result[:type]
      assert_equal [file1, file2], result[:files]
    end
  end

  def test_read_mixed_valid_and_invalid_paths
    with_temp_dir do |dir|
      # Create one valid file
      valid_file = File.join(dir, "valid.rb")
      File.write(valid_file, "# valid")

      invalid_file = File.join(dir, "nonexistent.rb")

      # Mixed content: one valid, one invalid
      clipboard_content = "#{valid_file}\n#{invalid_file}"
      mock_clipboard(clipboard_content)

      result = Ace::Taskflow::Atoms::ClipboardReader.read

      # Should treat as text since not all lines are valid file paths
      assert result[:success]
      assert_equal :text, result[:type]
      assert_empty result[:files]
    end
  end

  def test_read_file_paths_with_text
    with_temp_dir do |dir|
      # Create a test file
      test_file = File.join(dir, "test.rb")
      File.write(test_file, "# test")

      # Mixed: text line + file path
      clipboard_content = "Some text\n#{test_file}"
      mock_clipboard(clipboard_content)

      result = Ace::Taskflow::Atoms::ClipboardReader.read

      # Should treat as text since <50% are valid file paths
      assert result[:success]
      assert_equal :text, result[:type]
      assert_empty result[:files]
    end
  end

  def test_read_clipboard_error
    # Mock Clipboard.paste to raise an error
    mock_clipboard_error(StandardError.new("Clipboard unavailable"))

    result = Ace::Taskflow::Atoms::ClipboardReader.read

    refute result[:success]
    assert_match(/unable to read clipboard/i, result[:error])
    assert_match(/unavailable/i, result[:error])
  end

  def test_read_multiline_text
    text = "Line 1\nLine 2\nLine 3"
    mock_clipboard(text)

    result = Ace::Taskflow::Atoms::ClipboardReader.read

    assert result[:success]
    assert_equal :text, result[:type]
    assert_equal text, result[:content]
  end

  private

  def mock_clipboard(content)
    # Replace Clipboard module with a mock
    mock = Module.new do
      define_singleton_method(:paste) { content }
    end
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Object.send(:remove_const, :Clipboard) if defined?(Clipboard)
    Object.const_set(:Clipboard, mock)
  ensure
    $VERBOSE = old_verbose
  end

  def mock_clipboard_error(error)
    # Replace Clipboard module with a mock that raises an error
    mock = Module.new do
      define_singleton_method(:paste) { raise error }
    end
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Object.send(:remove_const, :Clipboard) if defined?(Clipboard)
    Object.const_set(:Clipboard, mock)
  ensure
    $VERBOSE = old_verbose
  end
end
