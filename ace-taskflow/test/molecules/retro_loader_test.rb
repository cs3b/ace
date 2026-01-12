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
    # Date prefix + Base36 ID: 2025-01-15-abc123-dated-retro.md
    # With backward compatibility removed, "2025" is treated as part of the slug
    path = "/some/path/2025-01-15-dated-retro.md"
    title = @loader.send(:extract_title_from_filename, path)
    # Should return full filename converted to title (date prefixes no longer supported)
    assert_equal "2025 01 15 dated retro", title
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
    # With backward compatibility removed, date prefix is no longer stripped
    # The entire filename is converted to title
    assert_equal "2025 01 15 dated retro", title
  end

  def test_extract_title_with_complex_name
    path = "/some/path/def456-q4-2025-planning-review.md"
    title = @loader.send(:extract_title_from_filename, path)
    # Should strip Base36 ID and format title
    assert_equal "Q4 2025 planning review", title
  end

  # Test the private extract_date_from_filename method
  # Tests Base36 timestamp decoding

  def test_extract_date_from_base36_filename
    # Create a valid Base36 timestamp using ace-timestamp
    time = Time.utc(2025, 1, 15, 12, 0, 0)
    timestamp_id = Ace::Support::Timestamp.encode(time)
    path = "/some/path/#{timestamp_id}-retro.md"
    date = @loader.send(:extract_date_from_filename, path)
    assert_equal "2025-01-15", date
  end

  def test_extract_date_from_base36_with_slug
    time = Time.utc(2024, 12, 31, 23, 59, 59)
    timestamp_id = Ace::Support::Timestamp.encode(time)
    path = "/some/path/#{timestamp_id}-sprint-review.md"
    date = @loader.send(:extract_date_from_filename, path)
    assert_equal "2024-12-31", date
  end

  def test_extract_date_returns_nil_for_invalid_base36
    # Invalid Base36 string that doesn't decode to a timestamp
    path = "/some/path/invalid123-retro.md"
    date = @loader.send(:extract_date_from_filename, path)
    assert_nil date
  end

  def test_extract_date_returns_nil_for_no_date_prefix
    path = "/some/path/my-retro.md"
    date = @loader.send(:extract_date_from_filename, path)
    assert_nil date
  end

  def test_legacy_date_formats_not_supported
    # Legacy YYYY-MM-DD format should return nil
    path = "/some/path/2025-01-15-retro.md"
    date = @loader.send(:extract_date_from_filename, path)
    assert_nil date

    # Legacy YYYYMMDD format should return nil
    path = "/some/path/20250115-retro.md"
    date = @loader.send(:extract_date_from_filename, path)
    assert_nil date
  end
end
