# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core/atoms/file_reader"
require "tempfile"

class FileReaderTest < Minitest::Test
  def setup
    @reader = Ace::Core::Atoms::FileReader
  end

  def test_read_existing_file
    Tempfile.create(["test", ".txt"]) do |file|
      content = "Hello, World!"
      file.write(content)
      file.flush

      result = @reader.read(file.path)

      assert result[:success]
      assert_equal content, result[:content]
      assert_equal content.bytesize, result[:size]
    end
  end

  def test_read_non_existent_file
    result = @reader.read("/non/existent/file.txt")

    refute result[:success]
    assert_match(/File not found/, result[:error])
  end

  def test_read_nil_path
    result = @reader.read(nil)

    refute result[:success]
    assert_equal "Path cannot be nil", result[:error]
  end

  def test_read_directory
    Dir.mktmpdir do |dir|
      result = @reader.read(dir)

      refute result[:success]
      assert_match(/Not a file/, result[:error])
    end
  end

  def test_read_file_with_size_limit
    Tempfile.create(["test", ".txt"]) do |file|
      content = "x" * 1000
      file.write(content)
      file.flush

      # Should succeed with larger limit
      result = @reader.read(file.path, max_size: 2000)
      assert result[:success]

      # Should fail with smaller limit
      result = @reader.read(file.path, max_size: 500)
      refute result[:success]
      assert_match(/File too large/, result[:error])
    end
  end

  def test_readable_returns_true_for_readable_file
    Tempfile.create do |file|
      assert @reader.readable?(file.path)
    end
  end

  def test_readable_returns_false_for_non_existent_file
    refute @reader.readable?("/non/existent/file.txt")
  end

  def test_readable_returns_false_for_nil
    refute @reader.readable?(nil)
  end

  def test_binary_detection_by_extension
    assert @reader.binary?("image.jpg")
    assert @reader.binary?("document.pdf")
    assert @reader.binary?("archive.zip")
    refute @reader.binary?("text.txt")
    refute @reader.binary?("script.rb")
  end

  def test_binary_detection_by_content
    Tempfile.create(["binary", ".dat"]) do |file|
      # Write binary content with null bytes
      file.write("\x00\x01\x02\x03")
      file.flush

      assert @reader.binary?(file.path)
    end

    Tempfile.create(["text", ".txt"]) do |file|
      file.write("Plain text content")
      file.flush

      refute @reader.binary?(file.path)
    end
  end

  def test_metadata_for_existing_file
    Tempfile.create do |file|
      file.write("test content")
      file.flush

      metadata = @reader.metadata(file.path)

      assert metadata[:exists]
      assert_equal file.path, metadata[:path]
      assert metadata[:readable]
      assert metadata[:file]
      refute metadata[:directory]
      assert_equal 12, metadata[:size]
    end
  end

  def test_metadata_for_non_existent_file
    metadata = @reader.metadata("/non/existent/file.txt")

    refute metadata[:exists]
    assert_equal "/non/existent/file.txt", metadata[:path]
  end

  def test_read_lines_with_limit
    Tempfile.create do |file|
      lines = (1..20).map { |n| "Line #{n}" }
      file.write(lines.join("\n"))
      file.flush

      result = @reader.read_lines(file.path, limit: 5, offset: 0)

      assert result[:success]
      assert_equal 5, result[:lines].size
      assert_equal "Line 1", result[:lines].first
      assert_equal "Line 5", result[:lines].last
      assert_equal 20, result[:total_lines]
    end
  end

  def test_read_lines_with_offset
    Tempfile.create do |file|
      lines = (1..10).map { |n| "Line #{n}" }
      file.write(lines.join("\n"))
      file.flush

      result = @reader.read_lines(file.path, limit: 3, offset: 5)

      assert result[:success]
      assert_equal 3, result[:lines].size
      assert_equal "Line 6", result[:lines].first
      assert_equal "Line 8", result[:lines].last
    end
  end

  def test_read_lines_binary_file
    Tempfile.create(["binary", ".jpg"]) do |file|
      file.write("\x00\x01\x02")
      file.flush

      result = @reader.read_lines(file.path)

      refute result[:success]
      assert_match(/Binary file detected/, result[:error])
    end
  end

  def test_read_invalid_utf8
    Tempfile.create do |file|
      # Write invalid UTF-8 bytes as binary
      file.binmode
      file.write("\xFF\xFE\xAB\xCD")
      file.flush

      result = @reader.read(file.path)

      refute result[:success]
      assert_match(/invalid UTF-8|Binary file/, result[:error])
    end
  end
end
