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
            # A durable queued record means a prior actor died with its body
            # transient. Replay from the unadvanced offset; secret failures
            # remain status-only and require a fresh challenge.
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
            updates = @telegram.updates(offset: cursor["offset"])
            ids = updates.map { |u| u.is_a?(Hash) && u["update_id"] }
            unless ids.all? { |id| id.is_a?(Integer) && id >= cursor["offset"] } && ids == ids.sort && ids.uniq == ids
              raise ContractError, "malformed Telegram update sequence"
            end
            unresolved = false
            updates.each do |update|
              message = update["message"]
              next unless message.is_a?(Hash)
              chat, from = message["chat"], message["from"]
              next unless chat.is_a?(Hash) && from.is_a?(Hash)
              next unless @registry.channels.any? { |c| c["chat_id"] == chat["id"].to_s }
              event = {"platform" => "telegram", "chat_id" => chat["id"].to_s,
                       "chat_type" => chat["type"], "user_id" => from["id"].to_s,
                       "message_id" => message["message_id"].to_s,
                       "reply_to_message_id" => message.dig("reply_to_message", "message_id").to_s,
                       "text" => message["text"]}
              begin
                result = @relay.receive(event)
                unresolved ||= %w[queued unresolved].include?(result["status"])
              rescue ContractError
                # Authority and malformed correlation are rejected, never
                # forwarded into an agent pipeline or preview log.
              end
            end
            finished = stamp
            continuous = Time.iso8601(started) - Time.iso8601(cursor["through"]) < 24 * 60 * 60
            # The getUpdates backlog is exhausted only on an empty response.
            # A nonempty batch may have more replies queued on Telegram.
            if updates.empty?
              @registry.channels.each do |channel|
                @relay.poll_complete(channel: channel["name"], started_at: cursor["coverage_from"],
                  through: started, continuous: continuous)
              end
            end
            return updates.size if unresolved # retain Telegram replay until ordinary handling recovers
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
