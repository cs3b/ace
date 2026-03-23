# frozen_string_literal: true

require "test_helper"
require "ace/llm/atoms/http_client"

module Ace
  module LLM
    module Atoms
      class HTTPClientErrorHandlingTest < AceLlmTestCase
        def setup
          @client = HTTPClient.new
        end

        def test_initializes_with_default_timeout_values
          client = HTTPClient.new

          # Verify object is created without errors
          assert client.is_a?(HTTPClient)
        end

        def test_accepts_custom_timeout_configuration
          client = HTTPClient.new(
            timeout: 60,
            open_timeout: 20,
            max_retries: 5,
            retry_delay: 2.0
          )

          assert client.is_a?(HTTPClient)
        end

        def test_accepts_custom_retry_statuses
          client = HTTPClient.new(
            retry_statuses: [429, 503]
          )

          assert client.is_a?(HTTPClient)
        end

        def test_should_retry_logic_for_timeout_errors
          client = HTTPClient.new(max_retries: 3)

          timeout_error = Faraday::TimeoutError.new("Request timeout")

          # Should retry on first attempt (retries < max_retries)
          assert client.send(:should_retry?, timeout_error, 0)
          assert client.send(:should_retry?, timeout_error, 1)
          assert client.send(:should_retry?, timeout_error, 2)

          # Should not retry when max retries reached
          refute client.send(:should_retry?, timeout_error, 3)
        end

        def test_should_retry_logic_for_connection_errors
          client = HTTPClient.new(max_retries: 2)

          connection_error = Faraday::ConnectionFailed.new("Connection refused")

          # Should retry connection errors
          assert client.send(:should_retry?, connection_error, 0)
          assert client.send(:should_retry?, connection_error, 1)

          # Should not retry when max retries reached
          refute client.send(:should_retry?, connection_error, 2)
        end

        def test_should_retry_logic_for_rate_limit_429
          client = HTTPClient.new(max_retries: 3)

          # Create mock response with 429 status
          response_env = {status: 429, body: "Rate limited"}
          error = Faraday::ClientError.new("Rate limit", response_env)

          # Should retry on 429 status
          assert client.send(:should_retry?, error, 0)
          assert client.send(:should_retry?, error, 1)
        end

        def test_should_retry_logic_for_500_server_error
          client = HTTPClient.new(max_retries: 3)

          response_env = {status: 500, body: "Server error"}
          error = Faraday::ServerError.new("Internal error", response_env)

          # Should retry on 500 status
          assert client.send(:should_retry?, error, 0)
        end

        def test_should_retry_logic_for_502_bad_gateway
          client = HTTPClient.new(max_retries: 3)

          response_env = {status: 502, body: "Bad gateway"}
          error = Faraday::ServerError.new("Bad gateway", response_env)

          # Should retry on 502 status
          assert client.send(:should_retry?, error, 0)
        end

        def test_should_retry_logic_for_503_service_unavailable
          client = HTTPClient.new(max_retries: 3)

          response_env = {status: 503, body: "Service unavailable"}
          error = Faraday::ServerError.new("Service unavailable", response_env)

          # Should retry on 503 status
          assert client.send(:should_retry?, error, 0)
        end

        def test_should_retry_logic_for_504_gateway_timeout
          client = HTTPClient.new(max_retries: 3)

          response_env = {status: 504, body: "Gateway timeout"}
          error = Faraday::ServerError.new("Gateway timeout", response_env)

          # Should retry on 504 status
          assert client.send(:should_retry?, error, 0)
        end

        def test_should_not_retry_on_400_client_error
          client = HTTPClient.new(max_retries: 3)

          response_env = {status: 400, body: "Bad request"}
          error = Faraday::ClientError.new("Bad request", response_env)

          # Should not retry on 400 status
          refute client.send(:should_retry?, error, 0)
        end

        def test_should_not_retry_on_404_not_found
          client = HTTPClient.new(max_retries: 3)

          response_env = {status: 404, body: "Not found"}
          error = Faraday::ClientError.new("Not found", response_env)

          # Should not retry on 404 status
          refute client.send(:should_retry?, error, 0)
        end

        def test_should_not_retry_on_401_unauthorized
          client = HTTPClient.new(max_retries: 3)

          response_env = {status: 401, body: "Unauthorized"}
          error = Faraday::ClientError.new("Unauthorized", response_env)

          # Should not retry on 401 status
          refute client.send(:should_retry?, error, 0)
        end

        def test_custom_retry_statuses
          # Only retry on 429
          client = HTTPClient.new(retry_statuses: [429])

          # 429 should be retried
          response_429 = {status: 429, body: "Rate limited"}
          error_429 = Faraday::ClientError.new("Rate limit", response_429)
          assert client.send(:should_retry?, error_429, 0)

          # 503 should not be retried (not in custom list)
          response_503 = {status: 503, body: "Service unavailable"}
          error_503 = Faraday::ServerError.new("Service unavailable", response_503)
          refute client.send(:should_retry?, error_503, 0)
        end

        def test_max_retries_limit
          client = HTTPClient.new(max_retries: 2)

          timeout_error = Faraday::TimeoutError.new("Timeout")

          # Should retry up to max_retries
          assert client.send(:should_retry?, timeout_error, 0)
          assert client.send(:should_retry?, timeout_error, 1)

          # Should not retry after max_retries reached
          refute client.send(:should_retry?, timeout_error, 2)
          refute client.send(:should_retry?, timeout_error, 3)
        end

        def test_zero_max_retries
          client = HTTPClient.new(max_retries: 0)

          timeout_error = Faraday::TimeoutError.new("Timeout")

          # Should not retry when max_retries is 0
          refute client.send(:should_retry?, timeout_error, 0)
        end

        def test_handles_error_without_response
          client = HTTPClient.new(max_retries: 3)

          # Generic Faraday error without response
          generic_error = Faraday::Error.new("Generic error")

          # Should not retry errors without response status
          refute client.send(:should_retry?, generic_error, 0)
        end

        def test_connection_method_creates_faraday_connection
          connection = @client.send(:connection, "https://api.example.com")

          assert connection.is_a?(Faraday::Connection)
        end

        def test_connection_applies_timeout_settings
          client = HTTPClient.new(timeout: 45, open_timeout: 15)
          connection = client.send(:connection, "https://api.example.com")

          assert_equal 45, connection.options.timeout
          assert_equal 15, connection.options.open_timeout
        end
      end
    end
  end
end
