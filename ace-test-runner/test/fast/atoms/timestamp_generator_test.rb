# frozen_string_literal: true

require "test_helper"

class TimestampGeneratorTest < Minitest::Test
  def setup
    @test_time = Time.utc(2025, 1, 6, 12, 30, 0)
  end

  # ======================
  # Base36 Compact ID Tests
  # ======================

  def test_generate_produces_6_char_id
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.generate(@test_time)

    assert_equal 6, result.length
    assert_match(/\A[0-9a-z]{6}\z/, result)
  end

  def test_generate_is_deterministic
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new

    result1 = generator.generate(@test_time)
    result2 = generator.generate(@test_time)

    assert_equal result1, result2
  end

  def test_directory_name_uses_base36
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.directory_name(@test_time)

    assert_equal 6, result.length
    assert_match(/\A[0-9a-z]{6}\z/, result)
  end

  def test_filename_timestamp_with_extension
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.filename_timestamp(@test_time, ".json")

    assert result.end_with?(".json")
    assert_equal 11, result.length  # 6 chars + ".json"
  end

  def test_filename_timestamp_without_extension
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.filename_timestamp(@test_time)

    assert_equal 6, result.length
    assert_match(/\A[0-9a-z]{6}\z/, result)
  end

  # ======================
  # Format Detection Tests
  # ======================

  def test_detect_format_2sec_id
    result = Ace::TestRunner::Atoms::TimestampGenerator.detect_format("i50jj3")
    assert_equal :"2sec", result
  end

  def test_detect_format_timestamp
    # Still able to detect legacy format for reference
    result = Ace::TestRunner::Atoms::TimestampGenerator.detect_format("20250106-123000")
    assert_equal :timestamp, result
  end

  def test_detect_format_invalid
    result = Ace::TestRunner::Atoms::TimestampGenerator.detect_format("invalid-format")
    assert_nil result
  end

  # ======================
  # Parse Tests
  # ======================

  def test_parse_compact_id
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    compact_id = generator.generate(@test_time)
    parsed = generator.parse(compact_id)

    # Allow 1s tolerance (Base36 encoding has 1-second precision)
    assert_in_delta @test_time.to_i, parsed.to_i, 1
  end

  def test_parse_invalid_returns_nil
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.parse("not-a-valid-id")

    assert_nil result
  end

  def test_parse_nil_returns_nil
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.parse(nil)

    assert_nil result
  end

  def test_parse_empty_string_returns_nil
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.parse("")

    assert_nil result
  end

  # ======================
  # ISO Timestamp Tests
  # ======================

  def test_iso_timestamp
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.iso_timestamp(@test_time)

    assert_equal "2025-01-06T12:30:00", result
  end

  def test_iso_timestamp_defaults_to_now
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.iso_timestamp

    # Should be a valid ISO timestamp format
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result)
  end

  # ======================
  # Elapsed Time Tests
  # ======================

  def test_elapsed_time_milliseconds
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    start_time = Time.now
    end_time = start_time + 0.5

    result = generator.elapsed_time(start_time, end_time)
    assert_match(/\d+\.?\d*ms/, result)
  end

  def test_elapsed_time_seconds
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    start_time = Time.now
    end_time = start_time + 30

    result = generator.elapsed_time(start_time, end_time)
    assert_match(/\d+\.?\d*s/, result)
  end

  def test_elapsed_time_minutes
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    start_time = Time.now
    end_time = start_time + 125  # 2m 5s

    result = generator.elapsed_time(start_time, end_time)
    assert_match(/\d+m \d+s/, result)
  end

  def test_elapsed_time_defaults_to_now
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    start_time = Time.now - 5

    result = generator.elapsed_time(start_time)
    assert_match(/\d+\.?\d*s/, result)
  end

  # ======================
  # Integration Tests
  # ======================

  def test_generate_and_parse_roundtrip
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new

    original_time = @test_time
    compact_id = generator.generate(original_time)
    parsed_time = generator.parse(compact_id)

    # Allow 1s tolerance for encoding precision
    assert_in_delta original_time.to_i, parsed_time.to_i, 1
  end
end
