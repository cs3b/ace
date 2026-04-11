# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module B36ts
    module Atoms
      class FormatSpecsTest < Minitest::Test
        # ===================
        # FORMATS Hash Tests
        # ===================

        def test_formats_contains_all_7_format_specs
          assert_equal 7, FormatSpecs::FORMATS.length
        end

        def test_formats_2sec_spec
          spec = FormatSpecs::FORMATS[:"2sec"]
          assert_equal :"2sec", spec.name
          assert_equal 6, spec.length
          assert_equal "~1.85s", spec.precision_desc
          assert_match spec.pattern, "abc123"
          assert_match spec.pattern, "000000"
          assert_match spec.pattern, "zzzzzz"
        end

        def test_formats_month_spec
          spec = FormatSpecs::FORMATS[:month]
          assert_equal :month, spec.name
          assert_equal 2, spec.length
          assert_equal "month", spec.precision_desc
          assert_match spec.pattern, "ab"
          assert_match spec.pattern, "00"
          assert_match spec.pattern, "zz"
        end

        def test_formats_week_spec
          spec = FormatSpecs::FORMATS[:week]
          assert_equal :week, spec.name
          assert_equal 3, spec.length
          assert_equal "week", spec.precision_desc
          assert_match spec.pattern, "abc"
          assert_match spec.pattern, "000"
          assert_match spec.pattern, "zzz"
        end

        def test_formats_day_spec
          spec = FormatSpecs::FORMATS[:day]
          assert_equal :day, spec.name
          assert_equal 3, spec.length
          assert_equal "day", spec.precision_desc
          assert_match spec.pattern, "abc"
          assert_match spec.pattern, "000"
          assert_match spec.pattern, "zzz"
        end

        def test_formats_40min_spec
          spec = FormatSpecs::FORMATS[:"40min"]
          assert_equal :"40min", spec.name
          assert_equal 4, spec.length
          assert_equal "40min", spec.precision_desc
          assert_match spec.pattern, "abcd"
          assert_match spec.pattern, "0000"
          assert_match spec.pattern, "zzzz"
        end

        def test_formats_50ms_spec
          spec = FormatSpecs::FORMATS[:"50ms"]
          assert_equal :"50ms", spec.name
          assert_equal 7, spec.length
          assert_equal "~50ms", spec.precision_desc
          assert_match spec.pattern, "abcdefg"
          assert_match spec.pattern, "0000000"
          assert_match spec.pattern, "zzzzzzz"
        end

        def test_formats_ms_spec
          spec = FormatSpecs::FORMATS[:ms]
          assert_equal :ms, spec.name
          assert_equal 8, spec.length
          assert_equal "~1.4ms", spec.precision_desc
          assert_match spec.pattern, "abcdefgh"
          assert_match spec.pattern, "00000000"
          assert_match spec.pattern, "zzzzzzzz"
        end

        # ===================
        # valid_format? Tests
        # ===================

        def test_valid_format_returns_true_for_valid_formats
          assert FormatSpecs.valid_format?(:"2sec")
          assert FormatSpecs.valid_format?(:month)
          assert FormatSpecs.valid_format?(:week)
          assert FormatSpecs.valid_format?(:day)
          assert FormatSpecs.valid_format?(:"40min")
          assert FormatSpecs.valid_format?(:"50ms")
          assert FormatSpecs.valid_format?(:ms)
        end

        def test_valid_format_returns_false_for_invalid_formats
          refute FormatSpecs.valid_format?(:invalid)
          refute FormatSpecs.valid_format?(:timestamp)
          refute FormatSpecs.valid_format?(:foo)
          refute FormatSpecs.valid_format?(nil)
        end

        # ===================
        # all_formats Tests
        # ===================

        def test_all_formats_returns_7_format_symbols
          formats = FormatSpecs.all_formats
          assert_equal 7, formats.length
          assert_includes formats, :"2sec"
          assert_includes formats, :month
          assert_includes formats, :week
          assert_includes formats, :day
          assert_includes formats, :"40min"
          assert_includes formats, :"50ms"
          assert_includes formats, :ms
        end

        # ===================
        # all_lengths Tests
        # ===================

        def test_all_lengths_returns_sorted_unique_lengths
          lengths = FormatSpecs.all_lengths
          assert_equal [2, 3, 4, 6, 7, 8], lengths
        end

        # ===================
        # Split Levels Tests
        # ===================

        def test_split_levels_constant
          assert_equal %i[month week day block], FormatSpecs::SPLIT_LEVELS
        end

        def test_valid_split_levels_accepts_supported_combinations
          assert FormatSpecs.valid_split_levels?([:month])
          assert FormatSpecs.valid_split_levels?([:month, :week])
          assert FormatSpecs.valid_split_levels?([:month, :day])
          assert FormatSpecs.valid_split_levels?([:month, :week, :day])
          assert FormatSpecs.valid_split_levels?([:month, :day, :block])
          assert FormatSpecs.valid_split_levels?([:month, :week, :day, :block])
        end

        def test_valid_split_levels_rejects_invalid_combinations
          refute FormatSpecs.valid_split_levels?([])
          refute FormatSpecs.valid_split_levels?([:day])
          refute FormatSpecs.valid_split_levels?([:week, :month])
          refute FormatSpecs.valid_split_levels?([:month, :block])
          refute FormatSpecs.valid_split_levels?([:month, :day, :week])
          refute FormatSpecs.valid_split_levels?([:month, :week, :day, :hour])
        end

        # ===================
        # get Tests
        # ===================

        def test_get_returns_correct_format_spec
          assert_equal :"2sec", FormatSpecs.get(:"2sec").name
          assert_equal :month, FormatSpecs.get(:month).name
          assert_equal :week, FormatSpecs.get(:week).name
          assert_equal :day, FormatSpecs.get(:day).name
          assert_equal :"40min", FormatSpecs.get(:"40min").name
          assert_equal :"50ms", FormatSpecs.get(:"50ms").name
          assert_equal :ms, FormatSpecs.get(:ms).name
        end

        def test_get_returns_nil_for_invalid_format
          assert_nil FormatSpecs.get(:invalid)
          assert_nil FormatSpecs.get(:foo)
          assert_nil FormatSpecs.get(nil)
        end

        # ===================
        # Day/Week Disambiguation Tests
        # ===================

        def test_day_format_max_constant
          assert_equal 30, FormatSpecs::DAY_FORMAT_MAX
        end

        def test_week_format_min_constant
          assert_equal 31, FormatSpecs::WEEK_FORMAT_MIN
        end

        def test_week_format_max_constant
          assert_equal 35, FormatSpecs::WEEK_FORMAT_MAX
        end

        # ===================
        # detect_from_id Tests
        # ===================

        def test_detect_from_id_returns_month_for_2_chars
          assert_equal :month, FormatSpecs.detect_from_id("00")
          assert_equal :month, FormatSpecs.detect_from_id("ab")
          assert_equal :month, FormatSpecs.detect_from_id("zz")
        end

        def test_detect_from_id_returns_day_for_3_chars_with_value_0_to_30
          # Third char '0' = value 0 (day 1)
          assert_equal :day, FormatSpecs.detect_from_id("000")
          # Third char 'u' = value 30 (day 31)
          assert_equal :day, FormatSpecs.detect_from_id("00u")
        end

        def test_detect_from_id_returns_week_for_3_chars_with_value_31_to_35
          # Third char 'v' = value 31 (week 1)
          assert_equal :week, FormatSpecs.detect_from_id("00v")
          # Third char 'z' = value 35 (week 5)
          assert_equal :week, FormatSpecs.detect_from_id("00z")
        end

        def test_detect_from_id_returns_nil_for_3_chars_with_value_over_35
          # Values 36+ don't exist in base36, but test edge case logic
          # Using alphabet that would produce values beyond 35
          custom_alphabet = "0123456789abcdefghijklmnopqrstuvwxyz{"
          assert_nil FormatSpecs.detect_from_id("00{", alphabet: custom_alphabet)
        end

        def test_detect_from_id_returns_40min_for_4_chars
          assert_equal :"40min", FormatSpecs.detect_from_id("0000")
          assert_equal :"40min", FormatSpecs.detect_from_id("abcd")
          assert_equal :"40min", FormatSpecs.detect_from_id("zzzz")
        end

        def test_detect_from_id_returns_2sec_for_6_chars
          assert_equal :"2sec", FormatSpecs.detect_from_id("000000")
          assert_equal :"2sec", FormatSpecs.detect_from_id("i50jj3")
          assert_equal :"2sec", FormatSpecs.detect_from_id("zzzzzz")
        end

        def test_detect_from_id_returns_50ms_for_7_chars
          assert_equal :"50ms", FormatSpecs.detect_from_id("0000000")
          assert_equal :"50ms", FormatSpecs.detect_from_id("abcdefg")
          assert_equal :"50ms", FormatSpecs.detect_from_id("zzzzzzz")
        end

        def test_detect_from_id_returns_ms_for_8_chars
          assert_equal :ms, FormatSpecs.detect_from_id("00000000")
          assert_equal :ms, FormatSpecs.detect_from_id("abcdefgh")
          assert_equal :ms, FormatSpecs.detect_from_id("zzzzzzzz")
        end

        def test_detect_from_id_returns_nil_for_unsupported_lengths
          assert_nil FormatSpecs.detect_from_id("")
          assert_nil FormatSpecs.detect_from_id("0")
          assert_nil FormatSpecs.detect_from_id("00000")     # 5 chars
          assert_nil FormatSpecs.detect_from_id("000000000") # 9 chars
          assert_nil FormatSpecs.detect_from_id("0" * 10)
        end

        def test_detect_from_id_returns_nil_for_nil
          assert_nil FormatSpecs.detect_from_id(nil)
        end

        def test_detect_from_id_returns_nil_for_empty_string
          assert_nil FormatSpecs.detect_from_id("")
        end

        def test_detect_from_id_case_insensitive
          assert_equal :month, FormatSpecs.detect_from_id("AB")
          assert_equal :day, FormatSpecs.detect_from_id("AB0")
          assert_equal :"40min", FormatSpecs.detect_from_id("ABCD")
          assert_equal :"2sec", FormatSpecs.detect_from_id("ABCDEF")
          assert_equal :"50ms", FormatSpecs.detect_from_id("ABCDEFG")
          assert_equal :ms, FormatSpecs.detect_from_id("ABCDEFGH")
        end

        def test_detect_from_id_with_custom_alphabet
          custom_alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
          assert_equal :month, FormatSpecs.detect_from_id("ab", alphabet: custom_alphabet)
          assert_equal :"2sec", FormatSpecs.detect_from_id("abcdef", alphabet: custom_alphabet)
        end

        # ===================
        # Day/Week Disambiguation Detail Tests
        # ===================

        def test_third_char_0_to_30_detects_as_day
          (0..30).each do |i|
            char = CompactIdEncoder::DEFAULT_ALPHABET[i]
            id = "00#{char}"
            assert_equal :day, FormatSpecs.detect_from_id(id), "Value #{i} (char '#{char}') should detect as :day"
          end
        end

        def test_third_char_31_to_35_detects_as_week
          (31..35).each do |i|
            char = CompactIdEncoder::DEFAULT_ALPHABET[i]
            id = "00#{char}"
            assert_equal :week, FormatSpecs.detect_from_id(id), "Value #{i} (char '#{char}') should detect as :week"
          end
        end

        def test_disambiguation_boundary_values
          # Value 30 = 'u' -> day format (day 31)
          assert_equal :day, FormatSpecs.detect_from_id("00u")

          # Value 31 = 'v' -> week format (week 1)
          assert_equal :week, FormatSpecs.detect_from_id("00v")

          # Value 35 = 'z' -> week format (week 5)
          assert_equal :week, FormatSpecs.detect_from_id("00z")
        end

        # ===================
        # Invalid Character Tests
        # ===================

        def test_detect_from_id_returns_nil_for_invalid_characters
          # Non-base36 characters should return nil
          assert_nil FormatSpecs.detect_from_id("0!")
          assert_nil FormatSpecs.detect_from_id("0#")
          assert_nil FormatSpecs.detect_from_id("0@")
          assert_nil FormatSpecs.detect_from_id("00$")
          assert_nil FormatSpecs.detect_from_id("00 ")
        end

        def test_detect_from_id_returns_nil_for_whitespace_characters
          assert_nil FormatSpecs.detect_from_id("0\n")
          assert_nil FormatSpecs.detect_from_id("0\t")
          assert_nil FormatSpecs.detect_from_id("0\r")
          assert_nil FormatSpecs.detect_from_id("00\n0")
        end

        def test_detect_from_id_returns_nil_for_unicode_characters
          assert_nil FormatSpecs.detect_from_id("0é")
          assert_nil FormatSpecs.detect_from_id("00€")
          assert_nil FormatSpecs.detect_from_id("日本")
        end
      end
    end
  end
end
