# frozen_string_literal: true

require_relative "../molecules/api_credentials"
require_relative "../molecules/http_request_builder"
require_relative "../molecules/api_response_parser"

module CodingAgentTools
  module Organisms
    # GeminiClient provides high-level interface to Google Gemini API
    # This is an organism - it orchestrates molecules to achieve business goals
    class GeminiClient
      # Gemini API base URL
      API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

      # Default model to use
      DEFAULT_MODEL = "gemini-2.0-flash-lite"

      # Default environment variable name for Gemini API key
      DEFAULT_API_KEY_ENV = "GEMINI_API_KEY"

      # Default generation config
      DEFAULT_GENERATION_CONFIG = {
        temperature: 0.7,
        maxOutputTokens: 8192
      }.freeze

      # Initialize Gemini client
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
          timeout: options.fetch(:timeout, 30)
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
        url = build_api_url("generateContent")

        response_data = @request_builder.post_json(url, payload)
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

      # Count tokens in a text
      # @param text [String] Text to count tokens for
      # @return [Hash] Token count information
      def count_tokens(text)
        payload = {
          contents: [
            {
              parts: [{ text: text }]
            }
          ]
        }

        url = build_api_url("countTokens")
        response_data = @request_builder.post_json(url, payload)
        parsed = @response_parser.parse_response(response_data)

        if parsed[:success]
          {
            token_count: parsed[:data][:totalTokens],
            details: parsed[:data]
          }
        else
          handle_error(parsed)
        end
      end

      # Get information about the model
      # @return [Hash] Model information
      def model_info
        url = "#{@base_url}/models/#{@model}"
        response_data = @request_builder.get_json(url, query: { key: @api_key })
        parsed = @response_parser.parse_response(response_data)

        if parsed[:success]
          parsed[:data]
        else
          handle_error(parsed)
        end
      end

      private

      # Build API URL with model and endpoint
      # @param endpoint [String] API endpoint
      # @return [String] Complete URL
      def build_api_url(endpoint)
        "#{@base_url}/models/#{@model}:#{endpoint}?key=#{@api_key}"
      end

      # Build generation payload
      # @param prompt [String] The prompt
      # @param options [Hash] Options
      # @return [Hash] Request payload
      def build_generation_payload(prompt, options)
        payload = {
          contents: [
            {
              role: "user",
              parts: [{ text: prompt }]
            }
          ],
          generationConfig: @generation_config.merge(
            options.fetch(:generation_config, {})
          )
        }

        # Add system instruction if provided
        if options[:system_instruction]
          payload[:systemInstruction] = {
            parts: [{ text: options[:system_instruction] }]
          }
        end

        payload
      end

      # Extract generated text from response
      # @param parsed_response [Hash] Parsed API response
      # @return [Hash] Extracted text and metadata
      def extract_generated_text(parsed_response)
        data = parsed_response[:data]

        # Navigate the response structure
        candidate = data.dig(:candidates, 0)
        text = candidate.dig(:content, :parts, 0, :text)

        {
          text: text,
          finish_reason: candidate[:finishReason],
          safety_ratings: candidate[:safetyRatings],
          usage_metadata: data[:usageMetadata]
        }
      rescue StandardError => e
        raise Error, "Failed to extract text from response: #{e.message}"
      end

      # Handle API errors
      # @param parsed_response [Hash] Parsed error response
      # @raise [Error] With formatted error message
      def handle_error(parsed_response)
        error = parsed_response[:error]
        details = error[:details] || {}

        message = if details[:message]
                    "Gemini API Error: #{details[:message]}"
                  elsif error[:raw_message]
                    "Gemini API Error: #{error[:raw_message]}"
                  else
                    "Gemini API Error (#{error[:status]}): #{error[:message]}"
                  end

        raise Error, message
      end
    end
  end
end
