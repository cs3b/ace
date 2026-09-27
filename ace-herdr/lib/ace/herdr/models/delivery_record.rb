# frozen_string_literal: true

require "json"

module Ace
  module Herdr
    module Models
      # Write-ahead record of one push delivery. Immutable value object:
      # state transitions return new instances; persistence lives in
      # Molecules::DeliveryRecordStore.
      #
      # States: pending (written before first herdr contact), delivered,
      # retryable (exhausted transient attempts; safe to re-push identical
      # content), failed (terminal).
      class DeliveryRecord
        STATES = %w[pending delivered retryable failed].freeze

        attr_reader :event_id, :session, :pane, :answer_digest, :state,
          :attempts, :history, :created_at, :updated_at

        def initialize(event_id:, session:, pane:, answer_digest:, state: "pending",
          attempts: 0, history: [], created_at: nil, updated_at: nil)
          raise ArgumentError, "unknown state: #{state}" unless STATES.include?(state)

          @event_id = event_id
          @session = session
          @pane = pane
          @answer_digest = answer_digest
          @state = state
          @attempts = attempts
          @history = history.dup.freeze
          @created_at = created_at
          @updated_at = updated_at
          freeze
        end

        def self.from_h(hash)
          new(
            event_id: hash["event_id"], session: hash["session"], pane: hash["pane"],
            answer_digest: hash["answer_digest"], state: hash["state"] || "pending",
            attempts: hash["attempts"] || 0, history: hash["history"] || [],
            created_at: hash["created_at"], updated_at: hash["updated_at"]
          )
        end

        def self.from_json(json)
          from_h(JSON.parse(json))
        end

        def to_h
          {
            "event_id" => event_id, "session" => session, "pane" => pane,
            "answer_digest" => answer_digest, "state" => state,
            "attempts" => attempts, "history" => history,
            "created_at" => created_at, "updated_at" => updated_at
          }
        end

        def delivered?
          state == "delivered"
        end

        # Return a copy with a history entry appended (no attempt counted);
        # used for non-prompt events such as bootstrap actions
        def append_event(detail:, timestamp:, state: nil)
          self.class.new(
            event_id: event_id, session: session, pane: pane,
            answer_digest: answer_digest, state: state || self.state,
            attempts: attempts,
            history: history + [detail.merge("at" => timestamp)],
            created_at: created_at || timestamp, updated_at: timestamp
          )
        end

        # Return a copy advanced to the next attempt with a history entry
        # @param state [String] resulting state after the attempt
        # @param detail [Hash] attempt detail (action, outcome, error)
        # @param timestamp [String] RFC 3339 timestamp of the transition
        def record_attempt(state:, detail:, timestamp:)
          appended = append_event(state: state, detail: detail, timestamp: timestamp)
          self.class.new(
            event_id: event_id, session: session, pane: pane,
            answer_digest: answer_digest, state: state,
            attempts: attempts + 1,
            history: appended.history,
            created_at: appended.created_at, updated_at: appended.updated_at
          )
        end
      end
    end
  end
end
