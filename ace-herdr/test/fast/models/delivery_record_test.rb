# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Models
      class DeliveryRecordTest < Minitest::Test
        def build(state: "pending", attempts: 0, history: [])
          DeliveryRecord.new(
            event_id: "evt-1", session: "ws-1", pane: "p5",
            answer_digest: "d" * 64, state: state, attempts: attempts,
            history: history
          )
        end

        def test_defaults_to_pending_and_frozen
          record = build

          assert_equal "pending", record.state
          assert record.frozen?
          assert record.history.frozen?
        end

        def test_serialization_roundtrip
          record = build(state: "retryable", attempts: 2, history: [{"at" => "t1"}])
          restored = DeliveryRecord.from_h(JSON.parse(JSON.generate(record.to_h)))

          assert_equal record.to_h, restored.to_h
        end

        def test_record_attempt_returns_new_immutable_record
          first = build(attempts: 1, history: [{"at" => "t0"}])
          second = first.record_attempt(
            state: "delivered", detail: {"action" => "prompt", "outcome" => "ok"},
            timestamp: "2026-09-27T12:00:00Z"
          )

          assert_equal "delivered", second.state
          assert_equal 2, second.attempts
          assert_equal 2, second.history.length
          assert_equal "2026-09-27T12:00:00Z", second.updated_at
          assert_equal 1, first.attempts # original untouched
        end

        def test_first_attempt_sets_created_at
          second = build.record_attempt(state: "pending", detail: {}, timestamp: "t1")

          assert_equal "t1", second.created_at
        end

        def test_rejects_unknown_state
          assert_raises(ArgumentError) { build(state: "bogus") }
        end

        def test_state_predicates
          assert build(state: "delivered").delivered?
          refute build.delivered?
        end
      end
    end
  end
end
