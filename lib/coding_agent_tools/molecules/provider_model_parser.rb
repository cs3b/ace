# frozen_string_literal: true

require_relative "../models/default_model_config"

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
      # Supported LLM providers
      SUPPORTED_PROVIDERS = %w[
        google
        anthropic
        openai
        mistral
        together_ai
        lmstudio
      ].freeze

      # Dynamic aliases mapping to provider:model combinations
      DYNAMIC_ALIASES = {
        "gflash" => "google:gemini-2.5-flash",
        "gpro" => "google:gemini-2.5-pro",
        "csonet" => "anthropic:claude-4-0-sonnet-latest",
        "copus" => "anthropic:claude-4-0-opus-latest",
        "o4mini" => "openai:gpt-4o-mini",
        "o3" => "openai:o3"
      }.freeze

      # Get the default model configuration instance
      #
      # @return [CodingAgentTools::Models::DefaultModelConfig] The configuration instance
      def default_config
        @default_config ||= CodingAgentTools::Models::DefaultModelConfig.default
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
        return create_error_result(input, "Input cannot be nil or empty") if input.nil? || input.strip.empty?

        original_input = input

        # Handle dynamic aliases first
        if DYNAMIC_ALIASES.key?(input.strip)
          input = DYNAMIC_ALIASES[input.strip]
        end

        # Parse provider:model syntax or provider-only
        parts = input.strip.split(":", 2)

        if parts.length == 1
          # Provider-only syntax, use default model
          provider = parts[0].strip.downcase

          # Validate provider
          unless SUPPORTED_PROVIDERS.include?(provider)
            return create_error_result(input, "Unknown provider: #{provider}. Supported providers: #{SUPPORTED_PROVIDERS.join(", ")}")
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
          unless SUPPORTED_PROVIDERS.include?(provider)
            return create_error_result(input, "Unknown provider: #{provider}. Supported providers: #{SUPPORTED_PROVIDERS.join(", ")}")
          end

          # Validate model is not empty
          if model.empty?
            return create_error_result(input, "Model name cannot be empty")
          end

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
        SUPPORTED_PROVIDERS.dup
      end

      # Returns all available dynamic aliases
      #
      # @return [Hash<String, String>] Mapping of aliases to provider:model combinations
      def dynamic_aliases
        DYNAMIC_ALIASES.dup
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
        SUPPORTED_PROVIDERS.include?(provider.strip.downcase)
      end

      # Resolves an alias to its full provider:model form
      #
      # @param alias_name [String] The alias to resolve
      # @return [String, nil] The provider:model string or nil if not found
      def resolve_alias(alias_name)
        return nil if alias_name.nil?
        DYNAMIC_ALIASES[alias_name.strip]
      end

      # Checks if input is a known dynamic alias
      #
      # @param input [String] The input to check
      # @return [Boolean] True if input is a known alias
      def alias?(input)
        return false if input.nil?
        DYNAMIC_ALIASES.key?(input.strip)
      end

      private

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
