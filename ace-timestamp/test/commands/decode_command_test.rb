# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Timestamp
    module Commands
      class DecodeCommandTest < Minitest::Test
        def setup
          Ace::Timestamp.reset_config!
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
          _, err = capture_io do
            exit_code = DecodeCommand.execute("abc")
            assert_equal 1, exit_code
          end

          assert_match(/Error/i, err)
        end

        def test_execute_with_invalid_characters_returns_error
          _, err = capture_io do
            exit_code = DecodeCommand.execute("ABC!!!")
            assert_equal 1, exit_code
          end

          assert_match(/Error/i, err)
        end

        def test_execute_with_empty_string_returns_error
          _, err = capture_io do
            exit_code = DecodeCommand.execute("")
            assert_equal 1, exit_code
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
      end
    end
  end
end
