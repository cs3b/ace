# frozen_string_literal: true

require_relative "base_chat_completion_client"
require "addressable/uri"

module CodingAgentTools
  module Organisms
    # MistralClient provides high-level interface to Mistral AI API
    # This is an organism - it orchestrates molecules to achieve business goals
    class MistralClient < BaseChatCompletionClient
      # Mistral AI API base URL
      API_BASE_URL = "https://api.mistral.ai/v1"

      # Default environment variable name for Mistral API key
      DEFAULT_API_KEY_ENV = "MISTRAL_API_KEY"

      # Default generation config
      DEFAULT_GENERATION_CONFIG = {
        temperature: 0.7,
        max_tokens: 4096
      }.freeze

      # Explicit provider name declaration
      # @return [String] The provider name for this client
      def self.provider_name
        "mistral"
      end

      # Initialize Mistral client
      # @param api_key [String, nil] API key (uses env/config if nil)
      # @param model [String] Model to use
      # @param options [Hash] Additional options
      # @option options [String] :base_url API base URL
      # @option options [Hash] :generation_config Default generation config
      # @option options [Integer] :timeout Request timeout
      def initialize(api_key: nil, model: nil, **options)
        # Set Mistral-specific defaults
        options[:event_namespace] ||= :mistral_api
        options[:api_key_env] ||= DEFAULT_API_KEY_ENV

        super
      end

      protected

      # Mistral doesn't support individual model info
      def supports_individual_model_info?
        false
      end

      # Override fallback for when model not found in list
      def fallback_model_info
        {
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

      # Extract error content from Mistral-specific error structure
      def extract_error_content(error_obj)
        details_message = error_obj.is_a?(Hash) ? error_obj.dig(:error, :message) : nil
        error_message = error_obj.is_a?(Hash) ? error_obj[:message] : nil
        raw_message = error_obj.is_a?(Hash) ? error_obj[:raw_message] : nil

        # Determine the most specific error content available
        if details_message
          details_message
        elsif raw_message
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
