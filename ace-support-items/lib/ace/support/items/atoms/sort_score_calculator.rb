# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Pure function computing sort scores for smart auto-sort.
        # Score formula: priority_weight × 100 + age_days (capped)
        # with status-based modifiers for in-progress boost and blocked penalty.
        module SortScoreCalculator
          DEFAULT_PRIORITY_WEIGHTS = {
            "critical" => 4,
            "high" => 3,
            "medium" => 2,
            "low" => 1
          }.freeze

          # Compute a sort score for an item.
          # @param priority_weight [Numeric] Weight for the item's priority level
          # @param age_days [Numeric] Days since creation
          # @param status [String, nil] Item status for boost/penalty
          # @param in_progress_boost [Numeric] Added to score for in-progress items
          # @param blocked_factor [Numeric] Score multiplied by this for blocked items
          # @param age_cap [Numeric] Maximum age_days value used in calculation
          # @return [Float] Computed sort score
          def self.compute(priority_weight:, age_days:, status: nil,
            in_progress_boost: 1000, blocked_factor: 0.1, age_cap: 90)
            capped_age = [age_days.to_f, age_cap.to_f].min
            score = priority_weight.to_f * 100 + capped_age

            case status
            when "in-progress"
              score + in_progress_boost
            when "blocked"
              score * blocked_factor
            else
              score
            end
          end

          # Look up the priority weight for a named priority.
          # @param priority [String, nil] Priority name (critical, high, medium, low)
          # @param weights [Hash] Custom weight mapping
          # @return [Numeric] Weight value (defaults to 0 for unknown priorities)
          def self.priority_weight(priority, weights: DEFAULT_PRIORITY_WEIGHTS)
            return 0 unless priority

            weights[priority.to_s.downcase] || 0
          end
        end
      end
    end
  end
end
