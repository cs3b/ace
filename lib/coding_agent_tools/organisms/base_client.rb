# frozen_string_literal: true

require_relative "../molecules/api_credentials"
require_relative "../molecules/http_request_builder"
require_relative "../molecules/api_response_parser"
require_relative "../molecules/client_factory"
require_relative "../models/default_model_config"

module CodingAgentTools
  module Organisms
    # BaseClient provides common functionality for all LLM provider clients
    # This is the foundation class that handles initialization, configuration, and common utilities
    class BaseClient
      attr_reader :model, :base_url, :generation_config

      # Auto-register subclasses with the ClientFactory
      def self.inherited(subclass)
        super
        # Register with ClientFactory if it's available
        # If not, the ensure_clients_loaded fallback will handle it
        provider_key = subclass.provider_key
        if provider_key
          begin
            Molecules::ClientFactory.register(provider_key, subclass)
          rescue NameError
            # ClientFactory not loaded yet - that's ok, ensure_clients_loaded will handle it
          end
        end
      end

      # Get the provider key for factory registration.
      # Returns nil for abstract base classes to prevent them from being registered.
      # Concrete subclasses use this key to auto-register with ClientFactory via the inherited hook.
      # 
      # @return [String, nil] Provider key for registration, nil to skip registration
      def self.provider_key
        return nil if self == BaseClient # Don't register the base class
        return nil if name&.include?("BaseChatCompletionClient") # Don't register abstract base classes

        begin
          provider_name
        rescue NotImplementedError
          nil # Don't register classes that don't implement provider_name
        end
      end

      # Initialize base client with common configuration
      # @param api_key [String, nil] API key (uses env/config if nil)
      # @param model [String, nil] Model to use (uses default if nil)
      # @param options [Hash] Additional options
      # @option options [String] :base_url API base URL
      # @option options [String] :api_key_env Environment variable name for API key
      # @option options [Hash] :generation_config Default generation config
      # @option options [Integer] :timeout Request timeout
      # @option options [Symbol] :event_namespace Event namespace for monitoring
      def initialize(api_key: nil, model: nil, **options)
        # Prevent direct instantiation of abstract base class
        if self.class == BaseClient
          raise NotImplementedError, "BaseClient is abstract and cannot be instantiated directly"
        end

        @model = model || default_model
        @base_url = options.fetch(:base_url, self.class::API_BASE_URL)
        @generation_config = self.class::DEFAULT_GENERATION_CONFIG.merge(
          options.fetch(:generation_config, {})
        )

        # Initialize components
        setup_credentials(api_key, options)
        setup_request_builder(options)
        setup_response_parser
      end

      # Get the provider name for this client instance
      # @return [String] Provider name (e.g., "google", "anthropic")
      def provider_name
        self.class.provider_name
      end

      # Get the provider name for this client class (class method)
      # Subclasses should override this method to declare their provider name explicitly
      # @return [String] Provider name (e.g., "google", "anthropic")
      def self.provider_name
        raise NotImplementedError, "#{name} must implement .provider_name"
      end

      protected

      # Get the default model for this provider
      # @return [String] The default model name
      def default_model
        CodingAgentTools::Models::DefaultModelConfig.default.default_model_for(provider_name)
      end

      # Setup API credentials
      # @param api_key [String, nil] Direct API key
      # @param options [Hash] Options containing credential configuration
      def setup_credentials(api_key, options)
        if needs_credentials?
          @credentials = Molecules::APICredentials.new(
            env_key_name: options.fetch(:api_key_env, default_api_key_env)
          )
          @api_key = api_key || @credentials.api_key
        else
          @api_key = api_key || ENV[options.fetch(:api_key_env, default_api_key_env)]
        end
      end

      # Setup HTTP request builder
      # @param options [Hash] Options containing request configuration
      def setup_request_builder(options)
        @request_builder = Molecules::HTTPRequestBuilder.new(
          timeout: options.fetch(:timeout, default_timeout).to_i,
          event_namespace: options.fetch(:event_namespace, default_event_namespace)
        )
      end

      # Setup API response parser
      def setup_response_parser
        @response_parser = Molecules::APIResponseParser.new
      end

      # Whether this client needs credential management
      # @return [Boolean] True if credentials component should be used
      def needs_credentials?
        true
      end

      # Get the default API key environment variable name
      # @return [String] Environment variable name
      def default_api_key_env
        "#{provider_name.upcase}_API_KEY"
      end

      # Get the default request timeout
      # @return [Integer] Timeout in seconds
      def default_timeout
        30
      end

      # Get the default event namespace for monitoring
      # @return [Symbol] Event namespace
      def default_event_namespace
        :"#{provider_name}_api"
      end

      # Make a POST request with JSON payload
      # @param url [String] Request URL
      # @param payload [Hash] JSON payload
      # @param options [Hash] Additional request options
      # @return [Hash] Parsed response
      def post_json_request(url, payload, **options)
        response_data = @request_builder.post_json(url, payload, **options)
        @response_parser.parse_response(response_data)
      end

      # Make a GET request
      # @param url [String] Request URL
      # @param options [Hash] Additional request options
      # @return [Hash] Parsed response
      def get_json_request(url, **options)
        response_data = @request_builder.get_json(url, **options)
        @response_parser.parse_response(response_data)
      end

      # Handle successful response
      # @param parsed_response [Hash] Parsed response
      # @param extract_method [Symbol] Method name to call for text extraction
      # @return [Hash] Extracted response data
      def handle_success(parsed_response, extract_method)
        send(extract_method, parsed_response)
      end

      # Handle error response
      # @param parsed_response [Hash] Parsed error response
      def handle_error_response(parsed_response)
        handle_error(parsed_response)
      end

      # Handle API errors with standardized format
      # @param parsed_response [Hash] Parsed error response
      # @raise [Error] With formatted error message
      def handle_error(parsed_response)
        # Ensure error object and HTTP status are safely accessed, providing defaults
        error_obj = parsed_response[:error] || {}
        http_status = error_obj[:status] || "Unknown HTTP Status"

        # Extract error content using provider-specific logic
        specific_content = extract_error_content(error_obj)

        # Format final error message
        final_message = format_error_message(http_status, specific_content)
        raise Error, final_message
      end

      # Extract error content from error object (provider-specific)
      # @param error_obj [Hash] Error object from response
      # @return [String] Extracted error content
      def extract_error_content(error_obj)
        # Default implementation - subclasses can override for provider-specific logic
        error_message = error_obj.is_a?(Hash) ? error_obj[:message] : nil
        raw_message = error_obj.is_a?(Hash) ? error_obj[:raw_message] : nil

        error_message || raw_message || "An unspecified error occurred."
      end

      # Format error message with provider context
      # @param http_status [String] HTTP status
      # @param content [String] Error content
      # @return [String] Formatted error message
      def format_error_message(http_status, content)
        provider_display_name = case provider_name
        when "openai"
          "OpenAI"
        when "anthropic"
          "Anthropic"
        when "google"
          "Google"
        when "mistral"
          "Mistral"
        when "together_ai", "togetherai"
          "Together AI"
        when "lmstudio", "lm_studio"
          "LM Studio"
        else
          provider_name.capitalize
        end

        "#{provider_display_name} API Error (#{http_status}): #{content}"
      end
    end
  end
end
