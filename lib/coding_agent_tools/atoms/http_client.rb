# frozen_string_literal: true

require "faraday"
require "json"

module CodingAgentTools
  module Atoms
    # HTTPClient provides basic HTTP operations using Faraday
    # This is an atom - it has no dependencies on other parts of this gem
    class HTTPClient
      # @param options [Hash] Configuration options
      # @option options [Integer] :timeout (30) Request timeout in seconds
      # @option options [Integer] :open_timeout (10) Connection open timeout in seconds
      def initialize(options = {})
        @timeout = options.fetch(:timeout, 30)
        @open_timeout = options.fetch(:open_timeout, 10)
      end

      # Perform a GET request
      # @param url [String] The URL to request
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] The response object
      def get(url, headers = {})
        connection(url).get do |req|
          req.headers.merge!(headers)
        end
      end

      # Perform a POST request
      # @param url [String] The URL to request
      # @param body [String, Hash] Request body (will be JSON-encoded if Hash)
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] The response object
      def post(url, body, headers = {})
        connection(url).post do |req|
          req.headers.merge!(headers)

          if body.is_a?(Hash)
            req.headers["Content-Type"] = "application/json"
            req.body = JSON.generate(body)
          else
            req.body = body
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
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
