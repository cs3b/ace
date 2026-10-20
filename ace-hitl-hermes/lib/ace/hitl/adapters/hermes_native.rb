# frozen_string_literal: true

require "ace/hitl/adapters"
require "ace/hitl/hermes/molecules/native_folder"

module Ace
  module Hitl
    module Hermes
      module Organisms
        class NativeHitlAdapter
          def initialize(route)
            @route = route
            @folder = Molecules::NativeFolder.new(route)
          end

          def deliver(event:, text:, recipient:, reply_to:)
            unless recipient && recipient["machine"] == @folder.machine && recipient["panel"] == @folder.channel
              raise ContractError, "native Hermes recipient differs from the configured channel"
            end
            record = @folder.publish(event, text)
            receipt = @folder.read("delivery", record.fetch("key"))
            confirmed = receipt && receipt["state"] == "delivered" &&
              receipt["message_ids"].is_a?(Array) && !receipt["message_ids"].empty? &&
              receipt["message_ids"].all? { |id| id.is_a?(String) && !id.empty? }
            Adapters::RouteResult.new(route: @route.fetch("route"), adapter: "hermes_native",
              status: confirmed ? :delivered : :unavailable,
              detail: "native transport #{record.fetch('key')}: #{receipt&.fetch('state', nil) || 'queued'}")
          rescue ContractError, SystemCallError, TypeError => e
            Adapters::RouteResult.new(route: @route.fetch("route"), adapter: "hermes_native",
              status: :failed, detail: e.message)
          end
        end
      end
    end
  end
end

Ace::Hitl::Adapters.register(:hermes_native, ->(route) { Ace::Hitl::Hermes::Organisms::NativeHitlAdapter.new(route) })
