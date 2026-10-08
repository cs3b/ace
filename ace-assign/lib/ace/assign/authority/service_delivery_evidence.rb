# frozen_string_literal: true
require "ace/git/atoms/service_merge_evidence"
require "ace/git/atoms/service_pr_evidence"
require_relative "service_evidence"

module Ace
  module Assign
    module Authority
      # The existing service completion/import transaction owns delivery writes.
      class ServiceDeliveryEvidence
        def initialize(journal:)
          @journal = journal
        end

        def completion_event(record:, receipt:, completion_digest:, artifacts:)
          unless artifacts.length == 1
            raise AttemptErrors::ReceiptRejected, "merge completion requires its one fixed evidence artifact"
          end
          proof = validate_artifact!(record, artifacts.first)
          {type: "delivery", payload: payload(record, receipt, completion_digest, proof)}
        end

        def verified(record:, events:, commit:)
          unless %w[create update ready merge].include?(record["operation"]) && record["state"] == "succeeded" &&
              record.fetch("receipt").fetch("evidence").length == 1
            raise AttemptErrors::EvidenceUnavailable, "canonical merge completion is unavailable"
          end
          receipt = record.fetch("receipt")
          reference = receipt.fetch("evidence").first
          bytes = Molecules::CanonicalEvidence.new(journal: @journal).read(reference,
            **ServiceEvidence.new(journal: @journal).context(record), commit: commit)
          expected = payload(record, receipt, record.fetch("completion_digest"), validate_artifact!(record, bytes))
          results = events.select { |event| event["type"] == "delivery" && event.dig("payload", "service_request_id") == record.fetch("request_id") }
          unless results.one? && Atoms::EvidenceDigest.digest(results.first.fetch("payload")) == Atoms::EvidenceDigest.digest(expected)
            raise AttemptErrors::EvidenceUnavailable, "canonical merge delivery result differs"
          end
          transitions = events.select { |event| event["type"] == "service_transition" &&
            event.dig("payload", "request_id") == record.fetch("request_id") && event.dig("payload", "state") == "succeeded" &&
            event.dig("payload", "record_digest") == Atoms::EvidenceDigest.digest(record) &&
            event.dig("payload", "receipt_digest") == Atoms::EvidenceDigest.digest(receipt) }
          imports = events.select { |event| event["type"] == "evidence_import" &&
            "evidence/imports/#{event.dig('payload', 'artifact_id')}" == reference.fetch("ref") }
          unless transitions.one? && imports.one?
            raise AttemptErrors::EvidenceUnavailable, "canonical merge completion introduction differs"
          end
          # The first completion's authority mutation immediately follows its
          # terminal transition. Later identical completion observations may
          # have their own mutation IDs; they cannot replace this introduction.
          completion = events[events.index(transitions.first) + 1]
          unless completion && completion["type"] == "authority_mutation" &&
              completion.dig("payload", "operation") == "complete_service" &&
              completion.dig("payload", "data", "request_id") == record.fetch("request_id")
            raise AttemptErrors::EvidenceUnavailable, "original merge completion mutation differs"
          end
          selected = [results.first, transitions.first, completion, imports.first]
          introductions = @journal.event_commits!(assignment_id: record.fetch("assignment_id"),
            event_digests: selected.map { |event| event.fetch("digest") }, commit: commit)
          unless introductions.values.uniq.length == 1
            raise AttemptErrors::EvidenceUnavailable, "merge delivery result was not atomically imported and completed"
          end
          results.first
        rescue KeyError, TypeError, ArgumentError, AttemptErrors::ReceiptRejected
          raise AttemptErrors::EvidenceUnavailable, "canonical merge delivery evidence is unverifiable"
        end

        private

        def validate_artifact!(record, bytes)
          options = {request_id: record.fetch("request_id"), input_digest: record.fetch("input_digest"),
            target: record.fetch("target"), head: record.fetch("candidate_head")}
          proof = if record.fetch("operation") == "merge"
            Ace::Git::Atoms::ServiceMergeEvidence.validate(bytes, **options)
          else
            Ace::Git::Atoms::ServicePrEvidence.validate(bytes, operation: record.fetch("operation"), **options)
          end
          unless Atoms::EvidenceDigest.digest(proof.fetch(:input)) == record.fetch("input_digest")
            raise AttemptErrors::ReceiptRejected, "merge evidence does not reconstruct the originally accepted input"
          end
          proof
        rescue ArgumentError, KeyError
          raise AttemptErrors::ReceiptRejected, "merge evidence original input or outcome differs"
        end

        def payload(record, receipt, completion_digest, proof)
          self.class.payload(record, receipt, completion_digest, proof)
        end

        # Pure result shape shared with the read-only worker consumer. This
        # function creates no evidence or authorization on its own.
        def self.payload(record, receipt, completion_digest, proof)
          {"stage" => "result", "operation" => record.fetch("operation"), "head" => record.fetch("candidate_head"), "outcome" => "succeeded",
            "intent_digest" => nil, "intent_attempt_id" => nil,
            "pr" => proof.fetch(:pr).slice("number", "url", "head_sha", "draft", "state", "merge_commit_sha"),
            "service_request_id" => record.fetch("request_id"), "service_completion_digest" => completion_digest,
            "service_receipt_digest" => Atoms::EvidenceDigest.digest(receipt), "service_evidence" => receipt.fetch("evidence"),
            "producer" => {"actor" => "service:#{record.fetch('executor_uid')}", "role" => "service", "runtime" => "herdr"}}
        end
      end
    end
  end
end
