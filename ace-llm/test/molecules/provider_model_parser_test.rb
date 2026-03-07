# frozen_string_literal: true

require_relative "../test_helper"
require "ace/llm/molecules/provider_model_parser"

module Ace
  module LLM
    module Molecules
      class ProviderModelParserTest < AceLlmTestCase
        StubAliasResolver = Struct.new(:resolved) do
          def resolve(input)
            resolved || input
          end
        end

        StubRegistry = Struct.new(:providers, :models) do
          def available_providers
            providers
          end

          def models_for_provider(provider)
            models[provider]
          end
        end

        StubConfiguration = Struct.new(:inactive, :active_provider_names) do
          def provider_inactive?(provider)
            inactive.include?(provider)
          end
        end

        def test_parse_returns_inactive_provider_error
          registry = StubRegistry.new(["google"], {"google" => ["gemini-2.5-flash"]})
          parser = ProviderModelParser.new(alias_resolver: StubAliasResolver.new(nil), registry: registry)
          configuration = StubConfiguration.new(["deepseek"], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("deepseek:deepseek-chat")

            refute result.valid?
            assert_match(/Provider 'deepseek' is inactive/, result.error)
            assert_match(/Active providers: google/, result.error)
          end
        end

        def test_parse_returns_unknown_provider_error_for_unconfigured_provider
          registry = StubRegistry.new(["google"], {"google" => ["gemini-2.5-flash"]})
          parser = ProviderModelParser.new(alias_resolver: StubAliasResolver.new(nil), registry: registry)
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("nonexistent:model")

            refute result.valid?
            assert_equal "Unknown provider: nonexistent. Supported providers: google", result.error
          end
        end
      end
    end
  end
end
