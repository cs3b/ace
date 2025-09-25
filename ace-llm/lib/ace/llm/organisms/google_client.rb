# frozen_string_literal: true

require_relative "base_client"

module Ace
  module LLM
    module Organisms
      # GoogleClient handles interactions with Google's Gemini API
      class GoogleClient < BaseClient
        API_BASE_URL = "https://generativelanguage.googleapis.com"
        DEFAULT_MODEL = "gemini-2.5-flash"
        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: nil,
          top_p: nil,
          top_k: nil
        }.freeze

        # Get the provider name
        # @return [String] Provider name
        def self.provider_name
          "google"
        end

        # Generate a response from Google's Gemini
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

        # Build request body for Gemini API
        # @param messages [Array<Hash>] Messages
        # @param generation_params [Hash] Generation parameters
        # @return [Hash] Request body
        def build_request_body(messages, generation_params)
          # Convert messages to Gemini format
          contents = messages.map do |msg|
            {
              role: msg[:role] == "assistant" ? "model" : "user",
              parts: [{ text: msg[:content] }]
            }
          end

          request = {
            contents: contents
          }

          # Add generation config if parameters provided
          if generation_params.any?
            request[:generationConfig] = {}
            request[:generationConfig][:temperature] = generation_params[:temperature] if generation_params[:temperature]
            request[:generationConfig][:maxOutputTokens] = generation_params[:max_tokens] if generation_params[:max_tokens]
            request[:generationConfig][:topP] = generation_params[:top_p] if generation_params[:top_p]
            request[:generationConfig][:topK] = generation_params[:top_k] if generation_params[:top_k]
          end

          request
        end

        # Make API request to Gemini
        # @param body [Hash] Request body
        # @return [Hash] API response
        def make_api_request(body)
          url = "#{@base_url}/v1beta/models/#{@model}:generateContent"

          response = @http_client.post(
            url,
            body,
            headers: {
              "Content-Type" => "application/json",
              "x-goog-api-key" => @api_key
            }
          )

          unless response.success?
            error_body = response.body rescue {}
            error_message = error_body["error"]["message"] rescue "Unknown error"
            raise Ace::LLM::ProviderError, "Google API error (#{response.status}): #{error_message}"
          end

          response.body
        end

        # Parse API response
        # @param response [Hash] Raw API response
        # @return [Hash] Parsed response with text and metadata
        def parse_response(response)
          # Extract text from response
          candidate = response.dig("candidates", 0)
          text = candidate.dig("content", "parts", 0, "text") if candidate

          unless text
            raise Ace::LLM::ProviderError, "No text in response from Google"
          end

          # Extract metadata
          metadata = {
            finish_reason: candidate["finishReason"],
            safety_ratings: candidate["safetyRatings"]
          }

          # Add token counts if available
          usage_metadata = response["usageMetadata"]
          if usage_metadata
            metadata[:input_tokens] = usage_metadata["promptTokenCount"]
            metadata[:output_tokens] = usage_metadata["candidatesTokenCount"]
            metadata[:total_tokens] = usage_metadata["totalTokenCount"]
          end

          create_response(text, metadata)
        end
      end
    end
  end
end