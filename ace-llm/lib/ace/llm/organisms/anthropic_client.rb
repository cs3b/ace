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

          request = {
            model: @model,
            messages: conversation_messages,
            max_tokens: generation_params[:max_tokens] || 4096
          }

          # Add system message if present
          request[:system] = system_message if system_message

          # Add other generation parameters
          request[:temperature] = generation_params[:temperature] if generation_params[:temperature]
          request[:top_p] = generation_params[:top_p] if generation_params[:top_p]
          request[:top_k] = generation_params[:top_k] if generation_params[:top_k]

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
            error_body = response.body rescue {}
            error_type = error_body.dig("error", "type") || "unknown"
            error_message = error_body.dig("error", "message") || "Unknown error"

            raise Ace::LLM::ProviderError, "Anthropic API error (#{response.status}): #{error_type} - #{error_message}"
          end

          response.body
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