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
        ENV["ACE_LLM_FALLBACK_MAX_TOTAL_TIMEOUT"] = "45.0"

        config = with_config_fallback(nil) do
          QueryInterface.send(:load_fallback_config, nil, nil)
        end

        assert_equal true, config.enabled
        assert_equal 2, config.providers.length
        assert_match(/\Aanthropic:/, config.providers[0])
        assert_match(/\Aopenai:/, config.providers[1])
        assert_equal 5, config.retry_count
        assert_equal 2.0, config.retry_delay
        assert_equal 45.0, config.max_total_timeout
      ensure
        ENV.delete("ACE_LLM_FALLBACK_ENABLED")
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
        ENV.delete("ACE_LLM_FALLBACK_RETRY_COUNT")
        ENV.delete("ACE_LLM_FALLBACK_RETRY_DELAY")
        ENV.delete("ACE_LLM_FALLBACK_MAX_TOTAL_TIMEOUT")
      end

      def test_load_fallback_config_with_explicit_parameters
        config = with_config_fallback({ "enabled" => true }) do
          QueryInterface.send(
            :load_fallback_config,
            false,
            ["claude", "gpt"]
          )
        end

        assert_equal false, config.enabled
        assert_equal 2, config.providers.length
        assert_match(/\A(anthropic|claude):/, config.providers[0])
        assert_match(/\A(openai:|gpt)\b/, config.providers[1])
      end

      def test_load_fallback_config_defaults
        config = with_config_fallback(nil) do
          QueryInterface.send(:load_fallback_config, nil, nil)
        end

        assert_equal true, config.enabled
        assert_equal 3, config.retry_count
        assert_equal 1.0, config.retry_delay
        assert_equal [], config.providers
        assert_equal 30.0, config.max_total_timeout
      end

      def test_load_fallback_config_from_configuration
        config = with_config_fallback(
          "enabled" => false,
          "retry_count" => 2,
          "retry_delay" => 0.75,
          "max_total_timeout" => 15.0,
          "providers" => ["openai:gpt-5"]
        ) do
          QueryInterface.send(:load_fallback_config, nil, nil)
        end

        assert_equal false, config.enabled
        assert_equal 2, config.retry_count
        assert_equal 0.75, config.retry_delay
        assert_equal 15.0, config.max_total_timeout
        assert_equal ["openai:gpt-5"], config.providers
      end

      def test_fallback_providers_from_env_are_split_and_trimmed
        ENV["ACE_LLM_FALLBACK_PROVIDERS"] = " anthropic , openai , mistral "

        config = with_config_fallback(nil) do
          QueryInterface.send(:load_fallback_config, nil, nil)
        end

        assert_equal 3, config.providers.length
        assert_match(/\Aanthropic:/, config.providers[0])
        assert_match(/\Aopenai:/, config.providers[1])
        assert_match(/\Amistral:/, config.providers[2])
      ensure
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
      end

      def test_explicit_fallback_param_overrides_environment
        ENV["ACE_LLM_FALLBACK_ENABLED"] = "true"

        config = with_config_fallback({ "enabled" => true }) do
          QueryInterface.send(:load_fallback_config, false, nil)
        end

        assert_equal false, config.enabled
      ensure
        ENV.delete("ACE_LLM_FALLBACK_ENABLED")
      end

      def test_explicit_providers_override_environment
        ENV["ACE_LLM_FALLBACK_PROVIDERS"] = "anthropic,openai"

        config = with_config_fallback(nil) do
          QueryInterface.send(:load_fallback_config, nil, ["claude"])
        end

        assert_equal 1, config.providers.length
        assert_match(/\A(anthropic|claude):/, config.providers.first)
      ensure
        ENV.delete("ACE_LLM_FALLBACK_PROVIDERS")
      end

      def test_fallback_providers_are_deduplicated_preserving_order
        parser = FakeParser.new(
          "glite" => FakeParseResult.new("google", "gemini-2.0-flash-lite", true),
          "google:gemini-2.0-flash-lite" => FakeParseResult.new("google", "gemini-2.0-flash-lite", true),
          "openai:gpt-5" => FakeParseResult.new("openai", "gpt-5", true)
        )

        config = with_config_fallback(
          "providers" => [
            "glite",
            "google:gemini-2.0-flash-lite",
            "openai:gpt-5",
            "openai:gpt-5"
          ]
        ) do
          QueryInterface.send(:load_fallback_config, nil, nil, parser: parser)
        end

        assert_equal ["google:gemini-2.0-flash-lite", "openai:gpt-5"], config.providers
      end

      private

      FakeParseResult = Struct.new(:provider, :model, :valid) do
        def valid?
          valid
        end
      end

      class FakeParser
        def initialize(results)
          @results = results
        end

        def parse(input)
          @results.fetch(input.to_s.strip, FakeParseResult.new(nil, nil, false))
        end
      end

      def with_config_fallback(config_hash)
        Ace::LLM::Molecules::ConfigLoader.stub(:get, ->(path) { path == "llm.fallback" ? config_hash : nil }) do
          yield
        end
      end
    end
  end
end
