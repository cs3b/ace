# frozen_string_literal: true

require_relative "../molecules/api_credentials"
require_relative "../molecules/http_request_builder"
require_relative "../molecules/api_response_parser"
require "addressable/uri"

module CodingAgentTools
  module Organisms
    # MistralClient provides high-level interface to Mistral AI API
    # This is an organism - it orchestrates molecules to achieve business goals
    class MistralClient
      # Mistral AI API base URL
      API_BASE_URL = "https://api.mistral.ai/v1"

      # Default model to use
      DEFAULT_MODEL = "open-mistral-nemo"

      # Default environment variable name for Mistral API key
      DEFAULT_API_KEY_ENV = "MISTRAL_API_KEY"

      # Default generation config
      DEFAULT_GENERATION_CONFIG = {
        temperature: 0.7,
        max_tokens: 4096
      }.freeze

      # Initialize Mistral client
      # @param api_key [String, nil] API key (uses env/config if nil)
      # @param model [String] Model to use
      # @param options [Hash] Additional options
      # @option options [String] :base_url API base URL
      # @option options [Hash] :generation_config Default generation config
      # @option options [Integer] :timeout Request timeout
      def initialize(api_key: nil, model: DEFAULT_MODEL, **options)
        @model = model
        @base_url = options.fetch(:base_url, API_BASE_URL)
        @generation_config = DEFAULT_GENERATION_CONFIG.merge(
          options.fetch(:generation_config, {})
        )

        # Initialize components
        @credentials = Molecules::APICredentials.new(
          env_key_name: options.fetch(:api_key_env, DEFAULT_API_KEY_ENV)
        )
        @api_key = api_key || @credentials.api_key

        @request_builder = Molecules::HTTPRequestBuilder.new(
          timeout: options.fetch(:timeout, 30),
          # The event_namespace is passed to HTTPClient, which uses it to configure
          # the FaradayDryMonitorLogger middleware for observability.
          event_namespace: :mistral_api # For dry-monitor event namespacing
        )
        @response_parser = Molecules::APIResponseParser.new
      end

      # Generate text content from a prompt
      # @param prompt [String] The prompt text
      # @param options [Hash] Generation options
      # @option options [String] :system_instruction System instruction/message
      # @option options [Hash] :generation_config Override generation config
      # @return [Hash] Response with generated text
      def generate_text(prompt, **options)
        payload = build_generation_payload(prompt, options)
        url = build_api_url("chat/completions")

        response_data = @request_builder.post_json(url, payload, headers: auth_headers)
        parsed = @response_parser.parse_response(response_data)

        if parsed[:success]
          extract_generated_text(parsed)
        else
          handle_error(parsed)
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

      # Count tokens in a text (Mistral doesn't have a direct API for this)
      # @param text [String] Text to count tokens for
      # @return [Hash] Token count information
      def count_tokens(text)
        raise NotImplementedError, "Token counting not directly supported by Mistral API"
      end

      # List all available models
      # @return [Array] List of available models
      def list_models
        url = build_api_url("models")
        response_data = @request_builder.get_json(url, headers: auth_headers)
        parsed = @response_parser.parse_response(response_data)

        if parsed[:success]
          parsed[:data][:data] || []
        else
          handle_error(parsed)
        end
      end

      # Get information about the model
      # @return [Hash] Model information
      def model_info
        models = list_models
        models.find { |model| model[:id] == @model } || {
          id: @model,
          object: "model",
          created: Time.now.to_i,
          owned_by: "mistralai"
        }
      end

      private

      # Build API URL for the given endpoint
      # @param endpoint [String] API endpoint
      # @return [String] Complete URL
      def build_api_url(endpoint)
        url_obj = Addressable::URI.parse(@base_url)

        # Use File.join-style logic to avoid double slashes
        base_path = url_obj.path.end_with?("/") ? url_obj.path.chomp("/") : url_obj.path
        url_obj.path = "#{base_path}/#{endpoint}"

        url_obj.to_s
      end

      # Build authentication headers
      # @return [Hash] Authentication headers
      def auth_headers
        {
          "Authorization" => "Bearer #{@api_key}",
          "Content-Type" => "application/json"
        }
      end

      # Build generation payload
      # @param prompt [String] The prompt
      # @param options [Hash] Options
      # @return [Hash] Request payload
      def build_generation_payload(prompt, options)
        messages = []

        # Add system message if provided
        if options[:system_instruction]
          messages << {
            role: "system",
            content: options[:system_instruction]
          }
        end

        # Add user message
        messages << {
          role: "user",
          content: prompt
        }

        generation_config = @generation_config.merge(
          options.fetch(:generation_config, {})
        )

        {
          model: @model,
          messages: messages,
          temperature: generation_config[:temperature],
          max_tokens: generation_config[:max_tokens]
        }
      end

      # Extract generated text from response
      # @param parsed_response [Hash] Parsed API response
      # @return [Hash] Extracted text and metadata
      def extract_generated_text(parsed_response)
        # 1. Verify parsed_response[:data] is a Hash
        data = parsed_response[:data]
        unless data.is_a?(Hash)
          raise Error, "Failed to extract generated text: Response data is not a Hash, cannot find choices."
        end

        # 2. Verify data[:choices] is a non-empty Array
        choices_field = data[:choices]
        unless choices_field.is_a?(Array)
          raise Error, "Failed to extract generated text: 'choices' field is not an array."
        end
        if choices_field.empty?
          raise Error, "Failed to extract generated text: 'choices' array is empty."
        end

        # 3. Verify the first choice data[:choices][0] is a Hash
        choice = choices_field[0]
        unless choice.is_a?(Hash)
          raise Error, "Failed to extract generated text: No valid first choice found in response."
        end

        # 4. Verify choice[:message] is a Hash
        message_field = choice[:message]
        unless message_field.is_a?(Hash)
          raise Error, "Failed to extract generated text: choice 'message' field is missing or not a Hash."
        end

        # 5. Verify choice[:message][:content] exists
        unless message_field.key?(:content)
          raise Error, "Failed to extract generated text: message does not have a 'content' key."
        end

        text_content = message_field[:content]
        if text_content.nil?
          raise Error, "Failed to extract generated text: message content is nil."
        end

        {
          text: text_content,
          finish_reason: choice[:finish_reason],
          usage_metadata: data[:usage]
        }
      end

      # Handle API errors
      # @param parsed_response [Hash] Parsed error response
      # @raise [Error] With formatted error message
      def handle_error(parsed_response)
        # Ensure error object and HTTP status are safely accessed, providing defaults
        error_obj = parsed_response[:error] || {}
        http_status = error_obj[:status] || "Unknown HTTP Status"

        # Extract primary message components from the error object
        details_message = error_obj.is_a?(Hash) ? error_obj.dig(:error, :message) : nil
        error_message = error_obj.is_a?(Hash) ? error_obj[:message] : nil
        raw_message = error_obj.is_a?(Hash) ? error_obj[:raw_message] : nil

        # Determine the most specific error content available
        specific_content = if details_message
          details_message
        elsif raw_message
          raw_message
        elsif error_message
          error_message
        else
          "An unspecified error occurred."
        end

        final_message = "Mistral API Error (#{http_status}): #{specific_content}"
        raise Error, final_message
      end
    end
  end
end
