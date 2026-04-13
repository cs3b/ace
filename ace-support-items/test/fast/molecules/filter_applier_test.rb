# frozen_string_literal: true

require "test_helper"

class FilterApplierTest < AceSupportItemsTestCase
  FA = Ace::Support::Items::Molecules::FilterApplier

  def setup
    @items = [
      {id: "item.001", status: "pending", priority: "high", team: "backend", tags: ["ux"], metadata: {estimate: "2h"}},
      {id: "item.002", status: "in-progress", priority: "medium", team: "frontend", tags: [], metadata: {estimate: "4h"}},
      {id: "item.003", status: "done", priority: "high", team: "backend", tags: ["ux", "design"], metadata: {estimate: "2h"}},
      {id: "item.004", status: "blocked", priority: "low", team: "backend", tags: ["backend"], metadata: {estimate: "1h"}}
    ]
  end

  # --- Simple matching ---

  def test_apply_simple_filter
    specs = [{key: "status", values: ["pending"], negated: false, or_mode: false}]
    result = FA.apply(@items, specs)

    assert_equal 1, result.length
    assert_equal "item.001", result[0][:id]
  end

  def test_apply_multiple_filters_and_logic
    specs = [
      {key: "status", values: ["pending"], negated: false, or_mode: false},
      {key: "priority", values: ["high"], negated: false, or_mode: false}
    ]
    result = FA.apply(@items, specs)

    assert_equal 1, result.length
    assert_equal "item.001", result[0][:id]
  end

  def test_apply_no_match
    specs = [{key: "status", values: ["archived"], negated: false, or_mode: false}]
    assert_equal 0, FA.apply(@items, specs).length
  end

  # --- OR values ---

  def test_apply_or_values
    specs = [{key: "status", values: ["pending", "in-progress"], negated: false, or_mode: true}]
    result = FA.apply(@items, specs)

    assert_equal 2, result.length
    ids = result.map { |i| i[:id] }
    assert_includes ids, "item.001"
    assert_includes ids, "item.002"
  end

  # --- Negation ---

  def test_apply_negated_filter
    specs = [{key: "status", values: ["done"], negated: true, or_mode: false}]
    result = FA.apply(@items, specs)

    assert_equal 3, result.length
    refute_includes result.map { |i| i[:id] }, "item.003"
  end

  def test_apply_negated_or_values
    specs = [{key: "status", values: ["done", "blocked"], negated: true, or_mode: true}]
    result = FA.apply(@items, specs)

    assert_equal 2, result.length
    ids = result.map { |i| i[:id] }
    assert_includes ids, "item.001"
    assert_includes ids, "item.002"
  end

  # --- Array matching ---

  def test_apply_array_contains
    specs = [{key: "tags", values: ["ux"], negated: false, or_mode: false}]
    result = FA.apply(@items, specs)

    assert_equal 2, result.length
    ids = result.map { |i| i[:id] }
    assert_includes ids, "item.001"
    assert_includes ids, "item.003"
  end

  def test_apply_array_or_values
    specs = [{key: "tags", values: ["ux", "backend"], negated: false, or_mode: true}]
    result = FA.apply(@items, specs)

    assert_equal 3, result.length
  end

  def test_apply_negated_array
    specs = [{key: "tags", values: ["ux"], negated: true, or_mode: false}]
    result = FA.apply(@items, specs)

    assert_equal 2, result.length
    ids = result.map { |i| i[:id] }
    assert_includes ids, "item.002"
    assert_includes ids, "item.004"
  end

  # --- Case insensitivity ---

  def test_apply_case_insensitive
    specs = [{key: "status", values: ["PENDING"], negated: false, or_mode: false}]
    assert_equal 1, FA.apply(@items, specs).length
  end

  # --- Edge cases ---

  def test_apply_empty_specs_returns_all
    assert_equal 4, FA.apply(@items, []).length
  end

  def test_apply_nil_specs_returns_all
    assert_equal 4, FA.apply(@items, nil).length
  end

  def test_apply_empty_items
    specs = [{key: "status", values: ["pending"], negated: false, or_mode: false}]
    assert_equal 0, FA.apply([], specs).length
  end

  def test_apply_nil_items
    specs = [{key: "status", values: ["pending"], negated: false, or_mode: false}]
    assert_equal 0, FA.apply(nil, specs).length
  end

  def test_apply_non_existent_field
    specs = [{key: "nonexistent", values: ["val"], negated: false, or_mode: false}]
    assert_equal 0, FA.apply(@items, specs).length
  end

  # --- String vs symbol keys ---

  def test_apply_string_key_access
    items = [{"status" => "pending", "priority" => "high"}]
    specs = [{key: "status", values: ["pending"], negated: false, or_mode: false}]

    assert_equal 1, FA.apply(items, specs).length
  end

  # --- Metadata access ---

  def test_apply_metadata_field
    specs = [{key: "estimate", values: ["2h"], negated: false, or_mode: false}]
    result = FA.apply(@items, specs)

    assert_equal 2, result.length
  end

  # --- Custom value accessor ---

  def test_apply_with_custom_accessor
    items = [
      OpenStruct.new(name: "Alice", role: "dev"),
      OpenStruct.new(name: "Bob", role: "pm")
    ]
    specs = [{key: "role", values: ["dev"], negated: false, or_mode: false}]
    accessor = ->(item, key) { item.send(key.to_sym) }

    result = FA.apply(items, specs, value_accessor: accessor)

    assert_equal 1, result.length
    assert_equal "Alice", result[0].name
  end

  # --- Whitespace handling ---

  def test_apply_handles_whitespace_in_values
    items = [{status: "  pending  "}]
    specs = [{key: "status", values: ["pending"], negated: false, or_mode: false}]

    assert_equal 1, FA.apply(items, specs).length
  end

  # --- Numeric and boolean values ---

  def test_apply_numeric_values
    items = [{sprint: 12}, {sprint: 13}]
    specs = [{key: "sprint", values: ["12"], negated: false, or_mode: false}]

    assert_equal 1, FA.apply(items, specs).length
  end

  def test_apply_boolean_values
    items = [{archived: true}, {archived: false}]
    specs = [{key: "archived", values: ["true"], negated: false, or_mode: false}]

    assert_equal 1, FA.apply(items, specs).length
  end
end
