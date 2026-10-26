# frozen_string_literal: true

require "ace/hitl/adapters"
require "ace/hitl/hermes/errors"
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
            state = confirmed ? "delivered" : receipt&.fetch("state", nil) || "queued"
            Adapters::RouteResult.new(route: @route.fetch("route"), adapter: "hermes_native",
              status: confirmed ? :delivered : :unavailable,
              detail: receipt_detail(record, state))
          rescue ContractError, SystemCallError, TypeError => e
            Adapters::RouteResult.new(route: @route.fetch("route"), adapter: "hermes_native",
              status: :failed, detail: e.message)
          end

          private

          # The receipt carries the guard warnings with their reasons: the
          # frame went through, and the delivery frontmatter shows why the
          # transport flagged it.
          def receipt_detail(record, state)
            detail = "native transport #{record.fetch('key')}: #{state}"
            warnings = @folder.warnings
            warnings.empty? ? detail : "#{detail} (warnings: #{warnings.join("; ")})"
          end
        end
      end
    end
  end
end

Ace::Hitl::Adapters.register(:hermes_native, ->(route) { Ace::Hitl::Hermes::Organisms::NativeHitlAdapter.new(route) })
