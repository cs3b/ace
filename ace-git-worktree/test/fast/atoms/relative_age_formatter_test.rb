# frozen_string_literal: true

require_relative "../../test_helper"

class RelativeAgeFormatterTest < Minitest::Test
  def format(seconds)
    Ace::Git::Worktree::Atoms::RelativeAgeFormatter.format(seconds)
  end

  def test_minutes
    assert_equal "0m", format(20)
    assert_equal "8m", format(8 * 60)
    assert_equal "59m", format((60 * 60) - 1)
  end

  def test_hours
    assert_equal "1h", format(60 * 60)
    assert_equal "3h", format((3 * 3600) + 120)
    assert_equal "23h", format((24 * 3600) - 1)
  end

  def test_days_before_two_weeks
    assert_equal "1d", format(24 * 3600)
    assert_equal "9d", format(9 * 24 * 3600)
    assert_equal "13d", format((14 * 24 * 3600) - 1)
  end

  def test_weeks
    assert_equal "2w", format(14 * 24 * 3600)
    assert_equal "3w", format(21 * 24 * 3600)
    assert_equal "8w", format((60 * 24 * 3600) - 1)
  end

  def test_months
    assert_equal "2mo", format(60 * 24 * 3600)
    assert_equal "12mo", format((365 * 24 * 3600) - 1)
  end

  def test_years
    assert_equal "1y", format(365 * 24 * 3600)
    assert_equal "3y", format(3 * 365 * 24 * 3600)
  end

  def test_never_for_missing_commit
    assert_equal "never", format(nil)
  end

  def test_future_clock_skew_renders_zero
    assert_equal "0m", format(-90)
  end
end
