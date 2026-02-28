# frozen_string_literal: true

require "test_helper"

class SlugSanitizerTest < AceSupportItemsTestCase
  def test_sanitizes_simple_string
    assert_equal "my-topic-slug", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("My Topic-Slug")
  end

  def test_removes_path_traversal_characters
    # Dots and slashes are all stripped (no separator injected between path components)
    assert_equal "etcpasswd", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("../../etc/passwd")
  end

  def test_returns_empty_for_only_dots
    assert_equal "", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("../")
  end

  def test_returns_empty_for_nil
    assert_equal "", Ace::Support::Items::Atoms::SlugSanitizer.sanitize(nil)
  end

  def test_returns_empty_for_empty_string
    assert_equal "", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("")
  end

  def test_lowercases_input
    assert_equal "hello-world", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("Hello World")
  end

  def test_replaces_special_chars_with_hyphens
    assert_equal "hello-world", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("hello@world!")
  end

  def test_collapses_multiple_hyphens
    assert_equal "hello-world", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("hello---world")
  end

  def test_trims_leading_trailing_hyphens
    assert_equal "hello", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("-hello-")
  end

  def test_preserves_numbers
    assert_equal "idea-123", Ace::Support::Items::Atoms::SlugSanitizer.sanitize("idea-123")
  end
end
