# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Molecules
      class HitlDeliveryStateTest < AceHitlTestCase
        def record(status)
          {"status" => status, "adapter" => "terminal", "detail" => nil, "attempted_at" => "2026-10-18T12:00:00Z"}
        end

        def test_retry_decision_table
          assert HitlDeliveryState.retry?(nil), "no record means undelivered"
          assert HitlDeliveryState.retry?(record("failed"))
          assert HitlDeliveryState.retry?(record("unavailable"))
          assert HitlDeliveryState.retry?(record("in_flight")), "stale in_flight is unknown - retried"
          refute HitlDeliveryState.retry?(record("delivered")), "confirmed delivered is skipped"
          assert HitlDeliveryState.retry?("garbage"), "malformed record counts as undelivered"
        end

        def test_unknown_predicate
          assert HitlDeliveryState.unknown?(record("in_flight"))
          refute HitlDeliveryState.unknown?(record("failed"))
          refute HitlDeliveryState.unknown?(nil)
        end

        def test_undelivered_and_fully_delivered_on_absent_map
          refute HitlDeliveryState.undelivered?(nil)
          refute HitlDeliveryState.fully_delivered?(nil)
        end

        def test_partial_map_is_undelivered
          map = {"r1" => record("delivered"), "r2" => record("failed")}
          assert HitlDeliveryState.undelivered?(map)
          refute HitlDeliveryState.fully_delivered?(map)
        end

        def test_all_delivered_map
          map = {"r1" => record("delivered"), "r2" => record("delivered")}
          assert HitlDeliveryState.fully_delivered?(map)
          refute HitlDeliveryState.undelivered?(map)
        end
      end
    end
  end
end
