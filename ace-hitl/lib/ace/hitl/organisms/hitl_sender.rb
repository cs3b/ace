# frozen_string_literal: true

require "ace/support/items"
require_relative "../adapters"
require_relative "../atoms/hitl_event_text"
require_relative "../molecules/hitl_route_loader"
require_relative "../molecules/hitl_delivery_state"
require_relative "hitl_manager"

module Ace
  module Hitl
    module Organisms
      # Delivers one persisted HITL event through the configured adapter
      # route set. The sender's interface is adapter-independent: routes
      # come from configuration, every route is invoked independently, and
      # per-route failures never prevent or substitute another route's
      # delivery (no silent rerouting).
      #
      # Retention (8xg.t.sbz.1.3): each route's last outcome, failure
      # reason, and attempt timestamp are persisted on the event file
      # itself (`delivery.<route>` frontmatter) — the single state owner.
      # Default redelivery retries only undelivered/unknown routes;
      # `force:` redelivers every route with the SAME case ID and content
      # (at-least-once: recipients dedup by case ID). Redelivery retries
      # the delivery, never the assignment.
      class HitlSender
        SendReport = Struct.new(:event_id, :results, :skipped, keyword_init: true) do
          def all_delivered?
            results.all?(&:delivered?) && skipped.all?(&:delivered?)
          end
        end

        SkippedRoute = Struct.new(:route, :adapter, :status, :detail, keyword_init: true) do
          def delivered?
            status == :delivered
          end
        end

        def initialize(manager: nil, config: nil, adapters: Adapters, now_proc: nil)
          @manager = manager || HitlManager.new(config: config)
          @config = config || @manager.config
          @adapters = adapters
          @now_proc = now_proc || -> { Time.now.utc }
        end

        # @param ref [String] event reference (exact ID or unique shortcut)
        # @param force [Boolean] redeliver every configured route
        # @param dry_run [Boolean] report decisions only; no delivery, no write
        # @return [SendReport]
        # @raise [Molecules::HitlRouteLoader::NoRoutesError,
        #   Molecules::HitlRouteLoader::InvalidRouteError,
        #   Adapters::UnknownAdapterError] before any delivery attempt
        def send(ref, scope: nil, force: false, dry_run: false)
          routes = Molecules::HitlRouteLoader.load(@config)

          current = @manager.show(ref, scope: scope)
          raise Adapters::Error, "HITL event '#{ref}' not found" unless current

          event = current[:event]
          text = Atoms::HitlEventText.call(event)
          delivery = event.metadata["delivery"]

          attempted, skipped = partition_routes(routes, delivery, force)

          if dry_run
            results = attempted.map do |route|
              reason = Molecules::HitlDeliveryState.unknown?(delivery&.dig(route["route"])) ?
                "unknown result - will retry" : "undelivered - will retry"
              Adapters::RouteResult.new(route: route["route"], adapter: route["adapter"],
                status: :dry_run, detail: reason)
            end
            return SendReport.new(event_id: event.id, results: results, skipped: skipped)
          end

          results = attempted.map do |route|
            persist_delivery(event, route, "in_flight", nil)
            deliver_route(route, event: event, text: text).tap do |result|
              persist_delivery(event, route, result.status.to_s, result.detail)
            end
          end

          SendReport.new(event_id: event.id, results: results, skipped: skipped)
        end

        private

        def partition_routes(routes, delivery, force)
          attempted = []
          skipped = []
          routes.each do |route|
            record = delivery.is_a?(Hash) ? delivery[route["route"]] : nil
            if !force && record.is_a?(Hash) && record["status"] == "delivered"
              skipped << SkippedRoute.new(route: route["route"], adapter: route["adapter"],
                status: :delivered, detail: "already delivered (#{record["attempted_at"]})")
            else
              attempted << route
            end
          end
          [attempted, skipped]
        end

        # Nested dot-keys through FieldUpdater: exclusive-flock atomic
        # rewrite of the event's own file (single state owner).
        def persist_delivery(event, route, status, detail)
          Ace::Support::Items::Molecules::FieldUpdater.update(event.file_path,
            set: {
              "delivery.#{route["route"]}.status" => status,
              "delivery.#{route["route"]}.adapter" => route["adapter"],
              "delivery.#{route["route"]}.detail" => detail,
              "delivery.#{route["route"]}.attempted_at" => @now_proc.call.iso8601
            })
        end

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
