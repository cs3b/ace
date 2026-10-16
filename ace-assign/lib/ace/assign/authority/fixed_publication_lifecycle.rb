# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      module FixedPublicationLifecycle
        def publication_executor_identity?(project:, uid:)
          service_project!(project).fetch("service_executor_uids").include?(uid)
        end

        def with_publication_hitl!(binding:, project:, peer:)
          params = binding.slice("mapping_id", "assignment_id", "attempt_id", "request_id", "claim_binding", "input_digest", "candidate_generation", "head")
          map = service_mapping!(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "publication project differs" unless map.fetch("project_id") == project
          with_service_scope(params: params, map: map) do |journal, _registration|
            service_journal!(journal)
            record = publication_record!(journal, params, map, peer, :executor)
            unless record["dispatch_phase"] == "otp_pending" && record["publication_challenge_digest"] == binding.fetch("challenge_digest")
              raise AttemptErrors::Conflict, "publication HITL challenge is no longer pending"
            end
            ServiceEvidence.new(journal: journal).publication_challenge!(record)
            selection = settlement_immutable({"executor_process_binding" => record.fetch("executor_process_binding"),
              "challenge_ref" => record.fetch("publication_challenge_ref").fetch("ref")})
            yield selection
          end
        end

        def authorize_publication_update!(journal:, existing:, replacement:, pending:)
          operation = pending.fetch(:operation)
          allowed = ServicePublicationEvidence::PUBLICATION_FIELDS + ["dispatch_phase"]
          unless existing.except(*allowed) == replacement.except(*allowed) && existing["state"] == "uncertain"
            raise AttemptErrors::InvalidState, "publication transition changed original binding"
          end
          owner = ServiceEvidence.new(journal: journal)
          if operation == "publication_challenge"
            unless %w[dispatch_started issuing].include?(existing["dispatch_phase"]) && replacement["dispatch_phase"] == "otp_pending" &&
                replacement["publication_issuing_event_digest"] == existing["publication_issuing_event_digest"]
              raise AttemptErrors::InvalidState, "publication need has no source-owned rejected push"
            end
            need = owner.publication_challenge!(replacement, pending: pending)
            unless need["previous_challenge_digest"] == existing["publication_challenge_digest"]
              raise AttemptErrors::InvalidState, "publication need predecessor differs"
            end
          elsif operation == "publication_continue"
            unless existing["dispatch_phase"] == "otp_pending" && replacement["dispatch_phase"] == "issuing" &&
                (allowed - %w[dispatch_phase publication_issuing_event_digest]).all? { |key| existing[key] == replacement[key] }
              raise AttemptErrors::InvalidState, "publication continuation is not a unique pending challenge"
            end
            owner.publication_challenge!(replacement, pending: pending)
            events = pending.fetch(:current_events) + pending.fetch(:pending_events)
            event = events.find { |row| row["digest"] == replacement["publication_issuing_event_digest"] }
            unless event && event["type"] == "service_publication_issuing" &&
                %w[request_id input_digest claim_binding publication_challenge_digest].all? { |key| event.dig("payload", key) == replacement[key] }
              raise AttemptErrors::EvidenceUnavailable, "publication issuing event is unavailable"
            end
          else
            raise AttemptErrors::InvalidState, "publication transition has no fixed source owner"
          end
          true
        end

        def publication_record!(journal, params, map, peer, role, events: nil)
          record = journal.service_request(params.fetch("request_id"))
          unless record && record["operation"] == "publish" && record["state"] == "uncertain" &&
              %w[dispatch_started otp_pending issuing].include?(record["dispatch_phase"]) &&
              %w[claim_binding input_digest candidate_generation].all? { |key| record[key] == params[key] } &&
              record["candidate_head"] == params["head"] && record["mapping_id"] == params["mapping_id"]
            raise AttemptErrors::Conflict, "publication original tuple or phase differs"
          end
          service_executor!(peer, role, record)
          service_ticket!(record, params, map, peer)
          events ||= attempt_events(journal, params)
          current = exact_candidate!(candidate(events), params)
          origin = service_origin!(events, params)
          service_worker!(record.fetch("worker_process_binding"), :worker, map, origin)
          service_review!(journal, events, params, map, current)
          service_scope_open!(events: events, params: params, map: map)
          service_policy!.authorize!(record)
          ServiceEvidence.new(journal: journal).context(record)
          record
        end

        def authorize_publication_transfer!(request, params, map, peer, role)
          with_service_scope(params: params, map: map) do |journal, _registration|
            service_journal!(journal)
            publication_record!(journal, params, map, peer, role)
          end
          true
        end

        def dispatch_publication(request, params, map, peer, role, transfer)
          authorize_publication_transfer!(request, params, map, peer, role)
          challenge = request.fetch("operation") == "publication_challenge"
          bytes = nil
          if challenge
            unless transfer && transfer.count == 1
              raise ArgumentError, "publication need requires one bounded artifact"
            end
            bytes = transfer.bytes.dup.freeze
            unless Digest::SHA256.hexdigest(bytes) == params.fetch("receipt_sha256")
              raise AttemptErrors::ReceiptRejected, "publication need transfer digest differs"
            end
          elsif transfer
            raise ArgumentError, "publication continuation forbids upload"
          end
          with_service_scope(params: params, map: map) do |journal, _registration|
            publication_record!(journal, params, map, peer, role)
            result = journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: request.fetch("operation"),
              parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: params.fetch("expected_generation"),
              with_replay: true) do |events, _commit, generation|
              record = publication_record!(journal, params, map, peer, role, events: events)
              if challenge
                publication_challenge_plan(journal, events, record, params, bytes, generation)
              else
                publication_continue_plan(journal, events, record, params, generation)
              end
            end
            if !challenge && result.fetch(:replayed)
              result = result.merge(data: result.fetch(:data).merge("invocation" => "already_issued"))
            end
            result
          end
        end

        def publication_challenge_plan(journal, events, record, params, bytes, generation)
          owner = ServiceEvidence.new(journal: journal)
          digest = Digest::SHA256.hexdigest(bytes)
          if record["dispatch_phase"] == "otp_pending"
            owner.publication_challenge!(record)
            raise AttemptErrors::Conflict, "publication pending challenge differs" unless record["publication_challenge_digest"] == digest
            return {data: service_projection(record).merge("challenge" => "retained")}
          end
          unless %w[dispatch_started issuing].include?(record["dispatch_phase"])
            raise AttemptErrors::InvalidState, "publication has no rejected push"
          end
          previous = record["publication_challenge_digest"]
          owner.publication_challenge!(record) if previous
          owner.publication_need!(bytes, record, previous: previous)
          payload = record.slice("request_id", "input_digest", "claim_binding").merge(
            "challenge_digest" => digest, "previous_challenge_digest" => previous, "generation" => generation + 1)
          time = Time.now.utc
          event = Models::EvidenceEvent.build(type: "service_publication_challenge", attempt_id: record.fetch("attempt_id"),
            payload: payload, previous_digest: events.last&.fetch("digest"), recorded_at: time)
          plan = Molecules::CanonicalEvidence.new(journal: journal).import_plan(**owner.context(record),
            artifacts: [bytes], admitted_after_event_digest: event.fetch("digest"))
          replacement = record.merge("dispatch_phase" => "otp_pending", "publication_challenge_digest" => digest,
            "publication_challenge_ref" => plan.fetch(:references).fetch(0),
            "publication_challenge_event_digest" => event.fetch("digest"), "publication_challenge_generation" => generation + 1)
          plan.merge(events: [{type: "service_publication_challenge", payload: payload, recorded_at: time}] + plan.fetch(:events),
            data: service_projection(replacement).merge("challenge" => "created"), service_updates: [{request_id: record.fetch("request_id"),
              expected: record, replacement: replacement, event_type: "service_transition"}])
        end

        def publication_continue_plan(journal, events, record, params, generation)
          ServiceEvidence.new(journal: journal).publication_challenge!(record)
          unless record["publication_challenge_digest"] == params.fetch("challenge_digest")
            raise AttemptErrors::Conflict, "publication continuation challenge differs"
          end
          if record["dispatch_phase"] == "issuing"
            return {data: service_projection(record).merge("invocation" => "already_issued")}
          end
          raise AttemptErrors::InvalidState, "publication is not pending" unless record["dispatch_phase"] == "otp_pending"
          payload = record.slice("request_id", "input_digest", "claim_binding", "publication_challenge_digest").merge("generation" => generation + 1)
          time = Time.now.utc
          event = Models::EvidenceEvent.build(type: "service_publication_issuing", attempt_id: record.fetch("attempt_id"),
            payload: payload, previous_digest: events.last&.fetch("digest"), recorded_at: time)
          replacement = record.merge("dispatch_phase" => "issuing", "publication_issuing_event_digest" => event.fetch("digest"))
          {events: [{type: "service_publication_issuing", payload: payload, recorded_at: time}],
            data: service_projection(replacement).merge("invocation" => "permitted"), service_updates: [{request_id: record.fetch("request_id"),
              expected: record, replacement: replacement, event_type: "service_transition"}]}
        end
      end
    end
  end
end
