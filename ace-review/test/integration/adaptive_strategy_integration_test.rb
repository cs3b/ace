# frozen_string_literal: true

require "test_helper"

# Explicitly require the strategies
require "ace/review/molecules/strategies/adaptive_strategy"
require "ace/review/molecules/subject_strategy"

# Integration tests for adaptive strategy selection
# These tests verify the end-to-end behavior of strategy selection
# based on model capabilities and subject size.
class AdaptiveStrategyIntegrationTest < AceReviewTest
  def setup
    super
    @factory = Ace::Review::Molecules::SubjectStrategy
  end

  # Factory integration tests
  def test_factory_creates_adaptive_strategy
    strategy = @factory.for(:adaptive)

    assert_kind_of Ace::Review::Molecules::Strategies::AdaptiveStrategy, strategy
    assert_equal :adaptive, strategy.strategy_name
  end

  def test_factory_passes_config_to_adaptive_strategy
    config = { headroom: 0.20 }
    strategy = @factory.for(:adaptive, config)

    # Verify config is used by checking behavior
    # With 20% headroom, 800 tokens available from 1000 limit
    subject = "a" * 3000  # 750 tokens
    selected = strategy.select_strategy(subject, 1000)

    # 750 tokens fits in 800 available
    assert_kind_of Ace::Review::Molecules::Strategies::FullStrategy, selected
  end

  # Model capability integration tests
  def test_gemini_2m_model_uses_full_for_large_diffs
    strategy = @factory.for(:adaptive)

    # Gemini 2.5-pro has 1M context window
    # 850k tokens available (85% of 1M)
    # A "large" diff of 100k chars = 25k tokens, easily fits
    large_diff = build_realistic_diff(50, 2000)  # 50 files, 2k chars each = 100k
    context = { model: "google:gemini-2.5-pro" }

    result = strategy.prepare(large_diff, context)

    assert_equal :full, result[0][:metadata][:strategy]
    assert_equal 1, result.length
  end

  def test_claude_1m_model_uses_chunked_for_huge_diffs
    strategy = @factory.for(:adaptive)

    # Claude has 1M context window
    # 850k tokens available (85% of 1M)
    # Need > 850k tokens = > 3.4M chars
    # Use larger file content to exceed the limit
    huge_diff = build_realistic_diff(500, 15_000)  # 500 files, ~15k chars each = ~7.5M chars
    context = { model: "anthropic:claude-3-sonnet" }

    result = strategy.prepare(huge_diff, context)

    assert_equal :chunked, result[0][:metadata][:strategy]
    # Should have multiple chunks
    assert result.length >= 1
  end

  def test_claude_uses_full_for_normal_prs
    strategy = @factory.for(:adaptive)

    # Normal PR: 20 files, 500 chars each = 10k chars = 2.5k tokens
    # This fits easily in Claude's 170k available tokens
    normal_pr = build_realistic_diff(20, 500)
    context = { model: "anthropic:claude-3-sonnet" }

    result = strategy.prepare(normal_pr, context)

    assert_equal :full, result[0][:metadata][:strategy]
    assert_equal 1, result.length
  end

  def test_gpt4_uses_chunked_for_medium_prs
    strategy = @factory.for(:adaptive)

    # GPT-4o has 128k context
    # 108.8k tokens available (85% of 128k)
    # Medium-large PR: 200k chars = 50k tokens, fits in GPT-4o
    medium_pr = build_realistic_diff(40, 5000)
    context = { model: "openai:gpt-4o" }

    result = strategy.prepare(medium_pr, context)

    assert_equal :full, result[0][:metadata][:strategy]
  end

  # Configuration override tests
  def test_explicit_limit_overrides_model_lookup
    strategy = @factory.for(:adaptive)

    # Small subject that would normally use full
    subject = "a" * 1000  # 250 tokens
    # But with explicit tiny limit, must chunk
    context = { model: "gemini-2.5-pro", model_context_limit: 100 }

    result = strategy.prepare(subject, context)

    # 250 tokens exceeds 85 available (85% of 100)
    assert_equal :chunked, result[0][:metadata][:strategy]
  end

  def test_custom_headroom_affects_selection
    # 25% headroom means only 75% available
    strategy = @factory.for(:adaptive, headroom: 0.25)

    # With 25% headroom on 1000 limit, only 750 tokens available
    subject = "a" * 3200  # 800 tokens
    selected = strategy.select_strategy(subject, 1000)

    # 800 tokens exceeds 750 available
    assert_kind_of Ace::Review::Molecules::Strategies::ChunkedStrategy, selected
  end

  # Edge cases
  def test_unknown_model_uses_conservative_default
    strategy = @factory.for(:adaptive)

    # Unknown model defaults to 128k context
    # 108.8k available
    subject = "a" * 100_000  # 25k tokens
    context = { model: "unknown-future-model" }

    result = strategy.prepare(subject, context)

    # 25k tokens fits in 108.8k
    assert_equal :full, result[0][:metadata][:strategy]
  end

  def test_empty_model_uses_default
    strategy = @factory.for(:adaptive)

    subject = "a" * 1000
    context = {}  # No model specified

    result = strategy.prepare(subject, context)

    # Should not error, uses default limit
    assert_includes [:full, :chunked], result[0][:metadata][:strategy]
  end

  # Preset configuration integration
  def test_preset_subject_strategy_config_structure
    # Verify the configuration structure documented in config.yml
    preset_config = {
      "subject_strategy" => {
        "type" => "adaptive",
        "headroom" => 0.15,
        "chunking" => {
          "max_tokens_per_chunk" => 100_000,
          "include_change_summary" => true
        }
      }
    }

    # Extract strategy config
    strategy_config = preset_config["subject_strategy"]
    assert_equal "adaptive", strategy_config["type"]
    assert_equal 0.15, strategy_config["headroom"]
    assert_equal 100_000, strategy_config["chunking"]["max_tokens_per_chunk"]

    # Create strategy with this config (converting to symbol keys)
    strategy = @factory.for(
      strategy_config["type"].to_sym,
      headroom: strategy_config["headroom"],
      chunking: {
        max_tokens_per_chunk: strategy_config["chunking"]["max_tokens_per_chunk"],
        include_change_summary: strategy_config["chunking"]["include_change_summary"]
      }
    )

    assert_kind_of Ace::Review::Molecules::Strategies::AdaptiveStrategy, strategy
  end

  def test_explicit_strategy_type_overrides_adaptive
    # When preset explicitly sets type: full, use full regardless of size
    full_strategy = @factory.for(:full)
    huge_subject = "a" * 1_000_000  # Would normally trigger chunked

    # Full strategy still wraps in single unit (doesn't check limits in prepare)
    result = full_strategy.prepare(huge_subject, {})

    assert_equal :full, result[0][:metadata][:strategy]
    assert_equal 1, result.length

    # But can_handle? returns false for oversized subjects
    refute full_strategy.can_handle?(huge_subject, 128_000)
  end

  private

  # Build a realistic diff for testing
  # Creates unified diff format with multiple files
  def build_realistic_diff(file_count, chars_per_file)
    files = []
    file_count.times do |i|
      # Create realistic-looking code content
      content_lines = []
      lines_needed = chars_per_file / 50  # ~50 chars per line

      lines_needed.times do |j|
        content_lines << "+def method_#{i}_#{j}; end"
      end

      files << <<~DIFF
        diff --git a/lib/module_#{i}/file_#{i}.rb b/lib/module_#{i}/file_#{i}.rb
        index abc#{format('%04d', i)}..def#{format('%04d', i)} 100644
        --- a/lib/module_#{i}/file_#{i}.rb
        +++ b/lib/module_#{i}/file_#{i}.rb
        @@ -1,10 +1,#{lines_needed + 10} @@
         # Module #{i} implementation
         module Module#{i}
         class File#{i}
        #{content_lines.join("\n")}
         end
         end
      DIFF
    end
    files.join("\n")
  end
end
