# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class AssignmentPruneSafetyChecker
        def initialize(assignment_discoverer_factory: nil, assignment_manager_factory: nil)
          @assignment_discoverer_factory = assignment_discoverer_factory || -> { Ace::Assign::Molecules::AssignmentDiscoverer.new }
          @assignment_manager_factory = assignment_manager_factory || -> { Ace::Assign::Molecules::AssignmentManager.new }
        end

        def check(assignment_id:)
          discoverer = @assignment_discoverer_factory.call
          all = discoverer.find_all(include_completed: true)
          info = all.find { |ai| ai.assignment.id == assignment_id }

          unless info
            return Models::AssignmentPruneCandidate.new(
              assignment_id: assignment_id,
              assignment_name: "",
              assignment_state: "not_found",
              location_path: "",
              reasons: ["assignment not found"]
            )
          end

          state = info.queue_state.assignment_state.to_s
          reasons = []
          reasons << "assignment still #{state}" unless state == "completed"

          Models::AssignmentPruneCandidate.new(
            assignment_id: assignment_id,
            assignment_name: info.assignment.name,
            assignment_state: state,
            location_path: info.assignment.cache_dir,
            reasons: reasons
          )
        end
      end
    end
  end
end
