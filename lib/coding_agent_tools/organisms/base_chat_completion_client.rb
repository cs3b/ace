# frozen_string_literal: true

require_relative "base_client"

module CodingAgentTools
  module Organisms
    # BaseChatCompletionClient provides chat completion workflow for LLM provider clients
    # This inherits from BaseClient and adds chat-specific functionality
    class BaseChatCompletionClient < BaseClient
      def initialize(api_key: nil, model: nil, **options)
        # Prevent direct instantiation of abstract base class
        if self.class == BaseChatCompletionClient
          raise NotImplementedError, "BaseChatCompletionClient is abstract and cannot be instantiated directly"
        end

        super
      end

      # Generate text content from a prompt
      # @param prompt [String] The prompt text
      # @param options [Hash] Generation options
      # @option options [String] :system_instruction System instruction/message
      # @option options [Hash] :generation_config Override generation config
      # @return [Hash] Response with generated text
      def generate_text(prompt, **options)
        payload = build_generation_payload(prompt, options)
        url = build_generation_url(options)

        request_options = build_request_options(options)
        parsed = post_json_request(url, payload, **request_options)

        if parsed[:success]
          handle_success(parsed, :extract_generated_text)
        else
          handle_error_response(parsed)
        end
      end

      # Generate text with streaming response
      # @param prompt [String] The prompt text
      # @param options [Hash] Generation options
      # @yield [chunk] Yields each response chunk
      # @yieldparam chunk [String] Text chunk
      # @return [String] Complete generated text
      def generate_text_stream(prompt, **options)
        raise NotImplementedError, "Streaming responses not yet implemented"
      end

      # Count tokens in a text
      # @param text [String] Text to count tokens for
      # @return [Hash] Token count information
      def count_tokens(text)
        if supports_token_counting?
          perform_token_counting(text)
        else
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

          raise NotImplementedError, "Token counting not directly supported by #{provider_display_name} API"
        end
      end

      # List all available models
      # @return [Array] List of available models
      def list_models
        url = build_models_url
        request_options = build_request_options({})
        parsed = get_json_request(url, **request_options)

        if parsed[:success]
          extract_models_list(parsed)
        else
          handle_error_response(parsed)
        end
      end

      # Get information about the model
      # @return [Hash] Model information
      def model_info
        if supports_individual_model_info?
          fetch_individual_model_info
        else
          extract_model_from_list
        end
      end

      protected

      # Whether this provider supports token counting
      # @return [Boolean] True if token counting is supported
      def supports_token_counting?
        false
      end

      # Whether this provider supports fetching individual model info
      # @return [Boolean] True if individual model info is supported
      def supports_individual_model_info?
        true
      end

      # Perform token counting for providers that support it
      # @param text [String] Text to count tokens for
      # @return [Hash] Token count information
      def perform_token_counting(text)
        raise NotImplementedError, "Subclasses must implement perform_token_counting if they support it"
      end

      # Fetch individual model information
      # @return [Hash] Model information
      def fetch_individual_model_info
        url = build_model_info_url
        request_options = build_request_options({})
        parsed = get_json_request(url, **request_options)

        if parsed[:success]
          parsed[:data]
        else
          handle_error_response(parsed)
        end
      end

      # Extract model info from the models list
      # @return [Hash] Model information
      def extract_model_from_list
        models = list_models
        models.find { |model| matches_current_model?(model) } || fallback_model_info
      end

      # Check if a model from the list matches the current model
      # @param model [Hash] Model information from list
      # @return [Boolean] True if this model matches current model
      def matches_current_model?(model)
        model[:id] == @model || model[:name] == @model
      end

      # Fallback model info when model is not found in list
      # @return [Hash] Basic model information
      def fallback_model_info
        {
          id: @model,
          name: @model,
          object: "model",
          created: Time.now.to_i
        }
      end

      # Build URL for generation endpoint
      # @param options [Hash] Generation options
      # @return [String] Generation URL
      def build_generation_url(options)
        build_api_url(generation_endpoint)
      end

      # Build URL for models list endpoint
      # @return [String] Models list URL
      def build_models_url
        build_api_url("models")
      end

      # Build URL for individual model info
      # @return [String] Model info URL
      def build_model_info_url
        build_api_url("models/#{@model}")
      end

      # Build request options including headers and other settings
      # @param options [Hash] Request-specific options
      # @return [Hash] Complete request options
      def build_request_options(options)
        request_opts = {}

        if needs_auth_headers?
          request_opts[:headers] = auth_headers
        end

        request_opts
      end

      # Whether this client needs authentication headers
      # @return [Boolean] True if auth headers are needed
      def needs_auth_headers?
        true
      end

      # Get the generation endpoint name
      # @return [String] Endpoint name
      def generation_endpoint
        "chat/completions"
      end

      # Extract models list from parsed response
      # @param parsed_response [Hash] Parsed response
      # @return [Array] List of models
      def extract_models_list(parsed_response)
        data = parsed_response[:data]
        data[:data] || data[:models] || []
      end

      # Abstract methods that subclasses must implement

      # Build API URL for the given endpoint
      # @param endpoint [String] API endpoint
      # @return [String] Complete URL
      def build_api_url(endpoint)
        raise NotImplementedError, "Subclasses must implement build_api_url"
      end

      # Build authentication headers
      # @return [Hash] Authentication headers
      def auth_headers
        raise NotImplementedError, "Subclasses must implement auth_headers if needed"
      end

      # Build generation payload
      # @param prompt [String] The prompt
      # @param options [Hash] Options
      # @return [Hash] Request payload
      def build_generation_payload(prompt, options)
        raise NotImplementedError, "Subclasses must implement build_generation_payload"
      end

      # Extract generated text from response
      # @param parsed_response [Hash] Parsed API response
      # @return [Hash] Extracted text and metadata
      def extract_generated_text(parsed_response)
        raise NotImplementedError, "Subclasses must implement extract_generated_text"
      end
    end
  end
end
