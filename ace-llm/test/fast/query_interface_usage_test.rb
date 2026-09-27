# frozen_string_literal: true

require_relative "../test_helper"

class QueryInterfaceUsageTest < AceLlmTestCase
  def test_usage_is_derived_from_metadata_token_counts
    usage = Ace::LLM::QueryInterface.send(:build_usage, {
      provider: "pi", model: "zai/glm-5.3-flash",
      input_tokens: 1479, output_tokens: 3, cached_tokens: 64, total_tokens: 1482
    })

    assert_equal "zai/glm-5.3-flash", usage[:model]
    assert_equal 1479, usage[:input_tokens]
    assert_equal 3, usage[:output_tokens]
    assert_equal 64, usage[:cached_tokens]
    assert_equal 1482, usage[:total_tokens]
  end

  def test_measured_zero_cached_tokens_are_kept
    usage = Ace::LLM::QueryInterface.send(:build_usage, {
      model: "m", input_tokens: 10, output_tokens: 2, cached_tokens: 0
    })

    assert_equal 0, usage[:cached_tokens]
    assert_equal 12, usage[:total_tokens]
  end

  def test_absent_cached_tokens_stay_absent
    usage = Ace::LLM::QueryInterface.send(:build_usage, {
      model: "m", input_tokens: 10, output_tokens: 2
    })

    refute usage.key?(:cached_tokens)
    assert_equal 12, usage[:total_tokens]
  end

  def test_usage_is_nil_without_any_token_counts
    assert_nil Ace::LLM::QueryInterface.send(:build_usage, {provider: "pi", model: "m"})
    assert_nil Ace::LLM::QueryInterface.send(:build_usage, nil)
  end

  def test_string_keyed_metadata_is_supported
    usage = Ace::LLM::QueryInterface.send(:build_usage, {
      "model" => "m", "input_tokens" => 7, "output_tokens" => 1
    })

    assert_equal 7, usage[:input_tokens]
    assert_equal 1, usage[:output_tokens]
    assert_equal 8, usage[:total_tokens]
  end
end
