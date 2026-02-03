# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Validates state transitions for feedback items.
      #
      # Implements the feedback item state machine:
      #   draft -> (verify valid=true) -> pending -> (resolve) -> done [archived]
      #   draft -> (verify valid=false) -> invalid [archived]
      #   draft -> (skip) -> skip [archived]
      #   pending -> (skip) -> skip [archived]
      #
      # Terminal states (invalid, skip, done) cannot transition further.
      #
      # @example Check if a transition is valid
      #   FeedbackStateValidator.valid_transition?("draft", "pending")
      #   #=> true
      #
      #   FeedbackStateValidator.valid_transition?("done", "pending")
      #   #=> false
      #
      # @example Get allowed transitions from a status
      #   FeedbackStateValidator.allowed_transitions("draft")
      #   #=> ["pending", "invalid", "skip"]
      #
      class FeedbackStateValidator
        # Define the state machine transitions
        # Maps from_status => [allowed target statuses]
        TRANSITIONS = {
          "draft" => %w[pending invalid skip],
          "pending" => %w[done skip],
          "invalid" => [],  # Terminal state
          "skip" => [],     # Terminal state
          "done" => []      # Terminal state
        }.freeze

        # Terminal states that require archiving
        TERMINAL_STATES = %w[invalid skip done].freeze

        # Check if a state transition is valid
        #
        # @param from_status [String] Current status
        # @param to_status [String] Target status
        # @return [Boolean] True if the transition is allowed
        #
        # @example Valid transition
        #   FeedbackStateValidator.valid_transition?("draft", "pending")
        #   #=> true
        #
        # @example Invalid transition
        #   FeedbackStateValidator.valid_transition?("draft", "done")
        #   #=> false
        def self.valid_transition?(from_status, to_status)
          allowed = TRANSITIONS[from_status]
          return false if allowed.nil?

          allowed.include?(to_status)
        end

        # Get the list of allowed target statuses from a given status
        #
        # @param status [String] Current status
        # @return [Array<String>] List of valid target statuses (empty for terminal states)
        #
        # @example
        #   FeedbackStateValidator.allowed_transitions("draft")
        #   #=> ["pending", "invalid", "skip"]
        def self.allowed_transitions(status)
          TRANSITIONS.fetch(status, []).dup
        end

        # Check if a status is terminal (requires archiving, no further transitions)
        #
        # @param status [String] Status to check
        # @return [Boolean] True if status is terminal
        #
        # @example
        #   FeedbackStateValidator.terminal?("done")
        #   #=> true
        #
        #   FeedbackStateValidator.terminal?("pending")
        #   #=> false
        def self.terminal?(status)
          TERMINAL_STATES.include?(status)
        end

        # Check if a status requires archiving
        #
        # @param status [String] Status to check
        # @return [Boolean] True if items with this status should be archived
        def self.should_archive?(status)
          terminal?(status)
        end
      end
    end
  end
end
