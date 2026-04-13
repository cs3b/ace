# frozen_string_literal: true

require_relative "../../test_helper"

class DemoNameSanitizerTest < AceDemoTestCase
  def test_downcases_and_slugifies
    assert_equal "my-demo", sanitize("My Demo")
  end

  def test_replaces_slashes
    assert_equal "my-demo-evil", sanitize("My Demo/evil")
  end

  def test_strips_special_characters
    assert_equal "hello-world", sanitize("hello@world!")
  end

  def test_collapses_consecutive_dashes
    assert_equal "a-b", sanitize("a---b")
  end

  def test_strips_leading_and_trailing_dashes
    assert_equal "hello", sanitize("--hello--")
  end

  def test_returns_demo_for_empty_string
    assert_equal "demo", sanitize("")
  end

  def test_returns_demo_for_all_special_characters
    assert_equal "demo", sanitize("@#$%^&*()")
  end

  def test_removes_path_traversal
    assert_equal "etc-passwd", sanitize("../etc/passwd")
  end

  def test_truncates_to_max_length
    long_name = "a" * 100
    result = sanitize(long_name)
    assert result.length <= Ace::Demo::Atoms::DemoNameSanitizer::MAX_LENGTH
  end

  def test_truncation_does_not_leave_trailing_dash
    name = "a" * 54 + "-b"
    result = sanitize(name)
    refute result.end_with?("-")
  end

  private

  def sanitize(name)
    Ace::Demo::Atoms::DemoNameSanitizer.sanitize(name)
  end
end
