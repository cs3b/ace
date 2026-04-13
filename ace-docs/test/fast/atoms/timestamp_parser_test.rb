# frozen_string_literal: true

require "test_helper"
require "ace/docs/atoms/timestamp_parser"

module Ace
  module Docs
    module Atoms
      class TimestampParserTest < Minitest::Test
        # ====================
        # ISO 8601 UTC Format Tests
        # ====================

        def test_parse_iso8601_utc_format
          result = TimestampParser.parse_timestamp("2025-11-15T08:30:45Z")

          assert_kind_of Time, result
          assert_equal 2025, result.year
          assert_equal 11, result.month
          assert_equal 15, result.day
          assert_equal 8, result.hour
          assert_equal 30, result.min
          assert_equal 45, result.sec
          assert_equal "UTC", result.zone
        end

        def test_parse_iso8601_at_midnight
          result = TimestampParser.parse_timestamp("2025-11-15T00:00:00Z")

          assert_equal 0, result.hour
          assert_equal 0, result.min
          assert_equal 0, result.sec
        end

        def test_parse_iso8601_at_end_of_day
          result = TimestampParser.parse_timestamp("2025-11-15T23:59:59Z")

          assert_equal 23, result.hour
          assert_equal 59, result.min
          assert_equal 59, result.sec
        end

        def test_parse_iso8601_year_boundary
          # New Year's Eve
          result = TimestampParser.parse_timestamp("2025-12-31T23:59:59Z")
          assert_equal 2025, result.year
          assert_equal 12, result.month
          assert_equal 31, result.day

          # New Year's Day
          result = TimestampParser.parse_timestamp("2026-01-01T00:00:00Z")
          assert_equal 2026, result.year
          assert_equal 1, result.month
          assert_equal 1, result.day
        end

        def test_validate_iso8601_format
          assert TimestampParser.validate_format("2025-11-15T08:30:45Z")
          assert TimestampParser.validate_format("2025-01-01T00:00:00Z")
          assert TimestampParser.validate_format("2025-12-31T23:59:59Z")
        end

        def test_format_time_to_iso8601
          time = Time.utc(2025, 11, 15, 8, 30, 45)
          result = TimestampParser.format_timestamp(time)

          assert_equal "2025-11-15T08:30:45Z", result
        end

        def test_format_time_at_midnight
          time = Time.utc(2025, 11, 1, 0, 0, 0)
          result = TimestampParser.format_timestamp(time)
          assert_equal "2025-11-01T00:00:00Z", result
        end

        def test_format_time_at_end_of_day
          time = Time.utc(2025, 11, 1, 23, 59, 0)
          result = TimestampParser.format_timestamp(time)
          assert_equal "2025-11-01T23:59:00Z", result
        end

        def test_format_single_digit_components
          time = Time.utc(2025, 1, 5, 9, 5, 0)
          result = TimestampParser.format_timestamp(time)
          assert_equal "2025-01-05T09:05:00Z", result
        end

        def test_format_year_boundary
          time = Time.utc(2024, 12, 31, 23, 59, 0)
          result = TimestampParser.format_timestamp(time)
          assert_equal "2024-12-31T23:59:00Z", result
        end

        # ====================
        # Date-Only Format Tests
        # ====================

        def test_parse_date_only_string_returns_date
          result = TimestampParser.parse_timestamp("2025-11-01")
          assert_instance_of Date, result
          assert_equal Date.new(2025, 11, 1), result
        end

        def test_parse_date_only_with_leading_zeros
          result = TimestampParser.parse_timestamp("2025-01-05")
          assert_instance_of Date, result
          assert_equal Date.new(2025, 1, 5), result
        end

        def test_validate_date_only_format
          assert TimestampParser.validate_format("2025-11-15")
          assert TimestampParser.validate_format("2025-01-01")
          assert TimestampParser.validate_format("2025-11-01")
        end

        def test_format_date_object_to_date_only_string
          date = Date.new(2025, 11, 1)
          result = TimestampParser.format_timestamp(date)
          assert_equal "2025-11-01", result
          refute_match(/T/, result)
        end

        # ====================
        # Polymorphic Type Handling (Already Parsed Objects)
        # ====================

        def test_parse_date_object_returns_as_is
          date = Date.new(2025, 11, 1)
          result = TimestampParser.parse_timestamp(date)
          assert_equal date, result
        end

        def test_parse_time_object_returns_as_is
          time = Time.new(2025, 11, 1, 14, 30)
          result = TimestampParser.parse_timestamp(time)
          assert_equal time, result
        end

        # ====================
        # Timezone Conversion Tests
        # ====================

        def test_all_parsed_time_objects_are_utc
          # ISO 8601
          iso_result = TimestampParser.parse_timestamp("2025-11-15T08:30:45Z")
          assert_equal "UTC", iso_result.zone
        end

        def test_format_converts_local_time_to_utc
          # Create time in non-UTC timezone
          time = Time.new(2025, 11, 15, 14, 30, 0, "+05:00")
          result = TimestampParser.format_timestamp(time)

          # Should output in UTC (14:30 +05:00 = 09:30 UTC)
          assert_match(/Z$/, result)
          assert_match(/T09:30:00Z/, result)
        end

        def test_format_preserves_utc_timezone
          # Create a time in different timezone
          time = Time.new(2025, 11, 15, 14, 30, 0, "+09:00")
          result = TimestampParser.format_timestamp(time)

          # Should output in UTC (14:30 +09:00 = 05:30 UTC)
          assert_match(/Z$/, result)
          assert_match(/T05:30:00Z/, result)
        end

        # ====================
        # Validation Tests
        # ====================

        def test_validate_invalid_format_with_am_pm
          refute TimestampParser.validate_format("2025-11-01 2:30pm")
        end

        def test_validate_invalid_format_with_wrong_separator
          refute TimestampParser.validate_format("11/01/2025")
        end

        def test_validate_nil_returns_false
          refute TimestampParser.validate_format(nil)
        end

        def test_validate_empty_string_returns_false
          refute TimestampParser.validate_format("")
        end

        def test_validate_non_string_returns_false
          refute TimestampParser.validate_format(12345)
          refute TimestampParser.validate_format([])
        end

        def test_reject_invalid_iso8601_formats
          # Missing Z suffix
          refute TimestampParser.validate_format("2025-11-15T08:30:45")

          # Wrong separator (space instead of T)
          refute TimestampParser.validate_format("2025-11-15 08:30:45Z")

          # Missing seconds
          refute TimestampParser.validate_format("2025-11-15T08:30Z")

          # ISO without Z - treated as invalid
          refute TimestampParser.validate_format("2025-11-01T14:30")
        end

        # ====================
        # Edge Cases
        # ====================

        def test_parse_leap_year_date
          result = TimestampParser.parse_timestamp("2024-02-29")
          assert_equal Date.new(2024, 2, 29), result
        end

        def test_parse_invalid_leap_year_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.parse_timestamp("2025-02-29")
          end
          assert_match(/Invalid timestamp/i, error.message)
        end

        def test_parse_month_end_30_days
          result = TimestampParser.parse_timestamp("2025-04-30")
          assert_equal Date.new(2025, 4, 30), result
        end

        def test_parse_month_end_31_days
          result = TimestampParser.parse_timestamp("2025-05-31")
          assert_equal Date.new(2025, 5, 31), result
        end

        def test_parse_invalid_month_day_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.parse_timestamp("2025-04-31") # April has only 30 days
          end
          assert_match(/Invalid timestamp/i, error.message)
        end

        # ====================
        # Round-trip Tests
        # ====================

        def test_round_trip_iso8601
          original = "2025-11-15T08:30:45Z"
          parsed = TimestampParser.parse_timestamp(original)
          formatted = TimestampParser.format_timestamp(parsed)

          assert_equal original, formatted
        end

        def test_round_trip_date_only
          original = "2025-11-15"
          parsed = TimestampParser.parse_timestamp(original)
          formatted = TimestampParser.format_timestamp(parsed)

          assert_equal original, formatted
        end

        # ====================
        # Invalid Format Tests
        # ====================

        def test_parse_invalid_format_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.parse_timestamp("2025-11-01 2:30pm")
          end
          assert_match(/Invalid timestamp format/i, error.message)
        end

        def test_parse_iso8601_without_z_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.parse_timestamp("2025-11-15T08:30:45")
          end
          assert_match(/Invalid timestamp format/, error.message)
        end

        def test_parse_partial_iso8601_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.parse_timestamp("2025-11-01T14:30")
          end
          assert_match(/Invalid timestamp format/i, error.message)
        end

        def test_parse_invalid_date_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.parse_timestamp("2025-13-01")
          end
          assert_match(/Invalid timestamp/i, error.message)
        end

        def test_parse_nil_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.parse_timestamp(nil)
          end
          assert_match(/Cannot parse nil/i, error.message)
        end

        def test_format_nil_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.format_timestamp(nil)
          end
          assert_match(/Cannot format nil/i, error.message)
        end

        def test_format_invalid_type_raises_error
          error = assert_raises(ArgumentError) do
            TimestampParser.format_timestamp("2025-11-01")
          end
          assert_match(/must be a Date or Time/i, error.message)
        end
      end
    end
  end
end
