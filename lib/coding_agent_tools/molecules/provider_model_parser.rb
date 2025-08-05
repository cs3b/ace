# frozen_string_literal: true

require_relative '../models/default_model_config'
require_relative 'client_factory'

module CodingAgentTools
  module Molecules
    # ProviderModelParser handles parsing and validation of provider:model syntax
    # for the unified LLM query interface. It supports all 6 providers:
    # google, anthropic, openai, mistral, together_ai, and lmstudio.
    #
    # @example Basic usage
    #   parser = ProviderModelParser.new
    #   result = parser.parse("google:gemini-2.5-flash")
    #   result.provider # => "google"
    #   result.model # => "gemini-2.5-flash"
    #
    # @example With validation
    #   parser = ProviderModelParser.new
    #   result = parser.parse("invalid:model")
    #   result.valid? # => false
    #   result.error # => "Unknown provider: invalid"
    class ProviderModelParser
      class << self
        # Register a provider and its aliases dynamically
        # Called by ClientFactory during client registration
        # @param provider_name [String] The provider identifier
        # @param aliases [Hash] Provider-specific aliases
        def register_provider(provider_name, aliases = {})
          registered_providers << provider_name unless registered_providers.include?(provider_name)
          registered_aliases.merge!(aliases)
        end

        # Get dynamically registered providers
        # @return [Array<String>] List of registered provider names
        def registered_providers
          @registered_providers ||= []
        end

        # Get dynamically registered aliases
        # @return [Hash<String, String>] Mapping of aliases to provider:model combinations
        def registered_aliases
          @registered_aliases ||= {}
        end

        # Clear dynamic registrations (mainly for testing)
        def clear_registrations!
          @registered_providers = []
          @registered_aliases = {}
        end
      end

      # Get the default model configuration instance
      #
      # @return [CodingAgentTools::Models::DefaultModelConfig] The configuration instance
      def default_config
        @default_config ||= CodingAgentTools::Models::DefaultModelConfig.default
      end

      # Ensure all client classes for supported providers are loaded
      # This triggers Zeitwerk autoloading and client registration
      def ensure_providers_loaded
        return if @providers_loaded

        # Dynamically discover client files in the organisms directory
        organisms_path = File.expand_path('../organisms', __dir__)
        client_files = Dir.glob(File.join(organisms_path, '*_client.rb'))

        client_files.each do |file|
          filename = File.basename(file, '.rb')

          # Skip base classes and abstract classes
          next if filename.start_with?('base_')

          # Convert filename to class name with proper acronym handling
          class_name = filename_to_class_name(filename)

          begin
            # Access the class to trigger Zeitwerk autoloading
            client_class = CodingAgentTools::Organisms.const_get(class_name)

            # Verify it's actually a client class that should be registered
            next unless client_class.respond_to?(:provider_name)

            # Get provider_name safely - skip if it raises NotImplementedError
            begin
              provider_key = client_class.provider_name
            rescue NotImplementedError
              next # Skip abstract classes that don't implement provider_name
            end

            next unless provider_key

            # Force registration with ClientFactory (fallback if inherited hook didn't work)
            Molecules::ClientFactory.register(provider_key, client_class)
          rescue NameError => e
            # Class doesn't exist or can't be loaded - log warning in debug mode but don't fail
            warn "Warning: Could not load client class #{class_name}: #{e.message}" if ENV['DEBUG']
          end
        end

        @providers_loaded = true
      end

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

      # Parses a provider:model string or dynamic alias
      #
      # @param input [String] The provider:model string or alias to parse
      # @return [ParseResult] The parsed result with provider, model, and validation info
      def parse(input)
        return create_error_result(input, 'Input cannot be nil or empty') if input.nil? || input.strip.empty?

        # Ensure all provider client classes are loaded for registration
        ensure_providers_loaded

        original_input = input

        # Handle dynamic aliases first
        input = dynamic_aliases[input.strip] if dynamic_aliases.key?(input.strip)

        # Parse provider:model syntax or provider-only
        parts = input.strip.split(':', 2)

        if parts.length == 1
          # Provider-only syntax, use default model
          provider = parts[0].strip.downcase

          # Validate provider
          unless supported_providers.include?(provider)
            return create_error_result(input,
              "Unknown provider: #{provider}. Supported providers: #{supported_providers.join(", ")}")
          end

          # Use default model for provider
          model = default_config.default_model_for(provider)

          # Create successful result
          ParseResult.new(provider, model, true, nil, original_input)
        elsif parts.length == 2
          # provider:model syntax
          provider, model = parts
          provider = provider.strip.downcase
          model = model.strip

          # Validate provider
          unless supported_providers.include?(provider)
            return create_error_result(input,
              "Unknown provider: #{provider}. Supported providers: #{supported_providers.join(", ")}")
          end

          # Validate model is not empty
          return create_error_result(input, 'Model name cannot be empty') if model.empty?

          # Create successful result
          ParseResult.new(provider, model, true, nil, original_input)
        else
          create_error_result(input, "Invalid format. Expected 'provider:model', 'provider', or alias")
        end
      end

      # Returns all supported providers
      #
      # @return [Array<String>] List of supported provider names
      def supported_providers
        # Ensure providers are loaded first
        ensure_providers_loaded
        self.class.registered_providers.sort
      end

      # Returns all available dynamic aliases
      #
      # @return [Hash<String, String>] Mapping of aliases to provider:model combinations
      def dynamic_aliases
        # Ensure providers are loaded first
        ensure_providers_loaded
        self.class.registered_aliases.dup
      end

      # Returns default models for all providers
      #
      # @return [Hash<String, String>] Mapping of providers to default models
      def default_models
        default_config.all_models
      end

      # Gets the default model for a specific provider
      #
      # @param provider [String] The provider name
      # @return [String, nil] The default model or nil if provider not found
      def default_model_for(provider)
        return nil if provider.nil? || provider.strip.empty?

        begin
          default_config.default_model_for(provider.strip.downcase)
        rescue CodingAgentTools::Models::DefaultModelConfig::UnsupportedProviderError
          nil
        end
      end

      # Validates if a provider is supported
      #
      # @param provider [String] The provider name to validate
      # @return [Boolean] True if the provider is supported
      def valid_provider?(provider)
        return false if provider.nil?

        supported_providers.include?(provider.strip.downcase)
      end

      # Resolves an alias to its full provider:model form
      #
      # @param alias_name [String] The alias to resolve
      # @return [String, nil] The provider:model string or nil if not found
      def resolve_alias(alias_name)
        return nil if alias_name.nil?

        dynamic_aliases[alias_name.strip]
      end

      # Checks if input is a known dynamic alias
      #
      # @param input [String] The input to check
      # @return [Boolean] True if input is a known alias
      def alias?(input)
        return false if input.nil?

        dynamic_aliases.key?(input.strip)
      end

      private

      # Converts a filename to the appropriate class name using algorithmic transformation
      # @param filename [String] The filename (without .rb extension)
      # @return [String] The class name
      def filename_to_class_name(filename)
        # Simple algorithmic transformation - no special cases needed
        filename.split('_').map(&:capitalize).join
      end

      # Creates an error result for invalid input
      #
      # @param input [String] The original input
      # @param error_message [String] The error message
      # @return [ParseResult] Error result
      def create_error_result(original_input, error_message)
        ParseResult.new(nil, nil, false, error_message, original_input)
      end
    end
  end
end
