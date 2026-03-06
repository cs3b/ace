# frozen_string_literal: true

require "test_helper"

class ContextLimitResolverTest < AceReviewTest
  def setup
    super
    @resolver = Ace::Review::Atoms::ContextLimitResolver
  end

  # Gemini models
  def test_gemini_1_5_pro_has_2m_context
    result = @resolver.resolve("gemini-1.5-pro")

    assert_equal 2_000_000, result
  end

  def test_gemini_1_5_flash_has_1m_context
    result = @resolver.resolve("gemini-1.5-flash")

    assert_equal 1_000_000, result
  end

  def test_gemini_2_5_pro_has_1m_context
    result = @resolver.resolve("gemini-2.5-pro")

    assert_equal 1_000_000, result
  end

  def test_gemini_2_5_flash_has_1m_context
    result = @resolver.resolve("gemini-2.5-flash")

    assert_equal 1_000_000, result
  end

  def test_gemini_2_0_has_1m_context
    result = @resolver.resolve("gemini-2.0-flash")

    assert_equal 1_000_000, result
  end

  def test_gemini_fallback_has_1m_context
    # Unknown gemini variant should still get 1M
    result = @resolver.resolve("gemini-3.0-ultra")

    assert_equal 1_000_000, result
  end

  # Claude models
  def test_claude_opus_has_200k_context
    result = @resolver.resolve("claude-3-opus")

    assert_equal 200_000, result
  end

  def test_claude_sonnet_has_200k_context
    result = @resolver.resolve("claude-3-sonnet")

    assert_equal 200_000, result
  end

  def test_claude_haiku_has_200k_context
    result = @resolver.resolve("claude-3-haiku")

    assert_equal 200_000, result
  end

  def test_claude_opus_4_has_200k_context
    result = @resolver.resolve("claude-4-opus")

    assert_equal 200_000, result
  end

  def test_claude_sonnet_4_has_200k_context
    result = @resolver.resolve("claude-sonnet-4")

    assert_equal 200_000, result
  end

  def test_claude_fallback_has_200k_context
    # Unknown claude variant should still get 200k
    result = @resolver.resolve("claude-5-ultra")

    assert_equal 200_000, result
  end

  # OpenAI models
  def test_gpt_4o_has_128k_context
    result = @resolver.resolve("gpt-4o")

    assert_equal 128_000, result
  end

  def test_gpt_4o_mini_has_128k_context
    result = @resolver.resolve("gpt-4o-mini")

    assert_equal 128_000, result
  end

  def test_gpt_4_turbo_has_128k_context
    result = @resolver.resolve("gpt-4-turbo")

    assert_equal 128_000, result
  end

  def test_gpt_4_turbo_preview_has_128k_context
    result = @resolver.resolve("gpt-4-turbo-preview")

    assert_equal 128_000, result
  end

  def test_gpt_4_has_8k_context
    result = @resolver.resolve("gpt-4")

    assert_equal 8_192, result
  end

  def test_gpt_4_32k_has_32k_context
    result = @resolver.resolve("gpt-4-32k")

    assert_equal 32_768, result
  end

  def test_gpt_4_1106_preview_has_128k_context
    result = @resolver.resolve("gpt-4-1106-preview")

    assert_equal 128_000, result
  end

  def test_gpt_4_0125_preview_has_128k_context
    result = @resolver.resolve("gpt-4-0125-preview")

    assert_equal 128_000, result
  end

  def test_gpt_4_0613_has_8k_context
    result = @resolver.resolve("gpt-4-0613")

    assert_equal 8_192, result
  end

  def test_o1_preview_has_200k_context
    result = @resolver.resolve("o1-preview")

    assert_equal 200_000, result
  end

  def test_o1_mini_has_200k_context
    result = @resolver.resolve("o1-mini")

    assert_equal 200_000, result
  end

  def test_o3_mini_has_200k_context
    result = @resolver.resolve("o3-mini")

    assert_equal 200_000, result
  end

  # Provider prefix handling
  def test_google_prefix_stripped
    result = @resolver.resolve("google:gemini-2.5-pro")

    assert_equal 1_000_000, result
  end

  def test_google_prefix_with_preset_suffix
    result = @resolver.resolve("google:gemini-2.5-pro@ro")

    assert_equal 1_000_000, result
  end

  def test_anthropic_prefix_stripped
    result = @resolver.resolve("anthropic:claude-3-sonnet")

    assert_equal 200_000, result
  end

  def test_openai_prefix_stripped
    result = @resolver.resolve("openai:gpt-4o")

    assert_equal 128_000, result
  end

  def test_codex_prefix_stripped
    result = @resolver.resolve("codex:gpt-4o")

    assert_equal 128_000, result
  end

  def test_cli_prefix_stripped
    result = @resolver.resolve("cli:claude-3-opus")

    assert_equal 200_000, result
  end

  # Case insensitivity
  def test_case_insensitive_matching
    result1 = @resolver.resolve("GEMINI-2.5-PRO")
    result2 = @resolver.resolve("Claude-3-Sonnet")
    result3 = @resolver.resolve("GPT-4O")

    assert_equal 1_000_000, result1
    assert_equal 200_000, result2
    assert_equal 128_000, result3
  end

  # Unknown models and defaults
  def test_unknown_model_returns_default
    result = @resolver.resolve("unknown-model-xyz")

    assert_equal 128_000, result
  end

  def test_nil_returns_default
    result = @resolver.resolve(nil)

    assert_equal 128_000, result
  end

  def test_empty_string_returns_default
    result = @resolver.resolve("")

    assert_equal 128_000, result
  end

  def test_default_limit_method
    result = @resolver.default_limit

    assert_equal 128_000, result
  end

  # Constant accessibility
  def test_default_limit_constant
    assert_equal 128_000, Ace::Review::Atoms::ContextLimitResolver::DEFAULT_LIMIT
  end

  # Edge cases
  def test_partial_model_name_match
    # "gemini" alone should match the gemini fallback
    result = @resolver.resolve("gemini")

    assert_equal 1_000_000, result
  end

  def test_model_name_with_extra_suffix
    # Should match gpt-4o pattern
    result = @resolver.resolve("gpt-4o-2024-08-06")

    assert_equal 128_000, result
  end

  def test_model_name_with_preset_suffix
    result = @resolver.resolve("claude-3-sonnet@rw")

    assert_equal 200_000, result
  end

  # ace-llm integration tests
  # These tests verify that ace-llm config is consulted when available

  def test_google_provider_uses_config_limit
    # google:gemini-2.5-pro should use ace-llm's provider config (1M)
    # which matches the hardcoded fallback
    result = @resolver.resolve("google:gemini-2.5-pro")

    assert_equal 1_000_000, result
  end

  def test_anthropic_provider_uses_config_limit
    # anthropic:claude-3-sonnet should use ace-llm's provider config (200K)
    # which matches the hardcoded fallback
    result = @resolver.resolve("anthropic:claude-3-sonnet")

    assert_equal 200_000, result
  end

  def test_openai_provider_uses_config_limit
    # openai:gpt-4o should use ace-llm's provider config (128K)
    # which matches the hardcoded fallback
    result = @resolver.resolve("openai:gpt-4o")

    assert_equal 128_000, result
  end

  def test_unknown_provider_falls_back_to_pattern
    # An unknown provider should fall back to pattern matching
    result = @resolver.resolve("unknown:claude-3-sonnet")

    # Should match claude pattern in fallback
    assert_equal 200_000, result
  end

  def test_model_without_provider_uses_pattern_matching
    # Models without provider prefix use pattern matching directly
    result = @resolver.resolve("gemini-2.5-pro")

    assert_equal 1_000_000, result
  end
end
