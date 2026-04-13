# frozen_string_literal: true

require "test_helper"

class SubjectStrategyTest < AceReviewTest
  def setup
    super
    @factory = Ace::Review::Molecules::SubjectStrategy
  end

  # Factory tests
  def test_for_returns_full_strategy_for_full_type
    strategy = @factory.for(:full)

    assert_kind_of Ace::Review::Molecules::Strategies::FullStrategy, strategy
  end

  def test_for_accepts_string_type
    strategy = @factory.for("full")

    assert_kind_of Ace::Review::Molecules::Strategies::FullStrategy, strategy
  end

  def test_for_accepts_config_hash
    strategy = @factory.for(:full, {custom_option: true})

    assert_kind_of Ace::Review::Molecules::Strategies::FullStrategy, strategy
  end

  def test_for_raises_on_unknown_type
    error = assert_raises(Ace::Review::Errors::UnknownStrategyError) do
      @factory.for(:nonexistent)
    end

    assert_match(/Unknown strategy type 'nonexistent'/, error.message)
    assert_match(/Available strategies:/, error.message)
    assert_match(/full/, error.message)
  end

  def test_for_raises_on_empty_type
    error = assert_raises(Ace::Review::Errors::UnknownStrategyError) do
      @factory.for(:unknown_type)
    end

    assert_match(/Unknown strategy type/, error.message)
  end

  # Helper method tests
  def test_available_returns_true_for_full
    assert @factory.available?(:full)
  end

  def test_available_returns_false_for_unknown
    refute @factory.available?(:nonexistent)
  end

  def test_available_accepts_string
    assert @factory.available?("full")
  end

  def test_available_strategies_returns_list
    strategies = @factory.available_strategies

    assert_kind_of Array, strategies
    assert_includes strategies, :full
    assert_includes strategies, :chunked
  end

  # Chunked strategy factory tests
  def test_for_returns_chunked_strategy_for_chunked_type
    strategy = @factory.for(:chunked)

    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, strategy
  end

  def test_for_chunked_accepts_string_type
    strategy = @factory.for("chunked")

    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, strategy
  end

  def test_for_chunked_accepts_config_hash
    strategy = @factory.for(:chunked, {max_tokens_per_chunk: 50_000})

    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, strategy
  end

  def test_available_returns_true_for_chunked
    assert @factory.available?(:chunked)
  end

  def test_available_chunked_accepts_string
    assert @factory.available?("chunked")
  end

  # Adaptive strategy factory tests
  def test_for_returns_adaptive_strategy_for_adaptive_type
    strategy = @factory.for(:adaptive)

    assert_kind_of Ace::Review::Molecules::Strategies::AdaptiveStrategy, strategy
  end

  def test_for_adaptive_accepts_string_type
    strategy = @factory.for("adaptive")

    assert_kind_of Ace::Review::Molecules::Strategies::AdaptiveStrategy, strategy
  end

  def test_for_adaptive_accepts_config_hash
    strategy = @factory.for(:adaptive, {headroom: 0.20})

    assert_kind_of Ace::Review::Molecules::Strategies::AdaptiveStrategy, strategy
  end

  def test_available_returns_true_for_adaptive
    assert @factory.available?(:adaptive)
  end

  def test_available_adaptive_accepts_string
    assert @factory.available?("adaptive")
  end

  def test_available_strategies_includes_adaptive
    strategies = @factory.available_strategies

    assert_includes strategies, :adaptive
  end
end
