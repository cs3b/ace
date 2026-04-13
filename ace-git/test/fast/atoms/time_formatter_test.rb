# frozen_string_literal: true

require "test_helper"
require "ace/git/atoms/time_formatter"

class TimeFormatterTest < AceGitTestCase
  def test_relative_time_returns_just_now_for_recent
    now = Time.now
    result = Ace::Git::Atoms::TimeFormatter.relative_time(now, reference_time: now)
    assert_equal "just now", result
  end

  def test_relative_time_returns_minutes_ago
    now = Time.now
    timestamp = now - (5 * 60) # 5 minutes ago
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "5m ago", result
  end

  def test_relative_time_returns_hours_ago
    now = Time.now
    timestamp = now - (2 * 60 * 60) # 2 hours ago
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "2h ago", result
  end

  def test_relative_time_returns_days_ago
    now = Time.now
    timestamp = now - (3 * 24 * 60 * 60) # 3 days ago
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "3d ago", result
  end

  def test_relative_time_returns_weeks_ago
    now = Time.now
    timestamp = now - (2 * 7 * 24 * 60 * 60) # 2 weeks ago
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "2w ago", result
  end

  def test_relative_time_returns_months_ago
    now = Time.now
    # 60 days * 12 / 365 = ~1.97 months (rounds to 1mo)
    # Use 65 days for a solid 2mo result (65 * 12 / 365 = ~2.1)
    timestamp = now - (65 * 24 * 60 * 60) # ~2 months ago
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "2mo ago", result
  end

  def test_relative_time_returns_years_ago
    now = Time.now
    timestamp = now - (400 * 24 * 60 * 60) # ~1 year ago
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "1y ago", result
  end

  def test_relative_time_parses_iso8601_string
    now = Time.parse("2025-12-23T15:00:00Z")
    timestamp = "2025-12-23T13:00:00Z" # 2 hours ago
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "2h ago", result
  end

  def test_relative_time_returns_empty_for_nil
    result = Ace::Git::Atoms::TimeFormatter.relative_time(nil)
    assert_equal "", result
  end

  def test_relative_time_returns_empty_for_empty_string
    result = Ace::Git::Atoms::TimeFormatter.relative_time("")
    assert_equal "", result
  end

  def test_relative_time_returns_empty_for_invalid_timestamp
    result = Ace::Git::Atoms::TimeFormatter.relative_time("not a date")
    assert_equal "", result
  end

  def test_boundary_59_seconds_is_just_now
    now = Time.now
    timestamp = now - 59
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "just now", result
  end

  def test_boundary_60_seconds_is_1m_ago
    now = Time.now
    timestamp = now - 60
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "1m ago", result
  end

  def test_boundary_59_minutes_is_minutes
    now = Time.now
    timestamp = now - (59 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "59m ago", result
  end

  def test_boundary_60_minutes_is_1h
    now = Time.now
    timestamp = now - (60 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "1h ago", result
  end

  def test_boundary_23_hours_is_hours
    now = Time.now
    timestamp = now - (23 * 60 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "23h ago", result
  end

  def test_boundary_24_hours_is_1d
    now = Time.now
    timestamp = now - (24 * 60 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "1d ago", result
  end

  def test_boundary_364_days_is_11mo_not_0y
    # Regression test: 364 days should be "11mo ago", not "0y ago"
    # Using precise calculation: 364 * 12 / 365 = 11.96 (rounds to 11mo)
    now = Time.now
    timestamp = now - (364 * 24 * 60 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "11mo ago", result
  end

  def test_boundary_365_days_is_1y
    now = Time.now
    timestamp = now - (365 * 24 * 60 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "1y ago", result
  end

  def test_boundary_10_months_is_months
    # 10 months (~330 days) should be "10mo ago"
    # Precise: 330 * 12 / 365 = 10.8 (rounds to 10mo)
    now = Time.now
    timestamp = now - (330 * 24 * 60 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "10mo ago", result
  end

  def test_relative_time_handles_leap_year
    # Feb 29 in leap year to Mar 1 next year
    now = Time.parse("2024-03-01T00:00:00Z")
    timestamp = Time.parse("2023-02-28T00:00:00Z")
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    # 367 days = 1y ago
    assert_equal "1y ago", result
  end

  def test_relative_time_handles_future_timestamp
    # Future timestamps should return empty string
    now = Time.now
    timestamp = now + (60 * 60) # 1 hour in the future
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "", result
  end

  def test_boundary_30_days_is_1mo_not_0mo
    # Regression test: 30 days should be "1mo ago", not "0mo ago"
    # 30 * 12 / 365 = 0.986, floor = 0, but we want 1mo minimum
    now = Time.now
    timestamp = now - (30 * 24 * 60 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "1mo ago", result
  end

  def test_boundary_28_days_is_4w
    # 28 days (4 weeks) should be "4w ago", not months
    now = Time.now
    timestamp = now - (28 * 24 * 60 * 60)
    result = Ace::Git::Atoms::TimeFormatter.relative_time(timestamp, reference_time: now)
    assert_equal "4w ago", result
  end
end
