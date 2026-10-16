# frozen_string_literal: true

require "time"

module Ace
  module Hitl
    module Hermes
      module Transport
        # The sole supervised polling actor owns both getUpdates offset and
        # proof that a batch's ingress has been handled before confirmation.
        class Poller
          def initialize(relay:, telegram:, journal:, registry:, clock: -> { Time.now.utc })
            @relay, @telegram, @journal, @registry, @clock = relay, telegram, journal, registry, clock
          end

          def once
            cursor = nil
            @journal.synchronize do |state, _commit|
              cursor = state["cursor"] || {"offset" => 0, "through" => stamp, "generation" => 0, "coverage_from" => stamp}
            end
            # Ordinary bodies already retained before offset confirmation retry
            # independently. Secret failures remain status-only and require a
            # fresh challenge; incomplete receipts replay at the old offset.
            started = stamp
            if Time.iso8601(started) - Time.iso8601(cursor["through"]) >= 24 * 60 * 60
              invalidate_coverage(started)
              cursor["coverage_from"] = started
              cursor["generation"] += 1
              @journal.synchronize do |state, commit|
                state["cursor"] = cursor
                commit.call
              end
            end
            @relay.drain
            updates = @telegram.updates(offset: cursor["offset"])
            ids = updates.map { |u| u.is_a?(Hash) && u["update_id"] }
            unless ids.all? { |id| id.is_a?(Integer) && id >= cursor["offset"] } && ids == ids.sort && ids.uniq == ids
              raise ContractError, "malformed Telegram update sequence"
            end
            unregistered = []
            updates.each do |update|
              message = update["message"]
              next unless message.is_a?(Hash)
              chat = message["chat"]
              next unless chat.is_a?(Hash)
              unless @registry.channels.any? { |c| c["chat_id"] == chat["id"].to_s }
                if %w[group supergroup].include?(chat["type"]) && chat["id"].to_s.match?(/\A-\d{4,32}\z/)
                  unregistered << {"chat_id" => chat["id"].to_s, "update_id" => update.fetch("update_id")}
                end
                next
              end
              from = message["from"]
              next unless from.is_a?(Hash)
              event = {"platform" => "telegram", "chat_id" => chat["id"].to_s,
                       "chat_type" => chat["type"], "user_id" => from["id"].to_s,
                       "message_id" => message["message_id"].to_s,
                       "reply_to_message_id" => message.dig("reply_to_message", "message_id").to_s,
                       "text" => message["text"]}
              begin
                @relay.receive(event)
              rescue ContractError
                # Authority and malformed correlation are rejected, never
                # forwarded into an agent pipeline or preview log.
              end
            end
            finished = stamp
            @journal.record_unregistered(updates: unregistered, observed_at: finished)
            continuous = Time.iso8601(started) - Time.iso8601(cursor["through"]) < 24 * 60 * 60
            # The getUpdates backlog is exhausted only on an empty response.
            # A nonempty batch may have more replies queued on Telegram.
            if updates.empty?
              @registry.channels.each do |channel|
                @relay.poll_complete(channel: channel["name"], started_at: cursor["coverage_from"],
                  through: started, continuous: continuous)
              end
            end
            @journal.synchronize do |state, commit|
              state["cursor"] = {"offset" => ids.empty? ? cursor["offset"] : ids.last + 1,
                                  "through" => finished, "generation" => cursor["generation"], "coverage_from" => cursor["coverage_from"]}
              commit.call
            end
            updates.size
          rescue StandardError
            at = stamp
            invalidate_coverage(at)
            @journal.synchronize do |state, commit|
              previous = state["cursor"] || cursor || {"offset" => 0, "generation" => 0}
              state["cursor"] = previous.merge("through" => at, "coverage_from" => at,
                "generation" => previous.fetch("generation", 0) + 1)
              commit.call
            end
            raise ContractError, "Telegram poll unavailable; ingress coverage is unknown"
          end

          private

          def invalidate_coverage(at)
            @registry.channels.each do |channel|
              @relay.poll_complete(channel: channel["name"], started_at: at, through: at, continuous: false)
            end
          end

          def stamp
            @clock.call.utc.iso8601
          end
        end
      end
    end
  end
end
