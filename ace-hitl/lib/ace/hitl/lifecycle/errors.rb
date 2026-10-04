# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # Error model for the generic HITL request lifecycle
      # (spec 8wm.t.y21 §9; ports of the migrated transport CLI error surfaces).
      class Error < StandardError; end

      # The Work/Attempt binding policy rejected the operation, or the
      # binding authority is unreachable. Never a silent pass.
      class BindingError < Error; end

      # The bound attempt has verifiably ENDED (terminal, replaced, or
      # reassigned): the request is cancelled. Distinct from an
      # unreachable authority, which stays retryable (review 8x333squ).
      class EndedAttemptError < BindingError; end

      # The operation requires an identity the caller does not have
      # (transport-only boundary operations, foreign-requester answers).
      class PermissionError < Error; end

      # The request record is unknown, already transitioned, or the
      # requested lifecycle transition does not hold.
      class StateError < Error; end

      # The answer violates its kind's shape or carries secret-shaped
      # content.
      class AnswerError < Error; end

      # The authenticated transport to the scoped store boundary failed
      # (unavailable, untrusted endpoint, deadline, malformed frame).
      # Visible and recoverable: it never silently changes lifecycle
      # state (spec 8wq.t.34i).
      class TransportError < Error; end
    end
  end
end
