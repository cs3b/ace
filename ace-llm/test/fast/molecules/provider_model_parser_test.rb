# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/llm/molecules/provider_model_parser"

module Ace
  module LLM
    module Molecules
      class ProviderModelParserTest < AceLlmTestCase
        StubAliasResolver = Struct.new(:resolved) do
          def resolve(input)
            return input if resolved.nil?
            resolved.fetch(input, input)
          end

          def available_aliases
            {global: {}, providers: {}}
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

        StubRoleResolver = Struct.new(:resolved) do
          def resolve(role_name)
            resolved.fetch(role_name)
          end

          def resolve_with_candidates(role_name)
            [resolved.fetch(role_name), []]
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
            assert_match(/ace-llm --list-providers/, result.error)
          end
        end

        def test_parse_returns_unknown_provider_error_for_unconfigured_provider
          registry = StubRegistry.new(["google"], {"google" => ["gemini-2.5-flash"]})
          parser = ProviderModelParser.new(alias_resolver: StubAliasResolver.new(nil), registry: registry)
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("nonexistent:model")

            refute result.valid?
            assert_equal "Unknown provider: nonexistent. Supported providers: google. Run `ace-llm --list-providers` for available providers and configuration guidance.", result.error
          end
        end

        def test_parse_resolves_global_alias_token_to_provider_and_model
          registry = StubRegistry.new(["google"], {"google" => ["gemini-2.5-flash", "gemini-flash-lite-latest"]})
          resolver = StubAliasResolver.new({
            "glite" => "google:lite",
            "google:lite" => "google:gemini-flash-lite-latest"
          })
          parser = ProviderModelParser.new(alias_resolver: resolver, registry: registry)
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("glite")

            assert result.valid?
            assert_equal "google", result.provider
            assert_equal "gemini-flash-lite-latest", result.model
            assert_nil result.preset
          end
        end

        def test_parse_resolves_global_alias_with_preset_suffix
          registry = StubRegistry.new(["google"], {"google" => ["gemini-2.5-flash", "gemini-flash-lite-latest"]})
          resolver = StubAliasResolver.new({
            "glite" => "google:lite",
            "google:lite" => "google:gemini-flash-lite-latest"
          })
          parser = ProviderModelParser.new(alias_resolver: resolver, registry: registry)
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("glite@ro")

            assert result.valid?
            assert_equal "google", result.provider
            assert_equal "gemini-flash-lite-latest", result.model
            assert_equal "ro", result.preset
          end
        end

        def test_parse_resolves_role_reference
          registry = StubRegistry.new(["google"], {"google" => ["gemini-flash-lite-latest"]})
          resolver = StubAliasResolver.new(nil)
          parser = ProviderModelParser.new(alias_resolver: resolver, registry: registry)
          parser.instance_variable_set(:@role_resolver, StubRoleResolver.new({"reviewer" => "google:gemini-flash-lite-latest"}))
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("role:reviewer")

            assert result.valid?
            assert_equal "google", result.provider
            assert_equal "gemini-flash-lite-latest", result.model
            assert_equal "role:reviewer", result.original_input
          end
        end

        def test_parse_role_caller_preset_override_wins
          registry = StubRegistry.new(["google"], {"google" => ["gemini-flash-lite-latest"]})
          parser = ProviderModelParser.new(alias_resolver: StubAliasResolver.new(nil), registry: registry)
          parser.instance_variable_set(:@role_resolver, StubRoleResolver.new({"reviewer" => "google:gemini-flash-lite-latest@yolo"}))
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("role:reviewer@ro")

            assert result.valid?
            assert_equal "ro", result.preset
          end
        end

        def test_parse_role_caller_thinking_override_wins
          registry = StubRegistry.new(["google"], {"google" => ["gemini-flash-lite-latest"]})
          parser = ProviderModelParser.new(alias_resolver: StubAliasResolver.new(nil), registry: registry)
          parser.instance_variable_set(:@role_resolver, StubRoleResolver.new({"reviewer" => "google:gemini-flash-lite-latest:high"}))
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("role:reviewer:low")

            assert result.valid?
            assert_equal "low", result.thinking_level
          end
        end

        def test_parse_role_caller_combined_override_wins
          registry = StubRegistry.new(["google"], {"google" => ["gemini-flash-lite-latest"]})
          parser = ProviderModelParser.new(alias_resolver: StubAliasResolver.new(nil), registry: registry)
          parser.instance_variable_set(:@role_resolver, StubRoleResolver.new({"reviewer" => "google:gemini-flash-lite-latest:high@yolo"}))
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("role:reviewer:low@ro")

            assert result.valid?
            assert_equal "low", result.thinking_level
            assert_equal "ro", result.preset
          end
        end

        def test_parse_role_errors_for_empty_role_name
          registry = StubRegistry.new(["google"], {"google" => ["gemini-flash-lite-latest"]})
          parser = ProviderModelParser.new(alias_resolver: StubAliasResolver.new(nil), registry: registry)
          configuration = StubConfiguration.new([], ["google"])

          Ace::LLM.stub(:configuration, configuration) do
            result = parser.parse("role:")

            refute result.valid?
            assert_match(/role name cannot be empty/, result.error)
          end
        end
      end
    end
  end
end
