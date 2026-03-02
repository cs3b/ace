# frozen_string_literal: true

require "test_helper"

class ItemStatisticsTest < AceSupportItemsTestCase
  Item = Struct.new(:status, :priority, keyword_init: true)

  def test_count_by_groups_by_field
    items = [
      Item.new(status: "pending"),
      Item.new(status: "done"),
      Item.new(status: "pending"),
      Item.new(status: "done"),
      Item.new(status: "done")
    ]

    stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(items, :status)

    assert_equal 5, stats[:total]
    assert_equal 2, stats[:by_field]["pending"]
    assert_equal 3, stats[:by_field]["done"]
  end

  def test_count_by_with_single_status
    items = [Item.new(status: "pending"), Item.new(status: "pending")]

    stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(items, :status)

    assert_equal 2, stats[:total]
    assert_equal 2, stats[:by_field]["pending"]
  end

  def test_count_by_empty_list
    stats = Ace::Support::Items::Atoms::ItemStatistics.count_by([], :status)

    assert_equal 0, stats[:total]
    assert_equal({}, stats[:by_field])
  end

  def test_count_by_different_field
    items = [
      Item.new(priority: "high"),
      Item.new(priority: "low"),
      Item.new(priority: "high")
    ]

    stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(items, :priority)

    assert_equal 3, stats[:total]
    assert_equal 2, stats[:by_field]["high"]
    assert_equal 1, stats[:by_field]["low"]
  end

  def test_count_by_converts_nil_to_string
    items = [Item.new(status: nil)]

    stats = Ace::Support::Items::Atoms::ItemStatistics.count_by(items, :status)

    assert_equal 1, stats[:total]
    assert_equal 1, stats[:by_field][""]
  end

  def test_completion_rate_basic
    stats = { total: 10, by_field: { "done" => 5, "pending" => 5 } }

    rate = Ace::Support::Items::Atoms::ItemStatistics.completion_rate(stats)

    assert_equal 50, rate
  end

  def test_completion_rate_all_done
    stats = { total: 3, by_field: { "done" => 3 } }

    rate = Ace::Support::Items::Atoms::ItemStatistics.completion_rate(stats)

    assert_equal 100, rate
  end

  def test_completion_rate_none_done
    stats = { total: 4, by_field: { "pending" => 4 } }

    rate = Ace::Support::Items::Atoms::ItemStatistics.completion_rate(stats)

    assert_equal 0, rate
  end

  def test_completion_rate_empty
    stats = { total: 0, by_field: {} }

    rate = Ace::Support::Items::Atoms::ItemStatistics.completion_rate(stats)

    assert_equal 0, rate
  end

  def test_completion_rate_rounds
    stats = { total: 3, by_field: { "done" => 1, "pending" => 2 } }

    rate = Ace::Support::Items::Atoms::ItemStatistics.completion_rate(stats)

    assert_equal 33, rate
  end

  def test_completion_rate_custom_done_values
    stats = { total: 6, by_field: { "done" => 2, "cancelled" => 1, "pending" => 3 } }

    rate = Ace::Support::Items::Atoms::ItemStatistics.completion_rate(
      stats, done_values: ["done", "cancelled"]
    )

    assert_equal 50, rate
  end
end
