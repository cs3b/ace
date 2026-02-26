# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        class ArgvCoalescerTest < Minitest::Test
          TASK_FLAGS = { "--task" => ["-t"] }.freeze

          # Single flag, no repeat → passthrough

          def test_single_flag_passes_through
            result = ArgvCoalescer.call(["--task", "288"], flags: TASK_FLAGS)
            assert_equal ["--task", "288"], result
          end

          # Repeated long flags coalesced

          def test_repeated_long_flags_coalesced
            result = ArgvCoalescer.call(
              ["--task", "288", "--task", "287"],
              flags: TASK_FLAGS
            )
            assert_equal ["--task", "288,287"], result
          end

          # Mixed long and short flags coalesced

          def test_mixed_long_short_flags_coalesced
            result = ArgvCoalescer.call(
              ["--task", "288", "-t", "287"],
              flags: TASK_FLAGS
            )
            assert_equal ["--task", "288,287"], result
          end

          # --flag=value form

          def test_equals_form_coalesced
            result = ArgvCoalescer.call(
              ["--task=288", "--task=287"],
              flags: TASK_FLAGS
            )
            assert_equal ["--task", "288,287"], result
          end

          def test_mixed_equals_and_space_form
            result = ArgvCoalescer.call(
              ["--task=288", "--task", "287"],
              flags: TASK_FLAGS
            )
            assert_equal ["--task", "288,287"], result
          end

          # Boolean flags between array flags preserved

          def test_boolean_flags_between_array_flags
            result = ArgvCoalescer.call(
              ["--task", "288", "--quiet", "--task", "287"],
              flags: TASK_FLAGS
            )
            assert_equal ["--quiet", "--task", "288,287"], result
          end

          # No matching flags → passthrough

          def test_no_matching_flags_passthrough
            result = ArgvCoalescer.call(
              ["--preset", "work-on-tasks", "--quiet"],
              flags: TASK_FLAGS
            )
            assert_equal ["--preset", "work-on-tasks", "--quiet"], result
          end

          # Empty argv → empty

          def test_empty_argv_returns_empty
            result = ArgvCoalescer.call([], flags: TASK_FLAGS)
            assert_equal [], result
          end

          # Multiple different flag specs coalesced independently

          def test_multiple_flag_specs_coalesced_independently
            flags = { "--task" => ["-t"], "--model" => ["-m"] }
            result = ArgvCoalescer.call(
              ["--task", "288", "--model", "gpt-4", "--task", "287", "--model", "claude"],
              flags: flags
            )
            assert_includes result, "--task"
            assert_includes result, "--model"

            task_idx = result.index("--task")
            model_idx = result.index("--model")
            assert_equal "288,287", result[task_idx + 1]
            assert_equal "gpt-4,claude", result[model_idx + 1]
          end

          # Non-flag arguments preserved in order

          def test_non_flag_arguments_preserved
            result = ArgvCoalescer.call(
              ["work-on", "--task", "288", "--task", "287"],
              flags: TASK_FLAGS
            )
            assert_equal "work-on", result[0]
            assert_includes result, "--task"
            task_idx = result.index("--task")
            assert_equal "288,287", result[task_idx + 1]
          end

          # Custom separator

          def test_custom_separator
            result = ArgvCoalescer.call(
              ["--task", "288", "--task", "287"],
              flags: TASK_FLAGS,
              separator: ";"
            )
            assert_equal ["--task", "288;287"], result
          end

          # Already comma-separated value preserved

          def test_already_comma_separated_preserved
            result = ArgvCoalescer.call(
              ["--task", "288,287"],
              flags: TASK_FLAGS
            )
            assert_equal ["--task", "288,287"], result
          end

          # Three repeated flags

          def test_three_repeated_flags
            result = ArgvCoalescer.call(
              ["--task", "288", "--task", "287", "--task", "286"],
              flags: TASK_FLAGS
            )
            assert_equal ["--task", "288,287,286"], result
          end

          # Short flag only

          def test_short_flag_only
            result = ArgvCoalescer.call(
              ["-t", "288", "-t", "287"],
              flags: TASK_FLAGS
            )
            # Short flags coalesce to canonical long form
            assert_equal ["--task", "288,287"], result
          end
        end
      end
    end
  end
end
