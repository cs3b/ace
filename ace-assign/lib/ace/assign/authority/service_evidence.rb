# frozen_string_literal: true

require_relative "../molecules/canonical_evidence"

module Ace
  module Assign
    module Authority
      # One source-owned context for initial and retained service evidence.
      # The journal supplies the record and transient pending view; callers
      # never supply an alternate reader, artifact path or trusted flag.
      class ServiceEvidence
        FIELDS = (Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS +
          %w[dispatch_ticket_id claim_binding candidate_generation claim_generation policy_digest]).freeze

        def initialize(journal:)
          @journal = journal
          @canonical = Molecules::CanonicalEvidence.new(journal: journal)
        end

        def context(record, no_effect: false)
          binding = FIELDS.to_h { |key| [key, record.fetch(key)] }
          unless %w[claim_binding policy_digest].all? { |key| binding[key].is_a?(String) && binding[key].match?(/\A[0-9a-f]{64}\z/) } &&
              %w[candidate_generation claim_generation].all? { |key| binding[key].is_a?(Integer) && binding[key].positive? } &&
              binding["dispatch_ticket_id"].is_a?(String) && binding["dispatch_ticket_id"].match?(Molecules::JournalMutation::ID)
            raise AttemptErrors::EvidenceUnavailable, "canonical dispatch binding is invalid"
          end
          if no_effect
            binding.merge!(%w[no_effect_challenge challenge_generation challenge_event_digest].to_h do |key|
              [key, record.fetch(key)]
            end)
            unless binding["no_effect_challenge"].is_a?(String) && !binding["no_effect_challenge"].empty? &&
                binding["challenge_generation"].is_a?(Integer) && binding["challenge_generation"].positive? &&
                binding["challenge_event_digest"].is_a?(String) && binding["challenge_event_digest"].match?(/\A[0-9a-f]{64}\z/)
              raise AttemptErrors::EvidenceUnavailable, "canonical no-effect challenge is invalid"
            end
          end
          {kind: "service", project_id: record.fetch("project_id"), assignment_id: record.fetch("assignment_id"),
            attempt_id: record.fetch("attempt_id"), peer_uid: record.fetch("executor_uid"), binding: binding,
            request_id_or_event_id: record.fetch("request_id"), generation: record.fetch("claim_generation")}
        rescue KeyError
          raise AttemptErrors::EvidenceUnavailable, "canonical service evidence binding is incomplete"
        end

        def call(reference, record, state, pending)
          expected = context(record, no_effect: state == "failed-settled")
          if pending && pending[:pending_events]
            @canonical.read_pending(reference, **expected, **pending.slice(:current_events, :pending_events, :blobs, :commit))
          else
            @canonical.read(reference, **expected, commit: pending && pending[:commit] || @journal.ref_value)
          end
        end
      end
    end
  end
end
