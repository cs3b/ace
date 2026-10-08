# frozen_string_literal: true
require_relative "../authority/service_delivery_evidence"
require "ace/git/atoms/service_pr_evidence"

module Ace
  module Assign
    module Organisms
      # Worker consumes only the original authority's canonical completion.
      # No local journal, provider mutation, recovery write or merge retry.
      class ProtectedDeliveryCoordinator
        BASE_FIELDS = %w[request_id assignment_id attempt_id project_id operation service_id target candidate_head
          candidate_generation state dispatch_ticket_id claim_binding claim_generation dispatch_phase policy_digest generation journal_commit].freeze
        COMPLETE_FIELDS = %w[input_digest authorization executor_uid completion_digest receipt delivery_event].freeze

        def initialize(client:, project_id:)
          @client, @project_id = client, project_id
        end

        def perform(assignment_id:, attempt_id:, operation:, service_request_id:, candidate_head:, candidate_generation:,
          input_digest:, target:, parameters: nil, title: nil, body: nil, tests: nil, review: nil)
          unless %w[create update ready merge status].include?(operation) && [title, body, tests, review].all?(&:nil?) &&
              [assignment_id, attempt_id, service_request_id].all? { |value| value.is_a?(String) && value.match?(Molecules::JournalMutation::ID) } &&
              candidate_head.is_a?(String) && candidate_head.match?(/\A[0-9a-f]{40}\z/) &&
              candidate_generation.is_a?(Integer) && candidate_generation.positive? &&
              input_digest.is_a?(String) && input_digest.match?(/\A[0-9a-f]{64}\z/) &&
              target.is_a?(Hash) && target.keys.sort == %w[artifact_digest resource] && target["resource"].is_a?(String) &&
              (target["artifact_digest"].nil? || target["artifact_digest"].is_a?(String) && target["artifact_digest"].match?(/\A[0-9a-f]{64}\z/))
            raise ArgumentError, "protected delivery requires exact canonical merge selectors; local delivery flags are unavailable"
          end
          binding = {"assignment_id" => assignment_id, "attempt_id" => attempt_id,
            "candidate_generation" => candidate_generation, "head" => candidate_head, "request_id" => service_request_id}
          data = @client.call("service_status", binding).data
          unless data.is_a?(Hash) && (data.keys - BASE_FIELDS - COMPLETE_FIELDS).empty? &&
              Atoms::EvidenceDigest.digest(data.slice("assignment_id", "attempt_id", "request_id", "candidate_generation")) == Atoms::EvidenceDigest.digest(binding.except("head")) &&
              data["project_id"] == @project_id && data["candidate_head"] == candidate_head && Atoms::EvidenceDigest.digest(data["target"]) == Atoms::EvidenceDigest.digest(target) &&
              %w[create update ready merge].include?(data["operation"]) && (operation == "status" || data["operation"] == operation) && data["generation"].is_a?(Integer) && data["generation"].positive? &&
              data["input_digest"] == input_digest &&
              data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise AttemptErrors::ReceiptRejected, "original canonical merge status differs"
          end
          if data["state"] != "succeeded"
            return data if operation == "status"
            raise AttemptErrors::EvidenceUnavailable, "original merge is not canonically succeeded; inspect its status without retry"
          end
          unless data.keys.sort == (BASE_FIELDS + COMPLETE_FIELDS).sort && data["input_digest"] == input_digest &&
              data["executor_uid"].is_a?(Integer) && data["executor_uid"].positive? &&
              data["completion_digest"].is_a?(String) && data["completion_digest"].match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::ReceiptRejected, "original canonical completion selectors differ"
          end
          receipt = data.fetch("receipt")
          unless receipt.is_a?(Hash) && receipt.keys.sort == Molecules::EvidenceJournal::TERMINAL_RECEIPT_FIELDS.sort &&
              receipt["outcome"] == "succeeded" && receipt["operation"] == data["operation"] && receipt["transport"] == "unix" &&
              receipt.slice("request_id", "assignment_id", "attempt_id", "project_id", "input_digest", "target", "candidate_head", "executor_uid") ==
                data.slice("request_id", "assignment_id", "attempt_id", "project_id", "input_digest", "target", "candidate_head", "executor_uid") &&
              receipt["evidence"].is_a?(Array) && receipt["evidence"].one?
            raise AttemptErrors::ReceiptRejected, "original canonical merge receipt differs"
          end
          reference = receipt.fetch("evidence").first
          unless reference.is_a?(Hash) && reference.keys.sort == %w[ref sha256] &&
              reference["ref"].is_a?(String) && reference["ref"].match?(%r{\Aevidence/imports/[a-z0-9-]+\z}) &&
              reference["sha256"].is_a?(String) && reference["sha256"].match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::ReceiptRejected, "original canonical artifact reference differs"
          end
          fetched = @client.call("evidence_fetch", {"assignment_id" => assignment_id, "attempt_id" => attempt_id,
            "kind" => "service", "purpose_id" => service_request_id,
            "artifact_id" => reference.fetch("ref").delete_prefix("evidence/imports/")}, download: true, purpose: :artifacts)
          descriptor = fetched.data.fetch("descriptor")
          original_binding = Authority::ServiceEvidence::FIELDS.to_h { |key| [key, receipt.key?(key) ? receipt.fetch(key) : data.fetch(key)] }
          unless Molecules::CanonicalEvidence.valid_descriptor?(descriptor) &&
              descriptor["binding_digest"] == Atoms::EvidenceDigest.digest(original_binding) &&
              descriptor["sha256"] == reference.fetch("sha256") && descriptor["peer_uid"] == data.fetch("executor_uid") &&
              fetched.parts.is_a?(Array) && fetched.parts.one? && fetched.parts.first.is_a?(String) &&
              Digest::SHA256.hexdigest(fetched.parts.first) == reference.fetch("sha256")
            raise AttemptErrors::ReceiptRejected, "original canonical artifact descriptor differs"
          end
          proof_options = {request_id: service_request_id, input_digest: input_digest, target: target, head: candidate_head}
          proof = if data.fetch("operation") == "merge"
            Ace::Git::Atoms::ServiceMergeEvidence.validate(fetched.parts.first, **proof_options)
          else
            Ace::Git::Atoms::ServicePrEvidence.validate(fetched.parts.first, operation: data.fetch("operation"), **proof_options)
          end
          unless Atoms::EvidenceDigest.digest(proof.fetch(:input)) == input_digest &&
              (!parameters || Atoms::EvidenceDigest.digest(Atoms::DeliveryParameters.validate(parameters)) == Atoms::EvidenceDigest.digest(proof.fetch(:input).fetch("delivery")))
            raise AttemptErrors::ReceiptRejected, "canonical merge artifact accepted input differs"
          end
          event = data.fetch("delivery_event")
          expected = Authority::ServiceDeliveryEvidence.payload(data, receipt, data.fetch("completion_digest"), proof)
          unless event.is_a?(Hash) && event.keys.sort == %w[attempt_id digest payload previous_digest recorded_at type] &&
              event["type"] == "delivery" && event["attempt_id"] == attempt_id && Models::EvidenceEvent.valid?(event) &&
              Atoms::EvidenceDigest.digest(event.fetch("payload")) == Atoms::EvidenceDigest.digest(expected)
            raise AttemptErrors::ReceiptRejected, "canonical delivery result/completion/import join differs"
          end
          data
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::ReceiptRejected, "protected merge evidence is malformed or unavailable"
        end
      end
    end
  end
end
