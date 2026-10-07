# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        private

        def review_requester!(params, map, peer, role, recorded: nil)
          @kernel.live!(peer)
          current = @deployment.verify!(params.fetch("mapping_id"), kernel: @kernel, authority_state: true)
          raise AttemptErrors::UnauthorizedIdentity, "review mapping changed" unless current == map
          project = @deployment.project(map.fetch("project_id"))
          credentials = project.fetch("peer_credentials")[peer.fetch("uid").to_s]
          principal = peer.slice("uid", "gid", "groups").merge("role" => role.to_s)
          unless role == :reviewer && project.fetch("reviewer_uids").include?(peer.fetch("uid")) &&
              peer.fetch("uid") != map.fetch("worker_uid") && credentials &&
              peer.values_at("gid", "groups") == credentials.values_at("gid", "groups") &&
              (!recorded || Atoms::EvidenceDigest.digest(principal) == Atoms::EvidenceDigest.digest(recorded))
            raise AttemptErrors::UnauthorizedIdentity, "review request requires its independently mapped principal"
          end
          principal
        end

        def request_review(request, params, map, peer, role, transfer)
          raise ArgumentError, "review request forbids upload" unless transfer.nil?
          unless request["mutation_id"].is_a?(String) && request["mutation_id"].match?(Molecules::JournalMutation::ID) &&
              params["expected_generation"].is_a?(Integer) && params["expected_generation"] >= 0
            raise ArgumentError, "review request mutation binding differs"
          end
          principal = review_requester!(params, map, peer, role)
          digest = Atoms::EvidenceDigest.digest(params.merge("requester_process_binding" => peer))
          channel = reservation = accepted = nil
          prepared = @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            events = attempt_events(journal, params)
            active_origin(events, params)
            replay = journal.mutation_result(request.fetch("mutation_id"))
            if replay
              unless replay["operation"] == "request_review" && replay["parameters_digest"] == digest &&
                  replay["assignment_id"] == params.fetch("assignment_id") && replay["attempt_id"] == params.fetch("attempt_id")
                raise AttemptErrors::Conflict, "review mutation is already bound to different input"
              end
              accepted = {data: replay.fetch("data").merge("journal_commit" => replay.fetch("journal_commit")), replayed: true}
            else
              channel, reservation, original = @launch.reserve_review_dispatch!(events: events, params: params, map: map)
              accepted = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: request.fetch("mutation_id"), operation: "request_review", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |fresh, _commit, _generation|
                review_requester!(params, map, peer, role)
                active_origin(fresh, params)
                @launch.scope_open_for_effect!(events: fresh, params: params, map: map)
                current = exact_candidate!(candidate(fresh), params)
                if active_review_reservation(fresh, current)
                  raise AttemptErrors::Conflict, "candidate review reservation is active"
                end
                unless channel.dispatch_reserved?(reservation) && @launch.review_original_reference!(events: fresh, params: params) == original
                  raise AttemptErrors::EvidenceUnavailable, "original review channel reservation changed"
                end
                {data: current.slice("head", "candidate_generation").merge(
                  "original_binding_digest" => original.fetch("binding_digest"), "requester" => principal,
                  "reviewer_uid" => peer.fetch("uid"), "reviewer_process_binding" => peer)}
              end
            end
            review_event_reply(journal, accepted, request, params, "request_event_id")
          end
          unless prepared.fetch(:replayed)
            frame = {"version" => 1, "type" => "launch_review_delegate", "attempt_id" => params.fetch("attempt_id"),
              "mutation_id" => request.fetch("mutation_id"), "request_event_id" => prepared.dig(:data, "request_event_id"),
              "journal_commit" => prepared.dig(:data, "journal_commit"),
              "original_binding_digest" => prepared.dig(:data, "original_binding_digest")}
            begin
              channel.dispatch_review(frame: frame, deadline: Ace::Runtime::Molecules::ProtectedSocket.deadline(30), reservation: reservation)
            rescue Ace::Runtime::RuntimeUnavailableError, AttemptErrors::EvidenceUnavailable, IOError, SystemCallError
              # The canonical assignment, not a transport ACK or its absence,
              # decides whether the recorded first reply can name an assignment.
            end
          end
          finish_review_reply(request, params, map, peer, role, prepared)
        ensure
          channel&.release_dispatch!(reservation) if reservation
        end

        def review_request_event!(journal, events, params, commit: journal.ref_value)
          accepted = journal.mutation_result(params.fetch("mutation_id"), commit: commit)
          unless accepted && accepted["operation"] == "request_review" &&
              accepted["assignment_id"] == params.fetch("assignment_id") && accepted["attempt_id"] == params.fetch("attempt_id")
            raise AttemptErrors::NotFound, "canonical review request is unavailable"
          end
          event = events.find { |item| item["type"] == "authority_mutation" && item.dig("payload", "mutation_id") == params.fetch("mutation_id") }
          unless event && event.fetch("payload") == accepted.except("journal_commit")
            raise AttemptErrors::EvidenceUnavailable, "canonical review request differs"
          end
          [event, accepted]
        end

        def review_assignment_observation(journal, events, params, event, commit: journal.ref_value)
          mutation = "review-delegate.#{event.fetch('digest')}"
          accepted = journal.mutation_result(mutation, commit: commit)
          return nil unless accepted
          source = event.fetch("payload").fetch("data")
          expected = params.slice("mapping_id", "assignment_id", "attempt_id").merge(
            source.slice("head", "candidate_generation", "reviewer_uid", "reviewer_process_binding"),
            "expected_generation" => source.fetch("generation"))
          actual = events.find { |item| item["type"] == "authority_mutation" && item.dig("payload", "mutation_id") == mutation }
          data = accepted.fetch("data")
          unless accepted["operation"] == "assign_review" && accepted["assignment_id"] == params.fetch("assignment_id") &&
              accepted["attempt_id"] == params.fetch("attempt_id") && actual && actual.fetch("payload") == accepted.except("journal_commit") &&
              accepted["parameters_digest"] == Atoms::EvidenceDigest.digest(expected) &&
              data.keys.sort == %w[candidate_generation generation head review_id reviewer_actor reviewer_process_binding reviewer_uid] &&
              data["generation"].is_a?(Integer) && data.fetch("generation") == source.fetch("generation") + 1 &&
              data["review_id"].is_a?(String) && data["review_id"].match?(/\A[0-9a-f]{32}\z/) &&
              data["reviewer_actor"] == "uid-#{source.fetch('reviewer_uid')}" &&
              Atoms::EvidenceDigest.digest(data.slice("head", "candidate_generation", "reviewer_uid", "reviewer_process_binding")) ==
                Atoms::EvidenceDigest.digest(source.slice("head", "candidate_generation", "reviewer_uid", "reviewer_process_binding"))
            raise AttemptErrors::EvidenceUnavailable, "canonical delegated assignment differs"
          end
          data.merge("assignment_event_id" => actual.fetch("digest"), "journal_commit" => accepted.fetch("journal_commit"))
        end

        def finish_review_reply(request, params, map, peer, role, prepared)
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            events = attempt_events(journal, params)
            selectors = params.slice("mapping_id", "assignment_id", "attempt_id").merge("mutation_id" => request.fetch("mutation_id"))
            event, = review_request_event!(journal, events, selectors)
            review_requester!(params, map, peer, role, recorded: event.dig("payload", "data", "requester"))
            reply_id = "review-reply.#{event.fetch('digest')}"
            result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: reply_id, operation: "review_reply", parameters_digest: Atoms::EvidenceDigest.digest(selectors),
              expected_generation: journal.authority_generation(events), with_replay: true) do |fresh, selected, _generation|
              assignment = review_assignment_observation(journal, fresh, params, event, commit: selected)
              {data: {"request_event_id" => event.fetch("digest"), "request_commit" => prepared.dig(:data, "journal_commit"),
                "state" => assignment ? "assigned" : "uncertain", "assignment" => assignment,
                "required_action" => assignment ? nil : "inspect_review_status"}}
            end
            result.merge(replayed: prepared.fetch(:replayed) || result.fetch(:replayed))
          end
        end

        def review_status(request, peer, role, transfer)
          raise ArgumentError, "review status forbids upload" unless transfer.nil?
          params = request.fetch("params")
          unless request["mutation_id"].nil? && params.is_a?(Hash) && params.keys.sort == %w[assignment_id attempt_id mapping_id mutation_id] &&
              params.values.all? { |value| value.is_a?(String) && value.match?(Molecules::JournalMutation::ID) }
            raise ArgumentError, "invalid review status selectors"
          end
          map = @deployment.mapping(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "review project differs" unless map.fetch("project_id") == request.fetch("project_id")
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            commit = journal.ref_value
            events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            event, = review_request_event!(journal, events, params, commit: commit)
            review_requester!(params, map, peer, role, recorded: event.dig("payload", "data", "requester"))
            assignment = review_assignment_observation(journal, events, params, event, commit: commit)
            cancellation = events.find { |item| item["type"] == "authority_mutation" && item.dig("payload", "operation") == "cancel_review" &&
              item.dig("payload", "data", "review_event_id") == event.fetch("digest") }
            acceptance = assignment && events.reverse.find do |item|
              item["type"] == "authority_mutation" && item.dig("payload", "operation") == "accept_review" &&
                item.dig("payload", "data", "review_id") == assignment.fetch("review_id")
            end
            current = candidate(events)
            state = if cancellation
              "cancelled"
            elsif !current || current.values_at("head", "candidate_generation") != event.dig("payload", "data").values_at("head", "candidate_generation")
              "candidate_replaced"
            elsif assignment
              "assigned"
            else
              "requested"
            end
            first = journal.mutation_result("review-reply.#{event.fetch('digest')}", commit: commit)
            {data: {"request_event_id" => event.fetch("digest"), "assignment" => assignment, "state" => state,
              "accepted_review_event_id" => acceptance&.fetch("digest"),
              "first_reply" => first && first.fetch("data").merge("journal_commit" => first.fetch("journal_commit")),
              "cancellation_event_id" => cancellation&.fetch("digest"), "generation" => journal.authority_generation(events),
              "journal_commit" => commit}, replayed: false}
          end
        end
      end
    end
  end
end
