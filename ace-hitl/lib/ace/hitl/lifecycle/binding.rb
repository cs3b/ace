# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # The binding seam between the generic request lifecycle and the
      # domain that owns Work/Attempt liveness and attribution (spec
      # 8wm.t.y21 §1). The store REQUIRES a binding; the generic core
      # never carries Work/Attempt semantics itself.
      #
      # Implementations must fail closed: any doubt raises BindingError.
      class Binding
        # Validate a request creation against the requester's exact live
        # attempt. Raises BindingError on any violation or unavailability.
        def validate_request(work: nil, assignment: nil, attempt:, project:, requester:)
          raise NotImplementedError
        end

        # Re-verify that the attempt is still live before an answer is
        # delivered or consumed. Raises BindingError when terminal.
        def require_active(work:, attempt:)
          raise NotImplementedError
        end

        # Hold verified live authority across ONE whole transition: the
        # check and the caller's locked commit happen inside the same
        # exclusion, so a concurrent attempt termination cannot land
        # between them (spec 8wq.t.34i). The yielded value is opaque.
        # Implementations without a holdable exclusion verify and yield
        # (the legacy gap); the assignment authority holds its lock.
        def with_active(work: nil, assignment: nil, attempt:, project: nil, requester: nil)
          require_active(work: work, attempt: attempt)
          yield
        end
      end
    end
  end
end
