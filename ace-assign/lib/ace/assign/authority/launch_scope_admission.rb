# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # Internal owner call, deliberately absent from the public operation
        # allowlist. The durable winner alone may call the fixed manager. A
        # lost StartUnit reply retains admission uncertainty; replay never starts.
        def admit_native_service!(params:, peer:, role:)
          strict!(params, %w[mapping_id assignment_id attempt_id launch_ticket mutation_id expected_generation])
          unless %i[launcher supervisor].include?(role)
            raise AttemptErrors::UnauthorizedIdentity, "native admission requires an exact launch owner"
          end
          %w[assignment_id attempt_id launch_ticket mutation_id].each { |key| token!(params.fetch(key)) }
          generation!(params.fetch("expected_generation"))
          @kernel.live!(peer)
          map = @deployment.mapping(params.fetch("mapping_id"))
          journal = journal_for(map)
          input = params.reject { |key, _| key == "mutation_id" }
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical(input)))
          with_exclusion(params, map, journal) do
            admit_native_service_held!(params, map, journal, peer, role, digest)
          end
        end

        private

        def admit_native_service_held!(params, map, journal, peer, role, digest)
            result = @mutex.synchronize do
              # Visibility is current even on a historical mutation replay.
              current = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              scope_admission_owner!(params, map, current, peer, role)
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: params.fetch("mutation_id"), operation: "scope_service_admission", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |events, _commit, generation|
                state, lineage = scope_admission_owner!(params, map, events, peer, role)
                lineage.require_open!
                unless state["phase"] == "reserved" && !lineage.native_event && !lineage.child_event &&
                    events.none? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_service_admission" }
                  raise AttemptErrors::Conflict, "native activation was already admitted or launch advanced"
                end
                observer = scope_observer_for(params.fetch("mapping_id"))
                installation = observer.native_admission_ready!(lineage)
                binding = lineage.binding
                data = state.merge("scope_generation" => binding.fetch("scope_generation"),
                  "scope_binding_event_id" => lineage.binding_event.fetch("digest"),
                  "service_unit" => map.fetch("execution_scope").fetch("service_unit"), "native_admission" => "issued_uncertain",
                  "network_installation" => installation)
                unless installation.is_a?(Hash) && installation["namespace_path"] == map.fetch("execution_scope").fetch("network_namespace_path")
                  raise AttemptErrors::EvidenceUnavailable, "network verifier output names another fixed namespace path"
                end
                candidate = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: params.fetch("attempt_id"),
                  payload: {"operation" => "scope_service_admission", "data" => data.merge("generation" => generation + 1)},
                  previous_digest: events.last&.fetch("digest"))
                Molecules::ExecutionScopeLineage.new(events: events + [candidate], project_id: map.fetch("project_id"),
                  assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
                {events: [], blobs: {}, data: data}
              end
            end
            # No authority mutex or journal ref lock is held while systemd waits
            # for its private readiness callback. Slot exclusion still prevents
            # another generation, seal or maintenance from racing this start.
            unless result.fetch(:replayed)
              scope_observer_for(params.fetch("mapping_id")).start_admitted_service!
            end
            result
        end

        def scope_admission_owner!(params, map, events, peer, role)
          state = states(events)[params.fetch("attempt_id")]
          unless state && state["mapping_id"] == params.fetch("mapping_id") &&
              state["launch_ticket"] == params.fetch("launch_ticket") &&
              (role == :supervisor || @kernel.same?(state.fetch("launcher_identity"), peer))
            raise AttemptErrors::UnauthorizedIdentity, "native admission launch origin differs"
          end
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
          [state, lineage]
        end
      end
    end
  end
end
