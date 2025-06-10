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
        headers = build_headers(options[:headers], json: options.fetch(:json, true), method: method, body: options[:body])
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
      # @param method [Symbol] HTTP method
      # @param body [String, Hash, nil] Request body
      # @return [Hash] Complete headers
      def build_headers(custom_headers, json: true, method: nil, body: nil)
        headers = {}

        if json
          headers["Accept"] = "application/json"
          # Only add Content-Type when body is present or method is POST
          if body || method == :post
            headers["Content-Type"] = "application/json"
          end
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

        # 1. Process the input 'query' hash (additional parameters to be added/merged).
        #    This correctly handles array values in the input 'query' hash, converting
        #    { key: [val1, val2] } to [["key", "val1"], ["key", "val2"]].
        new_params_list = []
        query.each do |key, value| # 'query' is the hash of additional parameters passed to the method
          if value.is_a?(Array)
            value.each { |v| new_params_list << [key.to_s, v.to_s] }
          else
            new_params_list << [key.to_s, value.to_s]
          end
        end

        # 2. Get existing parameters from the URL's query string as an array of [key, value] pairs.
        #    This preserves all original parameters, including multi-value ones (e.g., "ids=1&ids=2").
        existing_params_list = uri.query ? URI.decode_www_form(uri.query) : []

        # 3. Combine the new parameters and existing parameters.
        #    Parameters from the input 'query' hash are placed first, effectively taking precedence
        #    or being prepended if keys are duplicated.
        all_params_list = new_params_list + existing_params_list

        # 4. Set the URI query component.
        #    If the 'query' hash was empty (and the initial guard was bypassed or removed),
        #    and the original URL also had no query, all_params_list would be empty.
        #    In such cases, uri.query should be nil to avoid a trailing '?' in the URL.
        uri.query = if all_params_list.empty?
          nil
        else
          URI.encode_www_form(all_params_list)
        end

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
