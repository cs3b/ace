# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/molecules/filter_applier"

module Ace
  module Taskflow
    module Molecules
      class FilterApplierTest < Minitest::Test
        def setup
          @tasks = [
            {
              id: "v.0.9.0+task.001",
              status: "pending",
              priority: "high",
              team: "backend",
              dependencies: ["v.0.9.0+task.010"],
              metadata: {estimate: "2h"}
            },
            {
              id: "v.0.9.0+task.002",
              status: "in-progress",
              priority: "medium",
              team: "frontend",
              dependencies: [],
              metadata: {estimate: "4h"}
            },
            {
              id: "v.0.9.0+task.003",
              status: "done",
              priority: "high",
              team: "backend",
              dependencies: ["v.0.9.0+task.010", "v.0.9.0+task.020"],
              metadata: {estimate: "2h"}
            },
            {
              id: "v.0.9.0+task.004",
              status: "blocked",
              priority: "low",
              team: "backend",
              dependencies: [],
              metadata: {estimate: "1h"}
            }
          ]
        end

        # Simple Match Tests
        def test_apply_simple_filter
          filter_specs = [
            {key: "status", values: ["pending"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 1, result.length
          assert_equal "v.0.9.0+task.001", result[0][:id]
        end

        def test_apply_multiple_simple_filters_and_logic
          filter_specs = [
            {key: "status", values: ["pending"], negated: false, or_mode: false},
            {key: "priority", values: ["high"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 1, result.length
          assert_equal "v.0.9.0+task.001", result[0][:id]
        end

        def test_apply_no_match
          filter_specs = [
            {key: "status", values: ["archived"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 0, result.length
        end

        # OR Values Tests
        def test_apply_or_values_filter
          filter_specs = [
            {key: "status", values: ["pending", "in-progress"], negated: false, or_mode: true}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.002"
        end

        def test_apply_or_values_with_and_filter
          filter_specs = [
            {key: "status", values: ["pending", "done"], negated: false, or_mode: true},
            {key: "priority", values: ["high"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.003"
        end

        # Negation Tests
        def test_apply_negated_filter
          filter_specs = [
            {key: "status", values: ["done"], negated: true, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 3, result.length
          refute_includes result.map { |t| t[:id] }, "v.0.9.0+task.003"
        end

        def test_apply_negated_or_values
          filter_specs = [
            {key: "status", values: ["done", "blocked"], negated: true, or_mode: true}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.002"
        end

        def test_apply_multiple_negated_filters
          filter_specs = [
            {key: "status", values: ["done"], negated: true, or_mode: false},
            {key: "status", values: ["blocked"], negated: true, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.002"
        end

        # Array Matching Tests
        def test_apply_array_contains_filter
          filter_specs = [
            {key: "dependencies", values: ["v.0.9.0+task.010"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.003"
        end

        def test_apply_array_or_values
          filter_specs = [
            {key: "dependencies", values: ["v.0.9.0+task.010", "v.0.9.0+task.020"], negated: false, or_mode: true}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          # Tasks 001 and 003 both have task.010 in dependencies
          # Task 003 also has task.020
          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.003"
        end

        def test_apply_negated_array_filter
          filter_specs = [
            {key: "dependencies", values: ["v.0.9.0+task.010"], negated: true, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          # Tasks without task.010 in dependencies
          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.002"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.004"
        end

        def test_apply_empty_array_matching
          filter_specs = [
            {key: "dependencies", values: ["v.0.9.0+task.999"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 0, result.length
        end

        # Case Insensitivity Tests
        def test_apply_case_insensitive_match
          filter_specs = [
            {key: "status", values: ["PENDING"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 1, result.length
          assert_equal "v.0.9.0+task.001", result[0][:id]
        end

        def test_apply_mixed_case_or_values
          filter_specs = [
            {key: "status", values: ["PENDING", "In-Progress"], negated: false, or_mode: true}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 2, result.length
        end

        # Custom Field Tests
        def test_apply_custom_field_filter
          filter_specs = [
            {key: "team", values: ["backend"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          assert_equal 3, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.003"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.004"
        end

        def test_apply_metadata_field_filter
          filter_specs = [
            {key: "estimate", values: ["2h"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          # Items with estimate:2h in metadata
          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.003"
        end

        # Complex Combination Tests
        def test_apply_complex_multi_filter
          filter_specs = [
            {key: "status", values: ["pending", "done"], negated: false, or_mode: true},
            {key: "priority", values: ["high"], negated: false, or_mode: false},
            {key: "team", values: ["backend"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          # Should match: status in [pending, done] AND priority=high AND team=backend
          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.003"
        end

        def test_apply_complex_negation_combination
          filter_specs = [
            {key: "status", values: ["done"], negated: true, or_mode: false},
            {key: "status", values: ["blocked"], negated: true, or_mode: false},
            {key: "priority", values: ["low"], negated: true, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          # NOT done AND NOT blocked AND NOT low priority
          assert_equal 2, result.length
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.001"
          assert_includes result.map { |t| t[:id] }, "v.0.9.0+task.002"
        end

        # Edge Cases
        def test_apply_empty_filter_specs
          result = FilterApplier.apply(@tasks, [])
          assert_equal 4, result.length
        end

        def test_apply_nil_filter_specs
          result = FilterApplier.apply(@tasks, nil)
          assert_equal 4, result.length
        end

        def test_apply_empty_items
          filter_specs = [
            {key: "status", values: ["pending"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply([], filter_specs)
          assert_equal 0, result.length
        end

        def test_apply_nil_items
          filter_specs = [
            {key: "status", values: ["pending"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(nil, filter_specs)
          assert_equal 0, result.length
        end

        def test_apply_non_existent_field
          filter_specs = [
            {key: "nonexistent", values: ["value"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(@tasks, filter_specs)

          # No items have this field, so no matches
          assert_equal 0, result.length
        end

        def test_apply_nil_field_value
          tasks_with_nil = @tasks + [{id: "task.005", status: nil, priority: "high"}]

          filter_specs = [
            {key: "status", values: ["pending"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(tasks_with_nil, filter_specs)

          # Should not match task with nil status
          assert_equal 1, result.length
          assert_equal "v.0.9.0+task.001", result[0][:id]
        end

        # Symbol vs String Key Tests
        def test_apply_string_key_access
          tasks_with_string_keys = [
            {"status" => "pending", "priority" => "high"}
          ]

          filter_specs = [
            {key: "status", values: ["pending"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(tasks_with_string_keys, filter_specs)

          assert_equal 1, result.length
        end

        def test_apply_symbol_key_access
          tasks_with_symbol_keys = [
            {status: "pending", priority: "high"}
          ]

          filter_specs = [
            {key: "status", values: ["pending"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(tasks_with_symbol_keys, filter_specs)

          assert_equal 1, result.length
        end

        # Whitespace Handling
        def test_apply_handles_whitespace_in_values
          tasks_with_spaces = [
            {status: "  pending  ", priority: "high"}
          ]

          filter_specs = [
            {key: "status", values: ["pending"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(tasks_with_spaces, filter_specs)

          assert_equal 1, result.length
        end

        # Numeric Values
        def test_apply_numeric_values
          tasks_with_numbers = [
            {sprint: 12, estimate: "2h"},
            {sprint: 13, estimate: "4h"}
          ]

          filter_specs = [
            {key: "sprint", values: ["12"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(tasks_with_numbers, filter_specs)

          assert_equal 1, result.length
          assert_equal 12, result[0][:sprint]
        end

        # Boolean Values
        def test_apply_boolean_values
          tasks_with_booleans = [
            {archived: true, status: "done"},
            {archived: false, status: "pending"}
          ]

          filter_specs = [
            {key: "archived", values: ["true"], negated: false, or_mode: false}
          ]

          result = FilterApplier.apply(tasks_with_booleans, filter_specs)

          assert_equal 1, result.length
          assert_equal true, result[0][:archived]
        end
      end
    end
  end
end
