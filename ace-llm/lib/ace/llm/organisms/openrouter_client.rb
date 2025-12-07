# frozen_string_literal: true

require_relative "base_client"

module Ace
  module LLM
    module Organisms
      # OpenRouterClient handles interactions with OpenRouter's API
      # OpenRouter provides unified access to 400+ models through OpenAI-compatible API
      class OpenRouterClient < BaseClient
        API_BASE_URL = "https://openrouter.ai/api/v1"
        DEFAULT_MODEL = "openai/gpt-oss-120b:nitro"

        # Get the provider name
        # @return [String] Provider name
        def self.provider_name
          "openrouter"
        end

        # Initialize the client
        # @param api_key [String, nil] API key (uses env if nil)
        # @param model [String, nil] Model name (uses default if nil)
        # @param referer [String, nil] HTTP-Referer header for app attribution
        #   (should not contain sensitive information as it's sent with each request)
        # @param title [String, nil] X-Title header for app attribution
        #   (should not contain sensitive information as it's sent with each request)
        # @param options [Hash] Additional options passed to base client
        def initialize(api_key: nil, model: nil, referer: nil, title: nil, **options)
          # Store attribution headers separately for explicit dependencies
          @referer = referer
          @title = title
          super(api_key: api_key, model: model, **options)
        end

        # Generate a response from OpenRouter
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
          # Intentionally catch StandardError to wrap all API/network errors
          # as ProviderError for consistent error handling upstream
          handle_api_error(e)
        end

        private

        # Build request body for OpenRouter API
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

          # Add generation parameters (use nil checks to allow valid 0/false values)
          request[:temperature] = generation_params[:temperature] unless generation_params[:temperature].nil?
          request[:max_tokens] = generation_params[:max_tokens] unless generation_params[:max_tokens].nil?
          request[:top_p] = generation_params[:top_p] unless generation_params[:top_p].nil?
          request[:frequency_penalty] = generation_params[:frequency_penalty] unless generation_params[:frequency_penalty].nil?
          request[:presence_penalty] = generation_params[:presence_penalty] unless generation_params[:presence_penalty].nil?

          # Add streaming flag (always false for now)
          request[:stream] = false

          request
        end

        # Extract generation options including OpenRouter-specific ones
        # @param options [Hash] Raw options
        # @return [Hash] Generation parameters
        def extract_generation_options(options)
          gen_opts = super(options)

          # Add OpenRouter-specific options (use nil checks to allow valid 0 values)
          gen_opts[:frequency_penalty] = options[:frequency_penalty] unless options[:frequency_penalty].nil?
          gen_opts[:presence_penalty] = options[:presence_penalty] unless options[:presence_penalty].nil?

          gen_opts.compact
        end

        # Make API request to OpenRouter
        # @param body [Hash] Request body
        # @return [Hash] API response
        def make_api_request(body)
          url = "#{@base_url}/chat/completions"

          headers = {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{@api_key}"
          }

          # Add optional attribution headers if provided
          headers["HTTP-Referer"] = @referer if @referer
          headers["X-Title"] = @title if @title

          response = @http_client.post(url, body, headers: headers)

          unless response.success?
            # Guard against non-Hash response bodies (e.g., HTML error pages from 502)
            error_body = begin
              body = response.body
              body.is_a?(Hash) ? body : {}
            rescue
              {}
            end

            error_message = error_body.dig("error", "message") || "Unknown error: #{response.status}"
            error_type = error_body.dig("error", "type") || "unknown"

            raise Ace::LLM::ProviderError, "OpenRouter API error (#{response.status}): #{error_type} - #{error_message}"
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
            raise Ace::LLM::ProviderError, "No text in response from OpenRouter"
          end

          # Extract metadata
          metadata = {
            finish_reason: choice["finish_reason"],
            id: response["id"],
            created: response["created"]
          }

          # Preserve native_finish_reason (OpenRouter normalizes this field)
          if choice["native_finish_reason"]
            metadata[:native_finish_reason] = choice["native_finish_reason"]
          end

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
