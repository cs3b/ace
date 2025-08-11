# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # ClientFactory provides a centralized way to instantiate LLM provider clients
    # This eliminates the need for case statements when adding new providers
    class ClientFactory
      class UnknownProviderError < StandardError; end

      class << self
        # Register a client class for a specific provider
        # @param provider_name [String] The provider identifier (e.g., "google", "anthropic")
        # @param client_class [Class] The client class to instantiate for this provider
        def register(provider_name, client_class)
          @registry ||= {}
          @registry[provider_name] = client_class

          # Collect provider metadata for dynamic discovery
          collect_provider_metadata(provider_name, client_class)
        end

        # Build a client instance for the specified provider
        # @param provider_name [String] The provider identifier
        # @param options [Hash] Options to pass to the client constructor
        # @return [BaseClient] An instance of the appropriate client class
        # @raise [UnknownProviderError] If the provider is not registered
        def build(provider_name, options = {})
          @registry ||= {}
          client_class = @registry[provider_name]

          if client_class.nil?
            raise UnknownProviderError, "Unknown provider '#{provider_name}'. " \
                                       "Registered providers: #{registered_providers.join(", ")}"
          end

          client_class.new(**options)
        end

        # Get list of registered provider names
        # @return [Array<String>] List of provider names
        def registered_providers
          @registry ||= {}
          @registry.keys.sort
        end

        # Get the registry hash (mainly for testing)
        # @return [Hash] The provider registry
        def registry
          @registry ||= {}
        end

        # Clear the registry (mainly for testing)
        def clear_registry!
          @registry = {}
        end

        private

        # Collect provider metadata and notify ProviderModelParser
        # @param provider_name [String] The provider identifier
        # @param client_class [Class] The client class
        def collect_provider_metadata(provider_name, client_class)
          # Get dynamic aliases if the client class supports them
          aliases = {}
          aliases = client_class.dynamic_aliases || {} if client_class.respond_to?(:dynamic_aliases)

          # Notify ProviderModelParser about the new provider
          require_relative "provider_model_parser"
          ProviderModelParser.register_provider(provider_name, aliases)
        end
      end
    end
  end
end
