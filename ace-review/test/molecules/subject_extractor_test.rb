# frozen_string_literal: true

require "test_helper"

class SubjectExtractorTest < AceReviewTest
  def setup
    super
    @extractor = Ace::Review::Molecules::SubjectExtractor.new
  end

  def test_extracts_from_simple_string
    # Mock response for simple string
    result = @extractor.extract("test-string")
    assert_kind_of String, result
  end

  def test_extracts_from_hash_with_new_diff_format
    config = {
      "diff" => {
        "ranges" => ["origin/main...HEAD"]
      }
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_extracts_from_hash_with_old_diff_string_format
    config = {
      "diff" => "origin/main...HEAD"
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_validates_diff_hash_requires_ranges_or_since
    config = {
      "diff" => {
        "paths" => ["lib/**/*.rb"]  # Missing ranges or since
      }
    }

    error = assert_raises(ArgumentError) do
      @extractor.extract(config)
    end

    assert_match(/must specify 'ranges' or 'since'/, error.message)
  end

  def test_validates_ranges_must_be_array
    config = {
      "diff" => {
        "ranges" => "not-an-array"
      }
    }

    error = assert_raises(ArgumentError) do
      @extractor.extract(config)
    end

    assert_match(/must be an array/, error.message)
    assert_match(/got String/, error.message)
  end

  def test_accepts_hash_with_ranges
    config = {
      "diff" => {
        "ranges" => ["HEAD~5..HEAD", "origin/main...HEAD"]
      }
    }

    # Should not raise an error
    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_accepts_hash_with_since
    config = {
      "diff" => {
        "since" => "7d"
      }
    }

    # Should not raise an error (since is valid alternative to ranges)
    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_accepts_hash_with_both_ranges_and_since
    config = {
      "diff" => {
        "ranges" => ["HEAD~5..HEAD"],
        "since" => "7d"
      }
    }

    # Should not raise an error (having both is fine)
    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_extracts_from_hash_with_files
    config = {
      "files" => ["lib/**/*.rb"]
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_extracts_from_hash_with_commands
    config = {
      "commands" => ["git diff HEAD~1..HEAD"]
    }

    result = @extractor.extract(config)
    assert_kind_of String, result
  end

  def test_returns_empty_string_for_nil
    result = @extractor.extract(nil)
    assert_equal "", result
  end

  def test_returns_empty_string_for_invalid_type
    result = @extractor.extract(123)
    assert_equal "", result
  end
end
