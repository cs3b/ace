# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # Called by Endcap only while holding the existing assignment/slot
        # exclusion and shared authority mutex. Returned channel capacity is
        # released after the caller leaves those locks and waits on the stream.
        def reserve_review_dispatch!(events:, params:, map:)
          state = origin(events, **params.slice("mapping_id", "assignment_id", "attempt_id").transform_keys(&:to_sym))
          unless state["phase"] == "issued" && !terminal_events?(events)
            raise AttemptErrors::Conflict, "review delegation requires an issued original launcher"
          end
          scope_open_for_effect!(events: events, params: params, map: map)
          original = original_prompt_record!(events, state, params: params)
          @kernel.live!(state.fetch("launcher_identity"))
          channel = @control_channels[steering_key(params, map)]
          raise AttemptErrors::EvidenceUnavailable, "original review channel is unavailable" unless channel
          [channel, channel.reserve_dispatch!, original]
        end

        def review_original_reference!(events:, params:)
          state = origin(events, **params.slice("mapping_id", "assignment_id", "attempt_id").transform_keys(&:to_sym))
          original_prompt_record!(events, state, params: params)
        end

        # Read-only original-launcher projection at the exact request commit.
        # Permission to assign still belongs to Endcap's fresh/replay checks.
        def launch_review_intent!(request:, peer:, role:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id mutation_id request_event_id journal_commit original_binding_digest])
          raise ArgumentError, "Review intent lookup is read-only" unless request.fetch("mutation_id").nil?
          raise AttemptErrors::UnauthorizedIdentity, "Review intent requires original launcher" unless role == :launcher
          %w[mapping_id assignment_id attempt_id mutation_id].each { |key| token!(params.fetch(key)) }
          unless %w[request_event_id original_binding_digest].all? { |key| params[key].is_a?(String) && params[key].match?(/\A[0-9a-f]{64}\z/) } &&
              params["journal_commit"].is_a?(String) && params["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise ArgumentError, "Review intent selectors differ"
          end
          map = steering_principal!(params, peer, role)
          raise AttemptErrors::UnauthorizedIdentity, "Review project differs" unless request.fetch("project_id") == map.fetch("project_id")
          journal = journal_for(map)
          commit = params.fetch("journal_commit")
          journal.verify_canonical_prefix!(commit: commit)
          events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          state = origin(events, **params.slice("mapping_id", "assignment_id", "attempt_id").transform_keys(&:to_sym))
          unless @kernel.same?(state.fetch("launcher_identity"), peer)
            raise AttemptErrors::UnauthorizedIdentity, "Review intent requires exact original launcher birth"
          end
          original = original_prompt_record!(events, state, params: params)
          event = events.find { |item| item["digest"] == params.fetch("request_event_id") }
          accepted = journal.mutation_result(params.fetch("mutation_id"), commit: commit)
          unless event && event["type"] == "authority_mutation" && event.dig("payload", "operation") == "request_review" &&
              event.dig("payload", "mutation_id") == params.fetch("mutation_id") && accepted &&
              accepted == event.fetch("payload").merge("journal_commit" => commit) &&
              original.fetch("binding_digest") == params.fetch("original_binding_digest")
            raise AttemptErrors::EvidenceUnavailable, "Canonical review request introduction differs"
          end
          data = event.fetch("payload").fetch("data")
          fields = %w[candidate_generation generation head original_binding_digest requester reviewer_process_binding reviewer_uid]
          unless data.is_a?(Hash) && data.keys.sort == fields && data["original_binding_digest"] == original.fetch("binding_digest") &&
              data["head"].is_a?(String) && data["head"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              %w[candidate_generation generation reviewer_uid].all? { |key| data[key].is_a?(Integer) && data[key].positive? }
            raise AttemptErrors::EvidenceUnavailable, "Canonical review request data differs"
          end
          identity = data.fetch("reviewer_process_binding")
          boot = identity.is_a?(Hash) && identity["started_at"].is_a?(String) && identity["started_at"].split(":", -1)[1]
          Molecules::ExecutionScopeLineage.validate_process_identity!(identity, boot_id: boot)
          requester = data["requester"]
          unless requester.is_a?(Hash) && requester.keys.sort == %w[gid groups role uid] &&
              %w[uid gid].all? { |key| requester[key].is_a?(Integer) } && requester["groups"].is_a?(Array) &&
              requester["groups"].all? { |group| group.is_a?(Integer) } &&
              requester == identity.slice("uid", "gid", "groups").merge("role" => "reviewer") &&
              data["reviewer_uid"] == identity["uid"] && identity["uid"] != map.fetch("worker_uid")
            raise AttemptErrors::EvidenceUnavailable, "Canonical reviewer attribution differs"
          end
          candidate = events.reverse.find { |item| item["type"] == "authority_mutation" && item.dig("payload", "operation") == "submit_candidate" }&.dig("payload", "data")
          unless candidate && candidate.values_at("head", "candidate_generation") == data.values_at("head", "candidate_generation")
            raise AttemptErrors::EvidenceUnavailable, "Canonical request candidate differs"
          end
          assignment = params.slice("mapping_id", "assignment_id", "attempt_id").merge(
            data.slice("head", "candidate_generation", "reviewer_uid", "reviewer_process_binding"),
            "expected_generation" => data.fetch("generation"))
          {data: params.slice("request_event_id", "original_binding_digest").merge("assignment_params" => assignment), replayed: false}
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "Canonical review intent is incomplete"
        end
      end
    end
  end
end
