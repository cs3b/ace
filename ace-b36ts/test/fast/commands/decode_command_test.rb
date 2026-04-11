# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module B36ts
    module Commands
      class DecodeCommandTest < Minitest::Test
        def setup
          Ace::B36ts.reset_config!
        end

        # ===================
        # Success Cases
        # ===================

        def test_execute_with_valid_compact_id
          output, = capture_io do
            exit_code = DecodeCommand.execute("000000")
            assert_equal 0, exit_code
          end

          assert_match(/2000-01-01/, output)
        end

        def test_execute_with_readable_format
          output, = capture_io do
            exit_code = DecodeCommand.execute("000000", format: :readable)
            assert_equal 0, exit_code
          end

          assert_match(/2000-01-01 00:00:\d+ UTC/, output)
        end

        def test_execute_with_iso_format
          output, = capture_io do
            exit_code = DecodeCommand.execute("000000", format: :iso)
            assert_equal 0, exit_code
          end

          assert_match(/2000-01-01T00:00:\d+/, output)
        end

        def test_execute_with_timestamp_format
          output, = capture_io do
            exit_code = DecodeCommand.execute("000000", format: :timestamp)
            assert_equal 0, exit_code
          end

          assert_match(/20000101-0000\d{2}/, output)
        end

        def test_execute_with_year_zero_override
          output, = capture_io do
            exit_code = DecodeCommand.execute("000000", year_zero: 2025)
            assert_equal 0, exit_code
          end

          assert_match(/2025-01-01/, output)
        end

        def test_execute_with_string_format_option
          output, = capture_io do
            exit_code = DecodeCommand.execute("000000", format: "iso")
            assert_equal 0, exit_code
          end

          assert_match(/2000-01-01T00:00/, output)
        end

        # ===================
        # Error Cases
        # ===================

        def test_execute_with_invalid_length_returns_error
          # 5 characters is not a valid length for any format
          _, err = capture_io do
            assert_raises(ArgumentError) do
              DecodeCommand.execute("abcde")
            end
          end

          assert_match(/Error/i, err)
        end

        def test_execute_with_invalid_characters_returns_error
          _, err = capture_io do
            assert_raises(ArgumentError) do
              DecodeCommand.execute("ABC!!!")
            end
          end

          assert_match(/Error/i, err)
        end

        def test_execute_with_empty_string_returns_error
          _, err = capture_io do
            assert_raises(ArgumentError) do
              DecodeCommand.execute("")
            end
          end

          assert_match(/Error/i, err)
        end

        # ===================
        # Format Output Tests
        # ===================

        def test_default_format_is_readable
          output1, = capture_io { DecodeCommand.execute("000000") }
          output2, = capture_io { DecodeCommand.execute("000000", format: :readable) }

          assert_equal output1, output2
        end

        # ===================
        # Auto-detection Tests
        # ===================

        def test_decode_auto_detects_2_char_month_id
          # Encode a time to month format, then decode it
          encoder = Ace::B36ts::Atoms::CompactIdEncoder
          original = Time.utc(2025, 6, 15, 14, 30, 45)
          month_id = encoder.encode_with_format(original, format: :month)

          output, = capture_io { DecodeCommand.execute(month_id) }

          assert_match(/2025-06/, output)
          assert_match(/00:00:00/, output)  # Month format decodes to midnight of first day
        end

        def test_decode_auto_detects_3_char_day_id
          encoder = Ace::B36ts::Atoms::CompactIdEncoder
          original = Time.utc(2025, 6, 15, 14, 30, 45)
          day_id = encoder.encode_with_format(original, format: :day)

          output, = capture_io { DecodeCommand.execute(day_id) }

          assert_match(/2025-06-15/, output)
          assert_match(/00:00:00/, output)  # Day format decodes to midnight
        end

        def test_decode_auto_detects_3_char_week_id
          encoder = Ace::B36ts::Atoms::CompactIdEncoder
          original = Time.utc(2025, 1, 15, 14, 30, 45)
          week_id = encoder.encode_with_format(original, format: :week)

          output, = capture_io { DecodeCommand.execute(week_id) }

          assert_match(/2025-01/, output)
          # Week format decodes to first day of week
        end

        def test_decode_auto_detects_4_char_40min_id
          encoder = Ace::B36ts::Atoms::CompactIdEncoder
          original = Time.utc(2025, 6, 15, 14, 30, 45)
          min40_id = encoder.encode_with_format(original, format: :"40min")

          output, = capture_io { DecodeCommand.execute(min40_id) }

          assert_match(/2025-06-15/, output)
          assert_match(/14:00:00/, output)  # 40min format decodes to start of 40-min block
        end

        def test_decode_auto_detects_7_char_50ms_id
          encoder = Ace::B36ts::Atoms::CompactIdEncoder
          original = Time.utc(2025, 6, 15, 14, 30, 45, 123456)
          ms50_id = encoder.encode_with_format(original, format: :"50ms")

          output, = capture_io { DecodeCommand.execute(ms50_id) }

          assert_match(/2025-06-15/, output)
          assert_match(/14:30:45/, output)  # 50ms format preserves seconds
        end

        def test_decode_auto_detects_8_char_ms_id
          encoder = Ace::B36ts::Atoms::CompactIdEncoder
          original = Time.utc(2025, 6, 15, 14, 30, 45, 123456)
          ms_id = encoder.encode_with_format(original, format: :ms)

          output, = capture_io { DecodeCommand.execute(ms_id) }

          assert_match(/2025-06-15/, output)
          assert_match(/14:30:45/, output)  # ms format preserves seconds
        end

        # ===================
        # Split Path Tests
        # ===================

        def test_decode_with_split_path_separators
          encoder = Ace::B36ts::Atoms::CompactIdEncoder
          original = Time.utc(2025, 1, 6, 12, 30, 0)
          split = encoder.encode_split(original, levels: [:month, :week, :day, :block])

          output, = capture_io { DecodeCommand.execute(split[:path]) }
          assert_match(/2025-01-06/, output)
        end

        def test_decode_with_split_flag_accepts_full_string
          encoder = Ace::B36ts::Atoms::CompactIdEncoder
          original = Time.utc(2025, 1, 6, 12, 30, 0)
          split = encoder.encode_split(original, levels: [:month, :week, :day])

          output, = capture_io { DecodeCommand.execute(split[:full], split: true) }
          assert_match(/2025-01-06/, output)
        end
      end
    end
  end
end
