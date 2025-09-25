# frozen_string_literal: true

require_relative "client_registry"

module Ace
  module LLM
    module Molecules
      # ProviderModelParser handles parsing and validation of provider:model syntax
      # for the unified LLM query interface
      class ProviderModelParser
        # All provider information now comes from the registry

        # Result object for parsed provider:model combinations
        ParseResult = Struct.new(:provider, :model, :valid, :error, :original_input) do
          def valid?
            valid
          end

          def invalid?
            !valid?
          end

          def to_s
            "#{provider}:#{model}"
          end
        end

        attr_reader :alias_resolver, :registry

        # Initialize parser
        # @param alias_resolver [LlmAliasResolver, nil] Optional alias resolver
        # @param registry [ClientRegistry, nil] Optional client registry
        def initialize(alias_resolver: nil, registry: nil)
          @alias_resolver = alias_resolver || LlmAliasResolver.new
          @registry = registry || ClientRegistry.new
        end

        # Parse a provider:model string or alias
        # @param input [String] The provider:model string or alias to parse
        # @return [ParseResult] The parsed result with provider, model, and validation info
        def parse(input)
          return create_error_result(input, "Input cannot be nil or empty") if input.nil? || input.strip.empty?

          original_input = input.strip

          # Try to resolve as an alias first
          resolved_input = @alias_resolver.resolve(original_input)

          # Parse provider:model syntax or provider-only
          parts = resolved_input.split(":", 2)

          if parts.length == 1
            # Provider-only syntax, use default model
            provider = normalize_provider(parts[0])

            # Validate provider
            unless supported_providers.include?(provider)
              return create_error_result(original_input,
                "Unknown provider: #{provider}. Supported providers: #{supported_providers.join(", ")}")
            end

            # Use default model for provider
            model = default_model_for(provider)
            ParseResult.new(provider, model, true, nil, original_input)
          else
            # Provider:model syntax
            provider = normalize_provider(parts[0])
            model = parts[1].strip

            # Validate provider
            unless supported_providers.include?(provider)
              return create_error_result(original_input,
                "Unknown provider: #{provider}. Supported providers: #{supported_providers.join(", ")}")
            end

            # Model validation happens at the client level
            ParseResult.new(provider, model, true, nil, original_input)
          end
        end

        # Get list of supported providers
        # @return [Array<String>] List of provider names
        def supported_providers
          @registry.available_providers
        end

        # Get default model for a provider
        # @param provider [String] Provider name
        # @return [String, nil] Default model name or nil if provider not found
        def default_model_for(provider)
          # Get from registry only - no hardcoded fallbacks
          models = @registry.models_for_provider(provider)
          models&.first
        end

        # Get all available aliases from the resolver
        # @return [Hash] Available aliases
        def dynamic_aliases
          return {} unless @alias_resolver

          # Get global aliases
          global = @alias_resolver.available_aliases[:global] || {}

          # Merge with provider-specific aliases if needed
          providers = @alias_resolver.available_aliases[:providers] || {}

          # Flatten provider aliases into global namespace with provider prefix
          flattened = {}
          providers.each do |provider, aliases|
            aliases.each do |alias_name, model|
              flattened["#{provider}:#{alias_name}"] = "#{provider}:#{model}"
            end
          end

          global.merge(flattened)
        end

        private

        # Normalize provider name
        # @param provider [String] Provider name to normalize
        # @return [String] Normalized provider name
        def normalize_provider(provider)
          provider.strip.downcase.gsub(/[-_]/, "")
        end

        # Create an error result
        # @param input [String] Original input
        # @param error [String] Error message
        # @return [ParseResult] Error result
        def create_error_result(input, error)
          ParseResult.new(nil, nil, false, error, input)
        end
      end
    end
  end
end