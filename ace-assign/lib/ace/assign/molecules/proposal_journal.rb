# frozen_string_literal: true

require "securerandom"

module Ace
  module Assign
    module Molecules
      # A decision projection of the existing qjl event chain. No effect
      # executor, extra ref, file registry, or claim ledger lives here.
      module ProposalJournal
        PROPOSAL_REFERENCE = /\Aproposal-[0-9a-f]{24}-r[1-9][0-9]*\z/
        PROPOSAL_BINDING = %w[operation project_id assignment_id attempt_id input_digest target candidate_head caller_uid].freeze

        PROPOSAL_IMMUTABLE = (PROPOSAL_BINDING + %w[schema proposal_id revision revision_id request_id requester content_digest created_at authorization context options recommendation rationale prerequisites lifecycle_request]).freeze

        def proposal_history(id)
          assignment_ids.flat_map do |assignment|
            events = read_events(assignment)
            events.group_by { |event| event["attempt_id"] }.each_value do |chain|
              unless Models::EvidenceEvent.chain_valid?(chain)
                raise AttemptErrors::EvidenceUnavailable, "Proposal evidence chain is corrupt"
              end
            end
            events.select { |event| event["type"] == "proposal_state" && event.dig("payload", "record", "proposal_id") == id }
              .map { |event| event.fetch("payload").fetch("record") }
          end
        end

        def proposal_record(id)
          proposal_history(id).last
        end

        def proposals
          assignment_ids.flat_map do |assignment|
            read_events(assignment).select { |event| event["type"] == "proposal_state" }
              .map { |event| event.dig("payload", "record", "proposal_id") }
          end.uniq.map { |id| proposal_record(id) }
        end

        # Admitted HITL policy runs this block while the same canonical
        # mutation lock/CAS boundary excludes service claims and other replies.
        def change_proposal(id, assignment_id:, attempt_id:, &policy)
          3.times do
            events = read_events(assignment_id).select { |event| event["attempt_id"] == attempt_id }
            generation = events.count { |event| event["type"] == "authority_mutation" }
            begin
              return mutate(assignment_id: assignment_id, attempt_id: attempt_id,
                mutation_id: "proposal-#{SecureRandom.hex(16)}", operation: "proposal-decision",
                parameters_digest: Digest::SHA256.hexdigest(id), expected_generation: generation) do |current, _commit, _generation|
                record = current.reverse.find do |event|
                  event["type"] == "proposal_state" && event.dig("payload", "record", "proposal_id") == id
                end&.dig("payload", "record")
                global = proposal_record(id)
                if global && (global["assignment_id"] != assignment_id || global["attempt_id"] != attempt_id)
                  raise AttemptErrors::ReceiptRejected, "Proposal identity belongs to another assignment or attempt"
                end
                updated = policy.call(record)
                return record if updated == record
                unless updated.is_a?(Hash) && updated["proposal_id"] == id &&
                    updated["assignment_id"] == assignment_id && updated["attempt_id"] == attempt_id
                  raise AttemptErrors::ReceiptRejected, "Proposal policy changed immutable ownership"
                end
                validate_proposal_revision!(record, updated)
                entries = []
                if record.nil? || record["revision_id"] != updated["revision_id"]
                  entries << {type: "proposal_state", payload: {"record" => updated.merge("state" => "proposed")}}
                end
                entries << {type: "proposal_state", payload: {"record" => updated}}
                {events: entries, data: {"record" => updated}}
              end.fetch("record")
            rescue AttemptErrors::Conflict => e
              raise unless e.message == "Authority registration generation changed"
            end
          end
          raise AttemptErrors::EvidenceUnavailable, "Proposal generation stayed conflicting"
        end

        def validate_proposal_revision!(previous, updated)
          if previous && previous["revision_id"] == updated["revision_id"]
            unless PROPOSAL_IMMUTABLE.all? { |field| previous[field] == updated[field] }
              raise AttemptErrors::ReceiptRejected, "Proposal revision content is immutable"
            end
            return
          end
          expected = previous ? previous.fetch("revision") + 1 : 1
          reference = "#{updated.fetch("proposal_id")}-r#{expected}"
          valid = updated["revision"] == expected && updated["revision_id"] == reference &&
            updated["request_id"] == reference && updated["authorization"] == reference &&
            updated["state"] == "awaiting-delivery" && PROPOSAL_REFERENCE.match?(reference)
          if previous
            valid &&= previous["state"] == "superseded" &&
              %w[assignment_id attempt_id project_id requester caller_uid].all? { |field| previous[field] == updated[field] }
          end
          raise AttemptErrors::ReceiptRejected, "Proposal revision must begin with exact immutable delivery scope" unless valid
        end
        private :validate_proposal_revision!

        def proposal_claims(reference)
          service_request_records.select do |request|
            request["authorization"] == reference &&
              !(request["state"] == "rejected" && request["consumed"] == false)
          end
        end

        def proposal_authorize!(reference, binding)
          unless reference.is_a?(String) && PROPOSAL_REFERENCE.match?(reference)
            raise AttemptErrors::ReceiptRejected, "Invalid proposal authorization reference"
          end
          id = reference.sub(/-r[1-9][0-9]*\z/, "")
          record = proposal_record(id)
          unless record && record["revision_id"] == reference &&
              record["stop_requested"] != true &&
              %w[approved-explicitly approved-by-silence].include?(record["state"]) &&
              PROPOSAL_BINDING.all? { |field| record[field] == binding[field] }
            raise AttemptErrors::ReceiptRejected, "Proposal is not authorized for this exact effect"
          end
          attempt = derived_attempts(binding.fetch("assignment_id")).find do |candidate|
            candidate.attempt_id == binding.fetch("attempt_id")
          end
          unless attempt && attempt.state == "running"
            raise AttemptErrors::ReceiptRejected, "Proposal effect needs an authoritative bound running attempt"
          end
          record
        end
      end
    end
  end
end
