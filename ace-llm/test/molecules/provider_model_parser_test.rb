# frozen_string_literal: true

require "test_helper"

module Ace
  module LLM
    module Molecules
      class ProviderModelParserTest < AceLlmTestCase
        class StubAliasResolver
          def initialize(aliases = {})
            @aliases = aliases
          end

          def resolve(input)
            @aliases.fetch(input, input)
          end

          def available_aliases
            { global: @aliases, providers: {} }
          end
        end

        class StubRegistry
          def initialize(providers = {})
            @providers = providers
          end

          def available_providers
            @providers.keys
          end

          def models_for_provider(provider)
            @providers[provider]
          end
        end

        def setup
          super
          providers = {
            "google" => ["gemini-2.5-flash", "gemini-2.0-flash-lite"],
            "anthropic" => ["claude-sonnet-4-0"]
          }
          aliases = {
            "gflash" => "google:gemini-2.5-flash",
            "claude" => "anthropic:claude-sonnet-4-0"
          }
          @parser = ProviderModelParser.new(
            alias_resolver: StubAliasResolver.new(aliases),
            registry: StubRegistry.new(providers)
          )
        end

        def test_parses_provider_model_with_preset_suffix
          result = @parser.parse("google:gemini-2.5-flash@ro")

          assert result.valid?
          assert_equal "google", result.provider
          assert_equal "gemini-2.5-flash", result.model
          assert_equal "ro", result.preset
        end

        def test_parses_provider_only_with_preset_suffix
          result = @parser.parse("google@ro")

          assert result.valid?
          assert_equal "google", result.provider
          assert_equal "gemini-2.5-flash", result.model
          assert_equal "ro", result.preset
        end

        def test_parses_alias_with_preset_suffix
          result = @parser.parse("gflash@ro")

          assert result.valid?
          assert_equal "google", result.provider
          assert_equal "gemini-2.5-flash", result.model
          assert_equal "ro", result.preset
        end

        def test_rejects_empty_preset_name
          result = @parser.parse("google:gemini-2.5-flash@")

          assert result.invalid?
          assert_match(/preset name cannot be empty/i, result.error)
        end

        def test_keeps_legacy_inputs_unchanged_without_preset
          result = @parser.parse("claude")

          assert result.valid?
          assert_equal "anthropic", result.provider
          assert_equal "claude-sonnet-4-0", result.model
          assert_nil result.preset
        end
      end
    end
  end
end
