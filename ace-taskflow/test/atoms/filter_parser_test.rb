# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/atoms/filter_parser"

module Ace
  module Taskflow
    module Atoms
      class FilterParserTest < Minitest::Test
        # Simple Match Tests
        def test_parse_simple_filter
          result = FilterParser.parse(["status:pending"])

          assert_equal 1, result.length
          assert_equal "status", result[0][:key]
          assert_equal ["pending"], result[0][:values]
          assert_equal false, result[0][:negated]
          assert_equal false, result[0][:or_mode]
        end

        def test_parse_multiple_simple_filters
          result = FilterParser.parse(["status:pending", "priority:high"])

          assert_equal 2, result.length
          assert_equal "status", result[0][:key]
          assert_equal ["pending"], result[0][:values]
          assert_equal "priority", result[1][:key]
          assert_equal ["high"], result[1][:values]
        end

        # OR Values Tests
        def test_parse_or_values
          result = FilterParser.parse(["status:pending|in-progress"])

          assert_equal 1, result.length
          assert_equal "status", result[0][:key]
          assert_equal ["pending", "in-progress"], result[0][:values]
          assert_equal false, result[0][:negated]
          assert_equal true, result[0][:or_mode]
        end

        def test_parse_multiple_or_values
          result = FilterParser.parse(["status:pending|in-progress|blocked"])

          assert_equal 1, result.length
          assert_equal ["pending", "in-progress", "blocked"], result[0][:values]
          assert_equal true, result[0][:or_mode]
        end

        # Negation Tests
        def test_parse_negated_filter
          result = FilterParser.parse(["status:!done"])

          assert_equal 1, result.length
          assert_equal "status", result[0][:key]
          assert_equal ["done"], result[0][:values]
          assert_equal true, result[0][:negated]
          assert_equal false, result[0][:or_mode]
        end

        def test_parse_negated_or_values
          result = FilterParser.parse(["status:!done|blocked"])

          assert_equal 1, result.length
          assert_equal ["done", "blocked"], result[0][:values]
          assert_equal true, result[0][:negated]
          assert_equal true, result[0][:or_mode]
        end

        # Whitespace Handling Tests
        def test_parse_with_whitespace
          result = FilterParser.parse(["  status  :  pending  "])

          assert_equal 1, result.length
          assert_equal "status", result[0][:key]
          assert_equal ["pending"], result[0][:values]
        end

        def test_parse_or_values_with_whitespace
          result = FilterParser.parse(["status: pending | in-progress | blocked "])

          assert_equal 1, result.length
          assert_equal ["pending", "in-progress", "blocked"], result[0][:values]
        end

        # Complex Combinations
        def test_parse_complex_combination
          result = FilterParser.parse([
            "status:pending|in-progress",
            "priority:!low",
            "team:backend"
          ])

          assert_equal 3, result.length

          # First filter: OR values
          assert_equal "status", result[0][:key]
          assert_equal ["pending", "in-progress"], result[0][:values]
          assert_equal true, result[0][:or_mode]

          # Second filter: Negated
          assert_equal "priority", result[1][:key]
          assert_equal ["low"], result[1][:values]
          assert_equal true, result[1][:negated]

          # Third filter: Simple
          assert_equal "team", result[2][:key]
          assert_equal ["backend"], result[2][:values]
        end

        # Edge Cases - Custom Fields
        def test_parse_custom_frontmatter_fields
          result = FilterParser.parse(["sprint:12", "team:backend"])

          assert_equal 2, result.length
          assert_equal "sprint", result[0][:key]
          assert_equal ["12"], result[0][:values]
          assert_equal "team", result[1][:key]
          assert_equal ["backend"], result[1][:values]
        end

        def test_parse_dependency_array_matching
          result = FilterParser.parse(["dependencies:v.0.9.0+task.081"])

          assert_equal 1, result.length
          assert_equal "dependencies", result[0][:key]
          assert_equal ["v.0.9.0+task.081"], result[0][:values]
        end

        def test_parse_value_with_colon
          result = FilterParser.parse(["title:API: Review"])

          assert_equal 1, result.length
          assert_equal "title", result[0][:key]
          # Should split on first colon only, rest is the value
          assert_equal ["API: Review"], result[0][:values]
        end

        # Error Handling Tests
        def test_parse_empty_array
          result = FilterParser.parse([])
          assert_equal [], result
        end

        def test_parse_nil
          result = FilterParser.parse(nil)
          assert_equal [], result
        end

        def test_parse_missing_colon
          error = assert_raises(ArgumentError) do
            FilterParser.parse(["status"])
          end
          assert_match(/Invalid filter syntax.*Use: --filter key:value/, error.message)
        end

        def test_parse_empty_key
          error = assert_raises(ArgumentError) do
            FilterParser.parse([":pending"])
          end
          assert_match(/missing key/, error.message)
        end

        def test_parse_empty_value
          error = assert_raises(ArgumentError) do
            FilterParser.parse(["status:"])
          end
          assert_match(/missing value/, error.message)
        end

        def test_parse_only_negation
          error = assert_raises(ArgumentError) do
            FilterParser.parse(["status:!"])
          end
          assert_match(/empty value after negation/, error.message)
        end

        def test_parse_only_whitespace_in_value
          error = assert_raises(ArgumentError) do
            FilterParser.parse(["status:   "])
          end
          assert_match(/missing value/, error.message)
        end

        def test_parse_only_pipes_in_value
          error = assert_raises(ArgumentError) do
            FilterParser.parse(["status:|||"])
          end
          assert_match(/no valid values/, error.message)
        end

        # Special Characters
        def test_parse_value_with_special_characters
          result = FilterParser.parse(["description:Task: API 'review'"])

          assert_equal 1, result.length
          assert_equal "description", result[0][:key]
          assert_equal ["Task: API 'review'"], result[0][:values]
        end

        def test_parse_numeric_values
          result = FilterParser.parse(["estimate:2h", "sprint:12"])

          assert_equal 2, result.length
          assert_equal ["2h"], result[0][:values]
          assert_equal ["12"], result[1][:values]
        end

        # Case Sensitivity - Parser preserves case, applier handles it
        def test_parse_preserves_case
          result = FilterParser.parse(["status:PENDING"])

          assert_equal 1, result.length
          # Parser preserves the case as-is
          assert_equal ["PENDING"], result[0][:values]
        end
      end
    end
  end
end
