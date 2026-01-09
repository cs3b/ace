# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/atoms/slug_sanitizer"

module Ace
  module Taskflow
    module Atoms
      class SlugSanitizerTest < Minitest::Test
        def setup
          @sanitizer = SlugSanitizer
        end

        # Test basic slug sanitization
        def test_sanitize_basic_slug
          result = @sanitizer.sanitize("my-topic-slug")
          assert_equal "my-topic-slug", result
        end

        def test_sanitize_with_spaces
          result = @sanitizer.sanitize("My Topic Slug")
          assert_equal "my-topic-slug", result
        end

        def test_sanitize_with_uppercase
          result = @sanitizer.sanitize("MyTopicSlug")
          assert_equal "mytopicslug", result
        end

        def test_sanitize_with_special_chars
          result = @sanitizer.sanitize("my@topic#slug!")
          assert_equal "my-topic-slug", result
        end

        # Security: Path traversal tests
        def test_sanitize_path_traversal_dots
          result = @sanitizer.sanitize("../../etc/passwd")
          assert_equal "etcpasswd", result
          # Dots are removed, path traversal prevented
          refute_includes result, "."
          refute_includes result, ".."
          refute_includes result, "/"
        end

        def test_sanitize_path_traversal_forward_slash
          result = @sanitizer.sanitize("../../secret/file")
          assert_equal "secretfile", result
          refute_includes result, "/"
        end

        def test_sanitize_path_traversal_backslash
          result = @sanitizer.sanitize("..\\..\\windows\\system32")
          assert_equal "windowssystem32", result
          refute_includes result, "\\"
        end

        def test_sanitize_mixed_path_separators
          result = @sanitizer.sanitize("../../..\\etc/passwd")
          # All path traversal chars removed
          refute_includes result, "."
          refute_includes result, "/"
          refute_includes result, "\\"
        end

        def test_sanitize_only_dots_returns_empty
          result = @sanitizer.sanitize("...")
          assert_equal "", result
        end

        def test_sanitize_only_slashes_returns_empty
          result = @sanitizer.sanitize("///")
          assert_equal "", result
        end

        def test_sanitize_only_path_traversal_returns_empty
          result = @sanitizer.sanitize("../")
          assert_equal "", result
        end

        def test_sanitize_complex_path_traversal
          result = @sanitizer.sanitize("../../../etc/passwd")
          # Should not contain any path components
          refute_includes result, "."
          refute_includes result, "/"
          assert_equal "etcpasswd", result
        end

        # Edge cases: Empty and nil input
        def test_sanitize_nil_returns_empty
          result = @sanitizer.sanitize(nil)
          assert_equal "", result
        end

        def test_sanitize_empty_string_returns_empty
          result = @sanitizer.sanitize("")
          assert_equal "", result
        end

        def test_sanitize_whitespace_only_returns_empty
          result = @sanitizer.sanitize("   ")
          assert_equal "", result
        end

        # Hyphen handling
        def test_sanitize_collapses_multiple_hyphens
          result = @sanitizer.sanitize("my---topic---slug")
          assert_equal "my-topic-slug", result
        end

        def test_sanitize_trims_leading_hyphens
          result = @sanitizer.sanitize("-my-slug")
          assert_equal "my-slug", result
        end

        def test_sanitize_trims_trailing_hyphens
          result = @sanitizer.sanitize("my-slug-")
          assert_equal "my-slug", result
        end

        def test_sanitize_trims_both_leading_and_trailing_hyphens
          result = @sanitizer.sanitize("-my-slug-")
          assert_equal "my-slug", result
        end

        # Real-world examples
        def test_sanitize_real_world_idea_title
          result = @sanitizer.sanitize("Add Feature: User Authentication")
          assert_equal "add-feature-user-authentication", result
        end

        def test_sanitize_real_world_with_numbers
          result = @sanitizer.sanitize("Task 123: Fix Bug")
          assert_equal "task-123-fix-bug", result
        end

        def test_sanitize_real_world_underscores
          result = @sanitizer.sanitize("my_idea_slug")
          assert_equal "my-idea-slug", result
        end

        # Ensure consistent behavior across multiple calls
        def test_sanitize_is_idempotent
          first = @sanitizer.sanitize("My Idea Slug")
          second = @sanitizer.sanitize(first)
          assert_equal first, second
        end
      end
    end
  end
end
