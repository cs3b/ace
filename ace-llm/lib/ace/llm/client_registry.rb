# frozen_string_literal: true

module Ace
  module LLM
    # ClientRegistry provides a simple registration mechanism for LLM provider clients
    # This allows external gems to add new providers without modifying ace-llm
    class ClientRegistry
      class << self
        # Get the registry hash
        def registry
          @registry ||= default_clients
        end

        # Register a client for a provider
        # @param provider_name [String] The provider identifier (e.g., "ollama", "groq")
        # @param client_class [Class] The client class (must inherit from BaseClient)
        def register(provider_name, client_class)
          unless client_class < Organisms::BaseClient
            raise ArgumentError, "Client class must inherit from Ace::LLM::Organisms::BaseClient"
          end

          registry[provider_name.to_s] = client_class
        end

        # Get a client class for a provider
        # @param provider_name [String] The provider identifier
        # @return [Class, nil] The client class or nil if not found
        def get(provider_name)
          registry[provider_name.to_s]
        end

        # Check if a provider is registered
        # @param provider_name [String] The provider identifier
        # @return [Boolean] True if provider is registered
        def registered?(provider_name)
          registry.key?(provider_name.to_s)
        end

        # Get list of all registered providers
        # @return [Array<String>] List of provider names
        def providers
          registry.keys.sort
        end

        # Clear all registrations (mainly for testing)
        def clear!
          @registry = nil
        end

        # Load client registrations from external gems
        # This looks for ace-llm-* gems and loads their clients
        def load_extensions
          Gem.find_files("ace/llm_extensions.rb").each do |path|
            require path
          rescue LoadError => e
            warn "Failed to load LLM extension from #{path}: #{e.message}" if ENV["DEBUG"]
          end
        end

        private

        # Default built-in clients
        def default_clients
          {
            "google" => Organisms::GoogleClient,
            "openai" => Organisms::OpenAIClient,
            "anthropic" => Organisms::AnthropicClient,
            "mistral" => Organisms::MistralClient,
            "togetherai" => Organisms::TogetherAIClient,
            "lmstudio" => Organisms::LMStudioClient
          }
        end
      end
    end
  end
end