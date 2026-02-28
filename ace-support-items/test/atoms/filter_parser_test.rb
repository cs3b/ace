# frozen_string_literal: true

require "test_helper"

class FilterParserTest < AceSupportItemsTestCase
  FP = Ace::Support::Items::Atoms::FilterParser

  def test_parse_simple_filter
    result = FP.parse(["status:pending"])

    assert_equal 1, result.length
    assert_equal "status", result[0][:key]
    assert_equal ["pending"], result[0][:values]
    assert_equal false, result[0][:negated]
    assert_equal false, result[0][:or_mode]
  end

  def test_parse_multiple_simple_filters
    result = FP.parse(["status:pending", "priority:high"])

    assert_equal 2, result.length
    assert_equal "status", result[0][:key]
    assert_equal "priority", result[1][:key]
  end

  def test_parse_or_values
    result = FP.parse(["status:pending|in-progress"])

    assert_equal 1, result.length
    assert_equal ["pending", "in-progress"], result[0][:values]
    assert_equal true, result[0][:or_mode]
  end

  def test_parse_multiple_or_values
    result = FP.parse(["status:pending|in-progress|blocked"])

    assert_equal ["pending", "in-progress", "blocked"], result[0][:values]
    assert_equal true, result[0][:or_mode]
  end

  def test_parse_negated_filter
    result = FP.parse(["status:!done"])

    assert_equal ["done"], result[0][:values]
    assert_equal true, result[0][:negated]
    assert_equal false, result[0][:or_mode]
  end

  def test_parse_negated_or_values
    result = FP.parse(["status:!done|blocked"])

    assert_equal ["done", "blocked"], result[0][:values]
    assert_equal true, result[0][:negated]
    assert_equal true, result[0][:or_mode]
  end

  def test_parse_with_whitespace
    result = FP.parse(["  status  :  pending  "])

    assert_equal "status", result[0][:key]
    assert_equal ["pending"], result[0][:values]
  end

  def test_parse_or_values_with_whitespace
    result = FP.parse(["status: pending | in-progress | blocked "])

    assert_equal ["pending", "in-progress", "blocked"], result[0][:values]
  end

  def test_parse_complex_combination
    result = FP.parse([
      "status:pending|in-progress",
      "priority:!low",
      "team:backend"
    ])

    assert_equal 3, result.length
    assert_equal true, result[0][:or_mode]
    assert_equal true, result[1][:negated]
    assert_equal "backend", result[2][:values].first
  end

  def test_parse_value_with_colon
    result = FP.parse(["title:API: Review"])

    assert_equal "title", result[0][:key]
    assert_equal ["API: Review"], result[0][:values]
  end

  def test_parse_preserves_case
    result = FP.parse(["status:PENDING"])
    assert_equal ["PENDING"], result[0][:values]
  end

  # --- Edge cases ---

  def test_parse_empty_array
    assert_equal [], FP.parse([])
  end

  def test_parse_nil
    assert_equal [], FP.parse(nil)
  end

  def test_parse_missing_colon_raises
    assert_raises(ArgumentError) { FP.parse(["status"]) }
  end

  def test_parse_empty_key_raises
    assert_raises(ArgumentError) { FP.parse([":pending"]) }
  end

  def test_parse_empty_value_raises
    assert_raises(ArgumentError) { FP.parse(["status:"]) }
  end

  def test_parse_only_negation_raises
    assert_raises(ArgumentError) { FP.parse(["status:!"]) }
  end

  def test_parse_only_pipes_raises
    assert_raises(ArgumentError) { FP.parse(["status:|||"]) }
  end
end
