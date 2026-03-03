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

  def test_truncates_at_word_boundary
    long_title = "position ace as an ade while planning repository naming updates"
    result = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(long_title, max_length: 40)
    assert result.length <= 40
    refute result.end_with?("-")
    assert_equal "position-ace-as-an-ade-while-planning", result
  end

  def test_respects_custom_max_length
    result = Ace::Support::Items::Atoms::SlugSanitizer.sanitize("one two three four five six", max_length: 15)
    assert result.length <= 15
    assert_equal "one-two-three", result
  end

  def test_default_max_length_is_55
    long_slug = "a" + "-word" * 20 # way longer than 55
    result = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(long_slug)
    assert result.length <= 55
  end

  def test_short_slug_unchanged_by_max_length
    result = Ace::Support::Items::Atoms::SlugSanitizer.sanitize("short-slug", max_length: 55)
    assert_equal "short-slug", result
  end

  def test_truncate_with_no_hyphens_uses_hard_cut
    # A single long word with no hyphens falls back to hard truncation
    result = Ace::Support::Items::Atoms::SlugSanitizer.sanitize("abcdefghijklmnop", max_length: 10)
    assert_equal "abcdefghij", result
  end
end
