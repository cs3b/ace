# frozen_string_literal: true

require "test_helper"

class TimestampGeneratorTest < Minitest::Test
  def setup
    @test_time = Time.utc(2025, 1, 6, 12, 30, 0)
  end

  # ======================
  # Base36 Format Tests
  # ======================

  def test_default_format_is_base36
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    assert_equal :base36, generator.id_format
  end

  def test_generate_base36_produces_6_char_id
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new(id_format: :base36)
    result = generator.generate(@test_time)

    assert_equal 6, result.length
    assert_match(/\A[0-9a-z]{6}\z/, result)
  end

  def test_generate_base36_is_deterministic
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new(id_format: :base36)

    result1 = generator.generate(@test_time)
    result2 = generator.generate(@test_time)

    assert_equal result1, result2
  end

  def test_directory_name_uses_base36_by_default
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.directory_name(@test_time)

    assert_equal 6, result.length
    assert_match(/\A[0-9a-z]{6}\z/, result)
  end

  def test_filename_timestamp_with_extension_base36
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new(id_format: :base36)
    result = generator.filename_timestamp(@test_time, ".json")

    assert result.end_with?(".json")
    assert_equal 11, result.length  # 6 chars + ".json"
  end

  # ======================
  # Timestamp Format Tests
  # ======================

  def test_explicit_timestamp_format
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new(id_format: :timestamp)
    result = generator.generate(@test_time)

    assert_equal "20250106-123000", result
  end

  def test_directory_name_with_timestamp_format
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new(id_format: :timestamp)
    result = generator.directory_name(@test_time)

    assert_equal "20250106-123000", result
  end

  def test_filename_timestamp_with_extension_timestamp
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new(id_format: :timestamp)
    result = generator.filename_timestamp(@test_time, ".json")

    assert_equal "20250106-123000.json", result
  end

  # ======================
  # Format Detection Tests
  # ======================

  def test_detect_format_compact_id
    result = Ace::TestRunner::Atoms::TimestampGenerator.detect_format("i50jj3")
    assert_equal :compact, result
  end

  def test_detect_format_timestamp
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

    # Allow ~2s tolerance due to Base36 encoding precision
    assert_in_delta @test_time.to_i, parsed.to_i, 2
  end

  def test_parse_timestamp_format
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    parsed = generator.parse("20250106-123000")

    assert_equal @test_time.year, parsed.year
    assert_equal @test_time.month, parsed.month
    assert_equal @test_time.day, parsed.day
    assert_equal @test_time.hour, parsed.hour
    assert_equal @test_time.min, parsed.min
    assert_equal @test_time.sec, parsed.sec
  end

  def test_parse_invalid_returns_nil
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new
    result = generator.parse("not-a-valid-id")

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

  # ======================
  # Validation Tests
  # ======================

  def test_invalid_id_format_raises_error
    assert_raises(ArgumentError) do
      Ace::TestRunner::Atoms::TimestampGenerator.new(id_format: :invalid)
    end
  end

  def test_error_message_includes_valid_options
    error = assert_raises(ArgumentError) do
      Ace::TestRunner::Atoms::TimestampGenerator.new(id_format: :invalid)
    end

    assert_includes error.message, "base36"
    assert_includes error.message, "timestamp"
  end

  # ======================
  # Backward Compatibility
  # ======================

  def test_legacy_format_parameter_works_with_timestamp
    generator = Ace::TestRunner::Atoms::TimestampGenerator.new(
      id_format: :timestamp,
      format: "%Y%m%d"
    )
    result = generator.generate(@test_time)

    assert_equal "20250106", result
  end
end
