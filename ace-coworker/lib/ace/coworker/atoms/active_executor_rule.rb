# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure rule deciding whether a worktree holds an active executor.
      #
      # The commissioned assignment rules: the worktree's coworker config
      # names an assignment (a commission was handed) and its state is
      # anything other than completed — including unknown/unparseable, the
      # conservative direction never destroys work. Without a commission
      # record, only in-flight states (running/stalled) block, so up-front
      # pending assignments from the role-sequence leaf never self-conflict.
      module ActiveExecutorRule
        UNPARSEABLE = :unparseable
        IN_FLIGHT_STATES = %w[running stalled].freeze
        private_constant :IN_FLIGHT_STATES

        # @param config [nil, :unparseable, Hash] worktree coworker config
        #   (nil = missing file; :unparseable = present but unreadable)
        # @param assignments [Array<Hash>] worktree assignments with "id"
        #   and "state" keys
        # @return [Hash] {active: bool, evidence: {"assignment","state","source"} | nil}
        def self.evaluate(config:, assignments:)
          if config == UNPARSEABLE
            return active(assignment: nil, state: "unparseable", source: "config")
          end

          if config.is_a?(Hash) && !config["assignment"].to_s.empty?
            return commissioned(config["assignment"].to_s, assignments)
          end

          assignments.each do |record|
            state = record["state"].to_s
            if IN_FLIGHT_STATES.include?(state)
              return active(assignment: record["id"].to_s, state: state, source: "assignment")
            end
          end

          {active: false, evidence: nil}
        end

        # Private class-method section (kept inline for atom simplicity).

        def self.commissioned(assignment_id, assignments)
          record = assignments.find { |a| a["id"].to_s == assignment_id }
          state = record ? record["state"].to_s : "unknown"
          return {active: false, evidence: nil} if state == "completed"

          active(assignment: assignment_id, state: state, source: "config")
        end
        private_class_method :commissioned

        def self.active(assignment:, state:, source:)
          {active: true,
           evidence: {"assignment" => assignment, "state" => state, "source" => source}.freeze}
        end
        private_class_method :active
      end
    end
  end
end
