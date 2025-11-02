# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for validating status transitions
      # Unit testable - no filesystem access
      # Supports both strict (rigid) and flexible (forgiving) transition modes
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
        # @param flexible [Boolean] If true, allow any transition (default: true)
        # @return [Boolean] True if transition is valid
        def self.valid_transition?(from, to, flexible: true)
          # In flexible mode, all transitions are valid (except same status)
          return true if flexible

          # In strict mode, use the transition matrix
          allowed = TRANSITIONS[from] || []
          allowed.include?(to)
        end

        # Check if this is an idempotent operation (no-op)
        # @param from [String] Current status
        # @param to [String] Target status
        # @return [Boolean] True if statuses are the same
        def self.idempotent_operation?(from, to)
          from == to
        end

        # Get all valid transitions for a status
        # @param from [String] Current status
        # @param flexible [Boolean] If true, return all known statuses except current
        # @return [Array<String>] List of valid target statuses
        def self.allowed_transitions(from, flexible: true)
          if flexible
            # In flexible mode, can transition to any status except same
            all_statuses.reject { |s| s == from }
          else
            # In strict mode, use transition matrix
            TRANSITIONS[from] || []
          end
        end

        # Get all valid statuses
        # @return [Array<String>] List of all statuses
        def self.all_statuses
          TRANSITIONS.keys + TRANSITIONS.values.flatten.uniq
        end

        # Check if a status is valid (known or custom)
        # @param status [String] Status to check
        # @param flexible [Boolean] If true, any non-empty string is valid
        # @return [Boolean] True if status is valid
        def self.valid_status?(status, flexible: true)
          return false if status.nil? || status.strip.empty?

          if flexible
            # In flexible mode, any non-empty string is a valid status
            true
          else
            # In strict mode, must be in the known status list
            all_statuses.include?(status)
          end
        end
      end
    end
  end
end
