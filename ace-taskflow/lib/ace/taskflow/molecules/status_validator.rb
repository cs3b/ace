# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for validating status transitions
      # Unit testable - no filesystem access
      class StatusValidator
        TRANSITIONS = {
          "draft" => ["pending", "blocked"],
          "pending" => ["in-progress", "blocked"],
          "in-progress" => ["done", "pending", "blocked"],
          "blocked" => ["pending", "in-progress"],
          "done" => ["pending"] # Allow reopening
        }.freeze

        # Check if a status transition is valid
        # @param from [String] Current status
        # @param to [String] Target status
        # @return [Boolean] True if transition is valid
        def self.valid_transition?(from, to)
          allowed = TRANSITIONS[from] || []
          allowed.include?(to)
        end

        # Get all valid transitions for a status
        # @param from [String] Current status
        # @return [Array<String>] List of valid target statuses
        def self.allowed_transitions(from)
          TRANSITIONS[from] || []
        end

        # Get all valid statuses
        # @return [Array<String>] List of all statuses
        def self.all_statuses
          TRANSITIONS.keys + TRANSITIONS.values.flatten.uniq
        end
      end
    end
  end
end
