# frozen_string_literal: true

require_relative "../adapters"
require_relative "../atoms/hitl_event_text"
require_relative "../molecules/hitl_route_loader"
require_relative "hitl_manager"

module Ace
  module Hitl
    module Organisms
      # Delivers one persisted HITL event through the configured adapter
      # route set. The sender's interface is adapter-independent: routes
      # come from configuration, every route is invoked independently, and
      # per-route failures never prevent or substitute another route's
      # delivery (no silent rerouting). Results are reported, not
      # persisted — retention/redelivery of undelivered messages is
      # 8xg.t.sbz.1.3.
      class HitlSender
        SendReport = Struct.new(:event_id, :results, keyword_init: true) do
          def all_delivered?
            results.all?(&:delivered?)
          end
        end

        def initialize(manager: nil, config: nil, adapters: Adapters)
          @manager = manager || HitlManager.new(config: config)
          @config = config || @manager.instance_variable_get(:@config)
          @adapters = adapters
        end

        # @param ref [String] event reference (exact ID or unique shortcut)
        # @return [SendReport]
        # @raise [Molecules::HitlRouteLoader::NoRoutesError,
        #   Molecules::HitlRouteLoader::InvalidRouteError,
        #   Adapters::UnknownAdapterError] before any delivery attempt
        def send(ref, scope: nil)
          routes = Molecules::HitlRouteLoader.load(@config)

          current = @manager.show(ref, scope: scope)
          raise Adapters::Error, "HITL event '#{ref}' not found" unless current

          event = current[:event]
          text = Atoms::HitlEventText.call(event)

          results = routes.map do |route|
            deliver_route(route, event: event, text: text)
          end

          SendReport.new(event_id: event.id, results: results)
        end

        private

        # One route's failure is contained to its own result; the remaining
        # routes still run and nothing is ever sent to a different
        # destination than the route's own configuration.
        def deliver_route(route, event:, text:)
          adapter_name = route["adapter"]
          route = route.merge("machine" => @config.dig("hitl", "machine").to_s) do |_key, route_val, config_val|
            route_val.to_s.strip.empty? ? config_val : route_val
          end
          adapter = @adapters.resolve(adapter_name, route: route)
          adapter.deliver(event: event, text: text,
            recipient: event.recipient, reply_to: event.reply_to)
        rescue Adapters::UnknownAdapterError
          raise
        rescue StandardError => e
          Adapters::RouteResult.new(
            route: route["route"], adapter: adapter_name,
            status: :failed, detail: "#{e.class}: #{e.message}"
          )
        end
      end
    end
  end
end
