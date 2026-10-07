# frozen_string_literal: true
require "ace/support/cli/error"

module Ace
  module Assign
    # Base error class for all ace-assign exceptions.
    # Inherits from Ace::Support::Cli::Error to support exception-based
    # exit code pattern (per ADR-023).
    #
    # Subclasses should call super with appropriate exit_code.
    class Error < Ace::Support::Cli::Error
      def initialize(message, exit_code: 1)
        super
      end
    end

    # Assignment-related errors
    module AssignmentErrors
      class NotFound < Error
        def initialize(message = "Assignment not found")
          super(message, exit_code: 2)
        end
      end

      class NoActive < Error
        def initialize(message = "No active assignment")
          super(message, exit_code: 2)
        end
      end
    end

    # Config-related errors
    module ConfigErrors
      class NotFound < Error
        def initialize(message = "Configuration not found")
          super(message, exit_code: 3)
        end
      end
    end

    # Step-related errors
    module StepErrors
      class NotFound < Error
        def initialize(message = "Step not found")
          super(message, exit_code: 4)
        end
      end

      class InvalidState < Error; end
    end

    # Attempt/evidence-related errors (exit code 5)
    module AttemptErrors
      class InvalidTransition < Error
        def initialize(message = "Illegal attempt state transition")
          super(message, exit_code: 5)
        end
      end

      class InvalidScope < Error
        def initialize(message = "Invalid attempt scope")
          super(message, exit_code: 5)
        end
      end

      # Duplicate start with a conflicting binding for an owned subtree
      class Conflict < Error
        def initialize(message = "Conflicting active attempt for scope")
          super(message, exit_code: 5)
        end
      end

      class NotFound < Error
        def initialize(message = "Attempt not found")
          super(message, exit_code: 5)
        end
      end

      # Untrusted or unknown execution identity; authority fails closed
      class UnauthorizedIdentity < Error
        def initialize(message = "Unknown or unauthorized execution identity")
          super(message, exit_code: 5)
        end
      end

      # Receipt failed verification (binding, head, digest, artifacts, review)
      class ReceiptRejected < Error
        def initialize(message = "Receipt rejected")
          super(message, exit_code: 5)
        end
      end

      # Byte framing failed before any business receipt could be admitted.
      class MalformedTransfer < ReceiptRejected; end

      # Recovery settled a prior effect, but did not perform this request.
      class CurrentEffectRequired < ReceiptRejected
        def initialize(operation:, recovered_operation:)
          super("Recovered #{recovered_operation}; requested #{operation} still needs execution")
        end
      end

      # Attempt state forbids the requested effect (terminal, uncertain, blocked)
      class InvalidState < Error
        def initialize(message = "Attempt state forbids the requested operation")
          super(message, exit_code: 5)
        end
      end

      # Evidence storage is missing or unwritable; external effects are blocked
      class EvidenceUnavailable < Error
        def initialize(message = "Evidence storage unavailable")
          super(message, exit_code: 5)
        end
      end

      # Complete maintenance exclusions are busy or their admission deadline expired.
      class MaintenanceBusy < EvidenceUnavailable
      end

      # One canonical inventory row cannot fit the fixed protocol frame.
      class BoundedResultUnavailable < EvidenceUnavailable
      end

      # Exhaustively authenticated service inventory remains unsettled.
      class ServiceSettlementPending < EvidenceUnavailable
      end

      # Exhaustively authenticated current Inbox claims remain queued.
      class InboxSettlementPending < EvidenceUnavailable
      end

      # Positively admitted original Inbox work remains pending, not corrupt.
      class InboxContextPending < EvidenceUnavailable
      end
    end

  end
end
