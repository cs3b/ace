# frozen_string_literal: true

require "test_helper"
require "ace/review/atoms/task_auto_detector"

module Ace
  module Review
    module Atoms
      class TaskAutoDetectorTest < Minitest::Test
        def test_extract_from_standard_branch
          # Standard branch format: 121-feature
          result = TaskAutoDetector.extract_from_branch("121-feature")
          assert_equal "121", result
        end

        def test_extract_from_subtask_branch
          # Subtask format: 121.01-subtask
          result = TaskAutoDetector.extract_from_branch("121.01-subtask")
          assert_equal "121.01", result
        end

        def test_extract_from_branch_with_multiple_dashes
          # Branch with multiple dashes: 117-add-new-feature
          result = TaskAutoDetector.extract_from_branch("117-add-new-feature")
          assert_equal "117", result
        end

        def test_no_match_for_main_branch
          # Main branch should not match
          result = TaskAutoDetector.extract_from_branch("main")
          assert_nil result
        end

        def test_no_match_for_feature_first
          # Number not at start should not match
          result = TaskAutoDetector.extract_from_branch("feature-123")
          assert_nil result
        end

        def test_no_match_for_detached_head
          # Detached HEAD state should not match
          result = TaskAutoDetector.extract_from_branch("HEAD")
          assert_nil result
        end

        def test_nil_branch_name
          # Nil input should return nil
          result = TaskAutoDetector.extract_from_branch(nil)
          assert_nil result
        end

        def test_empty_branch_name
          # Empty input should return nil
          result = TaskAutoDetector.extract_from_branch("")
          assert_nil result
        end

        def test_custom_pattern_feature_slash
          # Custom pattern: feature/123-name
          patterns = ['^feature/(\d+)-']
          result = TaskAutoDetector.extract_from_branch("feature/123-name", patterns: patterns)
          assert_equal "123", result
        end

        def test_custom_pattern_bugfix_slash
          # Custom pattern: bugfix/456-description
          patterns = ['^bugfix/(\d+)-']
          result = TaskAutoDetector.extract_from_branch("bugfix/456-description", patterns: patterns)
          assert_equal "456", result
        end

        def test_multiple_patterns_first_match
          # Multiple patterns: use first match
          patterns = ['^feature/(\d+)-', '^(\d+)-']
          result = TaskAutoDetector.extract_from_branch("feature/123-name", patterns: patterns)
          assert_equal "123", result
        end

        def test_multiple_patterns_second_match
          # Multiple patterns: fallback to second if first doesn't match
          patterns = ['^feature/(\d+)-', '^(\d+)-']
          result = TaskAutoDetector.extract_from_branch("121-feature", patterns: patterns)
          assert_equal "121", result
        end

        def test_leading_zero_preserved
          # Leading zeros should be preserved: 042-answer
          result = TaskAutoDetector.extract_from_branch("042-answer-everything")
          assert_equal "042", result
        end

        def test_invalid_regex_pattern_skipped_with_warning
          # Invalid regex pattern should be skipped with warning
          patterns = ['[invalid(', '^(\d+)-']
          _output = capture_io do
            result = TaskAutoDetector.extract_from_branch("121-feature", patterns: patterns)
            assert_equal "121", result
          end
        end

        def test_invalid_regex_pattern_emits_warning
          # Invalid regex should emit a warning message
          patterns = ['[invalid(']
          output = capture_io do
            TaskAutoDetector.extract_from_branch("121-feature", patterns: patterns)
          end
          assert_match(/Warning: Invalid auto_save_branch_pattern/, output[1])
          assert_match(/\[invalid\(/, output[1])
        end

        def test_all_invalid_patterns_returns_nil
          # All invalid patterns should return nil (no crash)
          patterns = ['[invalid(', '???']
          result = nil
          capture_io do
            result = TaskAutoDetector.extract_from_branch("121-feature", patterns: patterns)
          end
          assert_nil result
        end
      end
    end
  end
end
