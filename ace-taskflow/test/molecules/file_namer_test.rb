# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/molecules/file_namer"

class FileNamerTest < AceTestCase
  def setup
    @config = {
      "directory" => "/test/ideas",
      "file_naming" => {
        "timestamp_format" => "%Y%m%d-%H%M%S",
        "title_max_length" => 50
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

    Time.stub :now, Time.new(2025, 1, 15, 10, 30, 45) do
      path = namer.generate
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
end