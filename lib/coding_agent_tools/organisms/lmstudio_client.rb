# frozen_string_literal: true

require_relative "base_chat_completion_client"
require "json"

module CodingAgentTools
  module Organisms
    # LmstudioClient provides high-level interface to LM Studio local server
    # This is an organism - it orchestrates molecules to achieve business goals
    class LmstudioClient < BaseChatCompletionClient
      # LM Studio API base URL (local server)
      API_BASE_URL = "http://localhost:1234"

      # Default generation config
      DEFAULT_GENERATION_CONFIG = {
        temperature: 0.7,
        max_tokens: -1,
        stream: false
      }.freeze

      # Explicit provider name declaration
      # @return [String] The provider name for this client
      def self.provider_name
        "lmstudio"
      end

      # Initialize LM Studio client
      # @param model [String] Model to use
      # @param options [Hash] Additional options
      # @option options [String] :base_url API base URL
      # @option options [Hash] :generation_config Default generation config
      # @option options [Integer] :timeout Request timeout
      def initialize(model: nil, **options)
        # Set LM Studio-specific defaults
        options[:event_namespace] ||= :lm_studio_api
        options[:timeout] ||= 180  # LM Studio needs longer timeout
        options[:api_key_env] ||= "LM_STUDIO_API_KEY"

        super(api_key: options[:api_key], model: model, **options)
      end

      # Check if LM Studio server is available
      # @return [Boolean] True if server is running and responsive
      def server_available?
        url = build_api_url("models")
        response_data = @request_builder.get_json(url)
        response_data[:success] && response_data[:status] == 200
      rescue
        false
      end

      # Override to add server availability check
      def generate_text(prompt, **options)
        unless server_available?
          raise Error, "LM Studio server is not available at #{@base_url}. Please ensure LM Studio is running."
        end

        super
      end

      # Override to add server availability check
      def list_models
        unless server_available?
          raise Error, "LM Studio server is not available at #{@base_url}. Please ensure LM Studio is running."
        end

        super
      end

      protected

      # LM Studio doesn't need credentials
      def needs_credentials?
        false
      end

      # LM Studio doesn't need auth headers
      def needs_auth_headers?
        false
      end

      # LM Studio doesn't support individual model info
      def supports_individual_model_info?
        false
      end

      # Override fallback for when model not found in list
      def fallback_model_info
        {
          id: @model,
          object: "model",
          owned_by: "local"
        }
      end

      private

      # Build API URL for the given endpoint (LM Studio specific format)
      # @param endpoint [String] API endpoint
      # @return [String] Complete URL
      def build_api_url(endpoint)
        "#{@base_url}/v1/#{endpoint}"
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
          max_tokens: generation_config[:max_tokens],
          stream: generation_config[:stream]
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

      # Extract error content from LM Studio-specific error structure
      def extract_error_content(error_obj)
        details_message = error_obj.is_a?(Hash) ? error_obj.dig(:details, :message) : nil
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
