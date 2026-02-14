# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/molecules/file_namer"
require "ace/b36ts"

class FileNamerTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    # Default config - all IDs are now Base36 format
    @config = {
      "directory" => "/test/ideas",
      "file_naming" => {
        "title_max_length" => 50
      }
    }
    @namer = Ace::Taskflow::Molecules::FileNamer.new(@config)
  end

  def test_generates_directory_path_with_base36_id
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        path = @namer.generate
        dirname = File.basename(path)
        # Base36 format: 6 alphanumeric characters followed by hyphen and title
        assert_match(/^[0-9a-z]{6}-idea$/i, dirname, "Should generate 6-char Base36 ID")
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  def test_includes_sanitized_title_in_directory_name
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = { title: "My Great Idea!" }
        path = @namer.generate(metadata)
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-my-great-idea$/i, dirname)
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  def test_sanitizes_title_with_special_characters
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = { title: "Test@#$%^&*()_+={}[]|\\:\";<>?,./~`" }
        path = @namer.generate(metadata)
        dirname = File.basename(path)
        # All special characters should be removed, leaving only ID and hyphens
        assert_match(/^[0-9a-z]{6}-test$/i, dirname)
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  def test_collapses_multiple_spaces_to_single_hyphen
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = { title: "Too    many     spaces" }
        path = @namer.generate(metadata)
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-too-many-spaces$/i, dirname)
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  def test_removes_leading_and_trailing_hyphens
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = { title: "   ---trimmed---   " }
        path = @namer.generate(metadata)
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-trimmed$/i, dirname)
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  def test_truncates_long_titles
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        long_title = "a" * 100
        metadata = { title: long_title }
        path = @namer.generate(metadata)

        dirname = File.basename(path)
        # Extract just the title part (after 6-char Base36 ID and hyphen)
        title_part = dirname.match(/^[0-9a-z]{6}-(.+)$/i)[1]
        assert_equal 50, title_part.length, "Title should be truncated to 50 characters"
      end
    end
  end

  def test_handles_empty_title
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = { title: "" }
        path = @namer.generate(metadata)
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-idea$/i, dirname)
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  def test_handles_nil_title
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = { title: nil }
        path = @namer.generate(metadata)
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-idea$/i, dirname)
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  def test_uses_default_directory_when_not_configured
    with_timestamp_test_context do
      config = {}
      namer = Ace::Taskflow::Molecules::FileNamer.new(config)

      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        path = namer.generate
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-idea$/i, dirname, "Should generate 6-char Base36 ID")
        assert path.start_with?("./ideas/"), "Should use default directory"
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  def test_uses_llm_generated_slugs_when_available
    with_timestamp_test_context do
      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = {
          title: "Improve search performance",
          folder_slug: "search-enhance",
          file_slug: "improve-performance"
        }
        path = @namer.generate(metadata)
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-search-enhance$/i, dirname)
        refute path.end_with?(".s.md"), "Should generate directory path, not file path"
      end
    end
  end

  # Tests for Base36 compact ID format
  def test_generates_base36_compact_id
    with_timestamp_test_context do
      config = {
        "directory" => "/test/ideas",
        "file_naming" => {
          "title_max_length" => 50
        }
      }
      namer = Ace::Taskflow::Molecules::FileNamer.new(config)

      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        path = namer.generate
        dirname = File.basename(path)
        # Base36 format: 6 alphanumeric characters followed by hyphen and title
        assert_match(/^[0-9a-z]{6}-idea$/i, dirname, "Should generate 6-char Base36 ID")
        refute_match(/^\d{8}-\d{6}/, dirname, "Should NOT generate timestamp format")
      end
    end
  end

  def test_base36_id_includes_sanitized_title
    with_timestamp_test_context do
      config = {
        "directory" => "/test/ideas",
        "file_naming" => {
          "title_max_length" => 50
        }
      }
      namer = Ace::Taskflow::Molecules::FileNamer.new(config)

      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = { title: "My Great Idea!" }
        path = namer.generate(metadata)
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-my-great-idea$/i, dirname)
      end
    end
  end

  def test_base36_id_uses_folder_slug_when_available
    with_timestamp_test_context do
      config = {
        "directory" => "/test/ideas",
        "file_naming" => {
          "title_max_length" => 50
        }
      }
      namer = Ace::Taskflow::Molecules::FileNamer.new(config)

      Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
        metadata = {
          title: "Improve search performance",
          folder_slug: "search-enhance"
        }
        path = namer.generate(metadata)
        dirname = File.basename(path)
        assert_match(/^[0-9a-z]{6}-search-enhance$/i, dirname)
      end
    end
  end

  # Helper method for tests requiring timestamp context
  # Combines config setup with timestamp reset to reduce boilerplate
  def with_timestamp_test_context
    with_real_config do
      Ace::B36ts.reset_config!
      yield
    end
  end

  def test_detect_id_format_identifies_timestamp
    # detect_id_format still works for reading legacy formats
    assert_equal :timestamp, Ace::Taskflow::Molecules::FileNamer.detect_id_format("20250115-103045")
  end

  def test_detect_id_format_identifies_2sec
    assert_equal :"2sec", Ace::Taskflow::Molecules::FileNamer.detect_id_format("abc123")
    assert_equal :"2sec", Ace::Taskflow::Molecules::FileNamer.detect_id_format("i50jj3")
  end

  def test_detect_id_format_returns_nil_for_invalid
    assert_nil Ace::Taskflow::Molecules::FileNamer.detect_id_format("invalid-format")
    assert_nil Ace::Taskflow::Molecules::FileNamer.detect_id_format("too-long-string")
  end
end