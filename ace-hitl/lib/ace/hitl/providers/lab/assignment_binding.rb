# frozen_string_literal: true

require_relative "../../lifecycle/binding"

module Ace
  module Hitl
    module Providers
      class Lab
        # The managed binding policy (spec 8wq.t.34i): requests bind to
        # the exact ACTIVE MANAGED attempt of the requesting actor,
        # verified by the authoritative ace-assign coordinator under the
        # assignment exclusion. with_active HOLDS that exclusion across
        # the caller's locked transition, so an attempt that ends
        # concurrently cancels the request instead of handing it fresh
        # authority. Every doubt maps to the classified BindingError —
        # unknown identity/authority is an error, never permission.
        class AssignmentBinding < Lifecycle::Binding
          def initialize(coordinator: nil, repo_root: nil)
            @coordinator = coordinator
            @repo_root = repo_root
          end

          def validate_request(work: nil, assignment: nil, attempt:, project:, requester:)
            with_verified(assignment, attempt, project, requester) { nil }
          end

          # The liveness scope: the assignment exclusion is HELD across
          # the yielded transition commit.
          def with_active(work: nil, assignment: nil, attempt:, project: nil, requester: nil)
            with_verified(assignment, attempt, project, requester) { yield }
          end

          private

          def with_verified(assignment_id, attempt_id, project_id, requester)
            coordinator.with_verified_attempt(
              assignment_id: assignment_id,
              attempt_id: attempt_id,
              project_id: project_id,
              requester: requester
            ) do |attempt|
              yield attempt
            end
          rescue StandardError => e
            raise map_error(e)
          end

          def coordinator
            @coordinator ||= Ace::Assign::Organisms::AttemptCoordinator.new(repo_root: @repo_root)
          end

          def map_error(error)
            message = error.message.to_s
            case error.class.name
            when /NotFound/
              Lifecycle::BindingError.new("HITL attempt is unknown: #{message}")
            when /UnauthorizedIdentity/
              Lifecycle::BindingError.new("HITL requester does not own the attempt: #{message}")
            else
              Lifecycle::BindingError.new(message)
            end
          end
        end
      end
    end
  end
end
