# frozen_string_literal: true

require "test_helper"

class ItemSorterTest < AceSupportItemsTestCase
  IS = Ace::Support::Items::Molecules::ItemSorter

  def setup
    @items = [
      {id: "c", priority: 3, title: "Charlie"},
      {id: "a", priority: 1, title: "Alice"},
      {id: "b", priority: 2, title: "Bob"}
    ]
  end

  def test_sort_ascending
    result = IS.sort(@items, field: :priority)

    assert_equal [1, 2, 3], result.map { |i| i[:priority] }
  end

  def test_sort_descending
    result = IS.sort(@items, field: :priority, direction: :desc)

    assert_equal [3, 2, 1], result.map { |i| i[:priority] }
  end

  def test_sort_by_string_field
    result = IS.sort(@items, field: :title)

    assert_equal %w[Alice Bob Charlie], result.map { |i| i[:title] }
  end

  def test_sort_nil_values_last_ascending
    items = @items + [{id: "d", priority: nil, title: "Dave"}]
    result = IS.sort(items, field: :priority)

    assert_equal [1, 2, 3], result[0..2].map { |i| i[:priority] }
    assert_nil result.last[:priority]
  end

  def test_sort_nil_values_last_descending
    items = @items + [{id: "d", priority: nil, title: "Dave"}]
    result = IS.sort(items, field: :priority, direction: :desc)

    assert_equal [3, 2, 1], result[0..2].map { |i| i[:priority] }
    assert_nil result.last[:priority]
  end

  def test_sort_empty_returns_empty
    assert_equal [], IS.sort([], field: :priority)
  end

  def test_sort_nil_returns_empty
    assert_equal [], IS.sort(nil, field: :priority)
  end

  def test_sort_with_string_key
    result = IS.sort(@items, field: "priority")

    assert_equal [1, 2, 3], result.map { |i| i[:priority] }
  end

  def test_sort_with_custom_accessor
    items = [
      OpenStruct.new(name: "Charlie", rank: 3),
      OpenStruct.new(name: "Alice", rank: 1),
      OpenStruct.new(name: "Bob", rank: 2)
    ]
    accessor = ->(item, key) { item.send(key.to_sym) }

    result = IS.sort(items, field: :rank, value_accessor: accessor)

    assert_equal %w[Alice Bob Charlie], result.map(&:name)
  end
end
