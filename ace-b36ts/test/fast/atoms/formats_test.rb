# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module B36ts
    module Atoms
      class FormatsTest < Minitest::Test
        # ===================
        # detect Tests
        # ===================

        def test_detect_2sec_format
          assert_equal :"2sec", Formats.detect("abc123")
          assert_equal :"2sec", Formats.detect("000000")
          assert_equal :"2sec", Formats.detect("zzzzzz")
          assert_equal :"2sec", Formats.detect("ABC123")  # Case insensitive
        end

        def test_detect_timestamp_format
          assert_equal :timestamp, Formats.detect("20250101-120000")
          assert_equal :timestamp, Formats.detect("20001231-235959")
          assert_equal :timestamp, Formats.detect("21071231-000000")
        end

        def test_detect_returns_nil_for_invalid
          # Strings with invalid characters should return nil
          assert_nil Formats.detect("invalid!")
          assert_nil Formats.detect("x!z")
          assert_nil Formats.detect("ab#")
          # String with unsupported length (9 chars)
          assert_nil Formats.detect("123456789")
          assert_nil Formats.detect("20250101120000")  # Missing hyphen
          assert_nil Formats.detect("2025-01-01")
          assert_nil Formats.detect("")
        end

        def test_detect_returns_nil_for_non_string
          assert_nil Formats.detect(123456)
          assert_nil Formats.detect(nil)
          assert_nil Formats.detect([])
        end

        # ===================
        # compact? Tests
        # ===================

        def test_compact_returns_true_for_compact
          assert Formats.compact?("abc123")
          assert Formats.compact?("ABC123")
        end

        def test_compact_returns_false_for_timestamp
          refute Formats.compact?("20250101-120000")
        end

        def test_compact_returns_false_for_invalid
          refute Formats.compact?("x!z")
          refute Formats.compact?("invalid!")
          refute Formats.compact?(nil)
        end

        # ===================
        # timestamp? Tests
        # ===================

        def test_timestamp_returns_true_for_timestamp
          assert Formats.timestamp?("20250101-120000")
          assert Formats.timestamp?("20001231-235959")
        end

        def test_timestamp_returns_false_for_compact
          refute Formats.timestamp?("abc123")
        end

        def test_timestamp_returns_false_for_invalid
          refute Formats.timestamp?("x!z")
          refute Formats.timestamp?("invalid!")
          refute Formats.timestamp?(nil)
        end

        # ===================
        # parse_timestamp Tests
        # ===================

        def test_parse_timestamp_returns_time
          result = Formats.parse_timestamp("20250106-123045")

          assert_instance_of Time, result
          assert result.utc?
          assert_equal 2025, result.year
          assert_equal 1, result.month
          assert_equal 6, result.day
          assert_equal 12, result.hour
          assert_equal 30, result.min
          assert_equal 45, result.sec
        end

        def test_parse_timestamp_boundary_values
          # Start of day
          result = Formats.parse_timestamp("20250101-000000")
          assert_equal 0, result.hour
          assert_equal 0, result.min
          assert_equal 0, result.sec

          # End of day
          result = Formats.parse_timestamp("20251231-235959")
          assert_equal 23, result.hour
          assert_equal 59, result.min
          assert_equal 59, result.sec
        end

        def test_parse_timestamp_raises_for_invalid_format
          assert_raises(ArgumentError) do
            Formats.parse_timestamp("abc123")
          end

          assert_raises(ArgumentError) do
            Formats.parse_timestamp("2025-01-01")
          end
        end

        # ===================
        # format_timestamp Tests
        # ===================

        def test_format_timestamp_returns_correct_format
          time = Time.utc(2025, 1, 6, 12, 30, 45)
          result = Formats.format_timestamp(time)

          assert_equal "20250106-123045", result
        end

        def test_format_timestamp_pads_zeros
          time = Time.utc(2025, 1, 6, 1, 5, 9)
          result = Formats.format_timestamp(time)

          assert_equal "20250106-010509", result
        end

        def test_format_timestamp_converts_to_utc
          # Create a non-UTC time
          time = Time.new(2025, 1, 6, 12, 30, 45, "+05:00")
          result = Formats.format_timestamp(time)

          # Should be in UTC (5 hours earlier)
          assert_equal "20250106-073045", result
        end

        # ===================
        # Round-trip Tests
        # ===================

        def test_roundtrip_timestamp_format
          original = "20250106-123045"
          time = Formats.parse_timestamp(original)
          result = Formats.format_timestamp(time)

          assert_equal original, result
        end
      end
    end
  end
end
