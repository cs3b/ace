# frozen_string_literal: true

require_relative "base_client"

module Ace
  module LLM
    module Organisms
      # GroqClient handles interactions with Groq's API
      class GroqClient < BaseClient
        API_BASE_URL = "https://api.groq.com/openai/v1"
        DEFAULT_MODEL = "openai/gpt-oss-120b"
        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: 4096,
          top_p: nil,
          frequency_penalty: nil,
          presence_penalty: nil
        }.freeze

        # Get the provider name
        # @return [String] Provider name
        def self.provider_name
          "groq"
        end

        # Generate a response from Groq
        # @param messages [Array<Hash>, String] Messages or prompt
        # @param options [Hash] Generation options
        # @return [Hash] Response with text and metadata
        def generate(messages, **options)
          messages_array = build_messages(messages)
          generation_params = extract_generation_options(options)

          request_body = build_request_body(messages_array, generation_params)
          response = make_api_request(request_body)

          parse_response(response)
        rescue Ace::LLM::ProviderError
          raise
        rescue StandardError => e
          handle_api_error(e)
        end

        private

        # Build request body for Groq API
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

          # Add allowed generation parameters (extract_generation_options already .compact removes nils)
          allowed_params = %i[temperature max_tokens top_p frequency_penalty presence_penalty stop]
          request.merge!(generation_params.slice(*allowed_params))

          # Streaming disabled (not implemented in ace-llm)
          request[:stream] = false

          request
        end

        # Extract generation options including Groq-specific ones
        # @param options [Hash] Raw options
        # @return [Hash] Generation parameters
        def extract_generation_options(options)
          gen_opts = super(options)

          # Add Groq-specific options (OpenAI-compatible)
          # Use key? check to preserve zero-valued params
          gen_opts[:frequency_penalty] = options[:frequency_penalty] if options.key?(:frequency_penalty)
          gen_opts[:presence_penalty] = options[:presence_penalty] if options.key?(:presence_penalty)
          gen_opts[:stop] = options[:stop] if options.key?(:stop)

          gen_opts.compact
        end

        # Make API request to Groq
        # @param body [Hash] Request body
        # @return [Hash] API response
        def make_api_request(body)
          url = "#{@base_url}/chat/completions"

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

            raise Ace::LLM::ProviderError, "Groq API error (#{response.status}): #{error_type} - #{error_message}"
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
            raise Ace::LLM::ProviderError, "No text in response from Groq"
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
