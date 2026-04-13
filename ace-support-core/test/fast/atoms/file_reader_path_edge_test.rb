# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core/atoms/file_reader"
require "tempfile"

class FileReaderPathEdgeTest < Minitest::Test
  def setup
    @reader = Ace::Core::Atoms::FileReader
  end

  def test_read_file_with_unicode_filename
    Dir.mktmpdir do |tmpdir|
      # Unicode filename with various scripts
      filename = File.join(tmpdir, "café_文件_🚀.txt")
      File.write(filename, "Unicode filename content")

      result = @reader.read(filename)

      assert result[:success], "Should read file with unicode filename: #{result[:error]}"
      assert_equal "Unicode filename content", result[:content]
    end
  end

  def test_read_file_with_spaces_in_path
    Dir.mktmpdir do |tmpdir|
      # Path with multiple spaces
      dir_with_spaces = File.join(tmpdir, "dir with spaces", "nested dir")
      FileUtils.mkdir_p(dir_with_spaces)
      filename = File.join(dir_with_spaces, "file with spaces.txt")
      File.write(filename, "Content in spaced path")

      result = @reader.read(filename)

      assert result[:success], "Should read file with spaces in path: #{result[:error]}"
      assert_equal "Content in spaced path", result[:content]
    end
  end

  def test_read_file_with_special_characters_in_name
    Dir.mktmpdir do |tmpdir|
      # Special characters that are valid in filenames
      filename = File.join(tmpdir, "file-name_with.special@chars#123.txt")
      File.write(filename, "Special chars content")

      result = @reader.read(filename)

      assert result[:success], "Should read file with special chars: #{result[:error]}"
      assert_equal "Special chars content", result[:content]
    end
  end

  def test_read_file_with_very_long_path
    Dir.mktmpdir do |tmpdir|
      # Create a deeply nested path (not as long as max to avoid filesystem limits)
      deep_path = tmpdir
      20.times do |i|
        deep_path = File.join(deep_path, "level_#{i}_with_longer_name")
      end
      FileUtils.mkdir_p(deep_path)

      filename = File.join(deep_path, "test_file.txt")
      File.write(filename, "Deep path content")

      result = @reader.read(filename)

      assert result[:success], "Should read file in very long path: #{result[:error]}"
      assert_equal "Deep path content", result[:content]
    end
  end

  def test_read_symlink_to_file
    Dir.mktmpdir do |tmpdir|
      original = File.join(tmpdir, "original.txt")
      symlink = File.join(tmpdir, "link.txt")

      File.write(original, "Original content")
      File.symlink(original, symlink)

      result = @reader.read(symlink)

      assert result[:success], "Should read symlink to file: #{result[:error]}"
      assert_equal "Original content", result[:content]
    end
  end

  def test_readable_with_unicode_path
    Dir.mktmpdir do |tmpdir|
      filename = File.join(tmpdir, "日本語ファイル.txt")
      File.write(filename, "test")

      assert @reader.readable?(filename), "Should detect unicode path as readable"
    end
  end

  def test_metadata_with_unicode_filename
    Dir.mktmpdir do |tmpdir|
      filename = File.join(tmpdir, "файл.txt")
      File.write(filename, "test content")

      metadata = @reader.metadata(filename)

      assert metadata[:exists], "Should get metadata for unicode filename"
      assert metadata[:readable]
      assert_equal filename, metadata[:path]
    end
  end

  def test_read_file_with_unicode_content
    Dir.mktmpdir do |tmpdir|
      filename = File.join(tmpdir, "unicode_content.txt")
      # Mix of ASCII and limited unicode to stay below binary threshold
      content = "Hello world! Café résumé naïve"
      File.write(filename, content, encoding: "UTF-8")

      result = @reader.read(filename)

      assert result[:success], "Should read unicode content: #{result[:error]}"
      assert_equal content, result[:content]
    end
  end

  def test_read_file_with_mixed_line_endings
    Dir.mktmpdir do |tmpdir|
      filename = File.join(tmpdir, "mixed_endings.txt")
      # Mix of Unix (\n), Windows (\r\n), and old Mac (\r) line endings
      content = "Line 1\nLine 2\r\nLine 3\rLine 4"
      File.write(filename, content)

      result = @reader.read(filename)

      assert result[:success], "Should read file with mixed line endings: #{result[:error]}"
      assert_equal content, result[:content]
    end
  end

  def test_read_file_with_bom
    Dir.mktmpdir do |tmpdir|
      filename = File.join(tmpdir, "bom.txt")
      # UTF-8 BOM followed by content
      File.open(filename, "wb") do |f|
        f.write("\xEF\xBB\xBF")
        f.write("Content with BOM")
      end

      result = @reader.read(filename)

      # Should handle BOM gracefully (either strip or include it)
      assert result[:success], "Should read file with BOM: #{result[:error]}"
      assert result[:content].include?("Content with BOM")
    end
  end

  def test_read_empty_file_with_unicode_name
    Dir.mktmpdir do |tmpdir|
      filename = File.join(tmpdir, "пустой.txt")
      File.write(filename, "")

      result = @reader.read(filename)

      assert result[:success], "Should read empty file with unicode name: #{result[:error]}"
      assert_equal "", result[:content]
      assert_equal 0, result[:size]
    end
  end

  def test_relative_path_resolution
    original_dir = Dir.pwd

    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir)
      File.write("relative.txt", "Relative path content")

      result = @reader.read("./relative.txt")

      assert result[:success], "Should read relative path: #{result[:error]}"
      assert_equal "Relative path content", result[:content]
    ensure
      Dir.chdir(original_dir)
    end
  end

  def test_path_with_dot_directories
    Dir.mktmpdir do |tmpdir|
      nested = File.join(tmpdir, "a", "b", "c")
      FileUtils.mkdir_p(nested)
      filename = File.join(nested, "test.txt")
      File.write(filename, "Dot dir content")

      # Path with .. components
      complex_path = File.join(tmpdir, "a", "b", "c", "..", "..", "b", "c", "test.txt")

      result = @reader.read(complex_path)

      assert result[:success], "Should read path with .. components: #{result[:error]}"
      assert_equal "Dot dir content", result[:content]
    end
  end

  def test_path_with_trailing_slash
    Dir.mktmpdir do |tmpdir|
      filename = File.join(tmpdir, "test.txt")
      File.write(filename, "Content")

      # Try to read file path with trailing slash
      # On some systems this resolves to the file, on others it fails
      result = @reader.read(filename + "/")

      # Either it should fail, or if the system allows it, should still read the content
      if result[:success]
        assert_equal "Content", result[:content]
      else
        assert_match(/File not found|Not a file/, result[:error])
      end
    end
  end

  def test_read_file_in_symlinked_directory
    Dir.mktmpdir do |tmpdir|
      real_dir = File.join(tmpdir, "real")
      link_dir = File.join(tmpdir, "link")
      FileUtils.mkdir_p(real_dir)
      File.symlink(real_dir, link_dir)

      filename = File.join(link_dir, "file.txt")
      File.write(filename, "Symlinked dir content")

      result = @reader.read(filename)

      assert result[:success], "Should read file in symlinked directory: #{result[:error]}"
      assert_equal "Symlinked dir content", result[:content]
    end
  end
end
