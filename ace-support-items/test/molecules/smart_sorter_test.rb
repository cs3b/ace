# frozen_string_literal: true

require "test_helper"

class SmartSorterTest < AceSupportItemsTestCase
  SS = Ace::Support::Items::Molecules::SmartSorter

  Item = Struct.new(:name, :position, :score, keyword_init: true)

  def setup
    @pin_accessor = ->(item) { item.position }
    @score_fn = ->(item) { item.score }
  end

  def test_pinned_items_sort_before_unpinned
    items = [
      Item.new(name: "unpinned-high", position: nil, score: 999),
      Item.new(name: "pinned", position: "aaaaaa", score: 1)
    ]

    result = SS.sort(items, score_fn: @score_fn, pin_accessor: @pin_accessor)

    assert_equal "pinned", result[0].name
    assert_equal "unpinned-high", result[1].name
  end

  def test_pinned_items_sorted_by_position_ascending
    items = [
      Item.new(name: "pin-late", position: "zzzzzz", score: 0),
      Item.new(name: "pin-early", position: "aaaaaa", score: 0),
      Item.new(name: "pin-mid", position: "mmmmmm", score: 0)
    ]

    result = SS.sort(items, score_fn: @score_fn, pin_accessor: @pin_accessor)

    assert_equal %w[pin-early pin-mid pin-late], result.map(&:name)
  end

  def test_unpinned_items_sorted_by_score_descending
    items = [
      Item.new(name: "low", position: nil, score: 100),
      Item.new(name: "high", position: nil, score: 500),
      Item.new(name: "mid", position: nil, score: 300)
    ]

    result = SS.sort(items, score_fn: @score_fn, pin_accessor: @pin_accessor)

    assert_equal %w[high mid low], result.map(&:name)
  end

  def test_mixed_pinned_and_unpinned
    items = [
      Item.new(name: "unpinned-1", position: nil, score: 200),
      Item.new(name: "pinned-2", position: "bbbbbb", score: 50),
      Item.new(name: "unpinned-2", position: nil, score: 400),
      Item.new(name: "pinned-1", position: "aaaaaa", score: 10)
    ]

    result = SS.sort(items, score_fn: @score_fn, pin_accessor: @pin_accessor)

    assert_equal %w[pinned-1 pinned-2 unpinned-2 unpinned-1], result.map(&:name)
  end

  def test_empty_returns_empty
    assert_equal [], SS.sort([], score_fn: @score_fn, pin_accessor: @pin_accessor)
  end

  def test_nil_returns_empty
    assert_equal [], SS.sort(nil, score_fn: @score_fn, pin_accessor: @pin_accessor)
  end

  def test_empty_string_position_treated_as_unpinned
    items = [
      Item.new(name: "empty-pos", position: "", score: 100),
      Item.new(name: "pinned", position: "aaaaaa", score: 50)
    ]

    result = SS.sort(items, score_fn: @score_fn, pin_accessor: @pin_accessor)

    assert_equal "pinned", result[0].name
    assert_equal "empty-pos", result[1].name
  end

  def test_single_pinned_item
    items = [Item.new(name: "only", position: "aaaaaa", score: 0)]
    result = SS.sort(items, score_fn: @score_fn, pin_accessor: @pin_accessor)
    assert_equal ["only"], result.map(&:name)
  end

  def test_single_unpinned_item
    items = [Item.new(name: "only", position: nil, score: 100)]
    result = SS.sort(items, score_fn: @score_fn, pin_accessor: @pin_accessor)
    assert_equal ["only"], result.map(&:name)
  end

  def test_equal_scores_stable_relative_order
    items = [
      Item.new(name: "a", position: nil, score: 100),
      Item.new(name: "b", position: nil, score: 100)
    ]

    result = SS.sort(items, score_fn: @score_fn, pin_accessor: @pin_accessor)

    # sort_by is stable in Ruby, so original order preserved for equal scores
    assert_equal %w[a b], result.map(&:name)
  end
end
