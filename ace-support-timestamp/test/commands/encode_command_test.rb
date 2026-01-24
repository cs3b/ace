# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Support
    module Timestamp
    module Commands
      class EncodeCommandTest < Minitest::Test
        def setup
          Ace::Support::Timestamp.reset_config!
        end

        # ===================
        # Success Cases
        # ===================

        def test_execute_with_iso_time_string
          output, = capture_io do
            exit_code = EncodeCommand.execute("2025-01-06 12:30:00 UTC")
            assert_equal 0, exit_code
          end

          assert_match(/\A[0-9a-z]{6}\n\z/, output)
        end

        def test_execute_with_nil_uses_current_time
          output, = capture_io do
            exit_code = EncodeCommand.execute(nil)
            assert_equal 0, exit_code
          end

          assert_match(/\A[0-9a-z]{6}\n\z/, output)
        end

        def test_execute_with_empty_string_uses_current_time
          output, = capture_io do
            exit_code = EncodeCommand.execute("")
            assert_equal 0, exit_code
          end

          assert_match(/\A[0-9a-z]{6}\n\z/, output)
        end

        def test_execute_with_now_uses_current_time
          output, = capture_io do
            exit_code = EncodeCommand.execute("now")
            assert_equal 0, exit_code
          end

          assert_match(/\A[0-9a-z]{6}\n\z/, output)
        end

        def test_execute_with_timestamp_format
          output, = capture_io do
            exit_code = EncodeCommand.execute("20250106-123000")
            assert_equal 0, exit_code
          end

          assert_match(/\A[0-9a-z]{6}\n\z/, output)
        end

        def test_timestamp_format_parses_time_component_correctly
          # Verify the time component (12:30:00) is correctly parsed, not just the date
          # This was a bug where Time.parse incorrectly treated -HHMMSS as timezone offset
          compact_id, = capture_io { EncodeCommand.execute("20250106-123000") }
          compact_id = compact_id.strip

          decoded_output, = capture_io { DecodeCommand.execute(compact_id) }

          # The decoded time should be around 12:30, not 00:00
          assert_match(/12:\d{2}:\d{2}/, decoded_output, "Time component should be ~12:30, not midnight")
        end

        def test_execute_with_year_zero_override
          output1, = capture_io { EncodeCommand.execute("2025-01-01 00:00:00 UTC", year_zero: 2025) }
          output2, = capture_io { EncodeCommand.execute("2000-01-01 00:00:00 UTC", year_zero: 2000) }

          assert_equal "000000\n", output1.strip + "\n"
          assert_equal "000000\n", output2.strip + "\n"
        end

        # ===================
        # Error Cases
        # ===================

        def test_execute_with_invalid_time_returns_error
          _, err = capture_io do
            exit_code = EncodeCommand.execute("not-a-time")
            assert_equal 1, exit_code
          end

          assert_match(/Error.*Cannot parse time/i, err)
        end

        def test_execute_with_out_of_range_year_returns_error
          _, err = capture_io do
            exit_code = EncodeCommand.execute("1990-01-01 00:00:00 UTC", year_zero: 2000)
            assert_equal 1, exit_code
          end

          assert_match(/Error/i, err)
        end

        # ===================
        # Integration Tests
        # ===================

        def test_roundtrip_encoding
          original_time = "2025-06-15 14:30:45 UTC"

          encoded, = capture_io { EncodeCommand.execute(original_time) }
          encoded = encoded.strip

          decoded, = capture_io { DecodeCommand.execute(encoded) }

          # Decoded time should contain the same date
          assert_match(/2025-06-15/, decoded)
        end

        # ===================
        # Format Option Tests
        # ===================

        def test_encode_with_format_option
          time = "2025-06-15 14:30:45 UTC"

          # Test month format (2 chars)
          month_output, = capture_io { EncodeCommand.execute(time, format: :month) }
          assert_match(/\A[0-9a-z]{2}\n\z/, month_output)

          # Test day format (3 chars)
          day_output, = capture_io { EncodeCommand.execute(time, format: :day) }
          assert_match(/\A[0-9a-z]{3}\n\z/, day_output)

          # Test 40min format (4 chars)
          min40_output, = capture_io { EncodeCommand.execute(time, format: :"40min") }
          assert_match(/\A[0-9a-z]{4}\n\z/, min40_output)

          # Test 2sec format (6 chars)
          sec2_output, = capture_io { EncodeCommand.execute(time, format: :"2sec") }
          assert_match(/\A[0-9a-z]{6}\n\z/, sec2_output)

          # Test 50ms format (7 chars)
          ms50_output, = capture_io { EncodeCommand.execute(time, format: :"50ms") }
          assert_match(/\A[0-9a-z]{7}\n\z/, ms50_output)

          # Test ms format (8 chars)
          ms_output, = capture_io { EncodeCommand.execute(time, format: :ms) }
          assert_match(/\A[0-9a-z]{8}\n\z/, ms_output)
        end

        def test_encode_with_invalid_format_raises_error
          _, err = capture_io do
            exit_code = EncodeCommand.execute("2025-06-15 14:30:45 UTC", format: :invalid)
            assert_equal 1, exit_code
          end

          assert_match(/Error.*Invalid format/i, err)
        end

        def test_encode_respects_default_format_config
          # Pass default_format via options hash
          output, = capture_io { EncodeCommand.execute("2025-06-15 14:30:45 UTC", default_format: :day) }

          # Should produce 3-char output for day format
          assert_match(/\A[0-9a-z]{3}\n\z/, output)
        end
      end
    end
  end
  end
end
