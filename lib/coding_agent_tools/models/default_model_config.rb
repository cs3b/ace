# frozen_string_literal: true

module CodingAgentTools
  module Models
    # DefaultModelConfig provides centralized configuration for default models
    # across all LLM providers. This eliminates scattered hardcoded constants
    # and provides a single source of truth for fallback model selections.
    #
    # @example Basic usage
    #   config = DefaultModelConfig.new
    #   config.default_model_for("google") # => "gemini-2.0-flash-lite"
    #   config.default_model_for("anthropic") # => "claude-3-5-haiku-20241022"
    #
    # @example With custom configuration
    #   custom_config = { "google" => "gemini-pro" }
    #   config = DefaultModelConfig.new(custom_config)
    #   config.default_model_for("google") # => "gemini-pro"
    class DefaultModelConfig
      # Default model mappings for all supported providers
      DEFAULT_MODELS = {
        "google" => "gemini-2.0-flash-lite",
        "anthropic" => "claude-3-5-haiku-20241022",
        "openai" => "gpt-4o-mini",
        "mistral" => "open-mistral-nemo",
        "together_ai" => "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
        "lmstudio" => "mistralai/devstral-small-2505"
      }.freeze

      # List of all supported providers
      SUPPORTED_PROVIDERS = DEFAULT_MODELS.keys.freeze

      # Error raised when requesting default model for unsupported provider
      class UnsupportedProviderError < StandardError; end

      # Error raised when configuration is invalid
      class InvalidConfigurationError < StandardError; end

      # Initialize with optional custom configuration
      #
      # @param custom_config [Hash<String, String>] Optional custom provider-to-model mappings
      # @raise [InvalidConfigurationError] If custom configuration is invalid
      def initialize(custom_config = {})
        # Validate input type before attempting merge
        normalized_config = custom_config || {}
        unless normalized_config.is_a?(Hash)
          raise InvalidConfigurationError, "Configuration must be a hash"
        end

        @config = DEFAULT_MODELS.merge(normalized_config)
        validate_configuration!
      end

      # Get default model for a provider
      #
      # @param provider [String] The provider name (e.g., "google", "anthropic")
      # @return [String] The default model for the provider
      # @raise [UnsupportedProviderError] If provider is not supported
      def default_model_for(provider)
        normalized_provider = normalize_provider(provider)

        unless supported_provider?(normalized_provider)
          raise UnsupportedProviderError,
            "Unsupported provider: #{provider}. Supported providers: #{supported_providers.join(", ")}"
        end

        @config[normalized_provider]
      end

      # Check if a provider is supported
      #
      # @param provider [String] The provider name to check
      # @return [Boolean] True if the provider is supported
      def supported_provider?(provider)
        return false if provider.nil?
        normalized_provider = normalize_provider(provider)
        @config.key?(normalized_provider)
      end

      # Get list of all supported providers
      #
      # @return [Array<String>] List of supported provider names
      def supported_providers
        @config.keys.sort
      end

      # Get all configured models as a hash
      #
      # @return [Hash<String, String>] Provider-to-model mappings
      def all_models
        @config.dup
      end

      # Check if configuration has a default model for all required providers
      #
      # @return [Boolean] True if all providers have default models
      def complete?
        SUPPORTED_PROVIDERS.all? { |provider| @config.key?(provider) && !@config[provider].nil? }
      end

      # Get any missing providers from configuration
      #
      # @return [Array<String>] List of providers without default models
      def missing_providers
        SUPPORTED_PROVIDERS.reject { |provider| @config.key?(provider) && !@config[provider].nil? }
      end

      # Load configuration from YAML file
      #
      # @param file_path [String] Path to YAML configuration file
      # @return [DefaultModelConfig] New instance with loaded configuration
      # @raise [InvalidConfigurationError] If file cannot be loaded or is invalid
      def self.load_from_file(file_path)
        require "yaml"

        unless File.exist?(file_path)
          raise InvalidConfigurationError, "Configuration file not found: #{file_path}"
        end

        begin
          custom_config = YAML.safe_load_file(file_path)
          new(custom_config)
        rescue => e
          raise InvalidConfigurationError, "Failed to load configuration from #{file_path}: #{e.message}"
        end
      end

      # Create default instance (convenience method)
      #
      # @return [DefaultModelConfig] New instance with default configuration
      def self.default
        @default_instance ||= new
      end

      private

      # Normalize provider name (lowercase, handle aliases)
      #
      # @param provider [String] Raw provider name
      # @return [String] Normalized provider name
      def normalize_provider(provider)
        return "" if provider.nil?

        normalized = provider.to_s.strip.downcase

        # Handle common aliases
        case normalized
        when "lms", "lm_studio"
          "lmstudio"
        when "openai", "open_ai"
          "openai"
        when "together", "together_ai"
          "together_ai"
        else
          normalized
        end
      end

      # Validate the current configuration
      #
      # @raise [InvalidConfigurationError] If configuration is invalid
      def validate_configuration!
        # Config type is already validated in initialize, so we can skip that check here

        @config.each do |provider, model|
          if provider.nil? || provider.to_s.strip.empty?
            raise InvalidConfigurationError, "Provider name cannot be nil or empty"
          end

          if model.nil? || model.to_s.strip.empty?
            raise InvalidConfigurationError, "Model name cannot be nil or empty for provider: #{provider}"
          end
        end

        # Check for any missing required providers
        missing = missing_providers
        unless missing.empty?
          raise InvalidConfigurationError,
            "Missing default models for required providers: #{missing.join(", ")}"
        end
      end
    end
  end
end
