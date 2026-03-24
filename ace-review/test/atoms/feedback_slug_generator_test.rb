# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Atoms
      class FeedbackSlugGeneratorTest < AceReviewTest
        def setup
          super
          @generator = FeedbackSlugGenerator
        end

        # Basic functionality tests

        def test_basic_slug_generation
          result = @generator.generate("Missing error handling")

          assert_equal "missing-error-handling", result
        end

        def test_converts_to_lowercase
          result = @generator.generate("Missing ERROR Handling")

          assert_equal "missing-error-handling", result
        end

        def test_replaces_spaces_with_hyphens
          result = @generator.generate("fix bug in module")

          assert_equal "fix-bug-in-module", result
        end

        def test_replaces_underscores_with_hyphens
          result = @generator.generate("fix_bug_in_module")

          assert_equal "fix-bug-in-module", result
        end

        # Special character handling

        def test_removes_special_characters
          result = @generator.generate("Add try/catch block (urgent!)")

          assert_equal "add-trycatch-block-urgent", result
        end

        def test_removes_punctuation
          result = @generator.generate("Fix: the bug, please!")

          assert_equal "fix-the-bug-please", result
        end

        def test_collapses_consecutive_hyphens
          result = @generator.generate("foo---bar")

          assert_equal "foo-bar", result
        end

        def test_removes_leading_hyphen
          result = @generator.generate("-fix bug")

          assert_equal "fix-bug", result
        end

        def test_removes_trailing_hyphen
          result = @generator.generate("fix bug-")

          assert_equal "fix-bug", result
        end

        def test_removes_both_leading_and_trailing_hyphens
          result = @generator.generate("-fix bug-")

          assert_equal "fix-bug", result
        end

        def test_handles_multiple_leading_special_chars
          result = @generator.generate("!!!fix bug")

          assert_equal "fix-bug", result
        end

        # Unicode handling

        def test_handles_accented_characters
          result = @generator.generate("Fix bug in cafe module")

          assert_equal "fix-bug-in-cafe-module", result
        end

        def test_handles_unicode_with_combining_marks
          # e followed by combining acute accent
          result = @generator.generate("cafe\u0301")

          assert_equal "cafe", result
        end

        def test_strips_non_ascii_characters
          result = @generator.generate("Fix bug in \u201cmodule\u201d")

          assert_equal "fix-bug-in-module", result
        end

        def test_handles_emoji
          result = @generator.generate("Fix bug")

          assert_equal "fix-bug", result
        end

        # Length truncation tests

        def test_default_max_length_is_40
          long_title = "a" * 50
          result = @generator.generate(long_title)

          assert_equal 40, result.length
        end

        def test_custom_max_length
          result = @generator.generate("abcdefghij", max_length: 5)

          assert_equal "abcde", result
        end

        def test_preserves_short_slugs
          result = @generator.generate("short", max_length: 100)

          assert_equal "short", result
        end

        def test_removes_trailing_hyphen_after_truncation
          # "missing-error-handling" at 15 chars would be "missing-error-h"
          # truncated at 14 should not end with hyphen
          result = @generator.generate("missing-error-handling", max_length: 14)

          refute result.end_with?("-")
          assert_equal "missing-error", result
        end

        def test_truncation_at_word_boundary
          result = @generator.generate("fix the critical bug now", max_length: 16)

          # Should truncate without trailing hyphen
          assert result.length <= 16
          refute result.end_with?("-")
        end

        # Edge case: empty/nil input

        def test_handles_nil_input
          result = @generator.generate(nil)

          assert_equal "", result
        end

        def test_handles_empty_string
          result = @generator.generate("")

          assert_equal "", result
        end

        def test_handles_whitespace_only
          result = @generator.generate("   ")

          assert_equal "", result
        end

        # Edge case: all special characters

        def test_handles_all_special_chars
          result = @generator.generate("@#$%^&*()")

          assert_equal "", result
        end

        def test_handles_only_numbers
          result = @generator.generate("12345")

          assert_equal "12345", result
        end

        # Real-world title examples

        def test_typical_feedback_title
          result = @generator.generate("Missing null check in user validation")

          assert_equal "missing-null-check-in-user-validation", result
        end

        def test_feedback_title_with_code_reference
          result = @generator.generate("Fix TypeError in UserHandler.process()")

          assert_equal "fix-typeerror-in-userhandlerprocess", result
        end

        def test_feedback_title_with_file_reference
          result = @generator.generate("Update src/handlers/user.rb:42")

          assert_equal "update-srchandlersuserrb42", result
        end

        def test_long_descriptive_title
          title = "Critical security vulnerability in authentication flow requires immediate attention"
          result = @generator.generate(title)

          assert result.length <= 40
          # The exact truncation depends on where characters fall
          assert_match(/\Acritical-security-vulnerability-in/, result)
          refute result.end_with?("-")
        end

        # Comparison with existing SlugGenerator

        def test_feedback_slug_vs_model_slug_similarity
          # Both should produce similar lowercase, hyphenated results
          model_name = "google:gemini-2.5-flash"
          feedback_title = "google gemini 2.5 flash"

          model_slug = SlugGenerator.generate(model_name)
          feedback_slug = @generator.generate(feedback_title)

          # Both should be lowercase and hyphenated
          assert_match(/\A[a-z0-9-]+\z/, model_slug)
          assert_match(/\A[a-z0-9-]+\z/, feedback_slug)
        end
      end
    end
  end
end
