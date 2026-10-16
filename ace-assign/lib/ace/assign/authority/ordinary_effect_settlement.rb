# frozen_string_literal: true

require_relative "service_evidence"
require_relative "../molecules/ordinary_merge_contract"

module Ace
  module Assign
    module Authority
      # Completion reads the existing effect owners at the held CAS prefix.
      # A prompt, acknowledgment or failed dispatch never settles an effect.
      class OrdinaryEffectSettlement
        def initialize(journal:)
          @journal = journal
        end

        def verify!(project:, assignment:, attempt:, events:, commit:)
          retained = @journal.read_events(assignment, commit: commit).select { |event| event["attempt_id"] == attempt }
          unless retained == events && Models::EvidenceEvent.chain_valid?(events)
            unavailable!("ordinary settlement needs its exact canonical attempt")
          end
          selection = {"project_id" => project, "assignment_id" => assignment, "attempt_id" => attempt}
          services = records!(@journal.service_request_records(commit: commit), events, selection, %w[service_claim service_transition])
          merges = records!(@journal.fixed_merge_request_records(commit: commit), events, selection, %w[merge_admission merge_transition])
          services.each { |record| service!(record, commit) }
          merges.each { |record| merge!(record, commit) }
          assignment_events = @journal.read_events(assignment, commit: commit)
          assignment_events.group_by { |event| event.fetch("attempt_id") }.each_value do |chain|
            unavailable!("ordinary delivery history is corrupt") unless Models::EvidenceEvent.chain_valid?(chain)
          end
          delivery!(events, merges, assignment_events)
          {"journal_commit" => commit, "service_requests" => services.map { |record| record.fetch("request_id") }.sort,
            "merge_requests" => merges.map { |record| record.fetch("request_id") }.sort}
        end

        private

        def records!(inventory, events, selection, types)
          records = inventory.select { |record| record.values_at("assignment_id", "attempt_id") == selection.values_at("assignment_id", "attempt_id") }
          references = events.select { |event| types.include?(event["type"]) }
          ids = references.map { |event| event.fetch("payload").fetch("request_id") }.uniq.sort
          unless records.map { |record| record.fetch("request_id") }.sort == ids
            unavailable!("ordinary effect inventory and event set differ")
          end
          records.each do |record|
            latest = references.reverse.find { |event| event.dig("payload", "request_id") == record.fetch("request_id") }
            unless record.slice(*selection.keys) == selection && latest.dig("payload", "state") == record["state"] &&
                latest.dig("payload", "record_digest") == Atoms::EvidenceDigest.digest(record) &&
                latest.dig("payload", "receipt_digest") == (record["receipt"] && Atoms::EvidenceDigest.digest(record["receipt"]))
              unavailable!("ordinary effect record differs from its accepted owner event")
            end
          end
          records
        end

        def service!(record, commit)
          return if record["state"] == "rejected" && record["consumed"] == false
          pending!("ordinary service effect is unresolved") unless %w[succeeded failed-settled].include?(record["state"])
          receipt = record.fetch("receipt")
          @journal.validate_terminal_receipt_structure!(record, record.fetch("state"), receipt)
          # The installed owner consumes the existing canonical import, never
          # the old local receipt file. This is independent of journal mode.
          owner = ServiceEvidence.new(journal: @journal)
          references = receipt.fetch("evidence")
          if %w[publish prune-preserved-workspace].include?(record["operation"])
            contents = owner.call(references, record, record.fetch("state"), {commit: commit})
            unless contents.is_a?(Array) && contents.size == references.size
              unavailable!("ordinary service evidence collection differs")
            end
          else
            contents = references.map { |reference| owner.call(reference, record, record.fetch("state"), {commit: commit}) }
          end
          references.zip(contents).each do |reference, bytes|
            unavailable!("ordinary service evidence digest differs") unless bytes.is_a?(String) && Digest::SHA256.hexdigest(bytes.b) == reference.fetch("sha256")
            @journal.verify_service_attestation!(bytes, record, record.fetch("state")) unless %w[publish prune-preserved-workspace].include?(record["operation"])
          end
        end

        def merge!(record, commit)
          unless @journal.fixed_merge_settlement!(record.fetch("request_id"), commit: commit) == record
            unavailable!("ordinary merge settlement differs from its selected record")
          end
        end

        def delivery!(events, merges, assignment_events)
          deliveries = assignment_events.select { |event| event["type"] == "delivery" }
          events.select { |event| event["type"] == "delivery" }.each do |intent|
            payload = intent.fetch("payload")
            case payload["stage"]
            when "intent"
              settled = deliveries.any? { |event| event.dig("payload", "stage") == "result" &&
                event.dig("payload", "intent_digest") == intent.fetch("digest") &&
                event.dig("payload", "intent_attempt_id") == intent.fetch("attempt_id") &&
                event.dig("payload", "operation") == payload.fetch("operation") &&
                event.dig("payload", "head") == payload.fetch("head") && event.dig("payload", "outcome") == "succeeded" }
              pending!("ordinary delivery intent is unresolved") unless settled
            when "ordinary-merge-intent"
              result = deliveries.reverse.find { |event| event.dig("payload", "stage") == "ordinary-merge-result" &&
                event.dig("payload", "request_id") == payload.fetch("request_id") && event.dig("payload", "input_digest") == payload.fetch("input_digest") }
              pending!("ordinary merge delivery is unresolved") unless result
              accepted = result.fetch("payload")
              record = merges.find { |item| item["request_id"] == payload.fetch("request_id") }
              if accepted["outcome"] == "refused_no_effect" && record.nil?
                refusal = accepted.slice("code", "message", "request_id", "input_digest").merge("schema" => "ace.lab.service.ordinary-merge-refusal/v1")
                Molecules::OrdinaryMergeContract.validate_refusal!(refusal)
                pending!("ordinary merge receiver availability is unresolved") if refusal["code"] == Molecules::OrdinaryMergeContract::UNAVAILABLE_CODE
              elsif !record || record["input_digest"] != payload.fetch("input_digest") || record["receipt"] != accepted["receipt"]
                unavailable!("ordinary delivery result differs from the merge owner")
              end
            end
          end
        end

        def unavailable!(message) = raise AttemptErrors::EvidenceUnavailable, message
        def pending!(message) = raise AttemptErrors::ServiceSettlementPending, message
      end
    end
  end
end
