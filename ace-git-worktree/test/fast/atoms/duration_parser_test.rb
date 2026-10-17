# frozen_string_literal: true

require_relative "../../test_helper"

class DurationParserTest < Minitest::Test
  def parse(value)
    Ace::Git::Worktree::Atoms::DurationParser.parse(value)
  end

  def test_minutes
    assert_in_delta 0.5, parse("30m")[:hours], 0.0001
    assert_equal "30m", parse("30m")[:label]
  end

  def test_hours
    assert_in_delta 18.0, parse("18h")[:hours], 0.0001
    assert_equal "18h", parse("18h")[:label]
  end

  def test_days
    assert_in_delta 48.0, parse("2d")[:hours], 0.0001
    assert_equal "2d", parse("2d")[:label]
  end

  def test_bare_integer_is_hours
    assert_in_delta 5.0, parse("5")[:hours], 0.0001
    assert_equal "5h", parse("5")[:label]
  end

  def test_ninety_minutes_boundary
    assert_in_delta 1.5, parse("90m")[:hours], 0.0001
    assert_equal "90m", parse("90m")[:label]
  end

  def test_no_upper_bound
    assert_in_delta 999 * 24.0, parse("999d")[:hours], 0.0001
  end

  def test_default_is_18h
    assert_equal({hours: 18.0, label: "18h"}, Ace::Git::Worktree::Atoms::DurationParser.default)
  end

  def test_whitespace_is_tolerated
    assert_in_delta 18.0, parse(" 18h ") [:hours], 0.0001
  end

  def test_invalid_values_raise_actionable_error
    ["abc", "", "  ", "0", "0h", "0m", "-3h", "1.5h", "h", "18H", "18 h"].each do |value|
      error = assert_raises(ArgumentError, "expected #{value.inspect} to be invalid") { parse(value) }
      assert_match(/invalid duration/, error.message)
      assert_match(/30m, 18h, 2d, or bare hours/, error.message)
    end
  end
end
