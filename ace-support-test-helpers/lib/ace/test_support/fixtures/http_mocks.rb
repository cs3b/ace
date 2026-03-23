# frozen_string_literal: true

require "securerandom"

module Ace
  module TestSupport
    module Fixtures
      # Shared mock fixtures for HTTP client testing
      # Extracted from ace-llm to promote reusability across LLM provider tests
      module HTTPMocks
        # Mock HTTP client for testing API interactions
        # Simulates HTTP requests without making actual network calls
        class MockHTTPClient
          attr_reader :last_request, :request_history

          def initialize
            @response = nil
            @error_response = nil
            @last_request = nil
            @request_history = []
          end

          # Set a successful response
          # @param body [Hash] The response body
          def set_response(body)
            @response = body
            @error_response = nil
          end

          # Set an error response
          # @param status [Integer] HTTP status code
          # @param message [String] Error message
          def set_error_response(status, message)
            @error_response = {status: status, message: message}
            @response = nil
          end

          # Simulate a POST request
          # @param url [String] Request URL
          # @param body [Hash] Request body
          # @param headers [Hash] Request headers
          # @return [MockResponse] Mock response object
          def post(url, body, headers: {})
            @last_request = {url: url, body: body, headers: headers}
            @request_history << @last_request

            if @error_response
              MockResponse.new(
                success: false,
                status: @error_response[:status],
                body: {"error" => {"message" => @error_response[:message], "type" => "api_error"}}
              )
            else
              MockResponse.new(success: true, status: 200, body: @response)
            end
          end

          # Reset the mock client state
          def reset!
            @response = nil
            @error_response = nil
            @last_request = nil
            @request_history = []
          end
        end

        # Mock HTTP response object
        class MockResponse
          attr_reader :status, :body

          def initialize(success:, status:, body:)
            @success = success
            @status = status
            @body = body
          end

          def success?
            @success
          end
        end

        # Common LLM API response fixtures
        module LLMResponses
          # Standard successful chat completion response (OpenAI-compatible format)
          # @param content [String] The assistant's response content
          # @param model [String] The model name
          # @param input_tokens [Integer] Prompt tokens
          # @param output_tokens [Integer] Completion tokens
          # @return [Hash] Success response
          def self.chat_completion(
            content: "Hello! How can I assist you today?",
            model: "test-model",
            input_tokens: 10,
            output_tokens: 20
          )
            {
              "id" => "chatcmpl-test#{SecureRandom.hex(4)}",
              "object" => "chat.completion",
              "created" => Time.now.to_i,
              "model" => model,
              "choices" => [
                {
                  "index" => 0,
                  "message" => {
                    "role" => "assistant",
                    "content" => content
                  },
                  "finish_reason" => "stop"
                }
              ],
              "usage" => {
                "prompt_tokens" => input_tokens,
                "completion_tokens" => output_tokens,
                "total_tokens" => input_tokens + output_tokens
              }
            }
          end

          # Response with missing usage field
          # @param content [String] The assistant's response content
          # @param model [String] The model name
          # @return [Hash] Response without usage
          def self.chat_completion_without_usage(
            content: "Hello! How can I assist you today?",
            model: "test-model"
          )
            {
              "id" => "chatcmpl-test#{SecureRandom.hex(4)}",
              "object" => "chat.completion",
              "created" => Time.now.to_i,
              "model" => model,
              "choices" => [
                {
                  "index" => 0,
                  "message" => {
                    "role" => "assistant",
                    "content" => content
                  },
                  "finish_reason" => "stop"
                }
              ]
            }
          end

          # Response with missing model field
          # @param content [String] The assistant's response content
          # @param input_tokens [Integer] Prompt tokens
          # @param output_tokens [Integer] Completion tokens
          # @return [Hash] Response without model
          def self.chat_completion_without_model(
            content: "Hello! How can I assist you today?",
            input_tokens: 10,
            output_tokens: 20
          )
            {
              "id" => "chatcmpl-test#{SecureRandom.hex(4)}",
              "object" => "chat.completion",
              "created" => Time.now.to_i,
              "choices" => [
                {
                  "index" => 0,
                  "message" => {
                    "role" => "assistant",
                    "content" => content
                  },
                  "finish_reason" => "stop"
                }
              ],
              "usage" => {
                "prompt_tokens" => input_tokens,
                "completion_tokens" => output_tokens,
                "total_tokens" => input_tokens + output_tokens
              }
            }
          end

          # Response with empty choices
          # @return [Hash] Response with empty choices array
          def self.empty_choices(model: "test-model")
            {
              "id" => "chatcmpl-test#{SecureRandom.hex(4)}",
              "object" => "chat.completion",
              "created" => Time.now.to_i,
              "model" => model,
              "choices" => []
            }
          end

          # Response with nil content
          # @return [Hash] Response with nil content in message
          def self.nil_content(model: "test-model")
            {
              "id" => "chatcmpl-test",
              "choices" => [{"message" => {"content" => nil}, "finish_reason" => "stop"}],
              "model" => model
            }
          end
        end
      end
    end
  end
end
