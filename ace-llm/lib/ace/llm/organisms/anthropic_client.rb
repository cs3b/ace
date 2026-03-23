# frozen_string_literal: true

require_relative "base_client"

module Ace
  module LLM
    module Organisms
      # AnthropicClient handles interactions with Anthropic's Claude API
      class AnthropicClient < BaseClient
        API_BASE_URL = "https://api.anthropic.com"
        DEFAULT_MODEL = "claude-3-5-sonnet-20241022"
        API_VERSION = "2023-06-01"

        # Generation parameters to include in API request (max_tokens handled separately as required)
        GENERATION_KEYS = %i[temperature top_p top_k].freeze

        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: 4096,  # Anthropic requires max_tokens
          top_p: nil,
          top_k: nil
        }.freeze

        # Get the provider name
        # @return [String] Provider name
        def self.provider_name
          "anthropic"
        end

        # Generate a response from Anthropic's Claude
        # @param messages [Array<Hash>, String] Messages or prompt
        # @param options [Hash] Generation options
        # @return [Hash] Response with text and metadata
        def generate(messages, **options)
          messages_array = build_messages(messages)
          generation_params = extract_generation_options(options)

          request_body = build_request_body(messages_array, generation_params)
          response = make_api_request(request_body)

          parse_response(response)
        rescue => e
          handle_api_error(e)
        end

        private

        # Build request body for Anthropic API
        # @param messages [Array<Hash>] Messages
        # @param generation_params [Hash] Generation parameters
        # @return [Hash] Request body
        def build_request_body(messages, generation_params)
          # Separate system message from conversation messages
          system_message = nil
          conversation_messages = []

          messages.each do |msg|
            if msg[:role] == "system"
              system_message = msg[:content]
            else
              # Convert to Anthropic format
              conversation_messages << {
                role: msg[:role],
                content: msg[:content]
              }
            end
          end

          # Handle system_append - concatenate with existing system message
          system_message = concatenate_system_prompts(system_message, generation_params[:system_append])

          request = {
            model: @model,
            messages: conversation_messages,
            max_tokens: generation_params[:max_tokens] || 4096
          }

          # Add system message if present
          request[:system] = system_message if system_message

          # Add other generation parameters (use nil? to preserve zero values like temperature: 0)
          GENERATION_KEYS.each do |key|
            request[key] = generation_params[key] unless generation_params[key].nil?
          end

          request
        end

        # Make API request to Anthropic
        # @param body [Hash] Request body
        # @return [Hash] API response
        def make_api_request(body)
          url = "#{@base_url}/v1/messages"

          response = @http_client.post(
            url,
            body,
            headers: {
              "Content-Type" => "application/json",
              "anthropic-version" => API_VERSION,
              "x-api-key" => @api_key
            }
          )

          unless response.success?
            error_type, error_message, status = parse_error_response(response)
            raise Ace::LLM::ProviderError, "Anthropic API error (#{status}): #{error_type} - #{error_message}"
          end

          response.body
        end

        # Parse error response from API
        # Extracts error details from the response body, handling both JSON (Hash)
        # and non-JSON (String) responses gracefully.
        #
        # @param response [Faraday::Response] Failed API response
        # @return [Array(String, String, Integer)] Tuple of [error_type, error_message, status]
        def parse_error_response(response)
          raw_body = response.body
          status = response.status

          case raw_body
          in Hash => error_body
            error_obj = error_body["error"]
            case error_obj
            when Hash
              error_message = error_obj["message"] || build_fallback_error_message(raw_body, status)
              error_type = error_obj["type"] || "unknown"
            when String
              error_message = error_obj
              error_type = "unknown"
            else
              error_message = build_fallback_error_message(raw_body, status)
              error_type = "unknown"
            end
          else
            error_message = build_fallback_error_message(raw_body, status)
            error_type = "unknown"
          end

          [error_type, error_message, status]
        end

        # Build fallback error message for non-JSON responses
        #
        # @param raw_body [Object] Raw response body
        # @param status [Integer] HTTP status code
        # @return [String] Human-readable error message
        def build_fallback_error_message(raw_body, status)
          if raw_body.is_a?(String) && !raw_body.empty?
            snippet = raw_body.byteslice(0, 100)&.scrub || raw_body[0, 100]
            snippet += "..." if raw_body.bytesize > 100
            "Non-JSON response: #{snippet}"
          else
            "Unknown error: #{status}"
          end
        end

        # Parse API response
        # @param response [Hash] Raw API response
        # @return [Hash] Parsed response with text and metadata
        def parse_response(response)
          # Extract text from response
          # Anthropic can return multiple content blocks, we'll concatenate text blocks
          content = response["content"]
          text_parts = []

          if content.is_a?(Array)
            content.each do |block|
              if block["type"] == "text"
                text_parts << block["text"]
              end
            end
          elsif content.is_a?(String)
            # Older format compatibility
            text_parts << content
          end

          text = text_parts.join("\n")

          if text.empty?
            raise Ace::LLM::ProviderError, "No text in response from Anthropic"
          end

          # Extract metadata
          metadata = {
            id: response["id"],
            type: response["type"],
            role: response["role"],
            model_used: response["model"],
            stop_reason: response["stop_reason"],
            stop_sequence: response["stop_sequence"]
          }

          # Add token usage if available
          usage = response["usage"]
          if usage
            metadata[:input_tokens] = usage["input_tokens"]
            metadata[:output_tokens] = usage["output_tokens"]
            metadata[:total_tokens] = (usage["input_tokens"] || 0) + (usage["output_tokens"] || 0)

            # Cache tokens if available
            metadata[:cached_tokens] = usage["cache_creation_input_tokens"] if usage["cache_creation_input_tokens"]
            metadata[:cache_read_tokens] = usage["cache_read_input_tokens"] if usage["cache_read_input_tokens"]
          end

          create_response(text, metadata)
        end
      end
    end
  end
end
