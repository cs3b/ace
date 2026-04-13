# frozen_string_literal: true

require_relative "../../test_helper"

class PricingInfoTest < AceModelsTestCase
  def test_from_hash_with_all_fields
    hash = {
      "input" => 2.5,
      "output" => 10.0,
      "reasoning" => 15.0,
      "cache_read" => 0.5,
      "cache_write" => 1.0
    }

    pricing = Ace::Support::Models::Models::PricingInfo.from_hash(hash)

    assert_equal 2.5, pricing.input
    assert_equal 10.0, pricing.output
    assert_equal 15.0, pricing.reasoning
    assert_equal 0.5, pricing.cache_read
    assert_equal 1.0, pricing.cache_write
  end

  def test_from_hash_with_nil
    pricing = Ace::Support::Models::Models::PricingInfo.from_hash(nil)

    assert_nil pricing.input
    assert_nil pricing.output
  end

  def test_available_returns_true_when_pricing_exists
    pricing = Ace::Support::Models::Models::PricingInfo.new(input: 2.5, output: 10.0)
    assert pricing.available?
  end

  def test_available_returns_false_when_no_pricing
    pricing = Ace::Support::Models::Models::PricingInfo.new
    refute pricing.available?
  end

  def test_calculate_basic
    pricing = Ace::Support::Models::Models::PricingInfo.new(input: 2.5, output: 10.0)
    cost = pricing.calculate(input_tokens: 1_000_000, output_tokens: 1_000_000)

    assert_in_delta 12.5, cost, 0.001
  end

  def test_calculate_with_reasoning
    pricing = Ace::Support::Models::Models::PricingInfo.new(
      input: 2.5,
      output: 10.0,
      reasoning: 15.0
    )
    cost = pricing.calculate(
      input_tokens: 1_000_000,
      output_tokens: 1_000_000,
      reasoning_tokens: 500_000
    )

    # 2.5 + 10.0 + 7.5 = 20.0
    assert_in_delta 20.0, cost, 0.001
  end

  def test_to_h
    pricing = Ace::Support::Models::Models::PricingInfo.new(input: 2.5, output: 10.0)
    hash = pricing.to_h

    assert_equal 2.5, hash[:input]
    assert_equal 10.0, hash[:output]
    refute_includes hash.keys, :reasoning
  end
end
