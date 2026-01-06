# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Timestamp
    module Atoms
      class CompactIdEncoderTest < Minitest::Test
        def setup
          @encoder = CompactIdEncoder
        end

        # ===================
        # Encode Tests
        # ===================

        def test_encode_returns_6_character_string
          time = Time.utc(2025, 1, 6, 12, 30, 0)
          result = @encoder.encode(time)

          assert_equal 6, result.length
          assert_match(/\A[0-9a-z]{6}\z/, result)
        end

        def test_encode_year_zero_boundary
          # Year 2000 (year_zero default) should produce IDs starting with "0"
          time = Time.utc(2000, 1, 1, 0, 0, 0)
          result = @encoder.encode(time)

          assert_equal "000000", result
        end

        def test_encode_year_zero_custom
          # With year_zero=2025, a 2025 date should produce IDs starting with "0"
          time = Time.utc(2025, 1, 1, 0, 0, 0)
          result = @encoder.encode(time, year_zero: 2025)

          assert_equal "000000", result
        end

        def test_encode_preserves_month_progression
          # Different months should produce different IDs
          jan = @encoder.encode(Time.utc(2000, 1, 15, 12, 0, 0))
          feb = @encoder.encode(Time.utc(2000, 2, 15, 12, 0, 0))
          mar = @encoder.encode(Time.utc(2000, 3, 15, 12, 0, 0))

          # IDs should be different and sortable
          assert_operator jan, :<, feb
          assert_operator feb, :<, mar
        end

        def test_encode_preserves_day_progression
          day1 = @encoder.encode(Time.utc(2000, 1, 1, 12, 0, 0))
          day15 = @encoder.encode(Time.utc(2000, 1, 15, 12, 0, 0))
          day31 = @encoder.encode(Time.utc(2000, 1, 31, 12, 0, 0))

          assert_operator day1, :<, day15
          assert_operator day15, :<, day31
        end

        def test_encode_preserves_time_progression
          morning = @encoder.encode(Time.utc(2000, 1, 1, 8, 0, 0))
          noon = @encoder.encode(Time.utc(2000, 1, 1, 12, 0, 0))
          evening = @encoder.encode(Time.utc(2000, 1, 1, 20, 0, 0))

          assert_operator morning, :<, noon
          assert_operator noon, :<, evening
        end

        def test_encode_raises_for_time_before_year_zero
          time = Time.utc(1999, 12, 31)

          assert_raises(ArgumentError) do
            @encoder.encode(time)
          end
        end

        def test_encode_raises_for_time_after_range
          # 108 years after 2000 = 2108
          time = Time.utc(2108, 1, 1)

          assert_raises(ArgumentError) do
            @encoder.encode(time)
          end
        end

        def test_encode_handles_end_of_range
          # Last valid time in range (107 years after year_zero + 11 months)
          time = Time.utc(2107, 12, 31, 23, 59, 59)
          result = @encoder.encode(time)

          assert_equal 6, result.length
        end

        # ===================
        # Decode Tests
        # ===================

        def test_decode_returns_time_object
          result = @encoder.decode("000000")

          assert_instance_of Time, result
          assert result.utc?
        end

        def test_decode_year_zero_boundary
          result = @encoder.decode("000000")

          assert_equal 2000, result.year
          assert_equal 1, result.month
          assert_equal 1, result.day
          assert_equal 0, result.hour
          assert_equal 0, result.min
        end

        def test_decode_custom_year_zero
          result = @encoder.decode("000000", year_zero: 2025)

          assert_equal 2025, result.year
          assert_equal 1, result.month
          assert_equal 1, result.day
        end

        def test_decode_case_insensitive
          upper = @encoder.decode("ABC123")
          lower = @encoder.decode("abc123")

          assert_equal upper, lower
        end

        def test_decode_raises_for_invalid_length
          assert_raises(ArgumentError) do
            @encoder.decode("abc")
          end

          assert_raises(ArgumentError) do
            @encoder.decode("abcdefgh")
          end
        end

        def test_decode_raises_for_invalid_characters
          assert_raises(ArgumentError) do
            @encoder.decode("abc!23")
          end
        end

        def test_decode_raises_for_non_string
          assert_raises(ArgumentError) do
            @encoder.decode(123456)
          end
        end

        def test_decode_raises_for_out_of_range_components
          # Day > 30 (max calendar day is 31, index 30)
          error = assert_raises(ArgumentError) do
            @encoder.decode("00v000")  # day = 31
          end
          assert_match(/Day value 31 exceeds maximum/, error.message)

          # Full max values (zzzzzz)
          error = assert_raises(ArgumentError) do
            @encoder.decode("zzzzzz")  # day = 35
          end
          assert_match(/Day value 35 exceeds maximum/, error.message)
        end

        # ===================
        # Round-trip Tests
        # ===================

        def test_roundtrip_preserves_approximate_time
          original = Time.utc(2025, 6, 15, 14, 30, 45)
          encoded = @encoder.encode(original)
          decoded = @encoder.decode(encoded)

          # Should be within precision window (~1.85 seconds)
          assert_in_delta original.to_i, decoded.to_i, 3
        end

        def test_roundtrip_various_dates
          dates = [
            Time.utc(2000, 1, 1, 0, 0, 0),
            Time.utc(2025, 7, 4, 12, 0, 0),
            Time.utc(2050, 12, 31, 23, 59, 59),
            Time.utc(2100, 6, 15, 8, 30, 0)
          ]

          dates.each do |original|
            encoded = @encoder.encode(original)
            decoded = @encoder.decode(encoded)

            assert_equal original.year, decoded.year, "Year mismatch for #{original}"
            assert_equal original.month, decoded.month, "Month mismatch for #{original}"
            assert_equal original.day, decoded.day, "Day mismatch for #{original}"
            # Time should be within a few seconds
            assert_in_delta original.to_i, decoded.to_i, 3, "Time mismatch for #{original}"
          end
        end

        def test_roundtrip_with_custom_year_zero
          original = Time.utc(2030, 5, 20, 10, 15, 30)
          year_zero = 2025

          encoded = @encoder.encode(original, year_zero: year_zero)
          decoded = @encoder.decode(encoded, year_zero: year_zero)

          assert_equal original.year, decoded.year
          assert_equal original.month, decoded.month
          assert_equal original.day, decoded.day
        end

        # ===================
        # Valid? Tests
        # ===================

        def test_valid_returns_true_for_valid_id
          assert @encoder.valid?("abc123")
          assert @encoder.valid?("000000")
          assert @encoder.valid?("ABC123")  # Case insensitive
          # Note: "zzzzzz" has valid format but invalid semantics (day=35 > 30)
          # so it correctly returns false from valid?
        end

        def test_valid_checks_semantic_ranges
          # Format-valid but semantically invalid (day > 30)
          refute @encoder.valid?("00v000")  # day = 31
          refute @encoder.valid?("zzzzzz")  # day = 35, precision = 1295

          # Format-valid and semantically valid (at boundaries)
          assert @encoder.valid?("zzu000")  # months_offset = 1295 (max), day = 30 (max valid)
          assert @encoder.valid?("00uzz0")  # day = 30 (max valid), block = 35, precision = 0
        end

        def test_valid_returns_false_for_invalid_length
          refute @encoder.valid?("abc")
          refute @encoder.valid?("abcdefgh")
          refute @encoder.valid?("")
        end

        def test_valid_returns_false_for_invalid_characters
          refute @encoder.valid?("abc!23")
          refute @encoder.valid?("abc 23")
          refute @encoder.valid?("abc-23")
        end

        def test_valid_returns_false_for_non_string
          refute @encoder.valid?(123456)
          refute @encoder.valid?(nil)
          refute @encoder.valid?([])
        end

        # ===================
        # Sortability Tests
        # ===================

        def test_ids_are_chronologically_sortable
          times = [
            Time.utc(2000, 1, 1),
            Time.utc(2010, 6, 15),
            Time.utc(2020, 3, 20),
            Time.utc(2025, 12, 31),
            Time.utc(2050, 7, 4)
          ]

          ids = times.map { |t| @encoder.encode(t) }
          sorted_ids = ids.sort

          assert_equal ids, sorted_ids, "IDs should be sortable chronologically"
        end

        def test_ids_sortable_within_same_day
          times = (0..23).map { |hour| Time.utc(2025, 1, 1, hour, 0, 0) }
          ids = times.map { |t| @encoder.encode(t) }

          assert_equal ids, ids.sort, "IDs should be sortable within same day"
        end

        # ===================
        # Edge Cases
        # ===================

        def test_encode_handles_leap_year
          time = Time.utc(2024, 2, 29, 12, 0, 0)
          result = @encoder.encode(time)

          assert_equal 6, result.length
        end

        def test_encode_handles_end_of_month_days
          # Day 31
          time = Time.utc(2025, 1, 31, 12, 0, 0)
          result = @encoder.encode(time)
          decoded = @encoder.decode(result)

          assert_equal 31, decoded.day
        end

        def test_encode_handles_midnight
          time = Time.utc(2025, 1, 1, 0, 0, 0)
          result = @encoder.encode(time)
          decoded = @encoder.decode(result)

          assert_equal 0, decoded.hour
          assert_equal 0, decoded.min
        end

        def test_encode_handles_end_of_day
          time = Time.utc(2025, 1, 1, 23, 59, 59)
          result = @encoder.encode(time)
          decoded = @encoder.decode(result)

          assert_equal 23, decoded.hour
          # Minutes/seconds may vary due to precision
        end
      end
    end
  end
end
