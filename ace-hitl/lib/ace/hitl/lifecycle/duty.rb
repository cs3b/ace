# frozen_string_literal: true

require_relative "errors"

module Ace
  module Hitl
    module Lifecycle
      # The standing-duty projection (spec 8wm.t.y21 §7; contract of the
      # deployed hitl_status/duty surface): pending answerable requests
      # with their effect declaration visibility, plus everything the
      # effect layer has escalated. Transport-scoped: the projection is
      # built from data already fetched through the authenticated
      # boundary (spec 8wq.t.34i).
      module Duty
        module_function

        def project(pending:, states:)
          {
            "pending" => pending.map { |value| pending_entry(value) },
            "escalated" => states.select do |record|
              record["effect_state"] == Effects::OUTCOME_ESCALATED
            end
          }
        end

        def pending_entry(value)
          {
            "id" => value["id"],
            "attempt" => value["attempt"],
            "project" => value["project"],
            "harness" => value["harness"],
            "kind" => value["kind"],
            "state" => value["state"],
            "requester" => value["requester"],
            "created_at" => value["created_at"],
            "has_effect" => value["has_effect"] == true
          }
        end
      end
    end
  end
end
