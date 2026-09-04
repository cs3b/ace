# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module LLM
    # Focused regression tests for the Pi GLM 5.3 registry release:
    # - all aliases and full slash-containing selectors resolve without truncation
    # - unknown models fail closed
    # - --no-fallback preserves exactly one provider/model target
    class PiGlm53TargetTest < AceLlmTestCase
      def real_parser
        registry = Molecules::ClientRegistry.new
        Molecules::ProviderModelParser.new(registry: registry)
      end

      def assert_resolves_to(input, provider, model)
        result = real_parser.parse(input)
        assert result.valid?, "expected '#{input}' to resolve, got error: #{result.error}"
        assert_equal provider, result.provider, "provider mismatch for '#{input}'"
        assert_equal model, result.model, "model mismatch for '#{input}' (truncation?)"
      end

      def test_global_pi_alias_resolves_to_flash_default
        assert_resolves_to("pi", "pi", "zai/glm-5.3-flash")
      end

      def test_glm_model_aliases_resolve_to_exact_live_targets
        assert_resolves_to("pi:glm", "pi", "zai/glm-5.3")
        assert_resolves_to("pi:glmflash", "pi", "zai/glm-5.3-flash")
        assert_resolves_to("pi:glmhighspeed", "pi", "zai/glm-5.3-highspeed")
      end

      def test_full_slash_selectors_resolve_without_truncation
        assert_resolves_to("pi:zai/glm-5.3", "pi", "zai/glm-5.3")
        assert_resolves_to("pi:zai/glm-5.3-flash", "pi", "zai/glm-5.3-flash")
        assert_resolves_to("pi:zai/glm-5.3-highspeed", "pi", "zai/glm-5.3-highspeed")
      end

      def test_obsolete_glm_aliases_are_gone
        result = real_parser.parse("pi:glmturbo")
        assert result.valid?, "expected passthrough parse, got error: #{result.error}"
        refute_equal "zai/glm-5-turbo", result.model
        assert_equal "glmturbo", result.model, "obsolete alias must not map to any live target"
      end

      FakeClient = Struct.new(:received_options)

      class FakeFallbackRegistry
        def initialize(clients)
          @clients = clients
        end

        def available_providers
          @clients.keys
        end

        def models_for_provider(_provider)
          []
        end

        def resolve_alias(input)
          input
        end

        def get_client(provider, **_opts)
          @clients.fetch(provider)
        end
      end

      def test_unknown_model_fails_closed_with_no_fallback
        client = FakeClient.new
        attempts = 0
        client.define_singleton_method(:generate) do |_messages, **_options|
          attempts += 1
          raise Ace::LLM::ProviderError, "unknown model rejected"
        end
        registry = FakeFallbackRegistry.new("pi" => client)
        fallback_config = Models::FallbackConfig.new(enabled: false)

        assert_raises(Ace::LLM::ProviderError) do
          QueryInterface.send(
            :execute_with_fallback,
            provider: "pi",
            model: "zai/glm-9.9-unknown",
            messages: [{role: "user", content: "hi"}],
            generation_opts: {},
            registry: registry,
            fallback_config: fallback_config,
            timeout: 60,
            debug: false,
            role_fallbacks: nil,
            preset: nil,
            thinking_level: nil,
            option_builder: ->(_target) { {} }
          )
        end

        assert_equal 1, attempts, "unknown model must fail closed with no fallback attempts"
      end

      def test_no_fallback_preserves_one_exact_provider_model_target
        captured = {}

        QueryInterface.stub(
          :execute_with_fallback,
          lambda { |**kwargs|
            captured[:provider] = kwargs[:provider]
            captured[:model] = kwargs[:model]
            captured[:fallback_config] = kwargs[:fallback_config]
            {text: "ok", metadata: {}}
          }
        ) do
          QueryInterface.query("pi:glmflash", "test prompt", fallback: false)
        end

        assert_equal "pi", captured[:provider]
        assert_equal "zai/glm-5.3-flash", captured[:model]
        assert captured[:fallback_config].disabled?, "expected fallback to be disabled"
        assert_empty captured[:fallback_config].providers
      end
    end
  end
end
