# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/llm/molecules/model_limit_resolver"

module Ace
  module LLM
    module Molecules
      class ModelLimitResolverTest < AceLlmTestCase
        def setup
          super
          Ace::LLM.reset_configuration!
          @resolver = ModelLimitResolver.new
        end

        def teardown
          Ace::LLM.reset_configuration!
          super
        end

        def test_resolve_returns_provider_default_limits_for_alias_target
          result = @resolver.resolve("openai:mini")

          assert_equal "openai", result.provider
          assert_equal "gpt-5.4-mini", result.model
          assert_equal 400_000, result.context_limit
          assert_equal 128_000, result.output_limit
          assert_equal :provider_default, result.source
        end

        def test_resolve_uses_model_override_for_explicit_alias
          result = @resolver.resolve("codex:gpt:high@ro")

          assert_equal "codex", result.provider
          assert_equal "gpt-5.4", result.model
          assert_equal 1_050_000, result.context_limit
          assert_equal 128_000, result.output_limit
          assert_equal :model_override, result.source
          assert_equal "codex:gpt:high@ro", result.original_target
        end

        def test_resolve_expands_role_before_limit_lookup
          parsed = ProviderModelParser::ParseResult.new(
            "codex",
            "gpt-5.4",
            "ro",
            "high",
            true,
            nil,
            "role:review-codex"
          )
          parser = Object.new
          parser.define_singleton_method(:parse) { |_target| parsed }
          resolver = ModelLimitResolver.new(parser: parser)

          result = resolver.resolve("role:review-codex")

          assert_equal "codex", result.provider
          assert_equal "gpt-5.4", result.model
          assert_equal 1_050_000, result.context_limit
          assert_equal :model_override, result.source
        end

        def test_resolve_returns_fallback_when_target_invalid
          result = @resolver.resolve("unknown-provider:model")

          assert_equal 200_000, result.context_limit
          assert_nil result.output_limit
          assert_equal :fallback, result.source
        end
      end
    end
  end
end
