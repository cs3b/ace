# frozen_string_literal: true

require "test_helper"

class ContextLimitResolverTest < AceReviewTest
  def setup
    super
    install_project_llm_provider_fixtures("codex")
    @resolver = Ace::Review::Atoms::ContextLimitResolver
  end

  def test_resolve_uses_concrete_model_override_for_provider_alias
    assert_equal 1_050_000, @resolver.resolve("codex:gpt:high@ro")
  end

  def test_resolve_details_expands_role_before_lookup
    result = @resolver.resolve_details("role:review-codex")

    assert_equal "codex", result.provider
    assert_equal "gpt-5.4", result.model
    assert_equal 1_050_000, result.context_limit
    assert_equal 128_000, result.output_limit
    assert_equal :model_override, result.source
  end

  def test_resolve_returns_provider_default_when_model_uses_default_pair
    result = @resolver.resolve_details("openai:mini")

    assert_equal "openai", result.provider
    assert_equal "gpt-5.4-mini", result.model
    assert_equal 400_000, result.context_limit
    assert_equal 128_000, result.output_limit
    assert_equal :provider_default, result.source
  end

  def test_unknown_model_returns_default
    assert_equal 200_000, @resolver.resolve("unknown-model-xyz")
  end

  def test_nil_returns_default
    assert_equal 200_000, @resolver.resolve(nil)
  end

  def test_default_limit_method
    assert_equal 200_000, @resolver.default_limit
  end

  def test_default_limit_constant
    assert_equal 200_000, Ace::Review::Atoms::ContextLimitResolver::DEFAULT_LIMIT
  end
end
