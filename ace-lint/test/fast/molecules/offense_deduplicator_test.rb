# frozen_string_literal: true

require "test_helper"

module Ace
  module Lint
    module Molecules
      class OffenseDeduplicatorTest < Minitest::Test
        def test_deduplicate_empty_array
          assert_equal [], OffenseDeduplicator.deduplicate([])
        end

        def test_deduplicate_single_offense
          offenses = [
            {file: "test.rb", line: 10, column: 5, message: "Use string literals"}
          ]

          result = OffenseDeduplicator.deduplicate(offenses)
          assert_equal 1, result.length
          assert_equal "test.rb", result.first[:file]
        end

        def test_deduplicate_by_location_and_message
          offenses = [
            {file: "test.rb", line: 10, column: 5, message: "Use string literals"},
            {file: "test.rb", line: 10, column: 5, message: "Use string literals"},
            {file: "test.rb", line: 10, column: 5, message: "Use STRING literals"}
          ]

          result = OffenseDeduplicator.deduplicate(offenses)
          assert_equal 1, result.length
        end

        def test_keeps_more_detailed_message
          # When offenses have the same normalized message (same location + message),
          # the one with the longer original message is kept (more detailed cop name)
          offenses = [
            {file: "test.rb", line: 10, column: 5, message: "use string literals"},
            {file: "test.rb", line: 10, column: 5, message: "Style/StringLiterals: use string literals"}
          ]

          result = OffenseDeduplicator.deduplicate(offenses)
          assert_equal 1, result.length
          # Should keep the longer, more detailed message (with cop name)
          assert result.first[:message].length > 20
        end

        def test_different_locations_not_deduplicated
          offenses = [
            {file: "test.rb", line: 10, column: 5, message: "Use string literals"},
            {file: "test.rb", line: 20, column: 5, message: "Use string literals"}
          ]

          result = OffenseDeduplicator.deduplicate(offenses)
          assert_equal 2, result.length
        end

        def test_normalizes_cop_names
          offenses = [
            {file: "test.rb", line: 10, column: 5, message: "Style/StringLiterals: Use string literals"},
            {file: "test.rb", line: 10, column: 5, message: "Layout/TrailingWhitespace: Use string literals"}
          ]

          result = OffenseDeduplicator.deduplicate(offenses)
          # After removing cop names and normalizing, these have the same message
          assert_equal 1, result.length
        end

        def test_normalizes_case_and_whitespace
          offenses = [
            {file: "test.rb", line: 10, column: 5, message: "Use  STRING  literals"},
            {file: "test.rb", line: 10, column: 5, message: "USE STRING LITERALS"}
          ]

          result = OffenseDeduplicator.deduplicate(offenses)
          assert_equal 1, result.length
        end

        def test_handles_various_cop_name_formats
          offenses = [
            {file: "test.rb", line: 10, column: 5, message: "Style/StringLiterals: Use string literals"},
            {file: "test.rb", line: 10, column: 5, message: "Style/StringLiterals - Use string literals"},
            {file: "test.rb", line: 10, column: 5, message: "Style-StringLiterals: Use string literals"}
          ]

          result = OffenseDeduplicator.deduplicate(offenses)
          # All should be deduplicated as the same offense
          assert_equal 1, result.length
        end

        def test_handles_nil_values
          offenses = [
            {file: nil, line: nil, column: nil, message: "Some error"}
          ]

          result = OffenseDeduplicator.deduplicate(offenses)
          assert_equal 1, result.length
        end
      end
    end
  end
end
