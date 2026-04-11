# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module B36ts
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

        # ===================
        # Month Format Tests (2 chars)
        # ===================

        def test_encode_month_returns_2_characters
          time = Time.utc(2025, 6, 15, 12, 30, 0)
          result = @encoder.encode_month(time)

          assert_equal 2, result.length
          assert_match(/\A[0-9a-z]{2}\z/, result)
        end

        def test_encode_month_year_boundary
          time = Time.utc(2000, 1, 1, 0, 0, 0)
          result = @encoder.encode_month(time)

          assert_equal "00", result
        end

        def test_decode_month_returns_first_day_of_month
          result = @encoder.decode_month("00")

          assert_equal 2000, result.year
          assert_equal 1, result.month
          assert_equal 1, result.day
          assert_equal 0, result.hour
          assert_equal 0, result.min
        end

        def test_month_roundtrip_preserves_year_and_month
          original = Time.utc(2025, 6, 15, 14, 30, 45)
          encoded = @encoder.encode_month(original)
          decoded = @encoder.decode_month(encoded)

          assert_equal original.year, decoded.year
          assert_equal original.month, decoded.month
          assert_equal 1, decoded.day  # Always first day
          assert_equal 0, decoded.hour
        end

        # ===================
        # Week Format Tests (3 chars)
        # ===================

        def test_encode_week_returns_3_characters
          time = Time.utc(2025, 6, 15, 12, 30, 0)
          result = @encoder.encode_week(time)

          assert_equal 3, result.length
          assert_match(/\A[0-9a-z]{3}\z/, result)
        end

        def test_encode_week_uses_iso_thursday_rule
          # Jan 6, 2025 is Monday → Thursday = Jan 9 → January week 2
          time = Time.utc(2025, 1, 6, 12, 0, 0)
          result = @encoder.encode_week(time)

          # Third char should be in 'v'-'z' range (31-35)
          third_char_value = CompactIdEncoder::DEFAULT_ALPHABET.index(result[2].downcase)
          assert_operator third_char_value, :>=, 31
          assert_operator third_char_value, :<=, 35
        end

        def test_decode_week_returns_thursday
          # "00v" = Jan 2000 week 1. Jan 1, 2000 is Saturday.
          # First Thursday of Jan 2000 is Jan 6.
          result = @encoder.decode_week("00v")

          assert_equal 2000, result.year
          assert_equal 1, result.month
          assert_equal 6, result.day  # Thursday Jan 6, 2000
          assert_equal 4, Date.new(result.year, result.month, result.day).wday  # Thursday
        end

        def test_week_format_third_char_in_range_31_to_35
          time = Time.utc(2025, 1, 1, 12, 0, 0)
          result = @encoder.encode_week(time)

          third_char_value = CompactIdEncoder::DEFAULT_ALPHABET.index(result[2].downcase)
          assert_operator third_char_value, :>=, 31
          assert_operator third_char_value, :<=, 35
        end

        def test_whole_month_week_numbers_monotonic
          # Test that week numbers only increase or stay same across January 2025
          previous_encoded = nil
          (1..31).each do |day|
            test_time = Time.utc(2025, 1, day, 12, 0, 0)
            encoded = @encoder.encode_week(test_time)

            # Encoded week IDs should be monotonically non-decreasing
            if previous_encoded
              assert_operator encoded, :>=, previous_encoded,
                "Week encoding decreased on January #{day}"
            end

            # Third char (week value) should always be in 31-35 range
            third_char_value = CompactIdEncoder::DEFAULT_ALPHABET.index(encoded[2].downcase)
            assert_operator third_char_value, :>=, 31
            assert_operator third_char_value, :<=, 35

            previous_encoded = encoded
          end
        end

        def test_decode_week_clamps_week_5_for_4_thursday_month
          # February 2025 has 4 Thursdays (6, 13, 20, 27).
          # Construct a week-5 ID for Feb 2025 manually.
          # months_offset for Feb 2025 = (2025-2000)*12 + 1 = 301
          feb_month_encoded = @encoder.encode_month(Time.utc(2025, 2, 1))
          week_5_id = feb_month_encoded + "z"  # 'z' = 35 = week 5

          # Should decode without error, clamped to last Thursday (Feb 27)
          decoded = @encoder.decode_week(week_5_id)
          assert_equal 2025, decoded.year
          assert_equal 2, decoded.month
          assert_equal 27, decoded.day  # Last Thursday of Feb 2025
        end

        def test_boundary_date_uses_iso_month
          # Feb 1, 2025 is Saturday → Thursday = Jan 30, 2025
          # Should encode as January week 5
          time = Time.utc(2025, 2, 1, 12, 0, 0)
          encoded = @encoder.encode_week(time)

          # Decode should return a Thursday in January
          decoded = @encoder.decode_week(encoded)
          assert_equal 2025, decoded.year
          assert_equal 1, decoded.month  # January, not February
          assert_equal 30, decoded.day   # Thursday Jan 30
        end

        def test_year_boundary_crossing
          # Dec 31, 2025 is Wednesday → Thursday = Jan 1, 2026
          # Should encode as January 2026 week 1
          time = Time.utc(2025, 12, 31, 12, 0, 0)
          encoded = @encoder.encode_week(time)

          decoded = @encoder.decode_week(encoded)
          assert_equal 2026, decoded.year
          assert_equal 1, decoded.month
          assert_equal 1, decoded.day  # Thursday Jan 1, 2026
        end

        def test_decoded_week_is_always_thursday
          # Check several dates across different months
          dates = [
            Time.utc(2025, 1, 1),
            Time.utc(2025, 3, 15),
            Time.utc(2025, 6, 30),
            Time.utc(2025, 12, 25),
            Time.utc(2028, 2, 29)  # Leap year
          ]

          dates.each do |time|
            encoded = @encoder.encode_week(time)
            decoded = @encoder.decode_week(encoded)
            wday = Date.new(decoded.year, decoded.month, decoded.day).wday
            assert_equal 4, wday, "Decoded #{decoded} from #{time} should be Thursday (wday=4), got #{wday}"
          end
        end

        def test_roundtrip_boundary_encode_decode
          # Feb 1, 2025 (Sat) → encodes as Jan week 5 → decodes to Thu Jan 30
          time = Time.utc(2025, 2, 1)
          encoded = @encoder.encode_week(time)
          decoded = @encoder.decode_week(encoded)

          # Verify the decoded Thursday is in the same ISO week as the input
          input_date = Date.new(time.year, time.month, time.day)
          decoded_date = Date.new(decoded.year, decoded.month, decoded.day)
          input_days_since_monday = (input_date.wday - 1) % 7
          decoded_days_since_monday = (decoded_date.wday - 1) % 7
          input_monday = input_date - input_days_since_monday
          decoded_monday = decoded_date - decoded_days_since_monday
          assert_equal input_monday, decoded_monday, "Input and decoded should be in the same ISO week"
        end

        def test_month_with_5_iso_weeks
          # January 2025 has 5 Thursdays: Jan 2, 9, 16, 23, 30
          time_week5 = Time.utc(2025, 1, 30, 12, 0, 0)  # Thursday Jan 30
          encoded = @encoder.encode_week(time_week5)
          third_char_value = CompactIdEncoder::DEFAULT_ALPHABET.index(encoded[2].downcase)
          assert_equal 35, third_char_value, "Jan 30 2025 should be week 5 (value 35)"
        end

        def test_month_with_4_iso_weeks
          # February 2025 has 4 Thursdays: Feb 6, 13, 20, 27
          time_week4 = Time.utc(2025, 2, 27, 12, 0, 0)  # Thursday Feb 27
          encoded = @encoder.encode_week(time_week4)
          third_char_value = CompactIdEncoder::DEFAULT_ALPHABET.index(encoded[2].downcase)
          assert_equal 34, third_char_value, "Feb 27 2025 should be week 4 (value 34)"
        end

        def test_split_encoder_uses_iso_weeks
          # Split encoder uses ISO Thursday-based week attribution (same as encode_week)
          # Feb 1 2025 is Saturday → Thursday is Jan 30 → ISO week is January week 5
          time = Time.utc(2025, 2, 1, 12, 0, 0)
          result = @encoder.encode_split(time, levels: [:month, :week])

          week_token = result[:week]
          week_value = CompactIdEncoder::DEFAULT_ALPHABET.index(week_token.downcase)
          # ISO week 5 → encoded as 5+30=35 (base36 'z')
          assert_equal 35, week_value, "Split should use ISO Thursday week (Feb 1 Sat → Jan week 5 → value 35)"

          # Month should also reflect ISO week's month (January, not February)
          jan_token = @encoder.encode_with_format(Time.utc(2025, 1, 1), format: :month)
          assert_equal jan_token, result[:month], "Split month for Feb 1 (Sat) should be January (ISO)"
        end

        def test_year_zero_boundary_with_iso_thursday_before_year_zero
          # Jan 1, 2000 is Saturday → Thursday = Dec 30, 1999
          # With default year_zero=2000, December 1999 is before range → ArgumentError
          time = Time.utc(2000, 1, 1, 12, 0, 0)

          assert_raises(ArgumentError) do
            @encoder.encode_week(time)
          end
        end

        def test_leap_year_feb_29_iso_week
          # Feb 29, 2028 is Tuesday → Thursday = Mar 2, 2028
          # Should encode as March 2028 week 1
          time = Time.utc(2028, 2, 29, 12, 0, 0)
          encoded = @encoder.encode_week(time)
          decoded = @encoder.decode_week(encoded)

          assert_equal 2028, decoded.year
          assert_equal 3, decoded.month  # March
          assert_equal 2, decoded.day    # Thursday Mar 2
        end

        # ===================
        # Day Format Tests (3 chars)
        # ===================

        def test_encode_day_returns_3_characters
          time = Time.utc(2025, 6, 15, 12, 30, 0)
          result = @encoder.encode_day(time)

          assert_equal 3, result.length
          assert_match(/\A[0-9a-z]{3}\z/, result)
        end

        def test_encode_day_preserves_day_of_month
          # Day 1 (value 0 = '0')
          time1 = Time.utc(2025, 1, 1, 12, 0, 0)
          result1 = @encoder.encode_day(time1)
          assert_equal "0", result1[2]

          # Day 31 (value 30 = 'u')
          time31 = Time.utc(2025, 1, 31, 12, 0, 0)
          result31 = @encoder.encode_day(time31)
          assert_equal "u", result31[2]
        end

        def test_decode_day_returns_midnight
          result = @encoder.decode_day("000")  # month 00, day 0 (day 1)

          assert_equal 2000, result.year
          assert_equal 1, result.month
          assert_equal 1, result.day
          assert_equal 0, result.hour
          assert_equal 0, result.min
        end

        def test_day_format_third_char_in_range_0_to_30
          time = Time.utc(2025, 1, 15, 12, 0, 0)
          result = @encoder.encode_day(time)

          third_char_value = CompactIdEncoder::DEFAULT_ALPHABET.index(result[2].downcase)
          assert_operator third_char_value, :<=, 30
        end

        # ===================
        # 40min Format Tests (4 chars)
        # ===================

        def test_encode_40min_returns_4_characters
          time = Time.utc(2025, 6, 15, 12, 30, 0)
          result = @encoder.encode_40min(time)

          assert_equal 4, result.length
          assert_match(/\A[0-9a-z]{4}\z/, result)
        end

        def test_encode_40min_uses_40_minute_blocks
          # 12:30 is 750 minutes into the day
          # 750 / 40 = 18.75, so block 18 (720-759 minutes = 12:00-12:39)
          time = Time.utc(2025, 1, 1, 12, 30, 0)
          result = @encoder.encode_40min(time)
          decoded = @encoder.decode_40min(result)

          # Should decode to the start of block 18 (12:00)
          assert_equal 12, decoded.hour
          assert_equal 0, decoded.min
        end

        def test_40min_format_encodes_blocks_not_hours
          # Regression test: Previously the 4-char format encoded hours (0-23),
          # now it correctly encodes 40-minute blocks (0-35).
          # 12:30 = 750 minutes into day, 750/40 = 18 (not hour 12)
          time = Time.utc(2025, 1, 1, 12, 30, 0)
          result = @encoder.encode_40min(time)

          # Extract the 4th character (block value)
          block_char = result[3]
          block_value = CompactIdEncoder::DEFAULT_ALPHABET.index(block_char.downcase)

          assert_equal 18, block_value, "12:30 should encode to block 18 (750/40=18), not hour 12"
        end

        def test_encode_40min_midnight_is_block_0
          time = Time.utc(2025, 1, 1, 0, 0, 0)
          result = @encoder.encode_40min(time)
          decoded = @encoder.decode_40min(result)

          assert_equal 0, decoded.hour
          assert_equal 0, decoded.min
        end

        def test_encode_40min_last_block_is_23_20_to_23_59
          # Block 35: 35 * 40 = 1400 minutes = 23:20
          time = Time.utc(2025, 1, 1, 23, 45, 0)
          result = @encoder.encode_40min(time)
          decoded = @encoder.decode_40min(result)

          assert_equal 23, decoded.hour
          assert_equal 20, decoded.min  # Start of block 35
        end

        def test_40min_roundtrip_preserves_date_and_block
          original = Time.utc(2025, 6, 15, 14, 30, 45)
          encoded = @encoder.encode_40min(original)
          decoded = @encoder.decode_40min(encoded)

          assert_equal original.year, decoded.year
          assert_equal original.month, decoded.month
          assert_equal original.day, decoded.day
          # 14:30 falls in block 21 (14:00-14:39)
          assert_equal 14, decoded.hour
          assert_equal 0, decoded.min
          assert_equal 0, decoded.sec
        end

        # ===================
        # 50ms Format Tests (7 chars, ~50ms)
        # ===================

        def test_encode_50ms_returns_7_characters
          time = Time.utc(2025, 6, 15, 12, 30, 0)
          result = @encoder.encode_50ms(time)

          assert_equal 7, result.length
          assert_match(/\A[0-9a-z]{7}\z/, result)
        end

        def test_encode_50ms_preserves_microsecond_precision
          time = Time.utc(2025, 1, 1, 12, 30, 45, 123456)
          result = @encoder.encode_50ms(time)
          decoded = @encoder.decode_50ms(result)

          assert_equal 12, decoded.hour
          assert_equal 30, decoded.min
          # Usec should be approximately preserved (within ~50ms)
          assert_in_delta 45, decoded.sec, 1
          assert_in_delta 123456, decoded.usec, 50_000
        end

        def test_decode_50ms_returns_approximate_time
          result = @encoder.decode_50ms("0000000")

          assert_equal 2000, result.year
          assert_equal 1, result.month
          assert_equal 1, result.day
        end

        def test_50ms_roundtrip_within_50ms_tolerance
          original = Time.utc(2025, 6, 15, 14, 30, 45, 123456)
          encoded = @encoder.encode_50ms(original)
          decoded = @encoder.decode_50ms(encoded)

          # Check that the times are within ~50ms of each other
          time_diff_us = ((original - decoded).abs * 1_000_000).to_i
          assert_operator time_diff_us, :<=, 50_000, "Times should be within 50ms, but were #{time_diff_us}μs apart"
        end

        # ===================
        # ms Format Tests (8 chars, ~1.4ms)
        # ===================

        def test_encode_ms_returns_8_characters
          time = Time.utc(2025, 6, 15, 12, 30, 0)
          result = @encoder.encode_ms(time)

          assert_equal 8, result.length
          assert_match(/\A[0-9a-z]{8}\z/, result)
        end

        def test_encode_ms_preserves_microsecond_precision
          time = Time.utc(2025, 1, 1, 12, 30, 45, 123456)
          result = @encoder.encode_ms(time)
          decoded = @encoder.decode_ms(result)

          assert_equal 12, decoded.hour
          assert_equal 30, decoded.min
          # Usec should be approximately preserved (within ~2ms)
          assert_in_delta 45, decoded.sec, 1
          assert_in_delta 123456, decoded.usec, 2_000
        end

        def test_decode_ms_returns_approximate_time
          result = @encoder.decode_ms("00000000")

          assert_equal 2000, result.year
          assert_equal 1, result.month
          assert_equal 1, result.day
        end

        def test_ms_roundtrip_within_2ms_tolerance
          original = Time.utc(2025, 6, 15, 14, 30, 45, 123456)
          encoded = @encoder.encode_ms(original)
          decoded = @encoder.decode_ms(encoded)

          # Check that the times are within ~2ms of each other
          time_diff_us = ((original - decoded).abs * 1_000_000).to_i
          assert_operator time_diff_us, :<=, 2_000, "Times should be within 2ms, but were #{time_diff_us}μs apart"
        end

        # ===================
        # Format Detection Tests
        # ===================

        def test_detect_format_by_length
          assert_equal :month, @encoder.detect_format("00")
          assert_equal :"40min", @encoder.detect_format("0000")
          assert_equal :"2sec", @encoder.detect_format("000000")
          assert_equal :"50ms", @encoder.detect_format("0000000")
          assert_equal :ms, @encoder.detect_format("00000000")
        end

        def test_detect_format_disambiguates_day_and_week
          # 3-char IDs: need to distinguish by third character value
          # Day format: third char 0-30
          day_id = @encoder.encode_day(Time.utc(2025, 1, 15))
          assert_equal :day, @encoder.detect_format(day_id)

          # Week format: third char 31-35
          week_id = @encoder.encode_week(Time.utc(2025, 1, 15))
          assert_equal :week, @encoder.detect_format(week_id)
        end

        def test_detect_format_returns_nil_for_invalid_length
          assert_nil @encoder.detect_format("")
          assert_nil @encoder.detect_format("0")
          assert_nil @encoder.detect_format("00000")   # 5 chars
          assert_nil @encoder.detect_format("0" * 9)  # 9+ chars
        end

        def test_decode_auto_auto_detects_and_decodes
          # Test auto-detection for all formats
          month_time = Time.utc(2025, 6, 15)
          month_id = @encoder.encode_with_format(month_time, format: :month)
          decoded_month = @encoder.decode_auto(month_id)
          assert_equal month_time.year, decoded_month.year
          assert_equal month_time.month, decoded_month.month

          day_time = Time.utc(2025, 6, 15)
          day_id = @encoder.encode_with_format(day_time, format: :day)
          decoded_day = @encoder.decode_auto(day_id)
          assert_equal day_time.year, decoded_day.year
          assert_equal day_time.month, decoded_day.month
          assert_equal day_time.day, decoded_day.day

          min40_time = Time.utc(2025, 6, 15, 14)
          min40_id = @encoder.encode_with_format(min40_time, format: :"40min")
          decoded_min40 = @encoder.decode_auto(min40_id)
          assert_equal min40_time.year, decoded_min40.year
          assert_equal min40_time.month, decoded_min40.month
          assert_equal min40_time.day, decoded_min40.day
          # 14:00-14:39 falls in block 21, so hour should be 14
          assert_equal 14, decoded_min40.hour
        end

        # ===================
        # Sortability Tests
        # ===================

        def test_month_ids_are_sortable
          times = [
            Time.utc(2000, 1, 1),
            Time.utc(2010, 6, 1),
            Time.utc(2025, 12, 1)
          ]

          ids = times.map { |t| @encoder.encode_with_format(t, format: :month) }
          sorted_ids = ids.sort

          assert_equal ids, sorted_ids, "Month IDs should be sortable chronologically"
        end

        def test_day_ids_are_sortable
          times = [
            Time.utc(2025, 1, 1),
            Time.utc(2025, 1, 15),
            Time.utc(2025, 1, 31),
            Time.utc(2025, 2, 1)
          ]

          ids = times.map { |t| @encoder.encode_with_format(t, format: :day) }
          sorted_ids = ids.sort

          assert_equal ids, sorted_ids, "Day IDs should be sortable chronologically"
        end

        def test_40min_ids_are_sortable
          times = [
            Time.utc(2025, 1, 1, 0),
            Time.utc(2025, 1, 1, 12),
            Time.utc(2025, 1, 1, 23)
          ]

          ids = times.map { |t| @encoder.encode_with_format(t, format: :"40min") }
          sorted_ids = ids.sort

          assert_equal ids, sorted_ids, "40min IDs should be sortable chronologically"
        end

        def test_week_ids_are_sortable
          # Test week format sortability across different weeks
          # Use dates that all have Thursdays in the same month (January 2025)
          times = [
            Time.utc(2025, 1, 2),   # Thu → Jan 2 → Week 1
            Time.utc(2025, 1, 9),   # Thu → Jan 9 → Week 2
            Time.utc(2025, 1, 23)   # Thu → Jan 23 → Week 4
          ]

          ids = times.map { |t| @encoder.encode_with_format(t, format: :week) }
          sorted_ids = ids.sort

          assert_equal ids, sorted_ids, "Week IDs should be sortable chronologically"
        end

        # ===================
        # Backward Compatibility Tests
        # ===================

        def test_encode_defaults_to_2sec_format
          time = Time.utc(2025, 6, 15, 12, 30, 0)
          result = @encoder.encode(time)

          assert_equal 6, result.length
        end

        def test_encode_with_format_defaults_to_2sec
          time = Time.utc(2025, 6, 15, 12, 30, 0)
          result = @encoder.encode_with_format(time, format: :"2sec")

          assert_equal 6, result.length
          assert_match(/\A[0-9a-z]{6}\z/, result)
        end

        def test_decode_defaults_to_2sec_format
          result = @encoder.decode("000000")

          assert_equal 2000, result.year
          assert_equal 1, result.month
        end

        # ===================
        # encode_with_format Tests
        # ===================

        def test_encode_with_format_month
          time = Time.utc(2025, 6, 15, 12, 30, 45)
          result = @encoder.encode_with_format(time, format: :month)

          assert_equal 2, result.length
          assert_match(/\A[0-9a-z]{2}\z/, result)
        end

        def test_encode_with_format_week
          time = Time.utc(2025, 6, 15, 12, 30, 45)
          result = @encoder.encode_with_format(time, format: :week)

          assert_equal 3, result.length
          assert_match(/\A[0-9a-z]{3}\z/, result)
        end

        def test_encode_with_format_day
          time = Time.utc(2025, 6, 15, 12, 30, 45)
          result = @encoder.encode_with_format(time, format: :day)

          assert_equal 3, result.length
          assert_match(/\A[0-9a-z]{3}\z/, result)
        end

        def test_encode_with_format_40min
          time = Time.utc(2025, 6, 15, 12, 30, 45)
          result = @encoder.encode_with_format(time, format: :"40min")

          assert_equal 4, result.length
          assert_match(/\A[0-9a-z]{4}\z/, result)
        end

        def test_encode_with_format_50ms
          time = Time.utc(2025, 6, 15, 12, 30, 45)
          result = @encoder.encode_with_format(time, format: :"50ms")

          assert_equal 7, result.length
          assert_match(/\A[0-9a-z]{7}\z/, result)
        end

        def test_encode_with_format_ms
          time = Time.utc(2025, 6, 15, 12, 30, 45)
          result = @encoder.encode_with_format(time, format: :ms)

          assert_equal 8, result.length
          assert_match(/\A[0-9a-z]{8}\z/, result)
        end

        def test_encode_with_format_raises_for_invalid_format
          time = Time.utc(2025, 6, 15, 12, 30, 45)

          error = assert_raises(ArgumentError) do
            @encoder.encode_with_format(time, format: :invalid)
          end

          assert_match(/Invalid format: invalid/, error.message)
        end

        def test_encode_with_format_suggests_new_name_for_deprecated_compact
          time = Time.utc(2025, 6, 15, 12, 30, 45)

          error = assert_raises(ArgumentError) do
            @encoder.encode_with_format(time, format: :compact)
          end

          assert_match(/Did you mean '2sec'\?/, error.message)
        end

        def test_encode_with_format_suggests_new_name_for_deprecated_hour
          time = Time.utc(2025, 6, 15, 12, 30, 45)

          error = assert_raises(ArgumentError) do
            @encoder.encode_with_format(time, format: :hour)
          end

          assert_match(/Did you mean '40min'\?/, error.message)
        end

        def test_decode_with_format_suggests_new_name_for_deprecated_high_7
          error = assert_raises(ArgumentError) do
            @encoder.decode_with_format("i500000", format: :high_7)
          end

          assert_match(/Did you mean '50ms'\?/, error.message)
        end

        def test_decode_with_format_suggests_new_name_for_deprecated_high_8
          error = assert_raises(ArgumentError) do
            @encoder.decode_with_format("i5000000", format: :high_8)
          end

          assert_match(/Did you mean 'ms'\?/, error.message)
        end

        # ===================
        # decode_with_format Tests
        # ===================

        def test_decode_with_format_month
          encoded = @encoder.encode_with_format(Time.utc(2025, 6, 15), format: :month)
          result = @encoder.decode_with_format(encoded, format: :month)

          assert_equal 2025, result.year
          assert_equal 6, result.month
          assert_equal 1, result.day
        end

        def test_decode_with_format_day
          encoded = @encoder.encode_with_format(Time.utc(2025, 6, 15), format: :day)
          result = @encoder.decode_with_format(encoded, format: :day)

          assert_equal 2025, result.year
          assert_equal 6, result.month
          assert_equal 15, result.day
        end

        def test_decode_with_format_40min
          encoded = @encoder.encode_with_format(Time.utc(2025, 6, 15, 14), format: :"40min")
          result = @encoder.decode_with_format(encoded, format: :"40min")

          assert_equal 2025, result.year
          assert_equal 6, result.month
          assert_equal 15, result.day
          assert_equal 14, result.hour
        end

        def test_decode_with_format_raises_for_invalid_format
          error = assert_raises(ArgumentError) do
            @encoder.decode_with_format("000000", format: :invalid)
          end

          assert_match(/Invalid format: invalid/, error.message)
        end

        # ===================
        # encode_sequence Tests
        # ===================

        def test_encode_sequence_returns_array_of_ids
          time = Time.utc(2025, 1, 6, 12, 30, 0)
          result = @encoder.encode_sequence(time, count: 5, format: :"2sec")

          assert_instance_of Array, result
          assert_equal 5, result.length
          result.each { |id| assert_equal 6, id.length }
        end

        def test_encode_sequence_count_1_returns_single_id
          time = Time.utc(2025, 1, 6, 12, 30, 0)
          result = @encoder.encode_sequence(time, count: 1, format: :"2sec")

          assert_equal 1, result.length
          assert_equal @encoder.encode_with_format(time, format: :"2sec"), result.first
        end

        def test_encode_sequence_ids_are_sequential
          time = Time.utc(2025, 1, 6, 12, 30, 0)
          result = @encoder.encode_sequence(time, count: 10, format: :"2sec")

          # Each ID should be greater than the previous (lexicographically sorted)
          result.each_cons(2) do |prev, curr|
            assert_operator prev, :<, curr, "IDs should be strictly increasing"
          end
        end

        def test_encode_sequence_works_for_all_formats
          time = Time.utc(2025, 1, 6, 12, 30, 0)

          formats_and_lengths = {
            month: 2,
            week: 3,
            day: 3,
            "40min": 4,
            "2sec": 6,
            "50ms": 7,
            ms: 8
          }

          formats_and_lengths.each do |format, expected_length|
            result = @encoder.encode_sequence(time, count: 3, format: format)

            assert_equal 3, result.length, "Failed for format #{format}"
            result.each do |id|
              assert_equal expected_length, id.length, "Wrong length for format #{format}"
            end
          end
        end

        def test_encode_sequence_raises_for_count_zero
          time = Time.utc(2025, 1, 6, 12, 30, 0)

          error = assert_raises(ArgumentError) do
            @encoder.encode_sequence(time, count: 0, format: :"2sec")
          end

          assert_match(/count must be greater than 0/, error.message)
        end

        def test_encode_sequence_raises_for_negative_count
          time = Time.utc(2025, 1, 6, 12, 30, 0)

          error = assert_raises(ArgumentError) do
            @encoder.encode_sequence(time, count: -1, format: :"2sec")
          end

          assert_match(/count must be greater than 0/, error.message)
        end

        # ===================
        # increment_id Tests
        # ===================

        def test_increment_id_increments_2sec_format
          # Simple increment within precision
          id = "i50000"
          result = @encoder.increment_id(id, format: :"2sec")

          assert_equal "i50001", result
        end

        def test_increment_id_handles_2sec_precision_overflow_to_block
          # Precision at max (zz = 1295), should overflow to block
          id = "i500zz"
          result = @encoder.increment_id(id, format: :"2sec")

          # Block increments, precision resets
          assert_equal "i50100", result
        end

        def test_increment_id_handles_2sec_block_overflow_to_day
          # Block at max (z = 35), precision at max (zz)
          id = "i50zzz"
          result = @encoder.increment_id(id, format: :"2sec")

          # Day increments, block and precision reset
          assert_equal "i51000", result
        end

        def test_increment_id_handles_2sec_day_overflow_to_month
          # Day at max (u = 30), block at max, precision at max
          id = "i5uzzz"
          result = @encoder.increment_id(id, format: :"2sec")

          # Month increments, day/block/precision reset
          assert_equal "i60000", result
        end

        def test_increment_id_handles_ms_format
          id = "i5000000"
          result = @encoder.increment_id(id, format: :ms)

          assert_equal "i5000001", result
        end

        def test_increment_id_handles_50ms_format
          id = "i500000"
          result = @encoder.increment_id(id, format: :"50ms")

          assert_equal "i500001", result
        end

        def test_increment_id_handles_40min_format
          id = "i500"
          result = @encoder.increment_id(id, format: :"40min")

          assert_equal "i501", result
        end

        def test_increment_id_handles_40min_block_overflow
          # Block at max (z = 35)
          id = "i50z"
          result = @encoder.increment_id(id, format: :"40min")

          # Day increments, block resets
          assert_equal "i510", result
        end

        def test_increment_id_handles_day_format
          id = "i50"
          result = @encoder.increment_id(id, format: :day)

          assert_equal "i51", result
        end

        def test_increment_id_handles_day_overflow_to_month
          # Day at max (u = 30)
          id = "i5u"
          result = @encoder.increment_id(id, format: :day)

          # Month increments, day resets
          assert_equal "i60", result
        end

        def test_increment_id_handles_week_format
          # Week value is in 31-35 range (v-z)
          id = "i5v"  # week 1 (31 = 'v')
          result = @encoder.increment_id(id, format: :week)

          assert_equal "i5w", result  # week 2 (32 = 'w')
        end

        def test_increment_id_handles_week_overflow_to_month
          # Week at max (z = 35)
          id = "i5z"
          result = @encoder.increment_id(id, format: :week)

          # Month increments, week resets to 31 (v)
          assert_equal "i6v", result
        end

        def test_increment_id_handles_month_format
          id = "i5"
          result = @encoder.increment_id(id, format: :month)

          assert_equal "i6", result
        end

        def test_increment_id_raises_on_month_overflow
          # Month at max (zz = 1295)
          id = "zz"

          error = assert_raises(ArgumentError) do
            @encoder.increment_id(id, format: :month)
          end

          assert_match(/would exceed month range/, error.message)
        end

        def test_increment_id_raises_on_full_overflow_2sec
          # All components at max for 2sec format
          id = "zzuzzz"

          error = assert_raises(ArgumentError) do
            @encoder.increment_id(id, format: :"2sec")
          end

          assert_match(/would exceed month range/, error.message)
        end

        # ===================
        # Overflow Cascade Tests
        # ===================

        def test_sequence_handles_block_boundary_crossover
          # Start near end of a block in 2sec format
          # Precision "zz" = 1295 (max), so next ID should overflow
          start_id = "i500zz"
          result = @encoder.encode_sequence(
            @encoder.decode_with_format(start_id, format: :"2sec"),
            count: 3,
            format: :"2sec"
          )

          # First ID is the starting point, then we get 2 more
          # The sequence should span across the block boundary
          assert_equal 3, result.length
          assert_operator result[0], :<, result[1]
          assert_operator result[1], :<, result[2]
        end

        def test_sequence_handles_day_boundary_crossover
          # Start at last block of day
          time = Time.utc(2025, 1, 1, 23, 59, 0)
          result = @encoder.encode_sequence(time, count: 5, format: :"40min")

          # Should produce sorted, increasing IDs even across day boundary
          assert_equal 5, result.length
          result.each_cons(2) do |prev, curr|
            assert_operator prev, :<, curr
          end
        end
      end
    end
  end
end
