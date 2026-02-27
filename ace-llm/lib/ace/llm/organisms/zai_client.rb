# frozen_string_literal: true

require_relative "base_client"
require_relative "../molecules/openai_compatible_params"

module Ace
  module LLM
    module Organisms
      # ZaiClient handles interactions with Z.AI's OpenAI-compatible API.
      class ZaiClient < BaseClient
        include Molecules::OpenAICompatibleParams

        API_BASE_URL = "https://api.z.ai/api/paas/v4"
        DEFAULT_MODEL = "glm-4.7-flashx"
        DEFAULT_GENERATION_CONFIG = {
          temperature: 0.7,
          max_tokens: 4096,
          top_p: nil,
          frequency_penalty: nil,
          presence_penalty: nil
        }.freeze
        GENERATION_KEYS = %i[temperature max_tokens top_p frequency_penalty presence_penalty].freeze

        def self.provider_name
          "zai"
        end

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

        def build_request_body(messages, generation_params)
          processed_messages = process_messages_with_system_append(
            messages,
            generation_params[:system_append]
          )

          request = {
            model: @model,
            messages: processed_messages
          }

          GENERATION_KEYS.each do |key|
            request[key] = generation_params[key] unless generation_params[key].nil?
          end

          request[:stream] = false
          request
        end

        def extract_generation_options(options)
          gen_opts = super(options)
          extract_openai_compatible_options(options, gen_opts)
          gen_opts.compact
        end

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
            error_type, error_message, status = parse_error_response(response)
            raise Ace::LLM::ProviderError, "Z.AI API error (#{status}): #{error_type} - #{error_message}"
          end

          response.body
        end

        def parse_response(response)
          choice = response.dig("choices", 0)
          raise Ace::LLM::ProviderError, "No choices in response from Z.AI" unless choice

          text = choice.dig("message", "content")
          raise Ace::LLM::ProviderError, "No text in response from Z.AI" unless text

          metadata = {
            finish_reason: choice["finish_reason"],
            id: response["id"],
            created: response["created"]
          }

          usage = response["usage"]
          if usage
            metadata[:input_tokens] = usage["prompt_tokens"]
            metadata[:output_tokens] = usage["completion_tokens"]
            metadata[:total_tokens] = usage["total_tokens"]
          end

          metadata[:model_used] = response["model"] if response["model"]
          create_response(text, metadata)
        end

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

        def build_fallback_error_message(raw_body, status)
          if raw_body.is_a?(String) && !raw_body.empty?
            snippet = raw_body.byteslice(0, 100)&.scrub || raw_body[0, 100]
            snippet += "..." if raw_body.bytesize > 100
            "Non-JSON response: #{snippet}"
          else
            "Unknown error: #{status}"
          end
        end
      end
    end
  end
end
