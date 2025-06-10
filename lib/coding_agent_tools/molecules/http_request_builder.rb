# frozen_string_literal: true

require_relative "../atoms/http_client"
# require_relative "../atoms/json_formatter" # No longer directly used here

module CodingAgentTools
  module Molecules
    # HTTPRequestBuilder builds and executes HTTP requests
    # This is a molecule - it composes HTTPClient and JSONFormatter atoms
    class HTTPRequestBuilder
      # @param client [Atoms::HTTPClient, nil] HTTP client instance (creates new if nil)
      # @param options [Hash] Options for the HTTP client
      def initialize(client: nil, **options)
        @client = client || Atoms::HTTPClient.new(options)
      end

      # Build and execute a JSON API request
      # @param method [Symbol] HTTP method (:get, :post, :put, :patch, :delete)
      # @param url [String] Request URL
      # @param options [Hash] Request options
      # @option options [Hash] :headers Additional headers
      # @option options [Hash, String] :body Request body
      # @option options [Hash] :query Query parameters
      # @option options [Boolean] :json (true) Whether to send/receive JSON
      # @return [Hash] Response data including status, headers, and body
      def json_request(method, url, **options)
        headers = build_headers(options[:headers], json: options.fetch(:json, true))
        # Query parameters are now passed directly to execute_request,
        # which will pass them to HTTPClient, which in turn lets Faraday handle them.
        response = execute_request(method, url, query: options[:query], body: options[:body], headers: headers)

        parse_response(response, json: options.fetch(:json, true))
      end

      # Build a POST request for JSON APIs
      # @param url [String] Request URL
      # @param body [Hash, String] Request body
      # @param headers [Hash] Additional headers
      # @return [Hash] Response data
      def post_json(url, body, headers: {})
        json_request(:post, url, body: body, headers: headers)
      end

      # Build a GET request for JSON APIs
      # @param url [String] Request URL
      # @param query [Hash] Query parameters
      # @param headers [Hash] Additional headers
      # @return [Hash] Response data
      def get_json(url, query: nil, headers: {})
        json_request(:get, url, query: query, headers: headers)
      end

      # Execute a raw HTTP request
      # @param method [Symbol] HTTP method
      # @param url [String] Request URL
      # @param query [Hash, nil] Query parameters (for GET requests)
      # @param body [String, Hash, nil] Request body
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] Raw response object
      def raw_request(method, url, query: nil, body: nil, headers: {})
        case method
        when :get
          @client.get(url, params: query || {}, headers: headers)
        when :post
          @client.post(url, body, headers: headers)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

      private

      # Build headers for the request
      # @param custom_headers [Hash, nil] Custom headers to merge
      # @param json [Boolean] Whether this is a JSON request
      # @return [Hash] Complete headers
      def build_headers(custom_headers, json: true)
        headers = {}

        if json
          headers["Accept"] = "application/json"
          # Content-Type: application/json for request body is now handled by
          # Faraday's :json request middleware in HTTPClient if the body is a Hash.
        end

        headers.merge!(custom_headers) if custom_headers
        headers
      end

      # Execute the HTTP request
      # @param method [Symbol] HTTP method
      # @param url [String] Request URL
      # @param query [Hash, nil] Query parameters for GET requests
      # @param body [String, Hash, nil] Request body for POST, PUT, PATCH
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] Response object
      def execute_request(method, url, query: nil, body: nil, headers: {})
        case method
        when :get
          @client.get(url, params: query || {}, headers: headers)
        when :post
          # For POST, query params are typically part of the URL or body, not separate.
          # If they were needed in URL for POST, URL construction should happen before this call.
          @client.post(url, body, headers: headers)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

      # Parse the response
      # @param response [Faraday::Response] Raw response from HTTPClient
      # @param json [Boolean] Hint for consumers; not used for parsing within this method anymore
      # @return [Hash] Parsed response data
      def parse_response(response, json: true) # rubocop:disable Lint/UnusedMethodArgument
        result = {
          status: response.status,
          headers: response.headers.to_h,
          success: response.success?,
          # response.body is now either a Hash/Array (if parsed by Faraday's :json middleware)
          # or a String (if not JSON, not parseable, or middleware not used/applicable).
          # APIResponseParser will handle further processing if it's a string.
          body: response.body
        }
        # The raw_body concept is simplified: if response.body is a string, that *is* the raw body.
        # If it's parsed, the raw string form is implicitly handled by the fact that
        # APIResponseParser will work with the parsed form or try to parse if it's a string.
        result
      end
    end
  end
end
