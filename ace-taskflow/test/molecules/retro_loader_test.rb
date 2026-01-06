# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/retro_loader"

class RetroLoaderTest < AceTaskflowTestCase
  def setup
    super
    @root_path = File.expand_path("../fixtures", __dir__)
    @loader = Ace::Taskflow::Molecules::RetroLoader.new(@root_path)
  end

  # Test the private extract_title_from_filename method directly
  # All tests use Base36 compact ID format (6 alphanumeric characters)

  def test_extract_title_from_base36_filename
    path = "/some/path/abc123-retro.md"
    title = @loader.send(:extract_title_from_filename, path)
    # Note: method uses .capitalize which capitalizes first word
    assert_equal "Retro", title
  end

  def test_extract_title_from_base36_multi_word
    path = "/some/path/xyz789-sprint-review.md"
    title = @loader.send(:extract_title_from_filename, path)
    assert_equal "Sprint review", title
  end

  def test_extract_title_with_date_prefix_and_base36_id
    # Date prefix + Base36 ID: 2025-01-15-abc123-retro.md
    path = "/some/path/2025-01-15-abc123-dated-retro.md"
    title = @loader.send(:extract_title_from_filename, path)
    # Should strip both date prefix and Base36 ID
    assert_equal "Dated retro", title
  end

  def test_extract_title_with_no_id_prefix
    path = "/some/path/my-retro-note.md"
    title = @loader.send(:extract_title_from_filename, path)
    # Files without ID prefix should still work
    # "my" is 2 chars, not 6, so it won't be treated as Base36 ID
    assert_equal "My retro note", title
  end

  def test_extract_title_with_date_prefix_only
    path = "/some/path/2025-01-15-dated-retro.md"
    title = @loader.send(:extract_title_from_filename, path)
    # Should strip date prefix only
    assert_equal "Dated retro", title
  end

  def test_extract_title_with_complex_name
    path = "/some/path/def456-q4-2025-planning-review.md"
    title = @loader.send(:extract_title_from_filename, path)
    # Should strip Base36 ID and format title
    assert_equal "Q4 2025 planning review", title
  end
end
