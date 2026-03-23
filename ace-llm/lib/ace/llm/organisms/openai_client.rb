# frozen_string_literal: true

require_relative "base_client"
require_relative "../molecules/openai_compatible_params"

module Ace
  module LLM
    module Organisms
      # OpenAIClient handles interactions with OpenAI's API
      class OpenAIClient < BaseClient
        include Molecules::OpenAICompatibleParams

        API_BASE_URL = "https://api.openai.com"
        DEFAULT_MODEL = "gpt-4o"

        # Generation parameters to include in API request
        GENERATION_KEYS = %i[temperature max_tokens top_p frequency_penalty presence_penalty].freeze

        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: nil,
          top_p: nil,
          frequency_penalty: nil,
          presence_penalty: nil
        }.freeze

        # Get the provider name
        # @return [String] Provider name
        def self.provider_name
          "openai"
        end

        # Generate a response from OpenAI
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

        # Build request body for OpenAI API
        # @param messages [Array<Hash>] Messages
        # @param generation_params [Hash] Generation parameters
        # @return [Hash] Request body
        def build_request_body(messages, generation_params)
          # Handle system_append - use shared helper for deep copy and concatenation
          processed_messages = process_messages_with_system_append(
            messages,
            generation_params[:system_append]
          )

          request = {
            model: @model,
            messages: processed_messages
          }

          # Add generation parameters (use nil? to preserve zero values like temperature: 0)
          GENERATION_KEYS.each do |key|
            request[key] = generation_params[key] unless generation_params[key].nil?
          end

          # Add streaming flag (always false for now)
          request[:stream] = false

          request
        end

        # Extract generation options including OpenAI-specific ones
        # @param options [Hash] Raw options
        # @return [Hash] Generation parameters
        def extract_generation_options(options)
          gen_opts = super

          # Add OpenAI-compatible options
          extract_openai_compatible_options(options, gen_opts)

          gen_opts.compact
        end

        # Make API request to OpenAI
        # @param body [Hash] Request body
        # @return [Hash] API response
        def make_api_request(body)
          url = "#{@base_url}/v1/chat/completions"

          response = @http_client.post(
            url,
            body,
            headers: {
              "Content-Type" => "application/json",
              "Authorization" => "Bearer #{@api_key}"
            }
          )

          unless response.success?
            error_type, error_message, status = parse_error_response(response)
            raise Ace::LLM::ProviderError, "OpenAI API error (#{status}): #{error_type} - #{error_message}"
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
          choice = response.dig("choices", 0)
          text = choice.dig("message", "content") if choice

          unless text
            raise Ace::LLM::ProviderError, "No text in response from OpenAI"
          end

          # Extract metadata
          metadata = {
            finish_reason: choice["finish_reason"],
            id: response["id"],
            created: response["created"]
          }

          # Add token usage if available
          usage = response["usage"]
          if usage
            metadata[:input_tokens] = usage["prompt_tokens"]
            metadata[:output_tokens] = usage["completion_tokens"]
            metadata[:total_tokens] = usage["total_tokens"]
          end

          # Add model info
          metadata[:model_used] = response["model"] if response["model"]

          create_response(text, metadata)
        end
      end
    end
  end
end
