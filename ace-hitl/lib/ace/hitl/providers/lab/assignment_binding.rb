# frozen_string_literal: true

require "ace/assign/organisms/attempt_coordinator"
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
          def initialize(coordinator: nil, repo_root: nil, project: nil, owner_guard: nil)
            unless (project.nil? && owner_guard.nil?) ||
                (project.is_a?(String) && !project.empty? && owner_guard.respond_to?(:call))
              raise ArgumentError, "installed binding needs both a fixed project and its owner guard"
            end
            @coordinator = coordinator
            @repo_root = repo_root
            @project, @owner_guard = project, owner_guard
          end

          def validate_request(assignment:, attempt:, project:, requester:, caller_pid: nil)
            with_verified(assignment, attempt, project, requester) do
              reverse_address(assignment: assignment, attempt: attempt, project: project, caller_pid: caller_pid)
            end
          end

          # Read-only owner verification can run inside an already-held
          # assignment exclusion without reacquiring that exclusion.
          def reverse_address(assignment:, attempt:, project:, caller_pid:)
            verify_selection!(project)
            unless caller_pid.is_a?(Integer) && caller_pid.positive?
              raise Lifecycle::BindingError, "kernel requester process identity is unavailable"
            end
            binding = coordinator.runtime_binding(attempt_id: attempt, caller_pid: caller_pid)
            {"schema" => Ref::SCHEMA, "session" => binding.fetch("session"), "pane" => binding.fetch("pane")}
          rescue Ace::Assign::Error => e
            raise Lifecycle::BindingError, "native requester authority is unavailable (#{e.message})"
          end

          # The liveness scope: the assignment exclusion is HELD across
          # the yielded transition commit.
          def with_active(assignment:, attempt:, project: nil, requester: nil)
            with_verified(assignment, attempt, project, requester) { yield }
          end

          def proposal_journal(project:)
            unless project.is_a?(String) && !project.empty?
              raise Lifecycle::BindingError, "proposal requires an explicit project"
            end
            verify_selection!(project)
            coordinator.send(:journal_for)
          end

          def proposal_projects
            if @project
              verify_selection!(@project)
              return [@project]
            end
            coordinator.send(:journal_for).proposals.map { |record| record.fetch("project_id") }.uniq.sort
          end

          private

          def verify_selection!(project)
            return unless @project
            raise Lifecycle::BindingError, "project differs from installed HITL owner" unless project == @project
            @owner_guard.call
          end

          def with_verified(assignment_id, attempt_id, project_id, requester)
            # ONLY the authority verification is error-mapped: the
            # caller's transition (answer hand-off, commits, effects)
            # keeps its own failure classes — mapping it into
            # BindingError would cancel a live request on an unrelated
            # failure (review 8x327bud). The exclusion still spans the
            # whole transition, so the phase flag separates the two.
            verifying = true
            verify_selection!(project_id)
            coordinator.with_verified_attempt(
              assignment_id: assignment_id,
              attempt_id: attempt_id,
              project_id: project_id,
              requester: requester
            ) do |attempt|
              verify_selection!(project_id)
              verifying = false
              yield attempt
            end
          rescue Ace::Assign::Error => e
            raise verifying ? map_error(e) : e
          end

          def coordinator
            @coordinator ||= Ace::Assign::Organisms::AttemptCoordinator.new(repo_root: @repo_root)
          end

          def map_error(error)
            message = error.message.to_s
            case error.class.name
            when /NotFound/
              # An unknown attempt id is a verifiably dead binding.
              Lifecycle::EndedAttemptError.new("HITL attempt is unknown: #{message}")
            when /ReceiptRejected/
              Lifecycle::EndedAttemptError.new(message)
            when /UnauthorizedIdentity/
              # A foreign actor on the record means the attempt moved on.
              Lifecycle::EndedAttemptError.new("HITL requester does not own the attempt: #{message}")
            when /InvalidState/
              Lifecycle::EndedAttemptError.new(message)
            else
              Lifecycle::BindingError.new(message)
            end
          end
        end
      end
    end
  end
end
