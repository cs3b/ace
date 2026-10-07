# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Pure state machine for assignment attempt lifecycles.
      #
      # Legal transitions:
      # - reserved -> running
      # - running  -> succeeded | failed | stopped | uncertain
      # - uncertain -> succeeded | failed (only via reconciliation)
      #
      # Terminal states are succeeded, failed, and stopped. Terminal attempts
      # never accept new transitions, effects, or receipts; accepted history is
      # immutable. A stop is never success, and an uncertain attempt must be
      # resolved through explicit reconciliation, never automatic replay.
      module AttemptStateMachine
        STATES = %w[reserved running succeeded failed stopped uncertain].freeze
        TERMINAL_STATES = %w[succeeded failed stopped].freeze
        RESOLVED_STATES = %w[succeeded failed].freeze

        TRANSITIONS = {
          "reserved" => %w[running].freeze,
          "running" => %w[succeeded failed stopped uncertain].freeze,
          "uncertain" => RESOLVED_STATES.freeze
        }.freeze

        # @return [Array<String>] All known attempt states
        def self.states
          STATES
        end

        # @param state [String] State to inspect
        # @return [Boolean] True if the state is terminal (no further transitions)
        def self.terminal?(state)
          TERMINAL_STATES.include?(state.to_s)
        end

        # @param state [String] State to inspect
        # @return [Boolean] True if the state awaits reconciliation
        def self.uncertain?(state)
          state.to_s == "uncertain"
        end

        # Check whether a transition is legal without raising.
        #
        # @param from [String] Current state
        # @param to [String] Requested next state
        # @return [Boolean] True if the transition is legal
        def self.can_transition?(from, to)
          TRANSITIONS.fetch(from.to_s, []).include?(to.to_s)
        end

        # Return the legal next states for a state.
        #
        # @param from [String] Current state
        # @return [Array<String>] Legal next states (empty for unknown/terminal)
        def self.next_states(from)
          TRANSITIONS.fetch(from.to_s, [])
        end

        # Source-owned cessation, invoked only after original no-writers and
        # exhaustive independent settlement proof. This does not broaden the
        # ordinary uncertain receipt-reconciliation transition table.
        def self.proof_stopped_transition!(state)
          return "stopped" if %w[running uncertain].include?(state.to_s)
          raise AttemptErrors::InvalidTransition, "Proof-linked stop requires an active bound attempt"
        end

        # Validate a transition.
        #
        # @param from [String] Current state
        # @param to [String] Requested next state
        # @raise [Ace::Assign::AttemptErrors::InvalidTransition] if illegal
        def self.transition!(from, to)
          return to.to_s if can_transition?(from, to)

          raise Ace::Assign::AttemptErrors::InvalidTransition,
            "Illegal attempt transition #{from} -> #{to} (legal from #{from}: #{next_states(from).join(', ')})"
        end
      end
    end
  end
end
