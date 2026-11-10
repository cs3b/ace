# frozen_string_literal: true

require "ace/hitl/molecules/event_observation"

module Ace
  module Overseer
    module Molecules
      # Read-only gateway to the overseer's incoming ace-hitl events
      # (L6.5). ace-hitl owns its files; this molecule only lists events
      # and normalizes them into plain hashes for the interpretation
      # atom. Reports carry status "recorded", questions stay "pending"
      # until answered — both are the overseer's inbox.
      class HitlInbox
        # @param manager [Ace::Hitl::Organisms::HitlManager, nil]
        def initialize(manager: nil, owner: "overseer", scope: nil)
          @manager = manager || Ace::Hitl::Organisms::HitlManager.new
          raise ArgumentError, "configured HITL owner is required" if owner.to_s.strip.empty?
          unless scope.nil? || %w[current all].include?(scope)
            raise ArgumentError, "HITL scope must be current or all"
          end
          @owner, @scope = owner, scope
          @observation = Ace::Hitl::Molecules::EventObservation.new(manager: @manager)
        end

        # @return [Array<Hash>] {"id","type","result","task","assignment",
        #   "title"} sorted oldest-first. Only the keys the interpretation
        #   atom matches on are carried: assignment, then the managing
        #   task's project_task.
        def incoming_events
          events = @observation.incoming_events(owner: @owner, scope: @scope).select do |event|
            event.type == "report" || (event.type == "question" && event.status == "pending")
          end
          events.sort_by { |event| event.created_at || Time.now }.map { |event| normalize(event) }
        end

        private

        def normalize(event)
          {
            "id" => event.id,
            "type" => event.type,
            "result" => event.result,
            "task" => event.metadata["task"],
            "assignment" => event.metadata["assignment"],
            "role" => event.metadata["role"],
            "title" => event.title
          }
        end
      end
    end
  end
end
