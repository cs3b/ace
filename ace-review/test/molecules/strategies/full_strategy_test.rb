# frozen_string_literal: true

require "test_helper"

# Explicitly require the strategy since it's lazy-loaded
require "ace/review/molecules/strategies/full_strategy"

class FullStrategyTest < AceReviewTest
  def setup
    super
    @strategy = Ace::Review::Molecules::Strategies::FullStrategy.new
  end

  # can_handle? tests
  def test_can_handle_returns_true_when_subject_fits
    subject = "a" * 1000  # 250 estimated tokens
    model_limit = 128_000

    result = @strategy.can_handle?(subject, model_limit)

    assert result
  end

  def test_can_handle_returns_false_when_subject_too_large
    # Create subject that exceeds safe limit
    # 128k tokens * 0.85 = 108,800 safe tokens
    # Need > 108,800 tokens = > 435,200 chars
    subject = "a" * 500_000
    model_limit = 128_000

    result = @strategy.can_handle?(subject, model_limit)

    refute result
  end

  def test_can_handle_returns_false_for_nil_subject
    result = @strategy.can_handle?(nil, 128_000)

    refute result
  end

  def test_can_handle_returns_false_for_empty_subject
    result = @strategy.can_handle?("", 128_000)

    refute result
  end

  def test_can_handle_returns_false_for_nil_limit
    result = @strategy.can_handle?("test subject", nil)

    refute result
  end

  def test_can_handle_returns_false_for_zero_limit
    result = @strategy.can_handle?("test subject", 0)

    refute result
  end

  def test_can_handle_returns_false_for_negative_limit
    result = @strategy.can_handle?("test subject", -1000)

    refute result
  end

  def test_can_handle_respects_context_margin
    # Context margin is 15%, so safe limit = 85% of model limit
    # Model limit = 1000 tokens, safe limit = 850 tokens
    # 850 tokens * 4 chars = 3400 chars
    model_limit = 1000

    # Just under safe limit - should fit
    subject_fits = "a" * 3300  # 825 tokens
    assert @strategy.can_handle?(subject_fits, model_limit)

    # Over safe limit - should not fit
    subject_too_big = "a" * 3600  # 900 tokens
    refute @strategy.can_handle?(subject_too_big, model_limit)
  end

  # prepare tests
  def test_prepare_returns_single_element_array
    subject = "test code to review"
    result = @strategy.prepare(subject, {})

    assert_kind_of Array, result
    assert_equal 1, result.length
  end

  def test_prepare_returns_complete_subject_content
    subject = "def hello\n  puts 'world'\nend"
    result = @strategy.prepare(subject, {})

    assert_equal subject, result[0][:content]
  end

  def test_prepare_includes_strategy_metadata
    subject = "test"
    result = @strategy.prepare(subject, {})

    metadata = result[0][:metadata]
    assert_equal :full, metadata[:strategy]
    assert_equal 0, metadata[:chunk_index]
    assert_equal 1, metadata[:total_chunks]
  end

  def test_prepare_ignores_context_for_full_strategy
    subject = "test"
    context = {
      system_prompt: "You are a reviewer",
      user_prompt: "Check for bugs",
      model: "gpt-4",
      model_context_limit: 128_000,
      preset: {name: "security"},
      file_list: ["foo.rb", "bar.rb"]
    }

    result = @strategy.prepare(subject, context)

    # Full strategy doesn't modify content based on context
    assert_equal subject, result[0][:content]
    assert_equal :full, result[0][:metadata][:strategy]
  end

  def test_prepare_handles_empty_context
    subject = "test"
    result = @strategy.prepare(subject)

    assert_equal subject, result[0][:content]
    assert_equal :full, result[0][:metadata][:strategy]
  end

  def test_prepare_handles_large_subject
    # Large subject still returns single unit
    subject = "x" * 100_000
    result = @strategy.prepare(subject, {})

    assert_equal 1, result.length
    assert_equal subject, result[0][:content]
  end

  # strategy_name tests
  def test_strategy_name_returns_full
    assert_equal :full, @strategy.strategy_name
  end

  # Configuration tests
  def test_accepts_config_in_constructor
    config = {some_option: true}
    strategy = Ace::Review::Molecules::Strategies::FullStrategy.new(config)

    assert_kind_of Ace::Review::Molecules::Strategies::FullStrategy, strategy
  end

  def test_default_context_margin_constant
    # Verify the constant exists and is reasonable
    margin = Ace::Review::Molecules::Strategies::FullStrategy::DEFAULT_CONTEXT_MARGIN

    assert_equal 0.15, margin
  end

  def test_can_handle_with_custom_headroom
    # With 30% headroom, 70K of 100K limit = 70K available
    strategy = Ace::Review::Molecules::Strategies::FullStrategy.new(headroom: 0.30)
    # 65K tokens should fit in 70K available
    # 65K tokens * 4 chars/token = 260K chars
    subject = "x" * 260_000
    assert strategy.can_handle?(subject, 100_000)
  end

  def test_can_handle_respects_string_key_headroom
    # Same test with string key
    strategy = Ace::Review::Molecules::Strategies::FullStrategy.new("headroom" => 0.30)
    subject = "x" * 260_000  # ~65K tokens at 4 chars/token
    assert strategy.can_handle?(subject, 100_000)
  end

  def test_can_handle_rejects_when_exceeds_custom_headroom
    # With 30% headroom, only 70K of 100K available
    # 75K tokens * 4 chars = 300K chars should NOT fit
    strategy = Ace::Review::Molecules::Strategies::FullStrategy.new(headroom: 0.30)
    subject = "x" * 300_000  # ~75K tokens
    refute strategy.can_handle?(subject, 100_000)
  end
end
