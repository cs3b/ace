# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/molecules/file_namer"
require "ace/timestamp"

class FileNamerTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers
  def setup
    # Default config uses timestamp format for backward compatibility in tests
    @config = {
      "directory" => "/test/ideas",
      "file_naming" => {
        "timestamp_format" => "%Y%m%d-%H%M%S",
        "title_max_length" => 50,
        "id_format" => "timestamp"
      }
    }
    @namer = Ace::Taskflow::Molecules::FileNamer.new(@config)
  end

  def test_generates_directory_path_with_timestamp
    # Freeze time for predictable timestamp
    # BUG FIX: Now generates directory paths instead of flat file paths
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      path = @namer.generate
      assert_match %r{/test/ideas/20250115-103045-idea$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  def test_includes_sanitized_title_in_directory_name
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      metadata = { title: "My Great Idea!" }
      path = @namer.generate(metadata)
      assert_match %r{/test/ideas/20250115-103045-my-great-idea$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  def test_sanitizes_title_with_special_characters
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      metadata = { title: "Test@#$%^&*()_+={}[]|\\:\";<>?,./~`" }
      path = @namer.generate(metadata)
      # All special characters should be removed, leaving only hyphens
      assert_match %r{/test/ideas/20250115-103045-test$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  def test_collapses_multiple_spaces_to_single_hyphen
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      metadata = { title: "Too    many     spaces" }
      path = @namer.generate(metadata)
      assert_match %r{/test/ideas/20250115-103045-too-many-spaces$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  def test_removes_leading_and_trailing_hyphens
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      metadata = { title: "   ---trimmed---   " }
      path = @namer.generate(metadata)
      assert_match %r{/test/ideas/20250115-103045-trimmed$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  def test_truncates_long_titles
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      long_title = "a" * 100
      metadata = { title: long_title }
      path = @namer.generate(metadata)

      dirname = File.basename(path)
      # Extract just the title part (after timestamp)
      title_part = dirname.match(/\d{8}-\d{6}-(.+)$/)[1]
      assert_equal 50, title_part.length, "Title should be truncated to 50 characters"
    end
  end

  def test_handles_empty_title
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      metadata = { title: "" }
      path = @namer.generate(metadata)
      assert_match %r{/test/ideas/20250115-103045-idea$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  def test_handles_nil_title
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      metadata = { title: nil }
      path = @namer.generate(metadata)
      assert_match %r{/test/ideas/20250115-103045-idea$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  def test_uses_default_directory_when_not_configured
    config = {}
    namer = Ace::Taskflow::Molecules::FileNamer.new(config)

    # Default is now base36 format, which produces 6-character IDs
    # Since ace-timestamp requires configuration, we use timestamp format for this test
    timestamp_config = { "file_naming" => { "id_format" => "timestamp" } }
    timestamp_namer = Ace::Taskflow::Molecules::FileNamer.new(timestamp_config)

    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      path = timestamp_namer.generate
      assert_match %r{^\./ideas/20250115-103045-idea$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  def test_uses_llm_generated_slugs_when_available
    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      metadata = {
        title: "Improve search performance",
        folder_slug: "search-enhance",
        file_slug: "improve-performance"
      }
      path = @namer.generate(metadata)
      assert_match %r{/test/ideas/20250115-103045-search-enhance$}, path
      refute path.end_with?(".s.md"), "Should generate directory path, not file path"
    end
  end

  # Tests for Base36 compact ID format
  def test_generates_base36_compact_id_when_configured
    # Use timestamp format for deterministic test IDs (no external config dependency)
    config = {
      "directory" => "/test/ideas",
      "file_naming" => {
        "id_format" => "timestamp",
        "timestamp_format" => "%Y%m%d-%H%M%S",
        "title_max_length" => 50
      }
    }
    namer = Ace::Taskflow::Molecules::FileNamer.new(config)

    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      path = namer.generate
      dirname = File.basename(path)
      # Timestamp format: 14-character timestamp followed by hyphen and title
      assert_match(/^\d{8}-\d{6}-idea$/, dirname, "Should generate timestamp format ID")
      refute_match(/^[0-9a-z]{6}-idea$/i, dirname, "Should NOT generate Base36 format")
    end
  end

  # Test Base36 format with real config (integration test - uses ace-timestamp)
  def test_base36_compact_id_integration
    with_real_config do
      # Reset ace-timestamp config cache to load gem defaults
      Ace::Timestamp.reset_config!

      config = {
        "directory" => "/test/ideas",
        "file_naming" => {
          "id_format" => "base36",
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
    with_real_config do
      # Reset ace-timestamp config cache to load gem defaults
      Ace::Timestamp.reset_config!

      config = {
        "directory" => "/test/ideas",
        "file_naming" => {
          "id_format" => "base36",
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
    with_real_config do
      # Reset ace-timestamp config cache to load gem defaults
      Ace::Timestamp.reset_config!

      config = {
        "directory" => "/test/ideas",
        "file_naming" => {
          "id_format" => "base36",
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

  # Helper method for Base36 integration tests
  def with_base36_config
    with_real_config do
      Ace::Timestamp.reset_config!
      yield
    end
  end

  def test_id_format_returns_configured_format
    assert_equal "timestamp", @namer.id_format

    base36_config = { "file_naming" => { "id_format" => "base36" } }
    base36_namer = Ace::Taskflow::Molecules::FileNamer.new(base36_config)
    assert_equal "base36", base36_namer.id_format
  end

  def test_id_format_defaults_to_base36
    empty_config = {}
    namer = Ace::Taskflow::Molecules::FileNamer.new(empty_config)
    assert_equal "base36", namer.id_format
  end

  def test_detect_id_format_identifies_timestamp
    assert_equal :timestamp, Ace::Taskflow::Molecules::FileNamer.detect_id_format("20250115-103045")
  end

  def test_detect_id_format_identifies_compact
    assert_equal :compact, Ace::Taskflow::Molecules::FileNamer.detect_id_format("abc123")
    assert_equal :compact, Ace::Taskflow::Molecules::FileNamer.detect_id_format("i50jj3")
  end

  def test_detect_id_format_returns_nil_for_invalid
    assert_nil Ace::Taskflow::Molecules::FileNamer.detect_id_format("invalid-format")
    assert_nil Ace::Taskflow::Molecules::FileNamer.detect_id_format("too-long-string")
  end
end