# frozen_string_literal: true

require "faraday"
# require "json" # No longer needed for direct use here, Faraday's :json middleware handles it.

module CodingAgentTools
  module Atoms
    # HTTPClient provides basic HTTP operations using Faraday
    # This is an atom - it has no dependencies on other parts of this gem
    class HTTPClient
      # @param options [Hash] Configuration options
      # @option options [Integer] :timeout (30) Request timeout in seconds
      # @option options [Integer] :open_timeout (10) Connection open timeout in seconds
      # @option options [Symbol] :event_namespace (:http_client) Namespace for dry-monitor events.
      def initialize(options = {})
        @timeout = options.fetch(:timeout, 30)
        @open_timeout = options.fetch(:open_timeout, 10)
        @event_namespace = options.fetch(:event_namespace, :http_client)
      end

      # Perform a GET request
      # @param url [String] The URL to request
      # @param params [Hash] Query parameters
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] The response object
      def get(url, params: {}, headers: {})
        # Faraday's GET request can take the path (nil if url is full), params, and headers.
        # If 'url' in connection is the base, 'url' here would be the path.
        # If 'url' in connection is full, path for .get should be nil or empty.
        # Assuming 'url' passed to this method is the full URL or specific path segment for the request.
        connection(url).get(nil, params, headers)
      end

      # Perform a POST request
      # @param url [String] The URL to request
      # @param body [String, Hash, nil] Request body. If Hash, will be JSON-encoded by middleware.
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] The response object
      def post(url, body, headers: {})
        # Faraday's POST request can take path (nil if url is full), body, and headers.
        # The :json request middleware will handle Hash bodies.
        connection(url).post(nil, body, headers)
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
          # and set 'Content-Type: application/json'.
          faraday.request :json

          # Custom middleware for dry-monitor logging
          # This should come after request manipulation middleware (like :json) to log final request details,
          # and before response manipulation middleware if we want to log the raw-ish response before parsing.
          # However, Faraday's :json response middleware parses the body and populates response.body.
          # Our logger accesses response.status and response.headers, which are fine.
          faraday.use :faraday_dry_monitor_logger,
                      notifications_instance: CodingAgentTools::Notifications.notifications,
                      event_namespace: @event_namespace

          # Middleware to automatically parse JSON response bodies.
          # It will parse bodies with 'Content-Type' matching /\bjson$/.
          # Using symbolize_names: true for consistency with previous manual parsing.
          faraday.response :json, parser_options: { symbolize_names: true }

          # Standard Faraday adapter
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
