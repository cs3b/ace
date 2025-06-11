# frozen_string_literal: true

require "faraday"
# require "json" # No longer needed for direct use here, Faraday's :json middleware handles it.
require_relative "../middlewares/faraday_dry_monitor_logger" # Ensure middleware is loaded and registered

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

        # Register events early to support subscription before making requests
        register_events
      end

      # Perform a GET request
      # @param url [String] The URL to request
      # @param options [Hash] Options hash, can include :params and :headers.
      # @option options [Hash] :params ({}) Query parameters.
      # @option options [Hash] :headers ({}) Request headers.
      # @return [Faraday::Response] The response object
      def get(url, **options)
        params = options.fetch(:params, {})
        headers = options.fetch(:headers, {})
        connection(url).get do |req|
          req.params = params unless params.empty?
          req.headers.merge!(headers) unless headers.empty?
        end
      end

      # Perform a POST request
      # @param url [String] The URL to request
      # @param body [String, Hash, nil] Request body. If Hash, will be JSON-encoded by middleware.
      # @param options [Hash] Options hash, can include :headers.
      # @option options [Hash] :headers ({}) Request headers.
      # @return [Faraday::Response] The response object
      def post(url, body, **options)
        headers = options.fetch(:headers, {})
        connection(url).post do |req|
          req.body = body # Let Faraday's JSON middleware handle nil or hash bodies appropriately
          req.headers.merge!(headers) unless headers.empty?
        end
      end

      private

      # Register events with the notifications system to allow early subscription
      def register_events
        notifications = CodingAgentTools::Notifications.notifications

        # Guard against duplicate event registration across multiple instances
        # While dry-monitor's register_event appears to be idempotent in current version,
        # we implement this guard as a defensive measure per code review feedback
        begin
          notifications.register_event("#{@event_namespace}.request.coding_agent_tools")
          notifications.register_event("#{@event_namespace}.response.coding_agent_tools")
        rescue
          # Silently ignore registration errors for already registered events
          # This handles cases where dry-monitor behavior might change between versions
        end
      end

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
          faraday.use CodingAgentTools::Middlewares::FaradayDryMonitorLogger,
            notifications_instance: CodingAgentTools::Notifications.notifications,
            event_namespace: @event_namespace

          # Middleware to automatically parse JSON response bodies.
          # It will parse bodies with 'Content-Type' matching /\bjson$/.
          # Using symbolize_names: true for consistency with previous manual parsing.
          faraday.response :json, parser_options: {symbolize_names: true}

          # Standard Faraday adapter
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
