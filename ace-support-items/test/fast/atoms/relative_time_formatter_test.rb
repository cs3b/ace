# frozen_string_literal: true

require "test_helper"

class RelativeTimeFormatterTest < AceSupportItemsTestCase
  Formatter = Ace::Support::Items::Atoms::RelativeTimeFormatter

  def test_nil_returns_unknown
    assert_equal "unknown", Formatter.format(nil)
  end

  def test_non_time_returns_unknown
    assert_equal "unknown", Formatter.format("not a time")
  end

  def test_just_now
    now = Time.now
    assert_equal "just now", Formatter.format(now - 30, reference: now)
  end

  def test_minutes_ago
    now = Time.now
    assert_equal "5m ago", Formatter.format(now - 300, reference: now)
  end

  def test_hours_ago
    now = Time.now
    assert_equal "2h ago", Formatter.format(now - 7200, reference: now)
  end

  def test_days_ago
    now = Time.now
    assert_equal "3d ago", Formatter.format(now - (3 * 86_400), reference: now)
  end

  def test_weeks_ago
    now = Time.now
    assert_equal "2w ago", Formatter.format(now - (14 * 86_400), reference: now)
  end

  def test_months_ago
    now = Time.now
    assert_equal "2mo ago", Formatter.format(now - (60 * 86_400), reference: now)
  end

  def test_years_ago
    now = Time.now
    assert_equal "1y ago", Formatter.format(now - (400 * 86_400), reference: now)
  end

  def test_boundary_59_seconds_is_just_now
    now = Time.now
    assert_equal "just now", Formatter.format(now - 59, reference: now)
  end

  def test_boundary_60_seconds_is_1m_ago
    now = Time.now
    assert_equal "1m ago", Formatter.format(now - 60, reference: now)
  end

  def test_boundary_6_days_is_days
    now = Time.now
    assert_equal "6d ago", Formatter.format(now - (6 * 86_400), reference: now)
  end

  def test_boundary_7_days_is_weeks
    now = Time.now
    assert_equal "1w ago", Formatter.format(now - (7 * 86_400), reference: now)
  end
end
