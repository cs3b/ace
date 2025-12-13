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

          # Add generation parameters (use nil checks to preserve zero values)
          request[:temperature] = generation_params[:temperature] unless generation_params[:temperature].nil?
          request[:max_tokens] = generation_params[:max_tokens] unless generation_params[:max_tokens].nil?
          request[:top_p] = generation_params[:top_p] unless generation_params[:top_p].nil?
          request[:frequency_penalty] = generation_params[:frequency_penalty] unless generation_params[:frequency_penalty].nil?
          request[:presence_penalty] = generation_params[:presence_penalty] unless generation_params[:presence_penalty].nil?

          # Add streaming flag (always false for now)
          request[:stream] = false

          request
        end

        # Extract generation options including OpenAI-specific ones
        # @param options [Hash] Raw options
        # @return [Hash] Generation parameters
        def extract_generation_options(options)
          gen_opts = super(options)

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
            error_body = response.body rescue {}
            error_message = error_body.dig("error", "message") || "Unknown error"
            error_type = error_body.dig("error", "type") || "unknown"

            raise Ace::LLM::ProviderError, "OpenAI API error (#{response.status}): #{error_type} - #{error_message}"
          end

          response.body
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