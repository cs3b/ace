# frozen_string_literal: true

require "dry-monitor"

module CodingAgentTools
  # Notifications module provides a central Dry::Monitor::Notifications instance
  # for instrumenting events within the gem.
  #
  # Applications consuming this gem can subscribe to events published through this
  # notifications instance.
  #
  # Example:
  #   CodingAgentTools::Notifications.subscribe("some.event.coding_agent_tools") do |event|
  #     puts "Event #{event.id} received with payload: #{event.payload}"
  #   end
  module Notifications
    class << self
      # The application's main notification system.
      # This instance is memoized.
      #
      # @return [Dry::Monitor::Notifications] The notifications instance for the gem.
      def notifications
        @notifications ||= Dry::Monitor::Notifications.new(:coding_agent_tools_gem)
      end

      # Utility method to explicitly register an event with the notification system.
      # While dry-monitor can implicitly register events on first publish/instrument,
      # explicit registration can be useful for documentation, early validation, or
      # associating default payload information.
      #
      # @param event_id [String, Symbol] The event identifier (e.g., "http.request").
      # @param payload [Hash] Optional default payload structure for the event.
      # @return [Dry::Events::Event] The registered event object.
      #
      # Example:
      #   CodingAgentTools::Notifications.register_event("gemini_api.request")
      def register_event(event_id, payload = {})
        notifications.register_event(event_id, payload)
      end

      # A convenience method to subscribe to events.
      #
      # @param event_id [String, Symbol] The event to subscribe to.
      # @param listener [#call, nil] An optional listener object that responds to #call.
      # @yield [Dry::Events::Event] If a block is given, it will be used as the listener.
      # @return [Dry::Events::Listener, Object] The listener object or the result of the block.
      #
      # Example:
      #   CodingAgentTools::Notifications.subscribe("gemini_api.request") do |event|
      #     MyLogger.info "Gemini API Request: #{event.payload}"
      #   end
      def subscribe(event_id, listener = nil, &block)
        notifications.subscribe(event_id, listener, &block)
      end

      # A convenience method to instrument a block of code.
      #
      # @param event_id [String, Symbol] The event to instrument.
      # @param payload [Hash] The payload for the event.
      # @yield The block of code to instrument.
      # @return The result of the yielded block.
      #
      # Example:
      #   CodingAgentTools::Notifications.instrument("my_gem.long_process", user_id: 1) do
      #     # ... some long process ...
      #   end
      def instrument(event_id, payload = {}, &block)
        notifications.instrument(event_id, payload, &block)
      end

      # A convenience method to publish an event.
      #
      # @param event_id [String, Symbol] The event ID.
      # @param payload [Hash] The payload for the event.
      #
      # Example:
      #   CodingAgentTools::Notifications.publish("my_gem.user_created", user_id: 123)
      def publish(event_id, payload = {})
        notifications.publish(event_id, payload)
      end
    end
  end
end
