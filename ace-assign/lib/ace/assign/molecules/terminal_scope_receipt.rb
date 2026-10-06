# frozen_string_literal: true
require_relative "receipt_verifier"
require_relative "canonical_evidence"

module Ace
  module Assign
    module Molecules
      # Pure reader over already accepted terminal owner evidence. A submitted
      # result alone carries no terminal authority; local filesystem artifacts
      # are never substituted for its imported protected bytes.
      class TerminalScopeReceipt
        BINDING_FIELDS = %w[mapping_id project_id assignment_id attempt_id result_id worker_uid worker_actor
          launch_ticket process_binding head candidate_generation uploaded_receipt_sha256 original_receipt_digest].freeze
        PAYLOAD_FIELDS = %w[version result_id binding uploaded_receipt_sha256 original_receipt_digest receipt_digest receipt artifacts].freeze

        def self.verify!(events:, lineage:, journal:, commit:, mapping:)
          raise AttemptErrors::EvidenceUnavailable, "terminal receipt chain differs" unless Models::EvidenceEvent.chain_valid?(events)
          terminal = events.select { |event| event["type"] == "receipt_accepted" &&
            %w[succeeded failed].include?(event.dig("payload", "receipt", "verdict")) }
          raise AttemptErrors::EvidenceUnavailable, "no unique accepted terminal receipt" unless terminal.size == 1
          accepted = terminal.first
          receipt = accepted.fetch("payload").fetch("receipt")
          before = events.take_while { |event| event.fetch("digest") != accepted.fetch("digest") }
          submitted = before.select { |event| event["type"] == "result_submitted" &&
            event.dig("payload", "receipt_digest") == receipt.fetch("digest") }
          raise AttemptErrors::EvidenceUnavailable, "accepted terminal result provenance differs" unless submitted.size == 1
          payload = submitted.first.fetch("payload")
          binding = payload.fetch("binding")
          reservation = before.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
          origin = reservation.fetch("payload").fetch("data")
          expected = {"mapping_id" => origin.fetch("mapping_id"), "project_id" => mapping.fetch("project_id"),
            "assignment_id" => origin.fetch("assignment_id"), "attempt_id" => accepted.fetch("attempt_id"),
            "worker_uid" => mapping.fetch("worker_uid"), "worker_actor" => mapping.fetch("worker_actor"),
            "launch_ticket" => origin.fetch("launch_ticket"), "process_binding" => lineage.child_event.fetch("payload").fetch("original_process_binding")}
          candidates = before.select { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "submit_candidate" &&
            event.dig("payload", "data", "candidate_generation") == binding.fetch("candidate_generation") }
          candidate = candidates.one? && candidates.first.dig("payload", "data")
          unless payload.keys.sort == PAYLOAD_FIELDS.sort && binding.keys.sort == BINDING_FIELDS.sort &&
              payload["version"] == 1 && expected.all? { |key, value| binding[key] == value } &&
              candidate && candidate["head"] == binding["head"] && receipt["head"] == binding["head"] &&
              payload["result_id"] == binding["result_id"] && payload["uploaded_receipt_sha256"] == binding["uploaded_receipt_sha256"] &&
              payload["original_receipt_digest"] == binding["original_receipt_digest"] &&
              Models::ExecutionReceipt.from_h(payload.fetch("receipt")).digest_payload == Models::ExecutionReceipt.from_h(receipt).digest_payload &&
              (receipt.keys - Models::ExecutionReceipt.from_h(receipt).to_h.keys).empty? &&
              payload["artifacts"] == receipt["artifacts"] &&
              receipt["producer"] == {"actor" => mapping.fetch("worker_actor"), "role" => "worker", "runtime" => "herdr"} &&
              journal.canonical_attempt_state(events) == receipt.fetch("verdict")
            raise AttemptErrors::EvidenceUnavailable, "accepted terminal receipt selectors differ"
          end
          model = Models::ExecutionReceipt.from_h(receipt)
          unless model.digest == Atoms::EvidenceDigest.digest(model.digest_payload) && model.digest == payload.fetch("receipt_digest")
            raise AttemptErrors::EvidenceUnavailable, "accepted terminal receipt digest differs"
          end
          canonical = CanonicalEvidence.new(journal: journal)
          context = {kind: "result", project_id: binding.fetch("project_id"), assignment_id: binding.fetch("assignment_id"),
            attempt_id: binding.fetch("attempt_id"), peer_uid: binding.fetch("worker_uid"), binding: binding,
            request_id_or_event_id: binding.fetch("result_id"), generation: binding.fetch("candidate_generation")}
          reader = ->(_data, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            **context, commit: commit) }
          Array(receipt["artifacts"]).each { |artifact| reader.call(receipt, artifact) }
          intent = before.find { |event| event["type"] == "intent" }
          attempt = journal.send(:build_attempt, binding.fetch("assignment_id"), binding.fetch("attempt_id"),
            intent.fetch("payload"), before, "running")
          verifier = ReceiptVerifier.new(artifact_reader: reader)
          verifier.verify_result!(receipt, attempt: attempt, live_head: binding.fetch("head"), repo_root: journal.repo_root)
          verifier.verify_accepted_evidence!(receipt, live_head: binding.fetch("head"), repo_root: journal.repo_root, historical: true)
          accepted
        rescue KeyError, TypeError, ArgumentError, NoMethodError, AttemptErrors::ReceiptRejected
          raise AttemptErrors::EvidenceUnavailable, "authenticated terminal scope receipt unavailable"
        end
      end
    end
  end
end
