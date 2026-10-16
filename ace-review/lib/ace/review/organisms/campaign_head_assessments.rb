# frozen_string_literal: true

module Ace
  module Review
    module Organisms
      # A head assessment extends one accepted campaign prefix. Only an
      # installed evidence owner can supply the source comparison, supervisor
      # provenance and check receipts. This is the existing campaign history,
      # not another execution or reviewer ledger.
      module CampaignHeadAssessments
        Contract = Atoms::CampaignContract
        SNAPSHOT_PREFIX_FIELDS = %w[assessments attempts execution_attempts head_assessments phases rounds].freeze
        HEAD_PROOF_FIELDS = %w[authority campaign_id checks classification context from predecessor_identity rationale schema to].freeze

        def record_head_assessment(id, input, dry_run: false, consumer_profiles: nil)
          unless @head_assessment_evidence && input.is_a?(Hash) && input.keys.sort == %w[id predecessor reference]
            raise Contract::Invalid, "head assessment requires its canonical evidence owner"
          end
          Contract.id!(input["id"], "head assessment ID")
          Contract.object!(input["reference"], "head assessment reference")
          digest = Contract.digest(input)
          store.transaction(dry_run: dry_run) do
            record = store.read(id)
            if (prior = record.fetch("head_assessments").find { |entry| entry["id"] == input["id"] })
              raise Contract::Invalid, "conflicting head assessment replay" unless prior["input_digest"] == digest
              next projection(record).merge("replayed" => true, "dry_run" => dry_run)
            end
            raise Contract::Invalid, "campaign contract is superseded" if record["successor"]
            verify_consumer_policy!(record, consumer_profiles) if consumer_profiles
            predecessor = input.fetch("predecessor")
            prefix = accepted_snapshot_prefix!(record, predecessor)
            unless SNAPSHOT_PREFIX_FIELDS.all? { |field| prefix.fetch(field).size == record.fetch(field).size }
              raise Contract::Invalid, "head assessment predecessor is not the current campaign prefix"
            end
            verify_retained_acceptance!(prefix, predecessor)
            head, base = current_revisions(record)
            unless clean_candidate? && [head, base] != predecessor.values_at("head", "base")
              raise Contract::Invalid, "head assessment requires a changed clean candidate"
            end
            proof, checks = head_assessment_proof!(record, reference: input.fetch("reference"), predecessor: predecessor,
              head: head, base: base, historical: false)
            event = immutable_projection(input.merge("input_digest" => digest, "proof" => proof, "checks" => checks))
            record.fetch("head_assessments") << event
            store.write(record) unless dry_run
            projection(record).merge("dry_run" => dry_run)
          end
        end

        private

        def head_assessment_proof!(record, reference:, predecessor:, head:, base:, historical:)
          raise Contract::Invalid, "head assessment evidence owner is unavailable" unless @head_assessment_evidence
          proof = @head_assessment_evidence.call(reference, campaign: record.slice("id", "subject", "contract_identity", "policy"),
            predecessor: predecessor, head: head, base: base, historical: historical)
          unless proof.is_a?(Hash) && proof.keys.sort == HEAD_PROOF_FIELDS &&
              proof["schema"] == "ace.review.head-assessment/v1" && proof["campaign_id"] == record.fetch("id") &&
              proof["predecessor_identity"] == predecessor.fetch("result_identity") &&
              proof["from"] == predecessor.slice("head", "base") && proof["to"] == {"head" => head, "base" => base} &&
              proof["authority"].is_a?(Hash) && !proof["authority"].empty? &&
              proof["rationale"].is_a?(String) && proof["rationale"].strip.bytesize.between?(1, 8192) &&
              JSON.generate(proof).bytesize <= 65_536
            raise Contract::Invalid, "canonical head assessment binding differs"
          end
          context = proof["context"]
          unless context.is_a?(Hash) && context.keys.sort == %w[bytes sha256 text_only] &&
              context["sha256"].is_a?(String) && context["sha256"].match?(/\A[0-9a-f]{64}\z/) &&
              context["bytes"].is_a?(Integer) && context["bytes"].between?(1, 64 * 1024 * 1024) &&
              [true, false].include?(context["text_only"])
            raise Contract::Invalid, "complete canonical head context is unavailable"
          end
          # This path carries a prior independent review. Material or uncertain
          # changes need an actually executed delta round through the campaign
          # owner; a classification label cannot replace that review.
          unless proof["classification"] == "nonsemantic" && context["text_only"]
            raise Contract::Invalid, "head change requires independent delta review"
          end
          checks = @evidence.head_checks(proof.fetch("checks"), head: head,
            required: record.fetch("policy").fetch("required_checks"), historical: historical)
          [immutable_projection(proof), immutable_projection(checks)]
        rescue KeyError, TypeError
          raise Contract::Invalid, "canonical head assessment is incomplete"
        end

        def verify_head_carry!(record, head:, base:, historical:)
          current = record
          target_head, target_base = head, base
          first = true
          loop do
            round = current.fetch("rounds").last
            raise Contract::Invalid, "head carry has no independent reviewed round" unless round && round["approval"]
            return true if round.fetch("binding").values_at("head", "base") == [target_head, target_base]
            event = current.fetch("head_assessments").last
            raise Contract::Invalid, "head change has no canonical assessment" unless event
            predecessor = event.fetch("predecessor")
            prefix = accepted_snapshot_prefix!(current, predecessor)
            unless SNAPSHOT_PREFIX_FIELDS.all? { |field|
                prefix.fetch(field).size == current.fetch(field).size - (field == "head_assessments" ? 1 : 0) }
              raise Contract::Invalid, "head assessment no longer follows its accepted prefix"
            end
            proof, checks = head_assessment_proof!(current, reference: event.fetch("reference"), predecessor: predecessor,
              head: target_head, base: target_base, historical: historical || !first)
            unless event.fetch("proof") == proof && event.fetch("checks").map { |check| check.except("execution_proof") } ==
                checks.map { |check| check.except("execution_proof") }
              raise Contract::Invalid, "retained canonical head assessment changed"
            end
            event.fetch("checks").zip(checks).each do |recorded, observed|
              @evidence.verify_execution_linkage!(recorded.fetch("execution_proof"), observed.fetch("execution_proof"))
            end
            current = prefix
            target_head, target_base = predecessor.values_at("head", "base")
            first = false
          end
        rescue KeyError, TypeError
          raise Contract::Invalid, "retained head assessment chain is unavailable"
        end

        def verify_retained_acceptance!(record, result)
          projected = Atoms::CampaignProjection.build(record)
          blockers = projected.fetch("open_findings").any? { |finding| %w[critical high medium].include?(finding["priority"]) }
          unless projected.fetch("search_converged") && !blockers && projected.fetch("recurring_blockers").empty? && !execution_failure(record)
            raise Contract::Invalid, "retained campaign prefix was not accepted"
          end
          record.fetch("attempts").each do |attempt|
            attempt.fetch("sessions").select { |session| session["completed"] }.each do |session|
              @evidence.verify_session_authority(session, head: attempt.fetch("binding").fetch("head"), historical: true)
            end
            @evidence.verify_approval_authority(attempt.fetch("approval"), historical: true) if attempt["approval"]
          end
          verify_head_carry!(record, head: result.fetch("head"), base: result.fetch("base"), historical: true)
        end
      end
    end
  end
end
