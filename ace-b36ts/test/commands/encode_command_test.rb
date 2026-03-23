# frozen_string_literal: true

require "json"
require_relative "../test_helper"

module Ace
  module B36ts
    module Commands
      class EncodeCommandTest < Minitest::Test
        def setup
          Ace::B36ts.reset_config!
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
            assert_raises(ArgumentError) do
              EncodeCommand.execute("not-a-time")
            end
          end

          assert_match(/Error.*Cannot parse time/i, err)
        end

        def test_execute_with_out_of_range_year_returns_error
          _, err = capture_io do
            assert_raises(ArgumentError) do
              EncodeCommand.execute("1990-01-01 00:00:00 UTC", year_zero: 2000)
            end
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
            assert_raises(ArgumentError) do
              EncodeCommand.execute("2025-06-15 14:30:45 UTC", format: :invalid)
            end
          end

          assert_match(/Error.*Invalid format/i, err)
        end

        def test_encode_with_split_outputs_key_values
          output, = capture_io do
            exit_code = EncodeCommand.execute("2025-01-06 12:30:00 UTC", split: "month,week,day")
            assert_equal 0, exit_code
          end

          assert_match(/month:/, output)
          assert_match(/week:/, output)
          assert_match(/day:/, output)
          assert_match(/rest:/, output)
          assert_match(/path:/, output)
          assert_match(/full:/, output)
        end

        def test_encode_with_split_path_only
          output, = capture_io do
            exit_code = EncodeCommand.execute("2025-01-06 12:30:00 UTC", split: "month,week", path_only: true)
            assert_equal 0, exit_code
          end

          assert_match(/\A[0-9a-z\/]+\n\z/, output)
          refute_match(/month:/, output)
        end

        def test_encode_with_split_json
          output, = capture_io do
            exit_code = EncodeCommand.execute("2025-01-06 12:30:00 UTC", split: "month,day", json: true)
            assert_equal 0, exit_code
          end

          parsed = JSON.parse(output)
          assert parsed.key?("month")
          assert parsed.key?("day")
          assert parsed.key?("rest")
          assert parsed.key?("path")
          assert parsed.key?("full")
        end

        def test_encode_with_split_and_format_returns_error
          _, err = capture_io do
            assert_raises(ArgumentError) do
              EncodeCommand.execute("2025-01-06 12:30:00 UTC", split: "month", format: :day)
            end
          end

          assert_match(/split and --format are mutually exclusive/i, err)
        end

        def test_encode_respects_default_format_config
          # Pass default_format via options hash
          output, = capture_io { EncodeCommand.execute("2025-06-15 14:30:45 UTC", default_format: :day) }

          # Should produce 3-char output for day format
          assert_match(/\A[0-9a-z]{3}\n\z/, output)
        end

        # ===================
        # Count Option Tests
        # ===================

        def test_encode_with_count_outputs_multiple_ids
          output, = capture_io do
            exit_code = EncodeCommand.execute("2025-01-06 12:30:00 UTC", count: 5)
            assert_equal 0, exit_code
          end

          lines = output.strip.split("\n")
          assert_equal 5, lines.length
          lines.each { |line| assert_match(/\A[0-9a-z]{6}\z/, line) }
        end

        def test_encode_with_count_and_format
          output, = capture_io do
            exit_code = EncodeCommand.execute("2025-01-06 12:30:00 UTC", count: 3, format: :ms)
            assert_equal 0, exit_code
          end

          lines = output.strip.split("\n")
          assert_equal 3, lines.length
          lines.each { |line| assert_match(/\A[0-9a-z]{8}\z/, line) }
        end

        def test_encode_with_count_and_json
          output, = capture_io do
            exit_code = EncodeCommand.execute("2025-01-06 12:30:00 UTC", count: 4, json: true)
            assert_equal 0, exit_code
          end

          parsed = JSON.parse(output)
          assert_instance_of Array, parsed
          assert_equal 4, parsed.length
          parsed.each { |id| assert_match(/\A[0-9a-z]{6}\z/, id) }
        end

        def test_encode_with_count_1_outputs_single_id
          output, = capture_io do
            exit_code = EncodeCommand.execute("2025-01-06 12:30:00 UTC", count: 1)
            assert_equal 0, exit_code
          end

          lines = output.strip.split("\n")
          assert_equal 1, lines.length
          assert_match(/\A[0-9a-z]{6}\z/, lines.first)
        end

        def test_encode_with_count_ids_are_sequential
          output, = capture_io do
            EncodeCommand.execute("2025-01-06 12:30:00 UTC", count: 10, format: :ms)
          end

          lines = output.strip.split("\n")
          lines.each_cons(2) do |prev, curr|
            assert_operator prev, :<, curr, "IDs should be strictly increasing"
          end
        end

        def test_encode_with_count_and_split_returns_error
          _, err = capture_io do
            assert_raises(ArgumentError) do
              EncodeCommand.execute("2025-01-06 12:30:00 UTC", count: 5, split: "month,day")
            end
          end

          assert_match(/count and --split are mutually exclusive/i, err)
        end

        def test_encode_with_count_zero_returns_error
          _, err = capture_io do
            assert_raises(ArgumentError) do
              EncodeCommand.execute("2025-01-06 12:30:00 UTC", count: 0)
            end
          end

          assert_match(/count must be greater than 0/i, err)
        end

        def test_encode_with_negative_count_returns_error
          _, err = capture_io do
            assert_raises(ArgumentError) do
              EncodeCommand.execute("2025-01-06 12:30:00 UTC", count: -1)
            end
          end

          assert_match(/count must be greater than 0/i, err)
        end
      end
    end
  end
end
