# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        private

        # Historical assignment lookup stays separate: revocation removes
        # permission, never the original receipt or response.
        def active_review_reservation(events, current)
          reservation = events.reverse.find do |event|
            event["type"] == "authority_mutation" &&
              %w[request_review assign_review].include?(event.dig("payload", "operation")) &&
              !event.dig("payload", "mutation_id").to_s.start_with?("review-delegate.") &&
              event.dig("payload", "data", "head") == current.fetch("head") &&
              event.dig("payload", "data", "candidate_generation") == current.fetch("candidate_generation")
          end
          return unless reservation
          cancelled = events.any? do |event|
            event["type"] == "authority_mutation" && event.dig("payload", "operation") == "cancel_review" &&
              event.dig("payload", "data", "review_event_id") == reservation.fetch("digest")
          end
          reservation unless cancelled
        end

        def active_review_event(events, current)
          reservation = active_review_reservation(events, current)
          return unless reservation
          return reservation if reservation.dig("payload", "operation") == "assign_review"
          events.find do |event|
            event["type"] == "authority_mutation" && event.dig("payload", "operation") == "assign_review" &&
              event.dig("payload", "mutation_id") == "review-delegate.#{reservation.fetch('digest')}"
          end
        end

        # Reserved spelling is not authorization. Reconstruct the immutable
        # request through the original-launcher reader before historical replay,
        # then separately check the active reservation for a fresh mutation.
        def delegated_review_request!(journal, events, request, params, peer, role)
          mutation = request.fetch("mutation_id")
          return unless mutation.is_a?(String) && mutation.start_with?("review-delegate.")
          digest = mutation.delete_prefix("review-delegate.")
          original = events.find { |event| event["digest"] == digest && event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "request_review" }
          raise AttemptErrors::UnauthorizedIdentity, "delegation requires a canonical request" unless original
          accepted = journal.mutation_result(original.dig("payload", "mutation_id"))
          selectors = params.slice("mapping_id", "assignment_id", "attempt_id").merge(
            "mutation_id" => original.dig("payload", "mutation_id"), "request_event_id" => digest,
            "journal_commit" => accepted.fetch("journal_commit"),
            "original_binding_digest" => original.dig("payload", "data", "original_binding_digest"))
          intent = @launch.launch_review_intent!(request: request.merge("operation" => "launch_review_intent",
            "mutation_id" => nil, "params" => selectors), peer: peer, role: role)
          unless Atoms::EvidenceDigest.digest(intent.dig(:data, "assignment_params")) == Atoms::EvidenceDigest.digest(params)
            raise AttemptErrors::UnauthorizedIdentity, "delegation differs from exact canonical request"
          end
          original
        end

        def cancel_review(request, params, map, peer, role, transfer)
          raise ArgumentError, "review cancellation forbids upload" unless transfer.nil?
          unless params["review_event_id"].is_a?(String) && params["review_event_id"].match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "review cancellation selector differs"
          end
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            events = attempt_events(journal, params)
            authenticate_review_cancellation!(events, params, map, peer, role)
            result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "cancel_review",
              parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: params.fetch("expected_generation"),
              with_replay: true) do |current_events, _commit, _generation|
              authenticate_review_cancellation!(current_events, params, map, peer, role)
              current = exact_candidate!(candidate(current_events), params)
              reservation = active_review_reservation(current_events, current)
              unless reservation && reservation.fetch("digest") == params.fetch("review_event_id")
                raise AttemptErrors::Conflict, "review reservation is no longer active"
              end
              {data: current.slice("head", "candidate_generation").merge(
                "review_event_id" => reservation.fetch("digest"),
                "review_id" => active_review_event(current_events, current)&.dig("payload", "data", "review_id"), "state" => "cancelled")}
            end
            review_event_reply(journal, result, request, params, "cancellation_event_id")
          end
        end

        def review_event_reply(journal, result, request, params, field)
          accepted = journal.read_events(params.fetch("assignment_id"), commit: result.fetch(:data).fetch("journal_commit")).find do |event|
            event["attempt_id"] == params.fetch("attempt_id") && event["type"] == "authority_mutation" &&
              event.dig("payload", "operation") == request.fetch("operation") &&
              event.dig("payload", "mutation_id") == request.fetch("mutation_id")
          end
          raise AttemptErrors::EvidenceUnavailable, "accepted review event is unavailable" unless accepted
          result.merge(data: result.fetch(:data).merge(field => accepted.fetch("digest")))
        end

        def authenticate_review_cancellation!(events, params, map, peer, role)
          origin = active_origin(events, params)
          @kernel.live!(peer)
          original = events.find { |event| event["digest"] == params.fetch("review_event_id") }
          unless original && original["type"] == "authority_mutation" &&
              %w[request_review assign_review].include?(original.dig("payload", "operation")) &&
              !original.dig("payload", "mutation_id").to_s.start_with?("review-delegate.") &&
              original.dig("payload", "data", "head") == params.fetch("head") &&
              original.dig("payload", "data", "candidate_generation") == params.fetch("candidate_generation")
            raise AttemptErrors::UnauthorizedIdentity, "review cancellation requires the exact reservation root"
          end
          if role == :launcher
            unless @kernel.same?(origin.fetch("launcher_identity"), peer)
              raise AttemptErrors::UnauthorizedIdentity, "cancellation requires original launcher birth"
            end
            worker_or_launcher!(peer, role, map, origin, launcher_only: true)
          elsif role == :reviewer && original.dig("payload", "operation") == "request_review"
            project = @deployment.project(map.fetch("project_id"))
            credentials = project.fetch("peer_credentials")[peer.fetch("uid").to_s]
            principal = peer.slice("uid", "gid", "groups").merge("role" => "reviewer")
            unless project.fetch("reviewer_uids").include?(peer.fetch("uid")) && peer.fetch("uid") != map.fetch("worker_uid") &&
                credentials && peer.values_at("gid", "groups") == credentials.values_at("gid", "groups") &&
                Atoms::EvidenceDigest.digest(principal) == Atoms::EvidenceDigest.digest(original.dig("payload", "data", "requester"))
              raise AttemptErrors::UnauthorizedIdentity, "cancellation requires the original mapped requester"
            end
          else
            raise AttemptErrors::UnauthorizedIdentity, "review reservation cancellation is unauthorized"
          end
          original
        end
      end
    end
  end
end
