# frozen_string_literal: true

require_relative "../molecules/api_credentials"
require_relative "../molecules/http_request_builder"
require_relative "../molecules/api_response_parser"
require_relative "../models/default_model_config"
require "addressable/uri"

module CodingAgentTools
  module Organisms
    # GoogleClient provides high-level interface to Google Gemini API
    # This is an organism - it orchestrates molecules to achieve business goals
    class GoogleClient
      # Google Gemini API base URL
      API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

      # Default environment variable name for Google API key
      DEFAULT_API_KEY_ENV = "GOOGLE_API_KEY"

      # Default generation config
      DEFAULT_GENERATION_CONFIG = {
        temperature: 0.7,
        maxOutputTokens: 8192
      }.freeze

      # Initialize Google client
      # @param api_key [String, nil] API key (uses env/config if nil)
      # @param model [String] Model to use
      # @param options [Hash] Additional options
      # @option options [String] :base_url API base URL
      # @option options [Hash] :generation_config Default generation config
      # @option options [Integer] :timeout Request timeout
      def initialize(api_key: nil, model: nil, **options)
        @model = model || default_model
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
          timeout: options.fetch(:timeout, 30).to_i,
          # The event_namespace is passed to HTTPClient, which uses it to configure
          # the FaradayDryMonitorLogger middleware for observability.
          event_namespace: :google_api # For dry-monitor event namespacing
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
              parts: [{text: text}]
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

      # List all available models
      # @return [Array] List of available models
      def list_models
        url = build_url_with_path("models")
        response_data = @request_builder.get_json(url)
        parsed = @response_parser.parse_response(response_data)

        if parsed[:success]
          parsed[:data][:models] || []
        else
          handle_error(parsed)
        end
      end

      # Get information about the model
      # @return [Hash] Model information
      def model_info
        url = build_url_with_path("models/#{@model}")
        response_data = @request_builder.get_json(url)
        parsed = @response_parser.parse_response(response_data)

        if parsed[:success]
          parsed[:data]
        else
          handle_error(parsed)
        end
      end

      private

      # Get the default model for this provider
      #
      # @return [String] The default model name
      def default_model
        CodingAgentTools::Models::DefaultModelConfig.default.default_model_for("google")
      end

      # Build API URL with model and endpoint
      # Build API URL for the given endpoint
      # @param endpoint [String] API endpoint
      # @return [String] Complete URL
      def build_api_url(endpoint)
        path_segment = "models/#{@model}:#{endpoint}"
        build_url_with_path(path_segment)
      end

      # Build URL with path segment, handling proper path joining and query parameters
      # @param path_segment [String] Path segment to append
      # @return [String] Complete URL
      def build_url_with_path(path_segment)
        url_obj = Addressable::URI.parse(@base_url)

        # Use File.join-style logic to avoid double slashes
        base_path = url_obj.path.end_with?("/") ? url_obj.path.chomp("/") : url_obj.path
        url_obj.path = "#{base_path}/#{path_segment}"

        # Set query parameters
        url_obj.query_values = {key: @api_key}
        url_obj.to_s
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
              parts: [{text: prompt}]
            }
          ],
          generationConfig: @generation_config.merge(
            options.fetch(:generation_config, {})
          )
        }

        # Add system instruction if provided
        if options[:system_instruction]
          payload[:systemInstruction] = {
            parts: [{text: options[:system_instruction]}]
          }
        end

        payload
      end

      # Extract generated text from response
      # @param parsed_response [Hash] Parsed API response
      # @return [Hash] Extracted text and metadata
      def extract_generated_text(parsed_response)
        # 1. Verify parsed_response[:data] is a Hash
        data = parsed_response[:data]
        unless data.is_a?(Hash)
          raise Error, "Failed to extract generated text: Response data is not a Hash, cannot find candidates."
        end

        # 2. Verify data[:candidates] is a non-empty Array
        candidates_field = data[:candidates]
        unless candidates_field.is_a?(Array)
          raise Error, "Failed to extract generated text: 'candidates' field is not an array."
        end
        if candidates_field.empty?
          raise Error, "Failed to extract generated text: 'candidates' array is empty."
        end

        # 3. Verify the first candidate data[:candidates][0] is a Hash
        candidate = candidates_field[0]
        unless candidate.is_a?(Hash)
          # This specific message is expected by a test when candidate is not a hash (e.g. a string)
          raise Error, "Failed to extract generated text: No valid first candidate found in response."
        end

        # 4. Verify candidate[:content] is a Hash
        content_field = candidate[:content]
        unless content_field.is_a?(Hash)
          raise Error, "Failed to extract generated text: candidate 'content' field is missing or not a Hash."
        end

        # 5. Verify candidate[:content][:parts] is a non-empty Array
        parts_field = content_field[:parts]
        unless parts_field.is_a?(Array)
          raise Error, "Failed to extract generated text: candidate 'content.parts' field is missing or not an Array."
        end
        if parts_field.empty?
          raise Error, "Failed to extract generated text: candidate 'content.parts' array is empty."
        end

        # 6. Verify the first part candidate[:content][:parts][0] is a Hash
        first_part = parts_field[0]
        unless first_part.is_a?(Hash)
          raise Error, "Failed to extract generated text: first element in candidate 'content.parts' array is not a Hash."
        end

        # 7. Verify the text field within the first part
        unless first_part.key?(:text)
          raise Error, "Failed to extract generated text: first element in candidate 'content.parts' array does not have a 'text' key, or its value is nil."
        end

        text_content = first_part[:text]
        if text_content.nil?
          # This case distinguishes between a missing :text key (covered above)
          # and a :text key that is present but its value is nil.
          raise Error, "Failed to extract generated text: text missing from the first part of the candidate's content."
        end

        {
          text: text_content,
          finish_reason: candidate[:finishReason], # .dig not strictly needed now due to Hash checks
          safety_ratings: candidate[:safetyRatings], # .dig not strictly needed
          usage_metadata: data[:usageMetadata] # .dig not strictly needed
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
        # details_message is typically from a nested Google JSON error structure like error.details.message
        # error_message is from the top-level Google JSON error structure like error.message
        # raw_message is the raw response body if it wasn't JSON or couldn't be parsed
        details_message = error_obj.is_a?(Hash) ? error_obj.dig(:details, :message) : nil
        error_message = error_obj.is_a?(Hash) ? error_obj[:message] : nil
        raw_message = error_obj.is_a?(Hash) ? error_obj[:raw_message] : nil

        # Determine the most specific error content available
        specific_content = if details_message
          details_message
        elsif raw_message # Key for non-JSON responses
          raw_message
        elsif error_message
          error_message
        else
          "An unspecified error occurred." # Default if no message parts found
        end

        final_message = "Google API Error (#{http_status}): #{specific_content}"
        raise Error, final_message # Assumes Error is CodingAgentTools::Error
      end
    end
  end
end
