# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # The binding seam between the generic request lifecycle and the
      # domain that owns assignment/attempt liveness and attribution (spec
      # 8wm.t.y21 §1). The store REQUIRES a binding; the generic core
      # never carries assignment journal semantics itself.
      #
      # Implementations must fail closed: any doubt raises BindingError.
      class Binding
        # Validate a request creation against the requester's exact live
        # attempt. Raises BindingError on any violation or unavailability.
        def validate_request(assignment:, attempt:, project:, requester:, caller_pid: nil)
          raise NotImplementedError
        end

        def reverse_address(assignment:, attempt:, project:, caller_pid:)
          raise NotImplementedError
        end

        # Re-verify that the attempt is still live before an answer is
        # delivered or consumed. Raises BindingError when terminal.
        # Hold verified live authority across ONE whole transition: the
        # check and the caller's locked commit happen inside the same
        # exclusion, so a concurrent attempt termination cannot land
        # between them (spec 8wq.t.34i). The yielded value is opaque.
        # Implementations must hold the assignment exclusion.
        def with_active(assignment:, attempt:, project:, requester:)
          raise NotImplementedError
        end
      end
    end
  end
end
