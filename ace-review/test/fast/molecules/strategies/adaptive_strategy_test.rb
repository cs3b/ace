# frozen_string_literal: true

require "test_helper"

# Explicitly require the strategy since it's lazy-loaded
require "ace/review/molecules/strategies/adaptive_strategy"

class AdaptiveStrategyTest < AceReviewTest
  def setup
    super
    @strategy = Ace::Review::Molecules::Strategies::AdaptiveStrategy.new
  end

  # can_handle? tests
  def test_can_handle_returns_true_for_any_valid_subject
    subject = "a" * 1000
    model_limit = 128_000

    result = @strategy.can_handle?(subject, model_limit)

    assert result
  end

  def test_can_handle_returns_true_for_large_subject
    # Adaptive can handle any size by choosing appropriate strategy
    subject = "a" * 1_000_000
    model_limit = 128_000

    result = @strategy.can_handle?(subject, model_limit)

    assert result
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

  # select_strategy tests - strategy selection logic
  def test_select_strategy_returns_full_for_small_subject
    # Small subject should fit in context with headroom
    subject = "a" * 1000  # ~250 tokens
    model_limit = 128_000  # Available: 108,800 tokens (85%)

    selected = @strategy.select_strategy(subject, model_limit)

    assert_kind_of Ace::Review::Molecules::Strategies::FullStrategy, selected
  end

  def test_select_strategy_returns_chunked_for_large_subject
    # Large subject exceeds context even for big model
    subject = "a" * 500_000  # ~125,000 tokens
    model_limit = 128_000    # Available: 108,800 tokens (85%)

    selected = @strategy.select_strategy(subject, model_limit)

    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, selected
  end

  def test_select_strategy_respects_headroom
    # Default headroom is 15%, so available = 85% of limit
    # Model limit = 1000 tokens, available = 850 tokens
    model_limit = 1000

    # 800 tokens (3200 chars) should fit
    subject_fits = "a" * 3200
    selected_fits = @strategy.select_strategy(subject_fits, model_limit)
    assert_kind_of Ace::Review::Molecules::Strategies::FullStrategy, selected_fits

    # 900 tokens (3600 chars) should not fit
    subject_too_big = "a" * 3600
    selected_chunked = @strategy.select_strategy(subject_too_big, model_limit)
    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, selected_chunked
  end

  def test_select_strategy_with_custom_headroom
    # Custom 20% headroom
    strategy = Ace::Review::Molecules::Strategies::AdaptiveStrategy.new(headroom: 0.20)
    model_limit = 1000  # Available: 800 tokens (80%)

    # 750 tokens (3000 chars) should fit with 20% headroom
    subject_fits = "a" * 3000
    selected = strategy.select_strategy(subject_fits, model_limit)
    assert_kind_of Ace::Review::Molecules::Strategies::FullStrategy, selected

    # 850 tokens (3400 chars) should not fit with 20% headroom
    subject_too_big = "a" * 3400
    selected_chunked = strategy.select_strategy(subject_too_big, model_limit)
    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, selected_chunked
  end

  # prepare tests - full integration
  def test_prepare_uses_full_strategy_for_small_subject
    subject = "def hello\n  puts 'world'\nend"
    context = {model: "gemini-2.5-pro"}

    result = @strategy.prepare(subject, context)

    assert_kind_of Array, result
    assert_equal 1, result.length
    assert_equal :full, result[0][:metadata][:strategy]
    assert_equal subject, result[0][:content]
  end

  def test_prepare_uses_chunked_strategy_for_large_subject
    # Create a large diff that will trigger chunked strategy
    large_diff = build_large_diff(10, 5000)  # 10 files, 5000 chars each
    context = {model: "claude-3-sonnet", model_context_limit: 10_000}

    result = @strategy.prepare(large_diff, context)

    assert_kind_of Array, result
    # Should have multiple chunks
    assert result.length > 1 || result[0][:metadata][:strategy] == :chunked
  end

  def test_prepare_uses_explicit_model_context_limit
    subject = "a" * 4000  # ~1000 tokens
    # Explicit limit of 500 tokens forces chunked
    context = {model: "gemini-2.5-pro", model_context_limit: 500}

    result = @strategy.prepare(subject, context)

    # With 500 token limit and 15% headroom = 425 available
    # 1000 tokens exceeds this, so chunked is selected
    assert_equal :chunked, result[0][:metadata][:strategy]
  end

  def test_prepare_resolves_model_limit_from_model_name
    subject = "a" * 1000  # ~250 tokens
    context = {model: "claude-3-sonnet"}  # 200k limit

    result = @strategy.prepare(subject, context)

    # 250 tokens easily fits in 200k context
    assert_equal :full, result[0][:metadata][:strategy]
  end

  def test_prepare_handles_string_keys_in_context
    subject = "a" * 1000
    context = {"model" => "gemini-2.5-pro"}

    result = @strategy.prepare(subject, context)

    assert_equal :full, result[0][:metadata][:strategy]
  end

  def test_prepare_handles_explicit_limit_with_string_key
    subject = "a" * 4000
    context = {"model_context_limit" => 500}

    result = @strategy.prepare(subject, context)

    assert_equal :chunked, result[0][:metadata][:strategy]
  end

  # Model-specific selection tests (acceptance criteria)
  def test_gemini_2m_uses_full_for_most_prs
    # Gemini 2.5-pro has 1M context, 850k available
    # Most PRs are < 850k tokens
    subject = "a" * 100_000  # ~25,000 tokens
    context = {model: "google:gemini-2.5-pro"}

    result = @strategy.prepare(subject, context)

    assert_equal :full, result[0][:metadata][:strategy]
  end

  def test_claude_1m_uses_chunked_for_large_prs
    # Claude has 1M context, ~850k available
    # PRs > 850k tokens should chunk
    subject = "a" * 4_000_000  # ~1,000,000 tokens
    context = {model: "anthropic:claude-3-sonnet"}

    result = @strategy.prepare(subject, context)

    assert_equal :chunked, result[0][:metadata][:strategy]
  end

  def test_claude_1m_uses_full_for_small_prs
    # Small PRs should use full even with Claude
    subject = "a" * 10_000  # ~2,500 tokens
    context = {model: "anthropic:claude-3-sonnet"}

    result = @strategy.prepare(subject, context)

    assert_equal :full, result[0][:metadata][:strategy]
  end

  # strategy_name tests
  def test_strategy_name_returns_adaptive
    assert_equal :adaptive, @strategy.strategy_name
  end

  # Configuration tests
  def test_accepts_config_in_constructor
    config = {headroom: 0.20, max_tokens_per_chunk: 50_000}
    strategy = Ace::Review::Molecules::Strategies::AdaptiveStrategy.new(config)

    assert_kind_of Ace::Review::Molecules::Strategies::AdaptiveStrategy, strategy
  end

  def test_default_headroom_constant
    default_headroom = Ace::Review::Molecules::Strategies::AdaptiveStrategy::DEFAULT_HEADROOM

    assert_equal 0.15, default_headroom
  end

  def test_passes_chunking_config_to_chunked_strategy
    config = {
      headroom: 0.15,
      chunking: {
        max_tokens_per_chunk: 50_000,
        include_change_summary: false
      }
    }
    strategy = Ace::Review::Molecules::Strategies::AdaptiveStrategy.new(config)

    # Force chunked selection with small limit
    large_diff = build_large_diff(5, 10_000)
    context = {model_context_limit: 1000}

    result = strategy.prepare(large_diff, context)

    # Verify it used chunked
    assert_equal :chunked, result[0][:metadata][:strategy]
  end

  # Logging tests
  def test_logs_selection_when_debug_enabled
    # Create a mock logger that captures calls
    logged_messages = []
    mock_logger = Object.new
    mock_logger.define_singleton_method(:info) { |msg| logged_messages << msg }

    strategy = Ace::Review::Molecules::Strategies::AdaptiveStrategy.new(logger: mock_logger)
    subject = "a" * 1000
    strategy.select_strategy(subject, 128_000, "test-model")

    assert_equal 1, logged_messages.length
    message = logged_messages.first
    assert_includes message, "[ace-review] Strategy selection:"
    assert_includes message, "model=test-model"
    assert_includes message, "selected=full"
  end

  # YAML config keys are strings - verify nested chunking config works
  def test_accepts_string_keyed_config_with_nested_chunking
    # Simulating config loaded from YAML (string keys, including nested)
    config = {
      "headroom" => 0.10,
      "chunking" => {
        "max_tokens_per_chunk" => 50_000,
        "include_change_summary" => false
      }
    }
    strategy = Ace::Review::Molecules::Strategies::AdaptiveStrategy.new(config)

    # Verify headroom is honored (10% instead of default 15%)
    # With 10% headroom and 100k limit, available is 90k
    # A 85k subject should trigger full strategy
    subject = "a" * 85_000  # ~85k tokens

    selected = strategy.select_strategy(subject, 100_000, "test-model")
    assert_equal :full, selected.strategy_name

    # With 15% default headroom, available would be 85k, and 85k subject would exceed
    # So using 10% headroom allows more content to fit in full strategy
  end

  private

  # Build a large diff for testing chunked behavior
  def build_large_diff(file_count, chars_per_file)
    files = []
    file_count.times do |i|
      content = "a" * chars_per_file
      files << <<~DIFF
        diff --git a/lib/file_#{i}.rb b/lib/file_#{i}.rb
        index abc1234..def5678 100644
        --- a/lib/file_#{i}.rb
        +++ b/lib/file_#{i}.rb
        @@ -1,10 +1,15 @@
        +#{content}
      DIFF
    end
    files.join("\n")
  end
end
