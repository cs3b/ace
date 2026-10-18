# frozen_string_literal: true

require "json"
require "ace/hitl/adapters"
require "ace/hitl/hermes/errors"
require "ace/hitl/hermes/organisms/hermes_box"
require "ace/hitl/hermes/molecules/hermes_channels"
require "ace/hitl/hermes/molecules/hermes_contract"

module Ace
  module Hitl
    module Hermes
      module Organisms
        # HITL delivery adapter for the hermes folder transport. Translates
        # the shared HITL rendering into an `ace.hitl.hermes.message/v1`
        # outbound question (both HITL questions and reports travel as the
        # outbound kind; the `[HITL report <result>]` body prefix preserves
        # the type and reports never await an answer on any side).
        class HitlAdapter
          def initialize(route)
            @route_name = route["route"].to_s.strip
            @channel_name = route["channel"].to_s.strip
            @machine = route["machine"].to_s.strip
            @folder = route["folder"].to_s.strip
            @sender = route["sender"].to_s.strip

            if @channel_name.empty?
              raise Adapters::Error, "hermes route '#{@route_name}' missing required 'channel'"
            end
            if @machine.empty?
              raise Adapters::Error,
                "hermes route '#{@route_name}' missing 'machine' (route or hitl.machine)"
            end
            if @folder.empty?
              raise Adapters::Error,
                "hermes route '#{@route_name}' missing required 'folder' (absolute channel path)"
            end
            @sender = @machine if @sender.empty?

            registry = Molecules::HermesChannels::Registry.new
            registry.register(@channel_name, machine: @machine, folder: @folder)
            @box = HermesBox.new(channel: @channel_name, registry: registry)
          end

          def deliver(event:, text:, recipient:, reply_to:)
            message = @box.publish(
              kind: :question, id: event.id, sender: @sender,
              timestamp: timestamp, body: text
            )
            Adapters::RouteResult.new(route: @route_name, adapter: "hermes", status: :delivered,
              detail: "published #{message.id} to #{@machine}/#{@channel_name}")
          rescue CollisionError
            if same_pending_message?(event.id, text)
              Adapters::RouteResult.new(route: @route_name, adapter: "hermes", status: :delivered,
                detail: "already pending in channel folder (same question and sender)")
            else
              Adapters::RouteResult.new(route: @route_name, adapter: "hermes", status: :failed,
                detail: "collision on #{event.id} with different content; not resent")
            end
          rescue ContractError, Errno::ENOENT, SystemCallError => e
            Adapters::RouteResult.new(route: @route_name, adapter: "hermes", status: :unavailable,
              detail: "#{e.class.to_s.split("::").last}: #{e.message}")
          end

          private

          def timestamp
            @timestamp ||= Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
          end

          # Idempotency: the pending file for this id carries the same
          # question body and sender (timestamps may differ between
          # attempts; they are not delivery identity).
          def same_pending_message?(id, text)
            path = Molecules::HermesContract.message_path(@box.channel.folder, id)
            existing = JSON.parse(File.read(path))
            existing["question"] == text && existing["sender"] == @sender
          rescue JSON::ParserError, Errno::ENOENT, SystemCallError
            false
          end
        end
      end
    end
  end
end

Ace::Hitl::Adapters.register(:hermes, ->(route) {
  Ace::Hitl::Hermes::Organisms::HitlAdapter.new(route)
})
