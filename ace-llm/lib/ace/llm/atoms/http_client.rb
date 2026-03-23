# frozen_string_literal: true

require "faraday"

module Ace
  module LLM
    module Atoms
      # HTTPClient provides basic HTTP operations using Faraday
      # This is an atom - it has no dependencies on other parts of this gem
      class HTTPClient
        # @param options [Hash] Configuration options
        # @option options [Integer] :timeout (30) Request timeout in seconds
        # @option options [Integer] :open_timeout (10) Connection open timeout in seconds
        # @option options [Integer] :max_retries (3) Maximum number of retries
        # @option options [Array<Integer>] :retry_statuses ([429, 500, 502, 503, 504]) Status codes to retry
        # @option options [Float] :retry_delay (1.0) Initial retry delay in seconds
        def initialize(options = {})
          @timeout = options.fetch(:timeout, 30).to_i
          @open_timeout = options.fetch(:open_timeout, 10).to_i
          @max_retries = options.fetch(:max_retries, 3).to_i
          @retry_statuses = options.fetch(:retry_statuses, [429, 500, 502, 503, 504])
          @retry_delay = options.fetch(:retry_delay, 1.0).to_f
        end

        # Perform a GET request
        # @param url [String] The URL to request
        # @param options [Hash] Options hash
        # @option options [Hash] :params ({}) Query parameters
        # @option options [Hash] :headers ({}) Request headers
        # @return [Faraday::Response] The response object
        def get(url, **options)
          params = options.fetch(:params, {})
          headers = options.fetch(:headers, {})

          execute_with_retry do
            connection(url).get do |req|
              req.params = params unless params.empty?
              req.headers.merge!(headers) unless headers.empty?
            end
          end
        end

        # Perform a POST request
        # @param url [String] The URL to request
        # @param body [String, Hash, nil] Request body (Hash will be JSON-encoded)
        # @param options [Hash] Options hash
        # @option options [Hash] :headers ({}) Request headers
        # @return [Faraday::Response] The response object
        def post(url, body = nil, **options)
          headers = options.fetch(:headers, {})

          execute_with_retry do
            connection(url).post do |req|
              req.body = body
              req.headers.merge!(headers) unless headers.empty?
            end
          end
        end

        # Perform a PUT request
        # @param url [String] The URL to request
        # @param body [String, Hash, nil] Request body
        # @param options [Hash] Options hash
        # @option options [Hash] :headers ({}) Request headers
        # @return [Faraday::Response] The response object
        def put(url, body = nil, **options)
          headers = options.fetch(:headers, {})

          execute_with_retry do
            connection(url).put do |req|
              req.body = body
              req.headers.merge!(headers) unless headers.empty?
            end
          end
        end

        # Perform a DELETE request
        # @param url [String] The URL to request
        # @param options [Hash] Options hash
        # @option options [Hash] :params ({}) Query parameters
        # @option options [Hash] :headers ({}) Request headers
        # @return [Faraday::Response] The response object
        def delete(url, **options)
          params = options.fetch(:params, {})
          headers = options.fetch(:headers, {})

          execute_with_retry do
            connection(url).delete do |req|
              req.params = params unless params.empty?
              req.headers.merge!(headers) unless headers.empty?
            end
          end
        end

        private

        # Create a Faraday connection for the given URL
        # @param url [String] The base URL
        # @return [Faraday::Connection] Configured connection
        def connection(url)
          Faraday.new(url: url) do |faraday|
            faraday.options.timeout = @timeout
            faraday.options.open_timeout = @open_timeout

            # Middleware to automatically encode request bodies as JSON
            faraday.request :json

            # Middleware to automatically parse JSON responses
            # Pattern matches: application/json, application/json; charset=utf-8, text/json, etc.
            faraday.response :json, content_type: /\bjson\b/

            # Use the default adapter
            faraday.adapter Faraday.default_adapter
          end
        end

        # Execute a block with retry logic
        # @yield The block to execute
        # @return The result of the block
        def execute_with_retry
          retries = 0
          delay = @retry_delay

          begin
            yield
          rescue Faraday::Error => e
            if should_retry?(e, retries)
              retries += 1
              sleep(delay)
              delay *= 2 # Exponential backoff
              retry
            else
              raise
            end
          end
        end

        # Determine if a request should be retried
        # @param error [Faraday::Error] The error that occurred
        # @param retries [Integer] Number of retries so far
        # @return [Boolean] Whether to retry
        def should_retry?(error, retries)
          return false if retries >= @max_retries

          # Check if it's a timeout error
          return true if error.is_a?(Faraday::TimeoutError)

          # Check if it's a connection error
          return true if error.is_a?(Faraday::ConnectionFailed)

          # Check if it's a retriable status code
          if error.respond_to?(:response) && error.response
            status = error.response[:status]
            return @retry_statuses.include?(status)
          end

          false
        end
      end
    end
  end
end
