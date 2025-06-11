# frozen_string_literal: true

require_relative "../atoms/http_client"
require "json"

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
        headers = build_headers(options[:headers], json: options.fetch(:json, true), method: method, body: options[:body])
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
      # @param method [Symbol, nil] HTTP method to determine if Content-Type is needed
      # @param body [Object, nil] Request body to determine if Content-Type is needed
      # @return [Hash] Complete headers
      def build_headers(custom_headers, json: true, method: nil, body: nil)
        headers = {}

        # Merge custom headers first to avoid overwriting them
        headers.merge!(custom_headers) if custom_headers

        if json
          headers["Accept"] ||= "application/json"
          # Add Content-Type for methods that typically have request bodies
          # or when a body is explicitly provided, but only if not already set
          if should_add_content_type?(method, body)
            headers["Content-Type"] ||= "application/json"
          end
        end

        headers
      end

      # Determine if Content-Type header should be added
      # @param method [Symbol, nil] HTTP method
      # @param body [Object, nil] Request body
      # @return [Boolean] Whether to add Content-Type header
      def should_add_content_type?(method, body)
        # Add Content-Type if there's a body or if method typically has a body
        return true if body
        return true if method && [:post, :put, :patch].include?(method)
        false
      end

      # Execute the HTTP request
      # @param method [Symbol] HTTP method
      # @param url [String] Request URL
      # @param query [Hash, nil] Query parameters for GET requests
      # @param body [String, Hash, nil] Request body for POST, PUT, PATCH
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] Response object
      #
      # @note Query parameters are only used for GET requests. For POST and other
      #   non-GET requests, query parameters are ignored and should be included
      #   in the URL or request body as appropriate for the API being called.
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
      # @param json [Boolean] Whether to parse JSON responses
      # @return [Hash] Parsed response data
      def parse_response(response, json: true)
        body = response.body
        raw_body = nil

        # Handle different cases:
        # 1. Body is already parsed (by Faraday middleware) - use efficient raw_body generation
        # 2. Body is a string - use it as raw_body and optionally parse it
        if body.is_a?(String)
          # Parse JSON if requested and it looks like JSON
          if json && looks_like_json?(response)
            begin
              raw_body = body
              parsed_body = JSON.parse(body, symbolize_names: true)
              body = parsed_body
            rescue JSON::ParserError
              # Keep body as string if parsing fails
              # Don't set raw_body since we didn't actually parse
            end
          end
        elsif body.is_a?(Hash) || body.is_a?(Array)
          # Body was already parsed by Faraday middleware
          # For compatibility, provide raw_body but optimize for common cases
          # Only re-encode if it's a reasonably sized response to avoid performance issues
          raw_body = if json && body_size_reasonable?(body)
            JSON.generate(body)
          else
            # For very large responses, skip raw_body to avoid performance penalty
            # This is a reasonable tradeoff for the edge case of huge JSON responses
            nil
          end
        end

        result = {
          status: response.status,
          headers: response.headers.to_h,
          success: response.success?,
          body: body
        }

        # Include raw_body if available (for JSON responses we parsed or re-encoded)
        result[:raw_body] = raw_body if raw_body

        result
      end

      # Check if response looks like JSON based on content-type
      # @param response [Faraday::Response] The response to check
      # @return [Boolean] Whether the response appears to be JSON
      def looks_like_json?(response)
        content_type = response.headers["content-type"] || ""
        content_type.include?("application/json") || content_type.include?("text/json")
      end

      # Check if body size is reasonable for re-encoding
      # This helps avoid performance issues with very large JSON responses
      # @param body [Hash, Array] The parsed body to check
      # @return [Boolean] Whether it's reasonable to re-encode this body
      def body_size_reasonable?(body)
        # Simple heuristic: if serialized size estimation is reasonable, allow re-encoding
        # For most API responses, this will be true. For huge responses, we skip raw_body.
        estimated_size = case body
        when Hash
          body.keys.size + body.values.flatten.size
        when Array
          body.flatten.size
        else
          0
        end
        estimated_size < 10_000 # Reasonable limit for typical API responses
      end
    end
  end
end
