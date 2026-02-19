# frozen_string_literal: true

module Ace
  module Overseer
    module Models
      class AssignmentPruneCandidate
        attr_reader :assignment_id, :assignment_name, :assignment_state, :location_path, :reasons

        def initialize(assignment_id:, assignment_name:, assignment_state:, location_path:, reasons: [])
          @assignment_id = assignment_id.to_s.freeze
          @assignment_name = assignment_name.to_s.freeze
          @assignment_state = assignment_state.to_s.freeze
          @location_path = location_path.to_s.freeze
          @reasons = reasons.map(&:to_s).freeze
        end

        def safe_to_prune?
          assignment_state == "completed"
        end

        def to_h
          {
            assignment_id: assignment_id,
            assignment_name: assignment_name,
            assignment_state: assignment_state,
            location_path: location_path,
            reasons: reasons,
            safe_to_prune: safe_to_prune?
          }
        end
      end
    end
  end
end
