# frozen_string_literal: true

require "test_helper"

module Ace
  module LLM
    class QueryInterfaceFallbackTest < AceLlmTestCase
      def test_query_executes_without_fallback_when_disabled
        # Set environment to disable fallback
        ENV["ACE_LLM_FALLBACK_ENABLED"] = "false"

        # This test is minimal since we don't have real API keys
        # Just verify the interface accepts the fallback parameter
        assert_raises(Ace::LLM::Error) do
          QueryInterface.query(
            "nonexistent:model",
            "test prompt",
            fallback: false
          )
        end
      ensure
        ENV.delete("ACE_LLM_FALLBACK_ENABLED")
      end

      def test_load_fallback_config_from_environment
        ENV["ACE_LLM_FALLBACK_ENABLED"] = "true"
        ENV["ACE_LLM_FALLBACK_PROVIDERS"] = "anthropic,openai"
        ENV["ACE_LLM_FALLBACK_RETRY_COUNT"] = "5"
        ENV["ACE_LLM_FALLBACK_RETRY_DELAY"] = "2.0"

        config = QueryInterface.send(:load_fallback_config, nil, nil)

        assert_equal true, config.enabled
        assert_equal ["anthropic", "openai"], config.providers
        assert_equal 5, config.retry_count
        assert_equal 2.0, config.retry_delay
      ensure
        ENV.delete("ACE_LLM_FALLBACK_ENABLED")
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
        ENV.delete("ACE_LLM_FALLBACK_RETRY_COUNT")
        ENV.delete("ACE_LLM_FALLBACK_RETRY_DELAY")
      end

      def test_load_fallback_config_with_explicit_parameters
        config = QueryInterface.send(
          :load_fallback_config,
          false,
          ["claude", "gpt"]
        )

        assert_equal false, config.enabled
        assert_equal ["claude", "gpt"], config.providers
      end

      def test_load_fallback_config_defaults
        config = QueryInterface.send(:load_fallback_config, nil, nil)

        assert_equal true, config.enabled
        assert_equal 3, config.retry_count
        assert_equal 1.0, config.retry_delay
        assert_equal [], config.providers
      end

      def test_fallback_providers_from_env_are_split_and_trimmed
        ENV["ACE_LLM_FALLBACK_PROVIDERS"] = " anthropic , openai , mistral "

        config = QueryInterface.send(:load_fallback_config, nil, nil)

        assert_equal ["anthropic", "openai", "mistral"], config.providers
      ensure
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
      end

      def test_explicit_fallback_param_overrides_environment
        ENV["ACE_LLM_FALLBACK_ENABLED"] = "true"

        config = QueryInterface.send(:load_fallback_config, false, nil)

        assert_equal false, config.enabled
      ensure
        ENV.delete("ACE_LLM_FALLBACK_ENABLED")
      end

      def test_explicit_providers_override_environment
        ENV["ACE_LLM_FALLBACK_PROVIDERS"] = "anthropic,openai"

        config = QueryInterface.send(:load_fallback_config, nil, ["claude"])

        assert_equal ["claude"], config.providers
      ensure
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
      end
    end
  end
end
