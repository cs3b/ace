# frozen_string_literal: true

require_relative "errors"

module Ace
  module Hitl
    module Lifecycle
      # The standing-duty projection (spec 8wm.t.y21 §7; contract of the
      # deployed hitl_status/duty surface): pending answerable requests
      # with their effect declaration visibility, plus everything the
      # effect layer has escalated. Root-only, like the store reads it
      # projects from.
      module Duty
        module_function

        def project(store)
          store.require_root!("duty")
          {
            "pending" => store.pending.map { |value| pending_entry(value) },
            "escalated" => store.states.select do |record|
              record["effect_state"] == Effects::OUTCOME_ESCALATED
            end
          }
        end

        def pending_entry(value)
          {
            "id" => value["id"],
            "work" => value["work"],
            "attempt" => value["attempt"],
            "project" => value["project"],
            "harness" => value["harness"],
            "kind" => value["kind"],
            "state" => "created",
            "requester" => value["requester"],
            "created_at" => value["created_at"],
            "has_effect" => value["effect"].is_a?(Hash) && Array(value["effect"]["argv"]).any?
          }
        end
      end
    end
  end
end
