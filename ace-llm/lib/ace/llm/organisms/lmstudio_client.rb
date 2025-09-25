# frozen_string_literal: true

require_relative "base_client"

module Ace
  module LLM
    module Organisms
      # LMStudioClient handles interactions with local LM Studio server
      # LM Studio provides an OpenAI-compatible API for local models
      class LMStudioClient < BaseClient
        API_BASE_URL = "http://localhost:1234"
        DEFAULT_MODEL = "local-model"
        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: nil,
          top_p: nil,
          top_k: nil
        }.freeze

        # Get the provider name
        # @return [String] Provider name
        def self.provider_name
          "lmstudio"
        end

        # Check if this client needs API credentials
        # @return [Boolean] False - LM Studio doesn't need API keys
        def needs_credentials?
          false
        end

        # Generate a response from LM Studio
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

        # Build request body for LM Studio API (OpenAI-compatible)
        # @param messages [Array<Hash>] Messages
        # @param generation_params [Hash] Generation parameters
        # @return [Hash] Request body
        def build_request_body(messages, generation_params)
          request = {
            messages: messages,
            stream: false
          }

          # Add generation parameters
          request[:temperature] = generation_params[:temperature] if generation_params[:temperature]
          request[:max_tokens] = generation_params[:max_tokens] if generation_params[:max_tokens]
          request[:top_p] = generation_params[:top_p] if generation_params[:top_p]

          # LM Studio may not support all OpenAI parameters, but we'll include them
          request
        end

        # Make API request to LM Studio
        # @param body [Hash] Request body
        # @return [Hash] API response
        def make_api_request(body)
          url = "#{@base_url}/v1/chat/completions"

          response = @http_client.post(
            url,
            body,
            headers: {
              "Content-Type" => "application/json"
            }
          )

          unless response.success?
            # LM Studio might not be running
            if response.status == 0 || response.body.nil?
              raise Ace::LLM::ProviderError,
                "Cannot connect to LM Studio at #{@base_url}. " \
                "Please ensure LM Studio is running with the local server enabled."
            end

            error_body = response.body rescue {}
            error_message = error_body["error"] || "Unknown error"

            raise Ace::LLM::ProviderError, "LM Studio API error (#{response.status}): #{error_message}"
          end

          response.body
        rescue Faraday::ConnectionFailed => e
          raise Ace::LLM::ProviderError,
            "Cannot connect to LM Studio at #{@base_url}. " \
            "Please ensure LM Studio is running with the local server enabled. " \
            "Error: #{e.message}"
        end

        # Parse API response
        # @param response [Hash] Raw API response
        # @return [Hash] Parsed response with text and metadata
        def parse_response(response)
          # LM Studio uses OpenAI-compatible format
          choice = response.dig("choices", 0)
          text = choice.dig("message", "content") if choice

          unless text
            raise Ace::LLM::ProviderError, "No text in response from LM Studio"
          end

          # Extract metadata
          metadata = {
            finish_reason: choice["finish_reason"],
            model_used: response["model"] || "local-model"
          }

          # Add token usage if available
          usage = response["usage"]
          if usage
            metadata[:input_tokens] = usage["prompt_tokens"]
            metadata[:output_tokens] = usage["completion_tokens"]
            metadata[:total_tokens] = usage["total_tokens"]
          end

          create_response(text, metadata)
        end

        # Fetch API key from environment (overridden to return nil)
        # @return [nil] LM Studio doesn't need API keys
        def fetch_api_key_from_env
          nil
        end
      end
    end
  end
end