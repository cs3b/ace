# frozen_string_literal: true

require "test_helper"

class TestHelperTest < Minitest::Test
  include Ace::TestSupport::TestHelper

  def test_with_temp_dir_creates_and_cleans_up_directory
    original_pwd = Dir.pwd
    temp_path = nil

    with_temp_dir do |dir|
      temp_path = dir
      assert Dir.exist?(dir), "Temp directory should exist"
      assert_equal File.realpath(dir), File.realpath(Dir.pwd), "Should change to temp directory"

      # Create a test file to ensure directory is writable
      File.write("test.txt", "content")
      assert File.exist?("test.txt"), "Should be able to write files"
    end

    assert_equal original_pwd, Dir.pwd, "Should restore original directory"
    refute Dir.exist?(temp_path), "Temp directory should be cleaned up"
  end

  def test_with_temp_file_creates_and_cleans_up_file
    file_path = nil
    test_content = "test content"

    with_temp_file(test_content) do |path|
      file_path = path
      assert File.exist?(path), "Temp file should exist"
      assert_equal test_content, File.read(path), "File should contain specified content"
    end

    refute File.exist?(file_path), "Temp file should be cleaned up"
  end

  def test_with_temp_file_with_empty_content
    with_temp_file do |path|
      assert File.exist?(path), "Temp file should exist"
      assert_equal "", File.read(path), "File should be empty by default"
    end
  end

  def test_create_config_file_creates_directories_and_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        path = "config/nested/file.yml"
        content = "key: value"

        create_config_file(path, content)

        assert File.exist?(path), "Config file should be created"
        assert_equal content, File.read(path), "Config file should have correct content"
      end
    end
  end

  def test_assert_file_exists_passes_when_file_exists
    with_temp_file do |path|
      assert_file_exists(path)
    end
  end

  def test_assert_file_exists_fails_when_file_missing
    assert_raises(Minitest::Assertion) do
      assert_file_exists("/nonexistent/file")
    end
  end

  def test_assert_file_exists_with_custom_message
    error = assert_raises(Minitest::Assertion) do
      assert_file_exists("/nonexistent/file", "Custom error message")
    end
    assert_match(/Custom error message/, error.message)
  end

  def test_assert_file_content_validates_content
    with_temp_file("expected content") do |path|
      assert_file_content(path, "expected content")
    end
  end

  def test_assert_file_content_fails_on_mismatch
    with_temp_file("actual content") do |path|
      assert_raises(Minitest::Assertion) do
        assert_file_content(path, "expected content")
      end
    end
  end

  def test_assert_file_content_fails_when_file_missing
    assert_raises(Minitest::Assertion) do
      assert_file_content("/nonexistent/file", "content")
    end
  end

  def test_assert_directory_exists_passes_when_directory_exists
    Dir.mktmpdir do |dir|
      assert_directory_exists(dir)
    end
  end

  def test_assert_directory_exists_fails_when_directory_missing
    assert_raises(Minitest::Assertion) do
      assert_directory_exists("/nonexistent/directory")
    end
  end

  def test_assert_directory_exists_with_custom_message
    error = assert_raises(Minitest::Assertion) do
      assert_directory_exists("/nonexistent/directory", "Custom directory error")
    end
    assert_match(/Custom directory error/, error.message)
  end

  def test_capture_subprocess_io_captures_stdout_and_stderr
    stdout, stderr = capture_subprocess_io do
      $stdout.puts "stdout message"
      $stderr.puts "stderr message"
    end

    assert_equal "stdout message\n", stdout
    assert_equal "stderr message\n", stderr
  end

  def test_capture_subprocess_io_restores_original_streams
    original_stdout = $stdout
    original_stderr = $stderr

    capture_subprocess_io do
      # Streams should be replaced during block
      refute_equal original_stdout, $stdout
      refute_equal original_stderr, $stderr
    end

    # Streams should be restored after block
    assert_equal original_stdout, $stdout
    assert_equal original_stderr, $stderr
  end

  def test_capture_subprocess_io_handles_exceptions
    original_stdout = $stdout
    original_stderr = $stderr

    assert_raises(RuntimeError) do
      capture_subprocess_io do
        raise "test error"
      end
    end

    # Streams should still be restored after exception
    assert_equal original_stdout, $stdout
    assert_equal original_stderr, $stderr
  end
end