# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # Source-owned close core. Its first accepted mutation seals admission
        # and caches the retained running reply before any manager stop. A
        # subsequent fresh mutation may record positive observation; replay of
        # the first mutation always keeps its original reply and performs no I/O.
        def close_execution_scope!(params:, peer:, role:)
          strict!(params, %w[mapping_id assignment_id attempt_id mutation_id expected_generation])
          %w[assignment_id attempt_id mutation_id].each { |key| token!(params.fetch(key)) }
          generation!(params.fetch("expected_generation"))
          @kernel.live!(peer)
          map = @deployment.mapping(params.fetch("mapping_id"))
          journal = journal_for(map)
          input = params.reject { |key, _| key == "mutation_id" }
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical(input)))
          with_exclusion(params, map, journal) do
            stop_after_commit = false
            result = @mutex.synchronize do
              current = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              scope_close_owner!(params, map, current, peer, role)
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: params.fetch("mutation_id"), operation: "close_execution_scope", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |events, _commit, _generation|
                lineage = scope_close_owner!(params, map, events, peer, role)
                binding = lineage.binding
                raise AttemptErrors::EvidenceUnavailable, "original parent binding is missing" unless binding
                projection = {"attempt_id" => params.fetch("attempt_id"), "scope_generation" => binding.fetch("scope_generation"),
                  "state" => "running", "proof_id" => nil, "required_action" => "close_scope"}
                if !lineage.sealed?
                  stop_after_commit = true
                  payload = {"scope_generation" => binding.fetch("scope_generation"), "scope_binding_event_id" => lineage.binding_event.fetch("digest")}
                  {events: [{type: "scope_sealed", payload: payload}], blobs: {}, data: projection}
                elsif @native_issuers.key?(native_issuer_key(params, map))
                  # A live issuer may still start after this inactive snapshot.
                  {events: [], blobs: {}, data: projection}
                elsif lineage.proof_event
                  scope_observer_for(params.fetch("mapping_id")).verify_closed!(lineage)
                  {events: [], blobs: {}, data: projection.merge("state" => "closed_no_writers", "proof_id" => lineage.proof_id, "required_action" => nil)}
                elsif scope_observer_for(params.fetch("mapping_id")).sealed_service_stop_required?(lineage)
                  # A fresh canonical close resumes a stop lost after the seal.
                  # Replaying either mutation performs no manager I/O.
                  stop_after_commit = true
                  {events: [], blobs: {}, data: projection}
                else
                  # This call must return a fresh validated observation, never
                  # a cached population, caller JSON or a manifest boolean.
                  payload = scope_observer_for(params.fetch("mapping_id")).closed_observation_for_proof!(lineage, events: events)
                  expected = binding.slice("scope_generation", "boot_id", "slice_invocation_id", "cgroup_identity").merge(
                    "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "seal_event_id" => lineage.seal_event.fetch("digest"), "populated" => 0)
                  unless payload == expected
                    raise AttemptErrors::EvidenceUnavailable, "fresh observation does not name the retained sealed parent"
                  end
                  at = Time.now.utc
                  event = Models::EvidenceEvent.build(type: "scope_closed_no_writers", attempt_id: params.fetch("attempt_id"),
                    payload: payload, previous_digest: events.last&.fetch("digest"), recorded_at: at)
                  {events: [{type: "scope_closed_no_writers", payload: payload, recorded_at: at}], blobs: {},
                    data: projection.merge("state" => "closed_no_writers", "proof_id" => event.fetch("digest"), "required_action" => nil)}
                end
              end
            end
            if !result.fetch(:replayed) && stop_after_commit
              scope_observer_for(params.fetch("mapping_id")).stop_sealed_service!
            end
            result
          end
        end

        def observe_execution_scope!(params:, peer:, role:)
          strict!(params, %w[mapping_id assignment_id attempt_id])
          %w[assignment_id attempt_id].each { |key| token!(params.fetch(key)) }
          @kernel.live!(peer)
          map = @deployment.mapping(params.fetch("mapping_id"))
          journal = journal_for(map)
          with_exclusion(params, map, journal) do
            @mutex.synchronize do
              commit = journal.ref_value
              events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              lineage = scope_close_owner!(params, map, events, peer, role)
              projection = {"attempt_id" => params.fetch("attempt_id"), "scope_generation" => lineage.binding&.fetch("scope_generation"),
                "state" => "unverifiable", "proof_id" => nil, "required_action" => "inspect_exact_scope",
                "generation" => journal.authority_generation(events), "journal_commit" => commit}
              return projection unless lineage.binding
              begin
                observation = scope_observer_for(params.fetch("mapping_id")).observe(lineage)
                if lineage.proof_event
                  scope_observer_for(params.fetch("mapping_id")).verify_closed!(lineage)
                  projection.merge("state" => "closed_no_writers", "proof_id" => lineage.proof_id, "required_action" => nil)
                elsif lineage.sealed? && observation.fetch("populated").zero?
                  projection.merge("required_action" => "close_scope")
                else
                  projection.merge("state" => "running", "required_action" => "close_scope")
                end
              rescue Ace::Runtime::RuntimeUnavailableError, AttemptErrors::EvidenceUnavailable
                projection
              end
            end
          end
        end

        private

        def scope_close_owner!(params, map, events, peer, role)
          state = states(events)[params.fetch("attempt_id")]
          unless state && state["mapping_id"] == params.fetch("mapping_id") &&
              (role == :supervisor || role == :launcher && @kernel.same?(state.fetch("launcher_identity"), peer))
            raise AttemptErrors::UnauthorizedIdentity, "scope closure requires the original launch owner"
          end
          Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
        end
      end
    end
  end
end
