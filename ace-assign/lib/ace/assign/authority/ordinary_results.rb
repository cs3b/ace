# frozen_string_literal: true

require_relative "receipt_transfer"
require_relative "../molecules/canonical_evidence"

module Ace
  module Assign
    module Authority
      # A worker submits an attributable result. This never accepts a terminal
      # outcome, an independent review, or an external delivery effect.
      module OrdinaryResults
        RESULT_OPERATIONS = %w[submit_result submit_review_context result_status result_snapshot].freeze
        RESULT_TRANSFERS = {
          "submit_result" => {direction: :upload, purpose: :receipt_artifacts, roles: %i[worker supervisor]},
          "submit_review_context" => {direction: :upload, purpose: :review_context, roles: %i[worker]},
          "result_snapshot" => {direction: :download, purpose: :receipt_artifacts, roles: %i[worker supervisor]}
        }.freeze
        RESULT_KEYS = %w[assignment_id attempt_id expected_generation pane head receipt_sha256 transfer].freeze
        REVIEW_CONTEXT_KEYS = %w[assignment_id attempt_id expected_generation pane head receipt_sha256 review_id
          producer_assignment_id transfer].freeze

        private

        def validate_result!(request)
          params = request.fetch("params")
          if request.fetch("operation") == "submit_review_context"
            strict!(params, REVIEW_CONTEXT_KEYS)
            token!(request.fetch("mutation_id"))
            unless params.fetch("expected_generation").is_a?(Integer) && params.fetch("expected_generation").positive? &&
                params.fetch("head").is_a?(String) && params.fetch("head").match?(/\A[0-9a-f]{40}\z/) &&
                params.fetch("receipt_sha256").is_a?(String) && params.fetch("receipt_sha256").match?(/\A[0-9a-f]{64}\z/)
              raise ArgumentError, "ordinary review context selection is invalid"
            end
            token!(params.fetch("review_id"))
          elsif request.fetch("operation") != "submit_result"
            snapshot = request.fetch("operation") == "result_snapshot"
            strict!(params, %w[assignment_id attempt_id] + (snapshot ? ["result_id"] : []))
            token!(params.fetch("result_id")) if snapshot
            raise ArgumentError, "ordinary result status mutation must be null" unless request.fetch("mutation_id").nil?
          else
            strict!(params, RESULT_KEYS)
            token!(request.fetch("mutation_id"))
            unless params.fetch("expected_generation").is_a?(Integer) && params.fetch("expected_generation").positive? &&
                params.fetch("head").is_a?(String) && params.fetch("head").match?(/\A[0-9a-f]{40}\z/) &&
                params.fetch("receipt_sha256").is_a?(String) && params.fetch("receipt_sha256").match?(/\A[0-9a-f]{64}\z/)
              raise ArgumentError, "ordinary result selection is invalid"
            end
          end
          %w[assignment_id attempt_id].each { |key| token!(params.fetch(key)) }
        end

        def ordinary_result(request, peer, role, deadline, transfer)
          validate_result!(request)
          params = request.fetch("params")
          commit = @journal.ref_value
          registered = registration(params.fetch("assignment_id"), commit: commit)
          raise AttemptErrors::NotFound, "ordinary work is not registered" unless registered
          if request.fetch("operation") != "submit_result"
            if request.fetch("operation") == "result_status" && @journal.read_events(params.fetch("assignment_id"), commit: commit)
                .none? { |event| event.fetch("attempt_id") == params.fetch("attempt_id") }
              authorize!(request, peer, role, deadline)
              return {data: params.slice("assignment_id", "attempt_id").merge("project_id" => @project,
                "state" => "not_started", "generation" => 0, "submitted_result" => nil), replayed: false}
            end
            events = result_events(params, commit)
            result = retained_ordinary_result(params, events, commit)
            if request.fetch("operation") == "result_snapshot"
              unless result && result.fetch("result_id") == params.fetch("result_id")
                raise AttemptErrors::NotFound, "ordinary exact result is unavailable"
              end
              receipt = result.fetch("receipt")
              canonical = Molecules::CanonicalEvidence.new(journal: @journal)
              parts = [JSON.generate(receipt)] + receipt.fetch("artifacts").map { |artifact|
                canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
                  **ordinary_result_context(result.fetch("binding")), commit: commit)
              }
              authorize!(request, peer, role, deadline)
              return {data: ordinary_result_projection(result).merge("journal_commit" => commit), transfer_parts: parts, replayed: false}
            end
            authorize!(request, peer, role, deadline)
            started = events.find { |event| event["type"] == "process_start" }.fetch("payload")
            scope = events.find { |event| event["type"] == "intent" }.fetch("payload").fetch("scope")
            return {data: {"project_id" => @project, "assignment_id" => params.fetch("assignment_id"), "attempt_id" => params.fetch("attempt_id"),
              "scope" => scope, "producer" => started.slice("actor", "role", "runtime"),
              "runtime_binding" => started.fetch("runtime_binding"),
              "journal_commit" => commit, "generation" => @journal.authority_generation(events),
              "state" => Molecules::CanonicalAttemptState.derive(events), "submitted_result" => result && ordinary_result_projection(result)}, replayed: false}
          end
          unless %i[worker supervisor].include?(role)
            raise AttemptErrors::UnauthorizedIdentity, "ordinary result requires its original worker"
          end
          authorize_start_replay!(request, peer, role, deadline)
          admitted = ReceiptTransfer.decode(input: transfer, receipt_sha256: params.fetch("receipt_sha256"),
            artifact_field: "artifacts", reference_key: "path")
          digest = Atoms::EvidenceDigest.digest({"params" => params, "project_id" => @project, "peer_uid" => peer.fetch("uid")})
          keys = [@exclusion.task_key(registered.fetch("task_id")), @exclusion.assignment_key(params.fetch("assignment_id"))]
          @exclusion.with_shared_multi(keys, deadline: deadline) do
            @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "submit_result", parameters_digest: digest,
              expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
              replay_authorizer: -> { authorize_start_replay!(request, peer, role, deadline) }) do |events, prefix, generation|
              authorize_start_replay!(request, peer, role, deadline)
              unless Molecules::CanonicalAttemptState.derive(events) == "running"
                raise AttemptErrors::Conflict, "ordinary result requires the original running attempt"
              end
              raise AttemptErrors::Conflict, "ordinary attempt already submitted its result" if retained_ordinary_result(params, events, prefix)
              observed = @admission.execution!(peer: peer, pane: params.fetch("pane"), head: params.fetch("head"), deadline: deadline)
              start_replay_owner!(params, observed.fetch(:identity))
              ordinary_result_plan(params, peer, admitted, observed, events, prefix, generation + 1)
            end
          end
        end

        # Closed review_context ingress (Captain decision 2026-10-17): only an
        # actual owner-selected campaign review-collect attempt with a matching
        # canonical begin may upload complete campaign prompts under the shared
        # complete-context cap. Ordinary results keep their small budgets and
        # can never select this larger kind.
        def ordinary_review_context_submission(request, peer, role, deadline, transfer)
          validate_result!(request)
          params = request.fetch("params")
          commit = @journal.ref_value
          registered = registration(params.fetch("assignment_id"), commit: commit)
          raise AttemptErrors::NotFound, "ordinary work is not registered" unless registered
          producer_all = @journal.read_events(params.fetch("producer_assignment_id"), commit: commit)
          selected = ordinary_review_selection!(producer_all, params.fetch("review_id"))
          producer_attempt = selected.dig("payload", "data", "producer_origin", "attempt_id")
          producer_events = producer_all.select { |event| event["attempt_id"] == producer_attempt }
          assigned = selected.fetch("payload").fetch("data")
          unless assigned.values_at("reviewer_assignment_id", "reviewer_attempt_id") ==
              params.values_at("assignment_id", "attempt_id") && assigned["campaign"].is_a?(Hash)
            raise AttemptErrors::ReceiptRejected, "review context belongs to another reviewer attempt"
          end
          begun = producer_events.any? do |event|
            event["type"] == "authority_mutation" && event.dig("payload", "operation") == "campaign_begin" &&
              event.dig("payload", "data", "review_id") == params.fetch("review_id") &&
              event.dig("payload", "data", "campaign_id") == assigned.fetch("campaign").fetch("campaign_id")
          end
          unless begun
            raise AttemptErrors::EvidenceUnavailable, "review context requires its matching canonical campaign begin"
          end
          _producer, reviewer = ordinary_review_origins!(producer_events, commit, assigned, reviewer_running: true)
          authorize_start_replay!(request, peer, role, deadline)
          observed = @admission.execution!(peer: peer, pane: params.fetch("pane"), head: params.fetch("head"), deadline: deadline)
          unless observed.fetch(:identity).runtime_binding == reviewer.fetch("runtime_binding")
            raise AttemptErrors::UnauthorizedIdentity, "review context requires its actual selected reviewer"
          end
          start_replay_owner!(params, observed.fetch(:identity))
          admitted = ReceiptTransfer.decode(input: transfer, receipt_sha256: params.fetch("receipt_sha256"),
            artifact_field: "artifacts", reference_key: "path")
          digest = Atoms::EvidenceDigest.digest({"params" => params, "project_id" => @project, "peer_uid" => peer.fetch("uid")})
          keys = [@exclusion.task_key(registered.fetch("task_id")), @exclusion.assignment_key(params.fetch("assignment_id"))]
          @exclusion.with_shared_multi(keys, deadline: deadline) do
            @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "submit_review_context", parameters_digest: digest,
              expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
              replay_authorizer: -> { authorize_start_replay!(request, peer, role, deadline) }) do |events, prefix, generation|
              authorize_start_replay!(request, peer, role, deadline)
              unless Molecules::CanonicalAttemptState.derive(events) == "running"
                raise AttemptErrors::Conflict, "review context requires the original running reviewer attempt"
              end
              if events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "submit_review_context" }
                raise AttemptErrors::Conflict, "reviewer attempt already submitted its context"
              end
              review = {"review_id" => assigned.fetch("review_id"),
                "campaign" => assigned.fetch("campaign").slice("campaign_id", "round_id", "scope", "execution_id")}
              ordinary_review_context_plan(params, peer, admitted, observed, events, prefix, generation + 1, review)
            end
          end
        end

        def ordinary_review_context_plan(params, peer, admitted, observed, events, commit, generation, review)
          original = admitted.fetch(:receipt)
          original_receipt = Models::ExecutionReceipt.from_h(original)
          unless original_receipt.digest == Atoms::EvidenceDigest.digest(original_receipt.digest_payload)
            raise AttemptErrors::ReceiptRejected, "ordinary original result digest differs"
          end
          identity = observed.fetch(:identity)
          expected_producer = {"actor" => identity.actor, "role" => identity.role, "runtime" => identity.runtime}
          validate_review_context_receipt!(original, expected_producer, review)
          id = SecureRandom.hex(16)
          binding = params.slice("assignment_id", "attempt_id", "head").merge("authority" => "ordinary", "project_id" => @project,
            "result_id" => id, "worker_uid" => peer.fetch("uid"), "producer" => expected_producer,
            "runtime_binding" => identity.runtime_binding, "checkout" => observed.fetch(:checkout),
            "generation" => generation, "uploaded_receipt_sha256" => admitted.fetch(:receipt_sha256),
            "original_receipt_digest" => original_receipt.digest, "review" => review)
          canonical = Molecules::CanonicalEvidence.new(journal: @journal)
          context = ordinary_result_context(binding).merge(kind: "review-context")
          plan = canonical.import_plan(**context, artifacts: admitted.fetch(:artifacts),
            admitted_after_event_digest: events.last.fetch("digest"))
          receipt = original.except("digest", "recorded_at").merge("artifacts" => plan.fetch(:references).map { |reference|
            {"path" => reference.fetch("ref"), "sha256" => reference.fetch("sha256")}
          })
          pending = @journal.send(:chain_mutation_events, params.fetch("attempt_id"), events.last.fetch("digest"), plan.fetch(:events))
          reader = ->(_data, artifact) { canonical.read_pending({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **context, current_events: events, pending_events: pending, blobs: plan.fetch(:blobs), commit: commit) }
          verified = verify_ordinary_result_receipt(params, receipt, binding, commit, reader,
            validator: ->(original, producer) { validate_review_context_receipt!(original, producer, review) })
          if JSON.generate(verified.to_h).bytesize > 16_384
            raise AttemptErrors::ReceiptRejected, "canonical ordinary receipt exceeds its transfer limit"
          end
          payload = {"authority" => "ordinary", "result_id" => id, "binding" => binding, "receipt" => verified.to_h}
          plan.merge(events: plan.fetch(:events) + [{type: "review_context_submitted", payload: payload}],
            data: ordinary_result_projection(payload))
        end

        def validate_review_context_receipt!(receipt, producer, review)
          unless receipt["producer"] == producer && receipt["review"].is_a?(Hash) &&
              receipt["review"].fetch("review_id") == review.fetch("review_id") &&
              receipt["review"].fetch("campaign") == review.fetch("campaign") &&
              receipt["operation"] == "review-collect" &&
              !Molecules::ReceiptVerifier::EXTERNAL_EFFECT_OPERATIONS.include?(receipt["operation"]) &&
              (receipt.keys - Models::ExecutionReceipt.from_h(receipt).to_h.keys).empty?
            raise AttemptErrors::ReceiptRejected, "review context producer or review reference requires its campaign owner"
          end
          true
        end

        def result_events(params, commit)
          events = @journal.read_events(params.fetch("assignment_id"), commit: commit)
            .select { |event| event.fetch("attempt_id") == params.fetch("attempt_id") }
          unless Models::EvidenceEvent.chain_valid?(events) && events.one? { |event| event["type"] == "process_start" }
            raise AttemptErrors::EvidenceUnavailable, "ordinary result attempt evidence is unavailable"
          end
          events
        end

        def ordinary_result_plan(params, peer, admitted, observed, events, commit, generation)
          original = admitted.fetch(:receipt)
          original_receipt = Models::ExecutionReceipt.from_h(original)
          unless original_receipt.digest == Atoms::EvidenceDigest.digest(original_receipt.digest_payload)
            raise AttemptErrors::ReceiptRejected, "ordinary original result digest differs"
          end
          identity = observed.fetch(:identity)
          expected_producer = {"actor" => identity.actor, "role" => identity.role, "runtime" => identity.runtime}
          validate_ordinary_result_receipt!(original, expected_producer)
          id = SecureRandom.hex(16)
          binding = params.slice("assignment_id", "attempt_id", "head").merge("authority" => "ordinary", "project_id" => @project,
            "result_id" => id, "worker_uid" => peer.fetch("uid"), "producer" => expected_producer,
            "runtime_binding" => identity.runtime_binding, "checkout" => observed.fetch(:checkout),
            "generation" => generation, "uploaded_receipt_sha256" => admitted.fetch(:receipt_sha256),
            "original_receipt_digest" => original_receipt.digest)
          canonical = Molecules::CanonicalEvidence.new(journal: @journal)
          plan = admitted.fetch(:artifacts).empty? ? {events: [], blobs: {}, references: []} :
            canonical.import_plan(**ordinary_result_context(binding), artifacts: admitted.fetch(:artifacts),
              admitted_after_event_digest: events.last.fetch("digest"))
          receipt = original.except("digest", "recorded_at").merge("artifacts" => plan.fetch(:references).map { |reference|
            {"path" => reference.fetch("ref"), "sha256" => reference.fetch("sha256")}
          })
          pending = @journal.send(:chain_mutation_events, params.fetch("attempt_id"), events.last.fetch("digest"), plan.fetch(:events))
          reader = ->(_data, artifact) { canonical.read_pending({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **ordinary_result_context(binding), current_events: events, pending_events: pending, blobs: plan.fetch(:blobs), commit: commit) }
          verified = verify_ordinary_result_receipt(params, receipt, binding, commit, reader)
          if JSON.generate(verified.to_h).bytesize > 16_384
            raise AttemptErrors::ReceiptRejected, "canonical ordinary receipt exceeds its transfer limit"
          end
          payload = {"authority" => "ordinary", "result_id" => id, "binding" => binding, "receipt" => verified.to_h}
          plan.merge(events: plan.fetch(:events) + [{type: "result_submitted", payload: payload}],
            data: ordinary_result_projection(payload))
        end

        def ordinary_result_projection(payload)
          payload.slice("result_id").merge(payload.fetch("binding").slice("head", "generation"),
            "receipt_digest" => payload.fetch("receipt").fetch("digest"), "verdict" => payload.fetch("receipt").fetch("verdict"),
            "state" => "running", "authority" => "ordinary")
        end

        def ordinary_result_context(binding)
          {kind: "result", project_id: @project, assignment_id: binding.fetch("assignment_id"), attempt_id: binding.fetch("attempt_id"),
            peer_uid: binding.fetch("worker_uid"), binding: binding, request_id_or_event_id: binding.fetch("result_id"), generation: binding.fetch("generation")}
        end

        def validate_ordinary_result_receipt!(receipt, producer)
          unless receipt["producer"] == producer && (receipt.keys - Models::ExecutionReceipt.from_h(receipt).to_h.keys).empty? &&
              !receipt["campaign"] && !receipt["review"] && receipt["operation"] != "review" &&
              !Molecules::ReceiptVerifier::EXTERNAL_EFFECT_OPERATIONS.include?(receipt["operation"])
            raise AttemptErrors::ReceiptRejected, "ordinary result producer or operation requires another evidence owner"
          end
        end

        def verify_ordinary_result_receipt(params, receipt, binding, commit, reader,
          validator: ->(original, producer) { validate_ordinary_result_receipt!(original, producer) })
          validator.call(receipt, binding.fetch("producer"))
          attempt = @journal.derived_attempts(params.fetch("assignment_id"), commit: commit).find { |item| item.attempt_id == params.fetch("attempt_id") }
          raise AttemptErrors::EvidenceUnavailable, "ordinary result attempt is unavailable" unless attempt
          Array(receipt["artifacts"]).each { |artifact| reader.call(receipt, artifact) }
          Molecules::ReceiptVerifier.new(artifact_reader: reader).verify_result!(receipt,
            attempt: attempt, live_head: binding.fetch("head"), repo_root: @journal.repo_root)
        end

        def retained_ordinary_result(params, events, commit)
          raise AttemptErrors::EvidenceUnavailable, "ordinary result chain is corrupt" unless Models::EvidenceEvent.chain_valid?(events)
          records = events.select { |event| event["type"] == "result_submitted" }
          replies = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "submit_result" }
          return nil if records.empty? && replies.empty?
          unless records.one? && replies.one?
            raise AttemptErrors::EvidenceUnavailable, "ordinary result provenance is missing or duplicated"
          end
          payload = records.first.fetch("payload")
          binding = payload.fetch("binding")
          start = events.find { |event| event["type"] == "process_start" }.fetch("payload")
          unless payload.keys.sort == %w[authority binding receipt result_id] && payload["authority"] == "ordinary" &&
              payload["result_id"].is_a?(String) && payload["result_id"].match?(/\A[0-9a-f]{32}\z/) &&
              binding.keys.sort == %w[assignment_id attempt_id authority checkout generation head original_receipt_digest producer project_id result_id runtime_binding uploaded_receipt_sha256 worker_uid] &&
              binding["authority"] == "ordinary" && binding["result_id"] == payload["result_id"] &&
              binding["head"] == binding.dig("checkout", "head") &&
              binding.values_at("project_id", "assignment_id", "attempt_id", "runtime_binding") ==
              [@project, params.fetch("assignment_id"), params.fetch("attempt_id"), start.fetch("runtime_binding")] &&
              binding.fetch("producer") == start.slice("actor", "role", "runtime") &&
              binding.fetch("worker_uid") == start.dig("runtime_binding", "process_identity", "uid") &&
              payload.fetch("receipt").fetch("producer") == binding.fetch("producer") &&
              replies.first.dig("payload", "data").slice(*ordinary_result_projection(payload).keys) == ordinary_result_projection(payload)
            raise AttemptErrors::EvidenceUnavailable, "ordinary result owner differs"
          end
          canonical = Molecules::CanonicalEvidence.new(journal: @journal)
          reader = ->(_data, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **ordinary_result_context(binding), commit: commit) }
          verify_ordinary_result_receipt(params, payload.fetch("receipt"), binding, commit, reader)
          payload
        end
      end
    end
  end
end
