# frozen_string_literal: true

require_relative "../organisms/attempt_coordinator"

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # The stop mutation owns its seal and immutable reply. Input inhibition
        # waits outside exclusions; manager stop runs after CAS outside @mutex,
        # retaining the existing containment slot guard.
        def stop_attempt!(request:, peer:, role:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id expected_generation])
          %w[assignment_id attempt_id].each { |key| token!(params.fetch(key)) }
          token!(request.fetch("mutation_id"))
          generation!(params.fetch("expected_generation"))
          map = steering_principal!(params, peer, role)
          journal = journal_for(map)
          principal = peer.slice("uid", "gid", "groups").merge("role" => role.to_s)
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical(params.merge("caller" => principal))))
          closure = nil
          pending_action = pending_commit = nil
          prepared = with_containment_exclusion(params, map, journal) do
            @mutex.synchronize do
              commit = journal.ref_value
              events = stop_events!(journal, params, commit)
              replay = journal.mutation_result(request.fetch("mutation_id"), commit: commit)
              if replay
                unless replay.values_at("operation", "parameters_digest", "assignment_id", "attempt_id") ==
                    ["stop_attempt", digest, params.fetch("assignment_id"), params.fetch("attempt_id")]
                  raise AttemptErrors::Conflict, "Mutation ID is already bound to different stop input"
                end
                if events.any? { |event| event["type"] == "attempt_stopped" }
                  terminal_scope_stopped!(events, journal, commit, deployment: @deployment)
                elsif %w[succeeded failed].include?(journal.canonical_attempt_state(events))
                  lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
                    assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
                  terminal_scope_receipt!(events, lineage, journal, commit)
                else
                  stop_owner!(params, map, events)
                end
                next({data: replay.fetch("data").merge("journal_commit" => replay.fetch("journal_commit")), replayed: true})
              end
              lineage = stop_owner!(params, map, events)
              if lineage.proof_event && !pending_prompt_issuers?(events, journal, commit)
                scope_observer_for(params.fetch("mapping_id")).verify_closed!(lineage)
                raise AttemptErrors::EvidenceUnavailable, "Settlement owner is unavailable" unless @result_owner
                begin
                  @result_owner.service_settlement_evidence!(journal: journal, events: events, params: params, map: map, commit: commit)
                rescue AttemptErrors::EvidenceUnavailable => error
                  raise unless authenticated_stop_pending_action(error) == "settle_services"
                  pending_action, pending_commit = "settle_services", commit
                end
                next nil
              end
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: request.fetch("mutation_id"), operation: "stop_attempt", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |current, old, _generation|
                lineage = stop_owner!(params, map, current)
                closure = scope_closure_plan!(lineage: lineage, params: params, map: map, events: current, journal: journal, commit: old)
                plan = closure.fetch(:plan)
                plan.merge(data: stop_pending_reply(params, plan.fetch(:data)["proof_id"], "reconcile_scope"))
              end
            end
          end
          if prepared
            unless prepared.fetch(:replayed)
              request_original_input_inhibition!(params, map, journal) if closure&.fetch(:inhibit_required)
              if closure&.fetch(:stop_required)
                with_containment_exclusion(params, map, journal) do
                  @mutex.synchronize { stop_owner!(params, map, stop_events!(journal, params, journal.ref_value)) }
                  scope_observer_for(params.fetch("mapping_id")).stop_sealed_service!
                end
              end
            end
            return prepared
          end
          if pending_action
            return record_pending_stop!(request, map, journal, digest, pending_action, pending_commit)
          end
          final_selection = journal.ref_value
          begin
            finalize_stopped_attempt!(request, peer, role, map, journal, digest)
          rescue AttemptErrors::EvidenceUnavailable => error
            action = authenticated_stop_pending_action(error)
            raise unless action
            record_pending_stop!(request, map, journal, digest, action, final_selection)
          end
        end

        private

        def stop_events!(journal, params, commit)
          journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
        end

        def stop_owner!(params, map, events)
          state = origin(events, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
          original_prompt_record!(events, state, params: params) if issued_input_actor?(events)
          canonical_state = Molecules::CanonicalAttemptState.derive(events)
          unless %w[running uncertain].include?(canonical_state)
            raise AttemptErrors::Conflict, "Attempt is not eligible for proof-authenticated stop"
          end
          Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
        end

        def stop_pending_reply(params, proof_id, action)
          {"attempt_id" => params.fetch("attempt_id"), "state" => "uncertain", "proof_id" => proof_id, "required_action" => action}
        end

        # Only positively authenticated owner-pending subclasses have public
        # recovery actions. Missing/corrupt evidence and auth failures propagate.
        def authenticated_stop_pending_action(error)
          if error.is_a?(AttemptErrors::ServiceSettlementPending)
            return "settle_services"
          end
          nil
        end

        def record_pending_stop!(request, map, journal, digest, action, selected_commit)
          params = request.fetch("params")
          with_containment_exclusion(params, map, journal) do
            @mutex.synchronize do
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: request.fetch("mutation_id"), operation: "stop_attempt", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |events, commit, _generation|
                unless commit == selected_commit
                  raise AttemptErrors::Conflict, "Authenticated pending settlement prefix advanced"
                end
                lineage = stop_owner!(params, map, events)
                unless lineage.proof_event && !pending_prompt_issuers?(events, journal, commit)
                  raise AttemptErrors::EvidenceUnavailable, "Original scope closure proof is unavailable"
                end
                scope_observer_for(params.fetch("mapping_id")).verify_closed!(lineage)
                {events: [], blobs: {}, data: stop_pending_reply(params, lineage.proof_id, action)}
              end
            end
          end
        end

        def finalize_stopped_attempt!(request, peer, role, map, journal, digest)
          params = request.fetch("params")
          with_exclusion(params, map, journal) do
            @mutex.synchronize do
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: request.fetch("mutation_id"), operation: "stop_attempt", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |events, commit, _generation|
                steering_principal!(params, peer, role)
                lineage = stop_owner!(params, map, events)
                unless lineage.proof_event && !pending_prompt_issuers?(events, journal, commit)
                  raise AttemptErrors::EvidenceUnavailable, "Original scope closure proof is unavailable"
                end
                scope_observer_for(params.fetch("mapping_id")).verify_closed!(lineage)
                raise AttemptErrors::EvidenceUnavailable, "Settlement owner is unavailable" unless @result_owner
                services = @result_owner.service_settlement_evidence!(journal: journal, events: events, params: params, map: map, commit: commit)

                provisioning = events.select { |event| event["type"] == "scope_provisioning" }
                raise AttemptErrors::EvidenceUnavailable, "Original deployment provenance is ambiguous" unless provisioning.one?
                selection = params.slice("mapping_id", "assignment_id", "attempt_id").merge("project_id" => map.fetch("project_id"),
                  "descriptor_sha256" => provisioning.first.fetch("payload").fetch("descriptor_sha256"),
                  "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "seal_event_id" => lineage.seal_event.fetch("digest"),
                  "closed_proof_event_id" => lineage.proof_id)
                plan = Organisms::AttemptCoordinator.stopped_transition_plan(events: events, selection: selection,
                  service_evidence: services, commit: commit)
                plan.merge(data: {"attempt_id" => params.fetch("attempt_id"), "state" => "stopped", "proof_id" => lineage.proof_id, "required_action" => nil})
              end
            end
          end
        end

        # Historical terminal authentication uses the original immutable
        # descriptor and the actual introduction prefix, not today's pointer.
        def terminal_scope_stopped!(events, journal, commit, deployment:)
          terminal = events.select { |event| event["type"] == "attempt_stopped" }
          raise AttemptErrors::EvidenceUnavailable, "Stopped terminal is missing or ambiguous" unless terminal.one?
          event = terminal.first
          acceptance = events.find { |entry| entry["type"] == "authority_mutation" && entry["previous_digest"] == event.fetch("digest") }
          raise AttemptErrors::EvidenceUnavailable, "Stopped terminal acceptance is missing" unless acceptance
          assignment_id = event.fetch("payload").fetch("assignment_id")
          prefix_commit = terminal_event_commit!(journal, assignment_id: assignment_id, event_digest: acceptance.fetch("digest"), commit: commit)
          verify_stopped_terminal_at_prefix!(events, journal, prefix_commit, deployment: deployment)
        rescue KeyError, TypeError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "Stopped original terminal evidence is malformed"
        end

        # Source composition supplies only an introduction authenticated by the
        # canonical Git owner. This immutable verifier grants no live exclusion.
        def verify_stopped_terminal_at_prefix!(events, journal, prefix_commit, deployment:)
          terminals = events.select { |entry| entry["type"] == "attempt_stopped" }
          raise AttemptErrors::EvidenceUnavailable, "Stopped terminal is missing or ambiguous" unless terminals.one?
          event = terminals.first
          accepted = events.select { |entry| entry["type"] == "authority_mutation" && entry["previous_digest"] == event.fetch("digest") }
          raise AttemptErrors::EvidenceUnavailable, "Stopped terminal acceptance is missing or ambiguous" unless accepted.one?
          acceptance = accepted.first
          assignment_id = event.fetch("payload").fetch("assignment_id")
          prefix = journal.read_events(assignment_id, commit: prefix_commit).select { |entry| entry["attempt_id"] == event.fetch("attempt_id") }
          unless prefix == events.take(events.index(acceptance) + 1) && Molecules::CanonicalAttemptState.derive(prefix) == "stopped"
            raise AttemptErrors::EvidenceUnavailable, "Stopped terminal introduction prefix differs"
          end
          payload = event.fetch("payload")
          descriptor = if deployment.artifact_reference&.fetch("sha256") == payload.fetch("descriptor_sha256")
            deployment
          else
            raise AttemptErrors::EvidenceUnavailable, "Original stopped descriptor history is unavailable" unless @deployment_history
            @deployment_history.descriptor!(sha256: payload.fetch("descriptor_sha256"))
          end
          map = descriptor.mapping(payload.fetch("mapping_id"))
          unless map.fetch("project_id") == payload.fetch("project_id")
            raise AttemptErrors::EvidenceUnavailable, "Original stopped project differs"
          end
          provisioning = prefix.select { |entry| entry["type"] == "scope_provisioning" }
          reservation = prefix.select { |entry| entry["type"] == "authority_mutation" && entry.dig("payload", "operation") == "reserve_attempt" }
          unless provisioning.one? && reservation.one?
            raise AttemptErrors::EvidenceUnavailable, "Original stopped reservation is ambiguous"
          end
          identity = provisioning.first.fetch("payload")
          reservation_data = reservation.first.dig("payload", "data")
          unless identity.is_a?(Hash) && identity.keys.sort == %w[deployment_digest descriptor_sha256 reservation_generation slot_id] &&
              reservation_data.is_a?(Hash) && identity["reservation_generation"] == reservation_data["reservation_generation"] &&
              reservation_data.values_at("mapping_id", "project_id") == payload.values_at("mapping_id", "project_id") &&
              Digest::SHA256.hexdigest(JSON.generate(canonical(map))) == identity.fetch("deployment_digest") &&
              map.fetch("execution_scope").fetch("slot_id") == identity.fetch("slot_id") &&
              descriptor.project(map.fetch("project_id")).values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root") ==
                [journal.repo_root, journal.ref, journal.checkout_root]
            raise AttemptErrors::EvidenceUnavailable, "Original stopped descriptor canonical association differs"
          end
          params = payload.slice("mapping_id", "assignment_id", "attempt_id")
          lineage = Molecules::ExecutionScopeLineage.new(events: prefix, **payload.slice("project_id", "assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
          unless lineage.binding.fetch("deployment_digest") == identity.fetch("deployment_digest")
            raise AttemptErrors::EvidenceUnavailable, "Original stopped parent mapping differs"
          end
          verify_historical_boot_baseline!(lineage.binding)
          lineage.require_positive!(scope_generation: lineage.binding.fetch("scope_generation"),
            scope_binding_event_id: payload.fetch("scope_binding_event_id"), seal_event_id: payload.fetch("seal_event_id"), proof_id: payload.fetch("closed_proof_event_id"))
          if issued_input_actor?(prefix) && !accepted_input_inhibition?(prefix, journal, prefix_commit)
            raise AttemptErrors::EvidenceUnavailable, "Stopped original input lifetime is not inhibited"
          end
          raise AttemptErrors::EvidenceUnavailable, "Original stopped settlement owner is unavailable" unless @result_owner
          services = @result_owner.service_settlement_evidence!(journal: journal, events: prefix, params: params, map: map, commit: prefix_commit)

          expected = Molecules::CanonicalAttemptState.stopped_payload!(events: prefix,
            selection: payload.slice(*Molecules::CanonicalAttemptState::SELECTION_FIELDS), service_evidence: services,
            commit: prefix_commit)
          raise AttemptErrors::EvidenceUnavailable, "Stopped exhaustive settlement differs" unless payload == expected
          event
        rescue KeyError, TypeError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "Stopped original terminal evidence is malformed"
        end
      end
    end
  end
end
