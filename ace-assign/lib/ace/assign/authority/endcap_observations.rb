# frozen_string_literal: true
require_relative "native_observation"

module Ace
  module Assign
    module Authority
      class Endcap
        OBSERVATION_BINDING_FIELDS = %w[project_id mapping_id assignment_id attempt_id event_id inbox_context_id registration claim_generation native_binding codex_submission codex_receipt runtime_id runtime_binding native_event_digest observer_uid].freeze
        def authorize_observation!(request:, peer:, role:)
          params, map = observation_request!(request)
          with_inbox_context(params, map, mutation_id: request["mutation_id"] || "observation-query") do
            @launch.with_assignment(params: params, map: map) do |journal, _|
              protected_journal!(journal)
              selected = observation_selection!(journal, attempt_events(journal, params), params, map, peer, role, request.fetch("operation"))
              observation_fetch!(journal, attempt_events(journal, params), params, map, selected, peer, role) if request.fetch("operation") == "fetch_observation"
            end
          end
          true
        end

        def dispatch_observation(request:, peer:, role:, transfer:)
          params, map = observation_request!(request)
          if request.fetch("operation") == "import_observation"
            raise ArgumentError, "observation requires one bounded transfer" unless transfer && transfer.count == 1
            bytes = transfer.bytes
            raise ArgumentError, "observation transfer digest differs" unless bytes.bytesize.between?(1, 65_536) && Digest::SHA256.hexdigest(bytes) == params.fetch("observation_sha256")
          elsif transfer
            raise ArgumentError, "observation fetch forbids upload"
          end
          with_inbox_context(params, map, mutation_id: request["mutation_id"] || "observation-query") do
            @launch.with_assignment(params: params, map: map) do |journal, _|
              protected_journal!(journal)
              events = attempt_events(journal, params)
              selected = observation_selection!(journal, events, params, map, peer, role, request.fetch("operation"))
              if request.fetch("operation") == "fetch_observation"
                next observation_fetch!(journal, events, params, map, selected, peer, role)
              end
              snapshot = selected.fetch(:snapshot)
              observation = NativeObservation.decode!(bytes, snapshot: snapshot, runtime: selected.fetch(:runtime))
              result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: request.fetch("mutation_id"), operation: "import_observation", parameters_digest: Atoms::EvidenceDigest.digest(params),
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |fresh, commit, _generation|
                current = observation_selection!(journal, fresh, params, map, peer, role, "import_observation")
                raise AttemptErrors::Conflict, "observation current snapshot changed" unless current == selected
                retained = fresh.select { |event| event["type"] == "native_observation" && event.dig("payload", "event_id") == params.fetch("event_id") &&
                  event.dig("payload", "claim_generation") == snapshot.fetch("claim_generation") }
                if !retained.empty?
                  raise AttemptErrors::EvidenceUnavailable, "ambiguous canonical observation" unless retained.one?
                  payload = retained.first.fetch("payload")
                  raw = verified_observation!(journal, fresh, payload, params, map, commit: commit)
                  unless raw == bytes && payload.fetch("binding") == observation_import_binding(params, map, selected, peer)
                    raise AttemptErrors::Conflict, "positive observation already differs for current claim"
                  end
                  next({data: observation_import_projection(payload)})
                end
                binding = observation_import_binding(params, map, selected, peer)
                plan = Molecules::CanonicalEvidence.new(journal: journal).import_plan(**observation_evidence_context(binding),
                  admitted_after_event_digest: fresh.last.fetch("digest"), artifacts: [bytes])
                ref = plan.fetch(:references).first
                payload = {"version" => 1, "event_id" => params.fetch("event_id"), "claim_generation" => observation.fetch("claim_generation"),
                  "outcome" => observation.fetch("outcome"), "binding" => binding,
                  "reference" => ref, "evidence_id" => ref.fetch("ref").delete_prefix("evidence/imports/")}
                # Recheck the protected event after constructing the immutable import plan.
                raise AttemptErrors::Conflict, "observation changed before import" unless selected.fetch(:box).retained_status(event: params.fetch("event_id")) == snapshot
                {data: observation_import_projection(payload), blobs: plan.fetch(:blobs),
                  events: plan.fetch(:events) + [{type: "native_observation", payload: payload}]}
              end
              final = attempt_events(journal, params)
              payload = final.find { |event| event["type"] == "native_observation" && event.dig("payload", "evidence_id") == result.dig(:data, "evidence_id") }&.fetch("payload")
              raise AttemptErrors::EvidenceUnavailable, "canonical observation import reply missing" unless payload
              verified_observation!(journal, final, payload, params, map, commit: journal.ref_value)
              result
            end
          end
        rescue Ace::Herdr::Error, Ace::Runtime::RuntimeUnavailableError, KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "canonical observation is unavailable"
        end

        private

        def observation_request!(request)
          operation, params = request.values_at("operation", "params")
          unless %w[import_observation fetch_observation].include?(operation) && params.is_a?(Hash) && params.keys.sort == PARAMETERS.fetch(operation).sort
            raise ArgumentError, "invalid observation parameters"
          end
          %w[mapping_id assignment_id attempt_id event_id inbox_context_id].each { |key| result_id!(params[key]) }
          if operation == "import_observation"
            result_id!(request.fetch("mutation_id"))
            unless inbox_registration?(params["expected_registration"]) && params["expected_registration"].values_at("event_id", "attempt_id") == params.values_at("event_id", "attempt_id") &&
                params["expected_generation"].is_a?(Integer) && params["expected_generation"] >= 0 && params["observation_sha256"].is_a?(String) && DIGEST.match?(params["observation_sha256"])
              raise ArgumentError, "observation registration or digest differs"
            end
          else
            result_id!(params["evidence_id"])
            raise ArgumentError, "observation fetch is read-only" unless request["mutation_id"].nil?
          end
          map = @deployment.mapping(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "observation project differs" unless map.fetch("project_id") == request.fetch("project_id")
          [params, map]
        end

        def observation_selection!(journal, events, params, map, peer, role, operation)
          retained_origin(events, params)
          @kernel.live!(peer)
          context = @deployment.inbox_context(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          project = @deployment.project(map.fetch("project_id"))
          credential = project.fetch("peer_credentials")[peer.fetch("uid").to_s]
          unless credential && peer.values_at("gid", "groups") == credential.values_at("gid", "groups") &&
              (role == :observer && context.fetch("observer_uids").include?(peer.fetch("uid")) ||
               operation == "fetch_observation" && (role == :signer && context.fetch("signer_uids").include?(peer.fetch("uid")) ||
                 role == :supervisor && context.fetch("supervisor_uids").include?(peer.fetch("uid"))))
            raise AttemptErrors::UnauthorizedIdentity, "observation requires fixed exact reader/observer principal"
          end
          box, registration, lineage = inbox_environment(events, params, map)
          snapshot = box.retained_status(event: params.fetch("event_id"))
          runtimes = context.fetch("runtime_bindings").select do |_id, runtime|
            runtime.values_at("assignment_id", "attempt_id") == params.values_at("assignment_id", "attempt_id") &&
              runtime.fetch("native_target") == snapshot.fetch("binding").slice(*ObservationTrust::TARGET)
          end
          raise AttemptErrors::EvidenceUnavailable, "observation runtime selection is absent or ambiguous" unless runtimes.one?
          runtime_id, runtime = runtimes.first
          if operation == "import_observation" && runtime.fetch("observer_uid") != peer.fetch("uid")
            raise AttemptErrors::UnauthorizedIdentity, "observer does not own exact runtime"
          end
          @kernel.live!(runtime.fetch("runtime_process_binding"))
          unless runtime.fetch("runtime_process_binding").fetch("uid") != map.fetch("worker_uid")
            raise AttemptErrors::EvidenceUnavailable, "worker runtime cannot produce trusted observation"
          end
          {box: box, snapshot: snapshot, registration: registration, runtime_id: runtime_id, runtime: runtime,
            native_event_digest: lineage.native_event.fetch("digest")}
        rescue KeyError, TypeError, Ace::Herdr::Error, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "observation trust or current registration unavailable"
        end

        def observation_import_binding(params, map, selected, peer)
          {"project_id" => map.fetch("project_id"), "mapping_id" => params.fetch("mapping_id"), "assignment_id" => params.fetch("assignment_id"),
            "attempt_id" => params.fetch("attempt_id"), "event_id" => params.fetch("event_id"), "inbox_context_id" => params.fetch("inbox_context_id"),
            "registration" => selected.fetch(:registration), "claim_generation" => selected.fetch(:snapshot).fetch("claim_generation"),
            "native_binding" => selected.fetch(:snapshot).fetch("binding"),
            "codex_submission" => selected.fetch(:snapshot).fetch("codex_submission"), "codex_receipt" => selected.fetch(:snapshot).fetch("codex_receipt"), "runtime_id" => selected.fetch(:runtime_id),
            "runtime_binding" => selected.fetch(:runtime), "native_event_digest" => selected.fetch(:native_event_digest), "observer_uid" => peer.fetch("uid")}
        end

        def observation_evidence_context(binding)
          {kind: "observation", project_id: binding.fetch("project_id"), assignment_id: binding.fetch("assignment_id"),
            attempt_id: binding.fetch("attempt_id"), peer_uid: binding.fetch("observer_uid"), binding: binding,
            request_id_or_event_id: binding.fetch("event_id"), generation: binding.fetch("claim_generation")}
        end

        def observation_import_projection(payload)
          payload.slice("evidence_id", "event_id", "claim_generation", "outcome", "reference", "binding")
        end

        def verified_observation!(journal, events, payload, params, map, commit:)
          binding = payload.fetch("binding")
          unless payload.keys.sort == %w[binding claim_generation event_id evidence_id outcome reference version] && payload["version"] == 1 &&
              binding.is_a?(Hash) && binding.keys.sort == OBSERVATION_BINDING_FIELDS.sort &&
              payload["outcome"] == "consumed" && payload["event_id"] == params.fetch("event_id") &&
              binding.values_at("project_id", "mapping_id", "assignment_id", "attempt_id", "inbox_context_id", "event_id") ==
                [map.fetch("project_id"), *params.values_at("mapping_id", "assignment_id", "attempt_id", "inbox_context_id", "event_id")] &&
              payload["claim_generation"] == binding.fetch("claim_generation") && payload.dig("reference", "ref") == "evidence/imports/#{payload.fetch('evidence_id')}"
            raise AttemptErrors::EvidenceUnavailable, "observation canonical record differs"
          end
          Molecules::CanonicalEvidence.new(journal: journal).read(payload.fetch("reference"), **observation_evidence_context(binding), commit: commit)
        end

        def observation_fetch!(journal, events, params, map, selected, peer, role)
          records = events.select { |event| event["type"] == "native_observation" && event.dig("payload", "evidence_id") == params.fetch("evidence_id") }
          raise AttemptErrors::NotFound, "observation evidence missing" unless records.one?
          payload = records.first.fetch("payload")
          binding = payload.fetch("binding")
          if role == :observer && binding.fetch("observer_uid") != peer.fetch("uid")
            raise AttemptErrors::UnauthorizedIdentity, "observer cannot fetch another observer import"
          end
          unless binding.fetch("registration") == selected.fetch(:registration) && binding.fetch("runtime_binding") == selected.fetch(:runtime) &&
              binding.fetch("runtime_id") == selected.fetch(:runtime_id) && binding.fetch("native_event_digest") == selected.fetch(:native_event_digest)
            raise AttemptErrors::EvidenceUnavailable, "observation retained trust binding changed"
          end
          commit = journal.ref_value
          bytes = verified_observation!(journal, events, payload, params, map, commit: commit)
          snapshot = selected.fetch(:snapshot)
          eligible = payload.fetch("claim_generation") == snapshot.fetch("claim_generation")
          # Historical bytes remain verifiable, but cannot authorize the new claim.
          historical = snapshot.merge("claim_generation" => payload.fetch("claim_generation"), "binding" => binding.fetch("native_binding"),
            "codex_submission" => binding.fetch("codex_submission"), "codex_receipt" => binding.fetch("codex_receipt"))
          NativeObservation.decode!(bytes, snapshot: eligible ? snapshot : historical, runtime: selected.fetch(:runtime))
          raise AttemptErrors::Conflict, "observation snapshot changed during fetch" unless selected.fetch(:box).retained_status(event: params.fetch("event_id")) == snapshot
          descriptor = events.find { |event| event["type"] == "evidence_import" && event.dig("payload", "artifact_id") == params.fetch("evidence_id") }.fetch("payload")
          {data: {"descriptor" => descriptor, "binding" => binding, "journal_commit" => commit,
            "generation" => journal.authority_generation(events), "current_claim_generation" => snapshot.fetch("claim_generation"), "eligible" => eligible},
            replayed: false, transfer_parts: [bytes]}
        end
      end
    end
  end
end
