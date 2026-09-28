# frozen_string_literal: true

require "test_helper"

module Ace
  module Runtime
    module Atoms
      class NameSanitizerTest < AceRuntimeTestCase
        def test_deterministic_normalization
          assert_equal "my-window", NameSanitizer.call("my window")
          assert_equal "my-window", NameSanitizer.call("my window")
        end

        def test_unsafe_characters_collapse_to_dashes
          assert_equal "weird-name", NameSanitizer.call("weird!!!name??")
          assert_equal "a-b-c", NameSanitizer.call("a // b :: c")
        end

        def test_leading_and_trailing_dashes_are_stripped
          assert_equal "padded", NameSanitizer.call("--padded--")
        end

        def test_safe_names_pass_through
          assert_equal "work-fs", NameSanitizer.call("work-fs")
          assert_equal "Window_1", NameSanitizer.call("Window_1")
        end

        def test_empty_name_falls_back
          assert_equal "window", NameSanitizer.call("")
          assert_equal "window", NameSanitizer.call("!!!")
        end

        def test_custom_fallback_is_sanitized_too
          assert_equal "fork", NameSanitizer.call("", fallback: "fork")
          assert_equal "fork", NameSanitizer.call("", fallback: "fork!!")
          assert_equal "window", NameSanitizer.call("", fallback: "!!!")
        end

        def test_module_level_delegate
          assert_equal "shared", Ace::Runtime.sanitize_name("shared!!")
        end
      end
    end
  end
end
