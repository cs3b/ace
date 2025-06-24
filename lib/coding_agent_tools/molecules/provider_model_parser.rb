# frozen_string_literal: true

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

        # Parse provider:model syntax
        parts = input.strip.split(":", 2)

        if parts.length != 2
          return create_error_result(input, "Invalid format. Expected 'provider:model' or alias")
        end

        provider, model = parts
        provider = provider.strip.downcase
        model = model.strip

        # Validate provider
        unless SUPPORTED_PROVIDERS.include?(provider)
          return create_error_result(input, "Unknown provider: #{provider}. Supported providers: #{SUPPORTED_PROVIDERS.join(', ')}")
        end

        # Validate model is not empty
        if model.empty?
          return create_error_result(input, "Model name cannot be empty")
        end

        # Create successful result
        ParseResult.new(provider, model, true, nil, original_input)
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
