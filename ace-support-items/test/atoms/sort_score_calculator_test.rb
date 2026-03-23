# frozen_string_literal: true

require "test_helper"

class SortScoreCalculatorTest < AceSupportItemsTestCase
  SSC = Ace::Support::Items::Atoms::SortScoreCalculator

  def test_basic_score_formula
    # priority_weight × 100 + age_days
    assert_equal 310.0, SSC.compute(priority_weight: 3, age_days: 10)
  end

  def test_medium_priority_30_days
    assert_equal 230.0, SSC.compute(priority_weight: 2, age_days: 30)
  end

  def test_age_capped_at_90
    assert_equal 490.0, SSC.compute(priority_weight: 4, age_days: 200)
    assert_equal 490.0, SSC.compute(priority_weight: 4, age_days: 90)
  end

  def test_custom_age_cap
    assert_equal 150.0, SSC.compute(priority_weight: 1, age_days: 100, age_cap: 50)
  end

  def test_in_progress_boost
    score = SSC.compute(priority_weight: 3, age_days: 10, status: "in-progress")
    assert_equal 1310.0, score
  end

  def test_blocked_penalty
    score = SSC.compute(priority_weight: 4, age_days: 5, status: "blocked")
    assert_in_delta 40.5, score, 0.001
  end

  def test_custom_boost_and_factor
    score = SSC.compute(priority_weight: 2, age_days: 10, status: "in-progress",
      in_progress_boost: 500)
    assert_equal 710.0, score

    score = SSC.compute(priority_weight: 2, age_days: 10, status: "blocked",
      blocked_factor: 0.5)
    assert_equal 105.0, score
  end

  def test_nil_status_no_modifier
    assert_equal 310.0, SSC.compute(priority_weight: 3, age_days: 10, status: nil)
  end

  def test_unknown_status_no_modifier
    assert_equal 310.0, SSC.compute(priority_weight: 3, age_days: 10, status: "pending")
  end

  def test_zero_weight_and_age
    assert_equal 0.0, SSC.compute(priority_weight: 0, age_days: 0)
  end

  # priority_weight helper
  def test_priority_weight_lookup
    assert_equal 4, SSC.priority_weight("critical")
    assert_equal 3, SSC.priority_weight("high")
    assert_equal 2, SSC.priority_weight("medium")
    assert_equal 1, SSC.priority_weight("low")
  end

  def test_priority_weight_nil_returns_zero
    assert_equal 0, SSC.priority_weight(nil)
  end

  def test_priority_weight_unknown_returns_zero
    assert_equal 0, SSC.priority_weight("urgent")
  end

  def test_priority_weight_case_insensitive
    assert_equal 3, SSC.priority_weight("HIGH")
    assert_equal 4, SSC.priority_weight("Critical")
  end

  def test_priority_weight_custom_weights
    custom = {"p0" => 10, "p1" => 5}
    assert_equal 10, SSC.priority_weight("p0", weights: custom)
    assert_equal 0, SSC.priority_weight("high", weights: custom)
  end
end
