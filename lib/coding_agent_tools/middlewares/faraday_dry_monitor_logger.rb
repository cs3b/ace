# frozen_string_literal: true

require "faraday"

module CodingAgentTools
  module Middlewares
    # FaradayDryMonitorLogger is a Faraday middleware for instrumenting HTTP calls
    # using a `Dry::Monitor::Notifications` instance.
    #
    # It publishes two events for each HTTP request:
    #
    # 1.  `"<namespace>.request.coding_agent_tools"`: Published before the request is sent.
    #     Payload:
    #       - `:method` (Symbol): The HTTP method (e.g., `:get`, `:post`).
    #       - `:url` (String): The full request URL.
    #       - `:headers` (Hash): The request headers.
    #
    # 2.  `"<namespace>.response.coding_agent_tools"`: Published after the response is received
    #     or an error occurs during the request.
    #     Payload:
    #       - `:method` (Symbol): The HTTP method.
    #       - `:url` (String): The full request URL.
    #       - `:status` (Integer, nil): The HTTP status code, or `nil` if an error occurred before a response.
    #       - `:duration_ms` (Float): The duration of the request-response cycle in milliseconds.
    #       - `:response_headers` (Hash): The response headers, or an empty hash if no response.
    #       - `:error_class` (String, nil): The class name of the error if one was raised, otherwise `nil`.
    #
    # @example Usage
    #   notifications_instance = CodingAgentTools::Notifications.notifications
    #
    #   connection = Faraday.new(url: "http://example.com") do |faraday|
    #     faraday.use :faraday_dry_monitor_logger,
    #                 notifications_instance: notifications_instance,
    #                 event_namespace: :my_api_service
    #     faraday.adapter Faraday.default_adapter
    #   end
    #
    #   # To register this middleware with Faraday for easier use:
    #   # Faraday::Middleware.register_middleware faraday_dry_monitor_logger: -> { FaradayDryMonitorLogger }
    #
    class FaradayDryMonitorLogger < Faraday::Middleware
      # Initializes the middleware.
      #
      # @param app [#call] The next Faraday middleware or adapter in the stack.
      # @param notifications_instance [Dry::Monitor::Notifications] The `dry-monitor`
      #   notifications instance to use for publishing events.
      # @param event_namespace [String, Symbol] An optional namespace for the events.
      #   Defaults to `:http_client`.
      def initialize(app, notifications_instance:, event_namespace: :http_client)
        super(app)
        unless notifications_instance&.respond_to?(:publish)
          raise ArgumentError, "notifications_instance must be a Dry::Monitor::Notifications compatible object"
        end
        @notifications = notifications_instance
        @namespace = event_namespace

        # Explicitly register the events this middleware will publish
        @notifications.register_event("#{@namespace}.request.coding_agent_tools")
        @notifications.register_event("#{@namespace}.response.coding_agent_tools")
      end

      # Processes the request and instruments it.
      #
      # @param request_env [Faraday::Env] The request environment.
      # @return [Faraday::Response] The response from the server.
      # @raise [StandardError] Propagates exceptions raised during the request.
      def call(request_env)
        method = request_env.method
        url = request_env.url.to_s
        request_headers = request_env.request_headers.to_h

        publish_request_event(method, url, request_headers)

        response = nil
        error_object = nil
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          response = @app.call(request_env)
        rescue StandardError => e
          error_object = e
          raise # Re-raise after instrumentation in ensure block
        ensure
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration_ms = ((end_time - start_time) * 1000).round(3)

          publish_response_event(method, url, response, duration_ms, error_object)
        end

        response
      end

      private

      def publish_request_event(method, url, headers)
        event_name = "#{@namespace}.request.coding_agent_tools"
        payload = {
          method: method,
          url: url,
          headers: headers
        }
        @notifications.publish(event_name, payload)
      end

      def publish_response_event(method, url, response, duration_ms, error_object)
        event_name = "#{@namespace}.response.coding_agent_tools"
        payload = {
          method: method,
          url: url,
          status: response&.status,
          duration_ms: duration_ms,
          response_headers: response&.headers&.to_h || {},
          error_class: error_object&.class&.name
        }
        @notifications.publish(event_name, payload)
      end
    end
    Faraday::Middleware.register_middleware faraday_dry_monitor_logger: -> { FaradayDryMonitorLogger }
  end
end
