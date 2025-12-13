# frozen_string_literal: true

require_relative "base_client"
require_relative "../molecules/openai_compatible_params"

module Ace
  module LLM
    module Organisms
      # XAIClient handles interactions with x.ai's API
      class XAIClient < BaseClient
        include Molecules::OpenAICompatibleParams
        API_BASE_URL = "https://api.x.ai"
        DEFAULT_MODEL = "grok-4"
        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: 4096,
          top_p: nil,
          frequency_penalty: nil,
          presence_penalty: nil
        }.freeze

        # Generation parameters to include in API request
        GENERATION_KEYS = %i[temperature max_tokens top_p frequency_penalty presence_penalty].freeze

        # Get the provider name
        # @return [String] Provider name
        def self.provider_name
          "xai"
        end

        # Generate a response from x.ai
        # @param messages [Array<Hash>, String] Messages or prompt
        # @param options [Hash] Generation options
        # @return [Hash] Response with text and metadata
        def generate(messages, **options)
          messages_array = build_messages(messages)
          generation_params = extract_generation_options(options)

          request_body = build_request_body(messages_array, generation_params)
          response = make_api_request(request_body)

          parse_response(response)
        rescue StandardError => e
          handle_api_error(e)
        end

        private

        # Build request body for x.ai API
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

        # Extract generation options including x.ai-specific ones
        # @param options [Hash] Raw options
        # @return [Hash] Generation parameters
        def extract_generation_options(options)
          gen_opts = super(options)

          # Add OpenAI-compatible options
          extract_openai_compatible_options(options, gen_opts)

          gen_opts.compact
        end

        # Make API request to x.ai
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
            error_body = response.body rescue {}
            error_message = error_body.dig("error", "message") || "Unknown error"
            error_type = error_body.dig("error", "type") || "unknown"

            raise Ace::LLM::ProviderError, "x.ai API error (#{response.status}): #{error_type} - #{error_message}"
          end

          response.body
        end

        # Parse API response
        # @param response [Hash] Raw API response
        # @return [Hash] Parsed response with text and metadata
        def parse_response(response)
          # Extract text from response with explicit bounds check
          choice = response.dig("choices", 0)
          unless choice
            raise Ace::LLM::ProviderError, "No choices in response from x.ai"
          end

          text = choice.dig("message", "content")
          unless text
            raise Ace::LLM::ProviderError, "No text in response from x.ai"
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
