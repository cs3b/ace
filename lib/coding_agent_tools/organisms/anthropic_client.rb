# frozen_string_literal: true

require_relative "base_chat_completion_client"
require "addressable/uri"

module CodingAgentTools
  module Organisms
    # AnthropicClient provides high-level interface to Anthropic API
    # This is an organism - it orchestrates molecules to achieve business goals
    class AnthropicClient < BaseChatCompletionClient
      # Anthropic API base URL
      API_BASE_URL = "https://api.anthropic.com/v1"

      # Default environment variable name for Anthropic API key
      DEFAULT_API_KEY_ENV = "ANTHROPIC_API_KEY"

      # API version
      API_VERSION = "2023-06-01"

      # Default generation config
      DEFAULT_GENERATION_CONFIG = {
        temperature: 0.7,
        max_tokens: 4096
      }.freeze

      # Explicit provider name declaration
      # @return [String] The provider name for this client
      def self.provider_name
        "anthropic"
      end

      # Dynamic aliases for this provider
      # @return [Hash] Mapping of aliases to provider:model combinations
      def self.dynamic_aliases
        {
          "csonet" => "anthropic:claude-4-0-sonnet-latest",
          "copus" => "anthropic:claude-4-0-opus-latest"
        }
      end

      # Initialize Anthropic client
      # @param api_key [String, nil] API key (uses env/config if nil)
      # @param model [String] Model to use
      # @param options [Hash] Additional options
      # @option options [String] :base_url API base URL
      # @option options [Hash] :generation_config Default generation config
      # @option options [Integer] :timeout Request timeout
      def initialize(api_key: nil, model: nil, **options)
        # Set Anthropic-specific defaults
        options[:event_namespace] ||= :anthropic_api
        options[:api_key_env] ||= DEFAULT_API_KEY_ENV

        super
      end

      # Override list_models to handle Anthropic's pagination and fallback
      def list_models
        all_models = []
        after_id = nil

        loop do
          url = build_api_url("models")
          query_params = {}
          query_params[:after_id] = after_id if after_id
          query_params[:limit] = 100 # Maximum allowed per page

          # Add query parameters to URL if present
          unless query_params.empty?
            uri = Addressable::URI.parse(url)
            uri.query_values = query_params
            url = uri.to_s
          end

          request_options = build_request_options({})
          parsed = get_json_request(url, **request_options)

          return fallback_models_list unless parsed[:success]

          data = parsed[:data]
          models_data = data[:data] || []

          # Transform API response to match expected format
          models_data.each do |model|
            all_models << {
              id: model[:id],
              name: model[:display_name],
              description: generate_model_description(model[:id]),
              created: parse_created_at(model[:created_at])
            }
          end

          # Check if there are more pages
          break unless data[:has_more]

          after_id = data[:last_id]

          # If API call fails, fall back to static list
        end

        all_models
      rescue
        # If any error occurs, fall back to static list
        fallback_models_list
      end

      protected

      # Anthropic doesn't support individual model info API
      def supports_individual_model_info?
        false
      end

      # Anthropic uses messages endpoint
      def generation_endpoint
        "messages"
      end

      # Override fallback for when model not found in list
      def fallback_model_info
        {
          id: @model,
          name: @model.split("-").map(&:capitalize).join(" "),
          description: "Anthropic Claude model"
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
          "x-api-key" => @api_key,
          "anthropic-version" => API_VERSION,
          "Content-Type" => "application/json"
        }
      end

      # Build generation payload
      # @param prompt [String] The prompt
      # @param options [Hash] Options
      # @return [Hash] Request payload
      def build_generation_payload(prompt, options)
        generation_config = @generation_config.merge(
          options.fetch(:generation_config, {})
        )

        payload = {
          model: @model,
          messages: [
            {
              role: "user",
              content: prompt
            }
          ],
          temperature: generation_config[:temperature],
          max_tokens: generation_config[:max_tokens]
        }

        # Add system message if provided
        payload[:system] = options[:system_instruction] if options[:system_instruction]

        payload
      end

      # Extract generated text from response
      # @param parsed_response [Hash] Parsed API response
      # @return [Hash] Extracted text and metadata
      def extract_generated_text(parsed_response)
        # 1. Verify parsed_response[:data] is a Hash
        data = parsed_response[:data]
        raise Error, "Failed to extract generated text: Response data is not a Hash." unless data.is_a?(Hash)

        # 2. Verify data[:content] is a non-empty Array
        content_field = data[:content]
        unless content_field.is_a?(Array)
          raise Error, "Failed to extract generated text: 'content' field is not an array."
        end
        raise Error, "Failed to extract generated text: 'content' array is empty." if content_field.empty?

        # 3. Extract text from all content blocks
        text_parts = []
        content_field.each do |block|
          text_parts << block[:text] if block.is_a?(Hash) && block[:type] == "text" && block[:text]
        end

        raise Error, "Failed to extract generated text: No text blocks found in content." if text_parts.empty?

        {
          text: text_parts.join("\n"),
          finish_reason: data[:stop_reason],
          usage_metadata: data[:usage]
        }
      end

      # Extract error content from Anthropic-specific error structure
      def extract_error_content(error_obj)
        # Anthropic's error structure is different from OpenAI
        error_data = error_obj.is_a?(Hash) ? error_obj[:error] : {}
        error_type = error_data[:type] if error_data.is_a?(Hash)
        error_message = error_data[:message] if error_data.is_a?(Hash)
        raw_message = error_obj[:raw_message] if error_obj.is_a?(Hash)

        # Determine the most specific error content available
        if error_message
          error_type ? "#{error_type}: #{error_message}" : error_message
        elsif raw_message
          raw_message
        else
          "An unspecified error occurred."
        end
      end

      # Generate a description for a model based on its ID
      # @param model_id [String] The model ID
      # @return [String] Model description
      def generate_model_description(model_id)
        case model_id
        when /claude-opus-4/
          "Our most capable model"
        when /claude-sonnet-4/
          "High-performance model"
        when /claude-3-7-sonnet/
          "High-performance model with early extended thinking"
        when /claude-3-5-sonnet/
          "Balanced intelligence and speed"
        when /claude-3-5-haiku/
          "Fast and cost-effective"
        when /claude-3-opus/
          "Powerful model for complex tasks"
        when /claude-3-sonnet/
          "Balanced performance and speed"
        when /claude-3-haiku/
          "Fast, compact, and cost-effective"
        else
          "Anthropic Claude model"
        end
      end

      # Parse created_at timestamp from API response
      # @param created_at [String] RFC 3339 timestamp
      # @return [Integer] Unix timestamp
      def parse_created_at(created_at)
        return Time.now.to_i if created_at.nil? || created_at.empty?

        Time.parse(created_at).to_i
      rescue
        Time.now.to_i
      end

      # Fallback static models list when API is unavailable
      # @return [Array] Static list of models
      def fallback_models_list
        [
          {
            id: "claude-3-5-sonnet-20241022",
            name: "Claude 3.5 Sonnet",
            description: "Most intelligent Claude model",
            created: 1_729_555_200
          },
          {
            id: "claude-3-5-haiku-20241022",
            name: "Claude 3.5 Haiku",
            description: "Fast and cost-effective",
            created: 1_729_555_200
          },
          {
            id: "claude-3-opus-20240229",
            name: "Claude 3 Opus",
            description: "Powerful model for complex tasks",
            created: 1_709_251_200
          },
          {
            id: "claude-3-sonnet-20240229",
            name: "Claude 3 Sonnet",
            description: "Balanced performance and speed",
            created: 1_709_251_200
          },
          {
            id: "claude-3-haiku-20240307",
            name: "Claude 3 Haiku",
            description: "Fast, compact, and cost-effective",
            created: 1_709_769_600
          }
        ]
      end
    end
  end
end
