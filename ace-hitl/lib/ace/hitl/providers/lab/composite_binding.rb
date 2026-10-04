# frozen_string_literal: true

require_relative "../../lifecycle/binding"

module Ace
  module Hitl
    module Providers
      class Lab
        # Routes each request to its binding authority by binding kind
        # (spec 8wq.t.34i): managed requests verify through the
        # assignment exclusion; the legacy Work path keeps the labd
        # daemon binding until vs2 switches consumers. Misuse is a
        # classified BindingError, never a silent pass.
        class CompositeBinding < Lifecycle::Binding
          def initialize(assignment:, work:)
            @assignment = assignment
            @work = work
          end

          def validate_request(work: nil, assignment: nil, attempt:, project:, requester:)
            if assignment
              @assignment.validate_request(assignment: assignment, attempt: attempt,
                project: project, requester: requester)
            else
              @work.validate_request(work: work, attempt: attempt,
                project: project, requester: requester)
            end
          end

          def require_active(work:, attempt:)
            @work.require_active(work: work, attempt: attempt)
          end

          def with_active(work: nil, assignment: nil, attempt:, project: nil, requester: nil)
            if assignment
              @assignment.with_active(assignment: assignment, attempt: attempt,
                project: project, requester: requester) { yield }
            else
              @work.with_active(work: work, attempt: attempt,
                project: project, requester: requester) { yield }
            end
          end
        end
      end
    end
  end
end
