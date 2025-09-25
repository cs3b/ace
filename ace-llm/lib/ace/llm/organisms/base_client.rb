# frozen_string_literal: true

require_relative "../atoms/env_reader"
require_relative "../atoms/http_client"

module Ace
  module LLM
    module Organisms
      # BaseClient provides common functionality for all LLM provider clients
      class BaseClient
        # Default generation configuration
        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: nil,
          top_p: nil,
          top_k: nil
        }.freeze

        attr_reader :model, :base_url, :api_key, :generation_config, :http_client

        # Initialize base client with common configuration
        # @param api_key [String, nil] API key (uses env if nil)
        # @param model [String, nil] Model to use (uses default if nil)
        # @param options [Hash] Additional options
        def initialize(api_key: nil, model: nil, **options)
          # Prevent direct instantiation of abstract base class
          if instance_of?(BaseClient)
            raise NotImplementedError, "BaseClient is abstract and cannot be instantiated directly"
          end

          @model = model || default_model
          @base_url = options.fetch(:base_url, self.class::API_BASE_URL)
          @generation_config = self.class::DEFAULT_GENERATION_CONFIG.merge(
            options.fetch(:generation_config, {})
          )

          # Setup API key
          @api_key = api_key || fetch_api_key_from_env

          # Setup HTTP client
          @http_client = Atoms::HTTPClient.new(
            timeout: options.fetch(:timeout, 30),
            max_retries: options.fetch(:max_retries, 3)
          )

          @options = options
        end

        # Generate a response from the LLM
        # @param messages [Array<Hash>] Conversation messages
        # @param options [Hash] Generation options
        # @return [Hash] Response with text and metadata
        def generate(messages, **options)
          raise NotImplementedError, "Subclasses must implement #generate"
        end

        # Get the provider name for this client
        # @return [String] Provider name
        def provider_name
          self.class.provider_name
        end

        # Get the provider name (class method)
        # @return [String] Provider name
        def self.provider_name
          raise NotImplementedError, "#{name} must implement .provider_name"
        end

        # Check if this client needs API credentials
        # @return [Boolean] True if credentials are required
        def needs_credentials?
          true
        end

        protected

        # Get the default model for this provider
        # @return [String] Default model name
        def default_model
          self.class::DEFAULT_MODEL
        rescue NameError
          "default"
        end

        # Fetch API key from environment
        # @return [String, nil] API key
        def fetch_api_key_from_env
          return nil unless needs_credentials?

          key = Atoms::EnvReader.get_api_key(provider_name)
          if key.nil? || key.empty?
            raise Ace::LLM::AuthenticationError,
              "No API key found for #{provider_name}. " \
              "Please set #{api_key_env_vars.join(" or ")}"
          end
          key
        end

        # Get environment variable names for API key
        # @return [Array<String>] Environment variable names
        def api_key_env_vars
          case provider_name.downcase
          when "google"
            ["GEMINI_API_KEY", "GOOGLE_API_KEY"]
          when "openai"
            ["OPENAI_API_KEY"]
          when "anthropic"
            ["ANTHROPIC_API_KEY"]
          when "mistral"
            ["MISTRAL_API_KEY"]
          when "togetherai"
            ["TOGETHER_API_KEY", "TOGETHERAI_API_KEY"]
          else
            ["#{provider_name.upcase}_API_KEY"]
          end
        end

        # Build messages for API request
        # @param messages [Array<Hash>, String] Messages or single prompt
        # @return [Array<Hash>] Formatted messages
        def build_messages(messages)
          if messages.is_a?(String)
            [{ role: "user", content: messages }]
          elsif messages.is_a?(Array)
            messages
          else
            raise ArgumentError, "Messages must be a string or array"
          end
        end

        # Extract generation options
        # @param options [Hash] Raw options
        # @return [Hash] Generation parameters
        def extract_generation_options(options)
          gen_opts = @generation_config.dup

          # Override with provided options
          gen_opts[:temperature] = options[:temperature] if options[:temperature]
          gen_opts[:max_tokens] = options[:max_tokens] if options[:max_tokens]
          gen_opts[:top_p] = options[:top_p] if options[:top_p]
          gen_opts[:top_k] = options[:top_k] if options[:top_k]

          # Remove nil values
          gen_opts.compact
        end

        # Create response structure
        # @param text [String] Response text
        # @param metadata [Hash] Response metadata
        # @return [Hash] Structured response
        def create_response(text, metadata = {})
          {
            text: text,
            metadata: {
              provider: provider_name,
              model: @model
            }.merge(metadata)
          }
        end

        # Handle API errors
        # @param error [Exception] The error to handle
        # @raise [ProviderError] Wrapped provider error
        def handle_api_error(error)
          case error
          when Faraday::TimeoutError
            raise Ace::LLM::ProviderError, "Request timeout for #{provider_name}: #{error.message}"
          when Faraday::ConnectionFailed
            raise Ace::LLM::ProviderError, "Connection failed for #{provider_name}: #{error.message}"
          when Faraday::ClientError
            handle_client_error(error)
          else
            raise Ace::LLM::ProviderError, "#{provider_name} API error: #{error.message}"
          end
        end

        # Handle client errors (4xx responses)
        # @param error [Faraday::ClientError] Client error
        def handle_client_error(error)
          status = error.response[:status] if error.respond_to?(:response)

          case status
          when 401
            raise Ace::LLM::AuthenticationError, "Invalid API key for #{provider_name}"
          when 403
            raise Ace::LLM::AuthenticationError, "Access forbidden for #{provider_name}"
          when 404
            raise Ace::LLM::ProviderError, "Resource not found for #{provider_name}"
          when 429
            raise Ace::LLM::ProviderError, "Rate limit exceeded for #{provider_name}"
          else
            raise Ace::LLM::ProviderError, "#{provider_name} error (#{status}): #{error.message}"
          end
        end
      end
    end
  end
end