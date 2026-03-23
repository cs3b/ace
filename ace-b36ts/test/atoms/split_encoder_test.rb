# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module B36ts
    module Atoms
      class SplitEncoderTest < Minitest::Test
        def setup
          @encoder = CompactIdEncoder
          @time = Time.utc(2025, 1, 6, 12, 30, 0)
        end

        def test_encode_split_returns_components_and_rest
          combinations = [
            {levels: [:month], rest_length: 4, expect_week: false},
            {levels: [:month, :week], rest_length: 4, expect_week: true},
            {levels: [:month, :day], rest_length: 3, expect_week: false},
            {levels: [:month, :week, :day], rest_length: 3, expect_week: true},
            {levels: [:month, :day, :block], rest_length: 2, expect_week: false},
            {levels: [:month, :week, :day, :block], rest_length: 2, expect_week: true}
          ]

          full_compact = @encoder.encode_2sec(@time)

          combinations.each do |config|
            result = @encoder.encode_split(@time, levels: config[:levels])

            assert_equal config[:rest_length], result[:rest].length
            assert result[:path].include?("/")
            assert result[:full].length.between?(6, 7)

            if config[:expect_week]
              reconstructed = result[:full][0..1] + result[:full][3..-1]
              assert_equal full_compact, reconstructed
              assert result[:week]
            else
              assert_equal full_compact, result[:full]
              refute result[:week]
            end
          end
        end

        def test_encode_split_invalid_levels_raise_errors
          assert_raises(ArgumentError) do
            @encoder.encode_split(@time, levels: [])
          end

          assert_raises(ArgumentError) do
            @encoder.encode_split(@time, levels: [:day])
          end

          assert_raises(ArgumentError) do
            @encoder.encode_split(@time, levels: [:month, :block])
          end

          assert_raises(ArgumentError) do
            @encoder.encode_split(@time, levels: [:month, :day, :week])
          end

          assert_raises(ArgumentError) do
            @encoder.encode_split(@time, levels: [:month, :week, :day, :hour])
          end
        end

        def test_decode_path_roundtrip
          result = @encoder.encode_split(@time, levels: [:month, :week, :day, :block])
          decoded = @encoder.decode_path(result[:path])

          assert_in_delta @time.to_i, decoded.to_i, 3
        end

        def test_decode_path_accepts_separators
          result = @encoder.encode_split(@time, levels: [:month, :day, :block])

          decoded_slash = @encoder.decode_path(result[:path])
          decoded_backslash = @encoder.decode_path(result[:path].tr("/", "\\"))
          decoded_colon = @encoder.decode_path(result[:path].tr("/", ":"))

          assert_in_delta @time.to_i, decoded_slash.to_i, 3
          assert_in_delta @time.to_i, decoded_backslash.to_i, 3
          assert_in_delta @time.to_i, decoded_colon.to_i, 3
        end

        def test_decode_path_accepts_full_string
          result = @encoder.encode_split(@time, levels: [:month, :week, :day])
          decoded = @encoder.decode_path(result[:full])

          assert_in_delta @time.to_i, decoded.to_i, 3
        end

        # Edge case tests for boundary conditions and malformed input

        def test_encode_split_month_boundaries
          # First day of year (Jan 1 2025 = Wednesday, Thursday = Jan 2 → same month)
          jan_1 = Time.utc(2025, 1, 1, 0, 0, 0)
          result_jan = @encoder.encode_split(jan_1, levels: [:month, :week, :day])
          decoded_jan = @encoder.decode_path(result_jan[:path])
          assert_in_delta jan_1.to_i, decoded_jan.to_i, 3

          # Last day of year (Dec 31 2025 = Wednesday, Thursday = Jan 1 2026 → year crossing)
          # ISO attribution puts Dec 31 in January 2026, so decode_path will not roundtrip.
          # Verify the path encodes successfully and the month reflects January 2026.
          dec_31 = Time.utc(2025, 12, 31, 23, 59, 59)
          result_dec = @encoder.encode_split(dec_31, levels: [:month, :week, :day])
          jan_2026_token = @encoder.encode_with_format(Time.utc(2026, 1, 1), format: :month)
          assert_equal jan_2026_token, result_dec[:month], "Dec 31 (Wed) ISO week is in Jan 2026"

          # February boundary (Feb 28 2025 = Friday, Thursday = Feb 27 → same month)
          feb_28 = Time.utc(2025, 2, 28, 12, 0, 0)
          result_feb = @encoder.encode_split(feb_28, levels: [:month, :week, :day])
          decoded_feb = @encoder.decode_path(result_feb[:path])
          assert_in_delta feb_28.to_i, decoded_feb.to_i, 3
        end

        def test_decode_path_with_mixed_separators
          result = @encoder.encode_split(@time, levels: [:month, :day, :block])
          # Create path with mixed separators: "i5/5\jj3"
          mixed_path = result[:path].sub("/", "\\")
          decoded = @encoder.decode_path(mixed_path)
          assert_in_delta @time.to_i, decoded.to_i, 3
        end

        def test_decode_path_with_trailing_separator
          result = @encoder.encode_split(@time, levels: [:month, :day])
          path_with_trailing = "#{result[:path]}/"
          decoded = @encoder.decode_path(path_with_trailing)
          assert_in_delta @time.to_i, decoded.to_i, 3
        end

        def test_decode_path_with_consecutive_separators
          result = @encoder.encode_split(@time, levels: [:month, :day])
          # Replace single separator with double
          path_with_double = result[:path].sub("/", "//")
          decoded = @encoder.decode_path(path_with_double)
          assert_in_delta @time.to_i, decoded.to_i, 3
        end

        def test_decode_path_with_leading_separator
          result = @encoder.encode_split(@time, levels: [:month, :day])
          path_with_leading = "/#{result[:path]}"
          decoded = @encoder.decode_path(path_with_leading)
          assert_in_delta @time.to_i, decoded.to_i, 3
        end

        def test_split_week_token_matches_encode_week_3rd_char
          result = @encoder.encode_split(@time, levels: [:month, :week])
          week_token = result[:week]
          week_id = @encoder.encode_with_format(@time, format: :week)
          assert_equal week_id[2], week_token,
            "encode_split week token #{week_token.inspect} should match 3rd char of encode_week #{week_id.inspect}"
        end

        def test_split_week_token_is_in_valid_range
          result = @encoder.encode_split(@time, levels: [:month, :week])
          week_value = @encoder.send(:decode_value, result[:week], CompactIdEncoder::DEFAULT_ALPHABET)
          assert_includes FormatSpecs::WEEK_FORMAT_MIN..FormatSpecs::WEEK_FORMAT_MAX, week_value,
            "week token value #{week_value} should be in #{FormatSpecs::WEEK_FORMAT_MIN}..#{FormatSpecs::WEEK_FORMAT_MAX}"
        end

        def test_split_month_uses_iso_attribution_at_boundary
          # March 1, 2026 is a Sunday. Its Thursday is Feb 26, so ISO week is in February.
          boundary_time = Time.utc(2026, 3, 1, 12, 0, 0)
          result = @encoder.encode_split(boundary_time, levels: [:month, :week])

          feb_time = Time.utc(2026, 2, 1)
          feb_month_token = @encoder.encode_with_format(feb_time, format: :month)

          assert_equal feb_month_token, result[:month],
            "March 1 (Sunday) should partition to February (ISO Thursday is Feb 26), got month=#{result[:month].inspect}"
        end
      end
    end
  end
end
