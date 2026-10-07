# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        private

        def authorize_service_settlement!(request, params, map, peer, role)
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            service_settlement_record!(journal, params, map, peer, role)
          end
          true
        end

        def service_settlement_record!(journal, params, map, peer, role)
          record = journal.service_request(params.fetch("request_id"))
          raise AttemptErrors::NotFound, "canonical service request is missing" unless record
          service_executor!(peer, role, record)
          receiver = service_receiver!(peer, role, map, record.fetch("service_id"))
          credentials = @deployment.project(map.fetch("project_id")).fetch("peer_credentials").fetch(peer.fetch("uid").to_s)
          unless peer["gid"] == credentials.fetch("gid") && peer["groups"] == credentials.fetch("groups") &&
              receiver.fetch("executor_uid") == record.fetch("executor_uid") &&
              %w[assignment_id attempt_id mapping_id].all? { |key| record[key] == params[key] } &&
              record["project_id"] == map.fetch("project_id") && record["candidate_head"] == params.fetch("head") &&
              record["candidate_generation"] == params.fetch("candidate_generation") &&
              %w[issued dispatch_started].include?(record["dispatch_phase"])
            raise AttemptErrors::UnauthorizedIdentity, "original service settlement identity differs"
          end
          # The normal protected binding validates original ticket/claim, even
          # while effect policy, worker liveness or current candidate changed.
          ServiceEvidence.new(journal: journal).context(record)
          record
        rescue KeyError
          raise AttemptErrors::EvidenceUnavailable, "original service settlement binding is incomplete"
        end

        def dispatch_service_settlement(request, params, map, peer, role, transfer)
          authorize_service_settlement!(request, params, map, peer, role)
          completion = request.fetch("operation") == "complete_no_effect"
          admitted = completion && ReceiptTransfer.decode(input: transfer, receipt_sha256: params.fetch("receipt_sha256"),
            artifact_field: "evidence", reference_key: "ref")
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            record = service_settlement_record!(journal, params, map, peer, role)
            no_effect_completion_binding!(record, params, admitted) if completion
            journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: request.fetch("operation"),
              parameters_digest: Atoms::EvidenceDigest.digest(params),
              expected_generation: completion ? nil : params.fetch("expected_generation"),
              generation_mode: completion ? :recorded_completion : :expected, with_replay: true) do |events, commit, generation|
              current = service_settlement_record!(journal, params, map, peer, role)
              if completion
                no_effect_completion_plan(journal, events, current, params, admitted)
              else
                service_challenge_plan(journal, events, current, params, map, generation, commit)
              end
            end
          end
        end

        def service_challenge_projection(record)
          record.slice("request_id", "state", "dispatch_ticket_id", "claim_binding", "dispatch_phase").merge(
            "reconciliation_challenge" => %w[succeeded failed-settled].include?(record.fetch("state")) ? nil :
              record.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest"))
        end

        def service_challenge_plan(journal, events, record, params, map, generation, commit)
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
          unless lineage.sealed? && lineage.binding && record["reservation_generation"] == lineage.binding.fetch("reservation_generation")
            raise AttemptErrors::Conflict, "original service generation is not sealed"
          end
          return {data: service_challenge_projection(record)} if %w[succeeded failed-settled].include?(record.fetch("state"))
          unless %w[uncertain failed].include?(record.fetch("state"))
            raise AttemptErrors::EvidenceUnavailable, "original protected request has no uncertainty outcome"
          end
          if record["challenge_event_digest"]
            begin
              ServiceEvidence.new(journal: journal).challenge!(record, pending: {commit: commit})
              return {data: service_challenge_projection(record)}
            rescue AttemptErrors::EvidenceUnavailable
              # Only a positively authenticated later failure may supersede a
              # challenge. Corrupt/missing old history never becomes freshness.
              old = ServiceEvidence.new(journal: journal).challenge!(record, pending: {commit: commit}, current: false)
              raise unless events.drop_while { |event| event["digest"] != old.fetch("digest") }.drop(1).any? do |event|
                %w[service_claim service_transition].include?(event["type"]) && event.dig("payload", "request_id") == record.fetch("request_id") &&
                  %w[uncertain failed].include?(event.dig("payload", "state"))
              end
            end
          end
          failure = events.reverse.find { |event| %w[service_claim service_transition].include?(event["type"]) &&
            event.dig("payload", "request_id") == record.fetch("request_id") && %w[uncertain failed].include?(event.dig("payload", "state")) }
          raise AttemptErrors::EvidenceUnavailable, "canonical service failure is missing" unless failure
          failure_prefix = events.take_while { |event| event["digest"] != failure.fetch("digest") }
          payload = record.slice("request_id", "input_digest", "claim_binding", "dispatch_ticket_id").merge(
            "version" => 1, "no_effect_challenge" => SecureRandom.hex(16), "challenge_generation" => generation + 1,
            "failure_event_digest" => failure.fetch("digest"), "failure_generation" => journal.authority_generation(failure_prefix) + 1)
          recorded_at = Time.now.utc
          challenge = Models::EvidenceEvent.build(type: "service_no_effect_challenge", attempt_id: params.fetch("attempt_id"),
            payload: payload, previous_digest: events.last&.fetch("digest"), recorded_at: recorded_at)
          replacement = record.merge(payload.slice("no_effect_challenge", "challenge_generation"), "challenge_event_digest" => challenge.fetch("digest"))
          {events: [{type: "service_no_effect_challenge", payload: payload, recorded_at: recorded_at}],
            data: service_challenge_projection(replacement), service_updates: [{request_id: record.fetch("request_id"),
              expected: record, replacement: replacement, event_type: "service_challenge"}]}
        end

        def no_effect_completion_binding!(record, params, admitted)
          selector = params.fetch("reconciliation_challenge")
          unless selector.is_a?(Hash) && selector.keys.sort == %w[no_effect_challenge challenge_generation challenge_event_digest].sort &&
              selector["no_effect_challenge"].is_a?(String) && selector["no_effect_challenge"].match?(/\A[0-9a-f]{32}\z/) &&
              selector["challenge_generation"].is_a?(Integer) && selector["challenge_generation"].positive? &&
              selector["challenge_event_digest"].is_a?(String) && selector["challenge_event_digest"].match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "no-effect challenge selector is malformed"
          end
          unless selector.all? { |key, value| record[key] == value } && record["claim_binding"] == params.fetch("claim_binding")
            raise AttemptErrors::Conflict, "no-effect challenge or claim differs"
          end
          receipt = admitted.fetch(:receipt)
          unless receipt.keys.sort == Molecules::EvidenceJournal::TERMINAL_RECEIPT_FIELDS.sort && receipt["outcome"] == "failed" &&
              Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS.all? { |field| receipt[field] == record[field] }
            raise AttemptErrors::ReceiptRejected, "no-effect receipt original binding differs"
          end
          digest = Atoms::EvidenceDigest.digest("challenge" => selector, "receipt_sha256" => admitted.fetch(:receipt_sha256),
            "artifacts" => admitted.fetch(:artifacts).map { |bytes| Digest::SHA256.hexdigest(bytes) })
          if record["state"] == "succeeded" || record["no_effect_completion_digest"] && record["no_effect_completion_digest"] != digest
            raise AttemptErrors::Conflict, "no-effect completion contradicts retained outcome"
          end
          digest
        end

        def no_effect_completion_plan(journal, events, record, params, admitted)
          digest = no_effect_completion_binding!(record, params, admitted)
          return {data: service_projection(record)} if record["no_effect_completion_digest"]
          owner = ServiceEvidence.new(journal: journal)
          challenge = owner.challenge!(record)
          admitted.fetch(:artifacts).each { |bytes| owner.inspection!(bytes, record, challenge) }
          plan = Molecules::CanonicalEvidence.new(journal: journal).import_plan(**owner.context(record, no_effect: true),
            artifacts: admitted.fetch(:artifacts), admitted_after_event_digest: challenge.fetch("digest"))
          receipt = admitted.fetch(:receipt).merge("evidence" => plan.fetch(:references))
          replacement = record.merge("state" => "failed-settled", "receipt" => receipt, "no_effect_completion_digest" => digest)
          plan.merge(data: service_projection(replacement), service_updates: [{request_id: record.fetch("request_id"),
            expected: record, replacement: replacement, event_type: "service_transition"}])
        end
      end
    end
  end
end
