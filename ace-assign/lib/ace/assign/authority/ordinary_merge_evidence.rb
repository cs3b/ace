# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # The installed fixed merge consumes this same lifecycle, never a local
      # receipt file. Locks precede journal CAS; no callback acquires an inverted
      # lifecycle lock while holding the journal writer lock.
      module OrdinaryMergeEvidence
        def with_merge_scope(record:, deadline:, exclusive: false)
          assignment, attempt = record.values_at("assignment_id", "attempt_id")
          token!(assignment)
          token!(attempt)
          registered = registration(assignment, commit: @journal.ref_value)
          raise AttemptErrors::EvidenceUnavailable, "merge assignment is unregistered" unless registered
          @exclusion.with_shared_multi([@exclusion.task_key(registered.fetch("task_id"))], deadline: deadline) do
            key = @exclusion.assignment_key(assignment)
            if exclusive
              @exclusion.with_exclusive(key, deadline: deadline) { yield }
            else
              @exclusion.with_shared_multi([key], deadline: deadline) { yield }
            end
          end
        end

        def verify_merge_evidence_at!(record:, commit:, deadline:)
          unless record.fetch("project_id") == @project
            raise AttemptErrors::ReceiptRejected, "merge evidence project differs"
          end
          request = record.fetch("request")
          events = result_events(record, commit)
          current = ordinary_candidate_event(events)&.dig("payload", "data")
          raise AttemptErrors::ReceiptRejected, "merge candidate is unavailable" unless current
          projection = merge_evidence_at!(events: events, commit: commit, head: request.fetch("candidate_head"),
            generation: current.fetch("candidate_generation"), execution_ids: request.fetch("test_evidence").map { |reference| reference.fetch("reference") }, deadline: deadline)
          unless request.fetch("review_evidence") == projection.fetch("review_evidence") && request.fetch("test_evidence") == projection.fetch("test_evidence")
            raise AttemptErrors::ReceiptRejected, "merge requires exact canonical review and executed test references"
          end
          origin = origin_at!(events: events, commit: commit)
          observed = @admission.recorded_execution!(binding: origin.fetch("runtime_binding"), head: request.fetch("candidate_head"), deadline: deadline)
          unless observed.fetch(:runtime_binding) == origin.fetch("runtime_binding")
            raise AttemptErrors::UnauthorizedIdentity, "merge producer native identity changed"
          end
          true
        rescue KeyError, TypeError
          raise AttemptErrors::ReceiptRejected, "canonical merge evidence is incomplete"
        end

        def merge_evidence_at!(events:, commit:, head:, generation:, execution_ids:, deadline:)
          unless @command_evidence && @command_evidence.journal.equal?(@journal) && execution_ids.is_a?(Array) &&
              execution_ids.size.between?(1, 16) && execution_ids.uniq == execution_ids
            raise AttemptErrors::EvidenceUnavailable, "merge requires the installed canonical executed-test owner"
          end
          candidate = candidate_at!(events: events, commit: commit, head: head, generation: generation)
          review = review_at!(events: events, commit: commit, head: head, generation: generation)
          tests = execution_ids.map { |id| @command_evidence.test_evidence_at!(execution_id: id, commit: commit,
            head: head, tree: candidate.fetch("tree"), deadline: deadline) }
          {"review_evidence" => {"schema" => "ace.review.acceptance-reference/v1", "reference" => review.fetch("review_id"),
            "reviewer" => review.fetch("reviewer_actor"), "verdict" => "approved", "reviewed_head" => head,
            "recorded_at" => review.fetch("recorded_at"), "record_sha256" => review.fetch("acceptance_event_digest")},
            "test_evidence" => tests}
        end

        private

        def ordinary_merge_evidence(request, peer, role, deadline)
          params = request.fetch("params")
          strict!(params, %w[assignment_id attempt_id head candidate_generation test_execution_ids])
          raise ArgumentError, "merge evidence read mutation must be null" unless request.fetch("mutation_id").nil?
          with_scope(assignment: params.fetch("assignment_id"), attempt: params.fetch("attempt_id"), deadline: deadline) do
            prefix = @journal.ref_value
            projection = merge_evidence_at!(events: result_events(params, prefix), commit: prefix, head: params.fetch("head"),
              generation: params.fetch("candidate_generation"), execution_ids: params.fetch("test_execution_ids"), deadline: deadline)
            authorize!(request, peer, role, deadline)
            {data: projection.merge("journal_commit" => prefix), replayed: false}
          end
        end
      end
    end
  end
end
