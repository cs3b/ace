# frozen_string_literal: true

require_relative "base_chat_completion_client"
require "addressable/uri"

module CodingAgentTools
  module Organisms
    # GoogleClient provides high-level interface to Google Gemini API
    # This is an organism - it orchestrates molecules to achieve business goals
    class GoogleClient < BaseChatCompletionClient
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
        # Set Google-specific defaults
        options[:event_namespace] ||= :google_api
        options[:api_key_env] ||= DEFAULT_API_KEY_ENV
        
        super(api_key: api_key, model: model, **options)
      end




      protected

      # Google supports token counting
      def supports_token_counting?
        true
      end

      # Google doesn't use auth headers (uses query parameters)
      def needs_auth_headers?
        false
      end

      # Google uses a different generation endpoint
      def generation_endpoint
        "generateContent"
      end

      # Google extracts models from 'models' field
      def extract_models_list(parsed_response)
        data = parsed_response[:data]
        data[:models] || []
      end

      # Perform token counting (Google-specific implementation)
      def perform_token_counting(text)
        payload = {
          contents: [
            {
              parts: [{text: text}]
            }
          ]
        }

        url = build_api_url("countTokens")
        parsed = post_json_request(url, payload)

        if parsed[:success]
          {
            token_count: parsed[:data][:totalTokens],
            details: parsed[:data]
          }
        else
          handle_error_response(parsed)
        end
      end

      # Build generation URL for Google (model-specific)
      def build_generation_url(options)
        build_api_url(generation_endpoint)
      end

      # Build models URL for Google
      def build_models_url
        build_url_with_path("models")
      end

      # Build model info URL for Google
      def build_model_info_url
        build_url_with_path("models/#{@model}")
      end

      private

      # Build API URL with model and endpoint (Google-specific format)
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

      # Extract error content from Google-specific error structure
      def extract_error_content(error_obj)
        # Google-specific error extraction logic
        details_message = error_obj.is_a?(Hash) ? error_obj.dig(:details, :message) : nil
        error_message = error_obj.is_a?(Hash) ? error_obj[:message] : nil
        raw_message = error_obj.is_a?(Hash) ? error_obj[:raw_message] : nil

        # Determine the most specific error content available
        if details_message
          details_message
        elsif raw_message # Key for non-JSON responses
          raw_message
        elsif error_message
          error_message
        else
          "An unspecified error occurred."
        end
      end
    end
  end
end
