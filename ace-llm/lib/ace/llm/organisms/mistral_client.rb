# frozen_string_literal: true

require_relative "base_client"

module Ace
  module LLM
    module Organisms
      # MistralClient handles interactions with Mistral AI's API
      class MistralClient < BaseClient
        API_BASE_URL = "https://api.mistral.ai"
        DEFAULT_MODEL = "mistral-large-latest"
        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: nil,
          top_p: nil,
          random_seed: nil
        }.freeze

        # Get the provider name
        # @return [String] Provider name
        def self.provider_name
          "mistral"
        end

        # Generate a response from Mistral
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

        # Build request body for Mistral API
        # @param messages [Array<Hash>] Messages
        # @param generation_params [Hash] Generation parameters
        # @return [Hash] Request body
        def build_request_body(messages, generation_params)
          request = {
            model: @model,
            messages: messages
          }

          # Add generation parameters
          request[:temperature] = generation_params[:temperature] if generation_params[:temperature]
          request[:max_tokens] = generation_params[:max_tokens] if generation_params[:max_tokens]
          request[:top_p] = generation_params[:top_p] if generation_params[:top_p]
          request[:random_seed] = generation_params[:random_seed] if generation_params[:random_seed]

          request
        end

        # Make API request to Mistral
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
            error_message = error_body.dig("message") || error_body.dig("error") || "Unknown error"

            raise Ace::LLM::ProviderError, "Mistral API error (#{response.status}): #{error_message}"
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
            raise Ace::LLM::ProviderError, "No text in response from Mistral"
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