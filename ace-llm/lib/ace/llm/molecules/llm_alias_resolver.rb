# frozen_string_literal: true

require_relative "client_registry"

module Ace
  module LLM
    module Molecules
      # LlmAliasResolver resolves LLM aliases to their actual model names
      # Now delegates to ClientRegistry which manages aliases from provider configs
      class LlmAliasResolver
        attr_reader :registry

        # Initialize alias resolver with optional registry
        # @param registry [ClientRegistry, nil] Optional registry to use
        def initialize(registry: nil)
          @registry = registry || ClientRegistry.new
        end

        # Resolve an alias or model name to its actual provider:model format
        # @param input [String] The input model name or alias
        # @return [String] The resolved provider:model format
        def resolve(input)
          @registry.resolve_alias(input)
        end

        # Check if a given input is an alias
        # @param input [String] The input to check
        # @return [Boolean] True if the input is a recognized alias
        def alias?(input)
          resolved = @registry.resolve_alias(input)
          resolved != input
        end

        # Get all available aliases
        # @return [Hash] Hash containing global and model aliases
        def available_aliases
          @registry.available_aliases
        end

        # Get aliases for a specific provider
        # @param provider [String] Provider name
        # @return [Hash] Provider-specific model aliases
        def provider_aliases(provider)
          normalized = provider.to_s.strip.downcase.gsub(/[-_]/, "")
          @registry.available_aliases[:model][normalized] || {}
        end
      end
    end
  end
end