# frozen_string_literal: true

require_relative "../atoms/http_client"
require_relative "../atoms/json_formatter"

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
        url_with_query = build_url_with_query(url, options[:query])

        response = execute_request(method, url_with_query, options[:body], headers)

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
      # @param body [String, Hash, nil] Request body
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] Raw response object
      def raw_request(method, url, body: nil, headers: {})
        case method
        when :get
          @client.get(url, headers)
        when :post
          @client.post(url, body, headers)
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
          headers["Content-Type"] = "application/json"
        end

        headers.merge!(custom_headers) if custom_headers
        headers
      end

      # Build URL with query parameters
      # @param url [String] Base URL
      # @param query [Hash, nil] Query parameters
      # @return [String] URL with query string
      def build_url_with_query(url, query)
        return url if query.nil? || query.empty?

        uri = URI.parse(url)
        existing_query = uri.query ? URI.decode_www_form(uri.query).to_h : {}

        # Merge with new query params
        all_params = existing_query.merge(query.transform_keys(&:to_s))

        uri.query = URI.encode_www_form(all_params)
        uri.to_s
      end

      # Execute the HTTP request
      # @param method [Symbol] HTTP method
      # @param url [String] Request URL
      # @param body [String, Hash, nil] Request body
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] Response object
      def execute_request(method, url, body, headers)
        case method
        when :get
          @client.get(url, headers)
        when :post
          @client.post(url, body, headers)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

      # Parse the response
      # @param response [Faraday::Response] Raw response
      # @param json [Boolean] Whether to parse as JSON
      # @return [Hash] Parsed response data
      def parse_response(response, json: true)
        result = {
          status: response.status,
          headers: response.headers.to_h,
          success: response.success?
        }

        if json && response.headers["content-type"]&.include?("application/json")
          result[:body] = Atoms::JSONFormatter.safe_parse(response.body, symbolize_names: true)
          result[:raw_body] = response.body
        else
          result[:body] = response.body
        end

        result
      end
    end
  end
end
