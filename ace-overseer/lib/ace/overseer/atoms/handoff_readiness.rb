# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      # Pure handoff gate for the overseer queue (L6.4): the SAME task
      # worktree may be handed to the next role in the prepared
      # role sequence only when the previous leg's assignment finished
      # successfully (ace-assign state "completed" — the existing state
      # model; no new status semantics) and no executor still holds the
      # worktree (the coworker ActiveExecutorRule verdict). A leg that
      # failed, is still in flight, or has an unreadable/unknown state is
      # never a finished predecessor: unknown state is not a free
      # resource and never permits starting (let alone overwriting) the
      # next executor.
      module HandoffReadiness
        COMPLETED_STATE = "completed"
        # A next leg may START from these states: "paused" is an
        # untouched pending queue (fresh leg), "empty" has no steps yet.
        STARTABLE_STATES = %w[paused empty].freeze

        # @param legs [Array<Hash>] ordered role-sequence legs, each
        #   {"role" => String|nil, "assignment" => String,
        #    "state" => String} (state "" = not present in the
        #    assignment inventory = unknown)
        # @param active_executor [Hash] ActiveExecutorRule verdict
        #   ({active: bool, evidence: {...}|nil})
        # @return [Hash] {status: :ready, next: leg} |
        #   {status: :sequence_complete} |
        #   {status: :refused, reasons: [String]}
        def self.evaluate(legs:, active_executor: {active: false})
          return {status: :refused, reasons: ["no role-sequence assignments for this task in the worktree"]} if legs.empty?

          if active_executor[:active]
            evidence = active_executor[:evidence] || {}
            return {status: :refused, reasons: [
              "an executor still holds the worktree: assignment #{evidence["assignment"]} " \
                "(state #{evidence["state"] || "unknown"}, source #{evidence["source"] || "config"})"
            ]}
          end

          incomplete = legs.reject { |leg| leg["state"] == COMPLETED_STATE }
          return {status: :sequence_complete} if incomplete.empty?

          # next_leg is the FIRST non-completed leg, so every leg before
          # it is completed by construction; the remaining gates are the
          # next leg's own state and start config.
          next_leg = incomplete.first
          reason = next_leg_reason(next_leg)
          return {status: :refused, reasons: [reason]} if reason

          {status: :ready, next: next_leg}
        end

        # Private class-method section (kept inline for atom simplicity).

        def self.next_leg_reason(leg)
          state = leg["state"]
          unless STARTABLE_STATES.include?(state)
            return "next leg #{leg["role"] || "?"} (assignment #{leg["assignment"]}) state " \
              "#{state.empty? ? "unknown" : state} - not startable; investigate or resume, " \
              "never start a second executor"
          end
          return nil if leg["role"]

          "assignment #{leg["assignment"]} has no start config " \
            "(.ace-local/coworker/prepare/<role>.yml); re-run ace-coworker prepare (idempotent)"
        end
        private_class_method :next_leg_reason
      end
    end
  end
end
