# frozen_string_literal: true

require "test_helper"

class PriorityFilterTest < AceReviewTest
  # ============================================================================
  # parse Tests
  # ============================================================================

  def test_parse_exact_match_critical
    result = Ace::Review::Atoms::PriorityFilter.parse("critical")

    assert_equal({priority: "critical", inclusive: false}, result)
  end

  def test_parse_exact_match_high
    result = Ace::Review::Atoms::PriorityFilter.parse("high")

    assert_equal({priority: "high", inclusive: false}, result)
  end

  def test_parse_exact_match_medium
    result = Ace::Review::Atoms::PriorityFilter.parse("medium")

    assert_equal({priority: "medium", inclusive: false}, result)
  end

  def test_parse_exact_match_low
    result = Ace::Review::Atoms::PriorityFilter.parse("low")

    assert_equal({priority: "low", inclusive: false}, result)
  end

  def test_parse_range_match_critical_plus
    result = Ace::Review::Atoms::PriorityFilter.parse("critical+")

    assert_equal({priority: "critical", inclusive: true}, result)
  end

  def test_parse_range_match_high_plus
    result = Ace::Review::Atoms::PriorityFilter.parse("high+")

    assert_equal({priority: "high", inclusive: true}, result)
  end

  def test_parse_range_match_medium_plus
    result = Ace::Review::Atoms::PriorityFilter.parse("medium+")

    assert_equal({priority: "medium", inclusive: true}, result)
  end

  def test_parse_range_match_low_plus
    result = Ace::Review::Atoms::PriorityFilter.parse("low+")

    assert_equal({priority: "low", inclusive: true}, result)
  end

  def test_parse_invalid_priority
    assert_nil Ace::Review::Atoms::PriorityFilter.parse("urgent")
    assert_nil Ace::Review::Atoms::PriorityFilter.parse("normal")
    assert_nil Ace::Review::Atoms::PriorityFilter.parse("p1")
  end

  def test_parse_invalid_priority_with_plus
    assert_nil Ace::Review::Atoms::PriorityFilter.parse("urgent+")
    assert_nil Ace::Review::Atoms::PriorityFilter.parse("normal+")
  end

  def test_parse_nil_input
    assert_nil Ace::Review::Atoms::PriorityFilter.parse(nil)
  end

  def test_parse_empty_string
    assert_nil Ace::Review::Atoms::PriorityFilter.parse("")
  end

  # ============================================================================
  # matches? Exact Match Tests
  # ============================================================================

  def test_matches_exact_same_priority
    assert Ace::Review::Atoms::PriorityFilter.matches?("critical", "critical")
    assert Ace::Review::Atoms::PriorityFilter.matches?("high", "high")
    assert Ace::Review::Atoms::PriorityFilter.matches?("medium", "medium")
    assert Ace::Review::Atoms::PriorityFilter.matches?("low", "low")
  end

  def test_matches_exact_different_priority
    refute Ace::Review::Atoms::PriorityFilter.matches?("high", "critical")
    refute Ace::Review::Atoms::PriorityFilter.matches?("medium", "high")
    refute Ace::Review::Atoms::PriorityFilter.matches?("low", "medium")
    refute Ace::Review::Atoms::PriorityFilter.matches?("critical", "low")
  end

  # ============================================================================
  # matches? Range Match Tests
  # ============================================================================

  def test_matches_range_critical_plus
    # critical+ should only match critical
    assert Ace::Review::Atoms::PriorityFilter.matches?("critical", "critical+")
    refute Ace::Review::Atoms::PriorityFilter.matches?("high", "critical+")
    refute Ace::Review::Atoms::PriorityFilter.matches?("medium", "critical+")
    refute Ace::Review::Atoms::PriorityFilter.matches?("low", "critical+")
  end

  def test_matches_range_high_plus
    # high+ should match critical and high
    assert Ace::Review::Atoms::PriorityFilter.matches?("critical", "high+")
    assert Ace::Review::Atoms::PriorityFilter.matches?("high", "high+")
    refute Ace::Review::Atoms::PriorityFilter.matches?("medium", "high+")
    refute Ace::Review::Atoms::PriorityFilter.matches?("low", "high+")
  end

  def test_matches_range_medium_plus
    # medium+ should match critical, high, and medium
    assert Ace::Review::Atoms::PriorityFilter.matches?("critical", "medium+")
    assert Ace::Review::Atoms::PriorityFilter.matches?("high", "medium+")
    assert Ace::Review::Atoms::PriorityFilter.matches?("medium", "medium+")
    refute Ace::Review::Atoms::PriorityFilter.matches?("low", "medium+")
  end

  def test_matches_range_low_plus
    # low+ should match all priorities
    assert Ace::Review::Atoms::PriorityFilter.matches?("critical", "low+")
    assert Ace::Review::Atoms::PriorityFilter.matches?("high", "low+")
    assert Ace::Review::Atoms::PriorityFilter.matches?("medium", "low+")
    assert Ace::Review::Atoms::PriorityFilter.matches?("low", "low+")
  end

  # ============================================================================
  # matches? Edge Cases
  # ============================================================================

  def test_matches_nil_item_priority
    refute Ace::Review::Atoms::PriorityFilter.matches?(nil, "high")
    refute Ace::Review::Atoms::PriorityFilter.matches?(nil, "high+")
  end

  def test_matches_nil_filter_string
    refute Ace::Review::Atoms::PriorityFilter.matches?("high", nil)
  end

  def test_matches_invalid_filter_string
    refute Ace::Review::Atoms::PriorityFilter.matches?("high", "urgent")
    refute Ace::Review::Atoms::PriorityFilter.matches?("high", "urgent+")
  end

  def test_matches_unknown_item_priority
    refute Ace::Review::Atoms::PriorityFilter.matches?("urgent", "high")
    refute Ace::Review::Atoms::PriorityFilter.matches?("urgent", "high+")
  end

  # ============================================================================
  # PRIORITY_ORDER Tests
  # ============================================================================

  def test_priority_order_hierarchy
    order = Ace::Review::Atoms::PriorityFilter::PRIORITY_ORDER

    assert order["critical"] > order["high"]
    assert order["high"] > order["medium"]
    assert order["medium"] > order["low"]
  end

  def test_valid_priorities_constant
    expected = %w[critical high medium low]
    assert_equal expected, Ace::Review::Atoms::PriorityFilter::VALID_PRIORITIES
  end
end
