# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        private

        # Historical assignment lookup stays separate: revocation removes
        # permission, never the original receipt or response.
        def active_review_event(events, current)
          assignment = events.reverse.find do |event|
            event["type"] == "authority_mutation" && event.dig("payload", "operation") == "assign_review" &&
              event.dig("payload", "data", "head") == current.fetch("head") &&
              event.dig("payload", "data", "candidate_generation") == current.fetch("candidate_generation")
          end
          return unless assignment
          cancelled = events.any? do |event|
            event["type"] == "authority_mutation" && event.dig("payload", "operation") == "cancel_review" &&
              event.dig("payload", "data", "review_event_id") == assignment.fetch("digest")
          end
          assignment unless cancelled
        end

        def cancel_review(request, params, map, peer, role, transfer)
          raise ArgumentError, "review cancellation forbids upload" unless transfer.nil?
          unless params["review_event_id"].is_a?(String) && params["review_event_id"].match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "review cancellation selector differs"
          end
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            events = attempt_events(journal, params)
            authenticate_direct_review_cancellation!(events, params, map, peer, role)
            result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "cancel_review",
              parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: params.fetch("expected_generation"),
              with_replay: true) do |current_events, _commit, _generation|
              current = authenticate_direct_review_cancellation!(current_events, params, map, peer, role)
              reservation = active_review_event(current_events, current)
              unless reservation && reservation.fetch("digest") == params.fetch("review_event_id")
                raise AttemptErrors::Conflict, "review reservation is no longer active"
              end
              {data: current.slice("head", "candidate_generation").merge(
                "review_event_id" => reservation.fetch("digest"),
                "review_id" => reservation.dig("payload", "data", "review_id"), "state" => "cancelled")}
            end
            accepted = journal.read_events(params.fetch("assignment_id"), commit: result.fetch(:data).fetch("journal_commit")).find do |event|
              event["attempt_id"] == params.fetch("attempt_id") && event["type"] == "authority_mutation" &&
                event.dig("payload", "operation") == "cancel_review" && event.dig("payload", "mutation_id") == request.fetch("mutation_id")
            end
            raise AttemptErrors::EvidenceUnavailable, "accepted cancellation is unavailable" unless accepted
            result.merge(data: result.fetch(:data).merge("cancellation_event_id" => accepted.fetch("digest")))
          end
        end

        def authenticate_direct_review_cancellation!(events, params, map, peer, role)
          origin = active_origin(events, params)
          @kernel.live!(peer)
          worker_or_launcher!(peer, role, map, origin, launcher_only: true)
          current = exact_candidate!(candidate(events), params)
          original = events.find { |event| event["digest"] == params.fetch("review_event_id") }
          unless original && original["type"] == "authority_mutation" &&
              original.dig("payload", "operation") == "assign_review" &&
              original.dig("payload", "data", "head") == current.fetch("head") &&
              original.dig("payload", "data", "candidate_generation") == current.fetch("candidate_generation")
            raise AttemptErrors::UnauthorizedIdentity, "review cancellation requires the exact assignment"
          end
          current
        end
      end
    end
  end
end
