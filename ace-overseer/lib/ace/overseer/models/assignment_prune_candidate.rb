# frozen_string_literal: true

module Ace
  module Overseer
    module Models
      class AssignmentPruneCandidate
        attr_reader :assignment_id, :assignment_name, :assignment_state, :location_path,
          :attempts_terminal, :reasons

        def initialize(assignment_id:, assignment_name:, assignment_state:, location_path:,
          attempts_terminal: true, reasons: [])
          @assignment_id = assignment_id.to_s.freeze
          @assignment_name = assignment_name.to_s.freeze
          @assignment_state = assignment_state.to_s.freeze
          @location_path = location_path.to_s.freeze
          @attempts_terminal = attempts_terminal
          @reasons = reasons.map(&:to_s).freeze
        end

        def safe_to_prune?
          assignment_state == "completed" && attempts_terminal
        end

        def to_h
          {
            assignment_id: assignment_id,
            assignment_name: assignment_name,
            assignment_state: assignment_state,
            location_path: location_path,
            attempts_terminal: attempts_terminal,
            reasons: reasons,
            safe_to_prune: safe_to_prune?
          }
        end
      end
    end
  end
end
