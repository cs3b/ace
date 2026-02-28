# frozen_string_literal: true

require "test_helper"

class DatePartitionPathTest < AceSupportItemsTestCase
  def test_returns_month_week_path
    # Use a fixed time so result is deterministic
    time = Time.utc(2026, 2, 28, 12, 0, 0)
    result = Ace::Support::Items::Atoms::DatePartitionPath.compute(time)
    # Result should be two slash-separated components (month/week)
    parts = result.split("/")
    assert_equal 2, parts.size, "Expected 2 components in #{result.inspect}"
    parts.each do |part|
      refute part.empty?, "Expected non-empty component in #{result.inspect}"
    end
  end

  def test_different_times_may_yield_same_month
    t1 = Time.utc(2026, 2, 1, 0, 0, 0)
    t2 = Time.utc(2026, 2, 28, 23, 59, 59)
    r1 = Ace::Support::Items::Atoms::DatePartitionPath.compute(t1)
    r2 = Ace::Support::Items::Atoms::DatePartitionPath.compute(t2)
    # Both share the same month prefix
    assert_equal r1.split("/").first, r2.split("/").first
  end

  def test_different_months_yield_different_paths
    t1 = Time.utc(2026, 1, 15, 0, 0, 0)
    t2 = Time.utc(2026, 2, 15, 0, 0, 0)
    r1 = Ace::Support::Items::Atoms::DatePartitionPath.compute(t1)
    r2 = Ace::Support::Items::Atoms::DatePartitionPath.compute(t2)
    refute_equal r1, r2
  end

  def test_custom_levels_month_only
    time = Time.utc(2026, 2, 28, 12, 0, 0)
    result = Ace::Support::Items::Atoms::DatePartitionPath.compute(time, levels: [:month])
    refute_includes result, "/"
    refute result.empty?
  end
end
