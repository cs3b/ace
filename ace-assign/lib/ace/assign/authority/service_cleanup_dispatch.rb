# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # Canonical-only original dispatch proof shared by status, root admission
      # and initial/retained inspection imports. Installed peer policy stays in
      # the fixed root transport owner.
      module ServiceCleanupDispatch
        CLEANUP_MUTABLE_SETTLEMENT_FIELDS = %w[state receipt reason claimed_at failed_at no_effect_challenge
          challenge_generation challenge_event_digest completion_digest no_effect_completion_digest].freeze

        def cleanup_dispatch_context!(record, commit:, selectors: nil, pending: nil)
          unless @journal.evidence_mode == :protected &&
              record.values_at("operation", "dispatch_phase") == ["prune-preserved-workspace", "dispatch_started"]
            raise AttemptErrors::EvidenceUnavailable, "cleanup original dispatch is unavailable"
          end
          pending ||= {commit: commit}
          @journal.verify_canonical_prefix!(commit: commit) unless service_read_view(pending)
          # The existing index authenticates accepted record provenance without
          # recursively asking this terminal collection to validate itself.
          selected = @journal.service_request_records(commit: commit)
            .select { |entry| entry["request_id"] == record.fetch("request_id") }
          # Initial import receives the lower writer's proposed terminal
          # replacement. Its settlement fields are validated by that writer
          # and collection; the original immutable dispatch must still match.
          unless selected.one? && selected.first.except(*CLEANUP_MUTABLE_SETTLEMENT_FIELDS) ==
              record.except(*CLEANUP_MUTABLE_SETTLEMENT_FIELDS)
            raise AttemptErrors::EvidenceUnavailable, "cleanup selected record differs"
          end
          context(record, pending: {commit: commit})
          events = service_read_events(record, pending)
          names = %w[request_event_digest dispatch_event_digest]
          operations = %w[request_service begin_dispatch]
          if selectors.nil?
            selectors = names.zip(operations).to_h do |name, operation|
              matches = events.select do |event|
                event["type"] == "authority_mutation" && event.dig("payload", "operation") == operation &&
                  event.dig("payload", "data", "request_id") == record.fetch("request_id") &&
                  event.dig("payload", "data", "claim_binding") == record.fetch("claim_binding") &&
                  event.dig("payload", "data", operation == "request_service" ? "claim" : "invocation") ==
                    (operation == "request_service" ? "created" : "permitted")
              end
              raise AttemptErrors::EvidenceUnavailable, "cleanup original acceptance is ambiguous" unless matches.one?
              [name, matches.first.fetch("digest")]
            end
          end
          unless selectors.is_a?(Hash) && selectors.keys.sort == names.sort &&
              selectors.values.all? { |value| value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/) } && selectors.values.uniq.size == 2
            raise AttemptErrors::EvidenceUnavailable, "cleanup original acceptance selectors differ"
          end
          introductions = service_read_introductions(record, selectors.values, pending)
          dispatch_record = nil
          names.zip(operations).each do |name, operation|
            selector = selectors.fetch(name)
            matches = events.select { |event| event.fetch("digest") == selector }
            event = matches.one? && matches.first
            payload = event && event.fetch("payload")
            unless event && event.fetch("type") == "authority_mutation" && payload.fetch("operation") == operation &&
                payload.slice("assignment_id", "attempt_id") == record.slice("assignment_id", "attempt_id") &&
                payload.fetch("data").slice("request_id", "claim_binding") == record.slice("request_id", "claim_binding") &&
                payload.fetch("data").fetch(operation == "request_service" ? "claim" : "invocation") ==
                  (operation == "request_service" ? "created" : "permitted")
              raise AttemptErrors::EvidenceUnavailable, "cleanup original acceptance differs"
            end
            prefix = @journal.read_events(record.fetch("assignment_id"), commit: introductions.fetch(selector))
              .select { |entry| entry.fetch("attempt_id") == record.fetch("attempt_id") }
            original = @journal.service_request(record.fetch("request_id"), commit: introductions.fetch(selector))
            expected = operation == "request_service" ? original&.merge("dispatch_phase" => "dispatch_started",
              "operation_owner_binding" => record.fetch("operation_owner_binding"),
              "executor_process_binding" => record.fetch("executor_process_binding")) : original
            unless expected&.except(*CLEANUP_MUTABLE_SETTLEMENT_FIELDS) == record.except(*CLEANUP_MUTABLE_SETTLEMENT_FIELDS) &&
                prefix.last == event && prefix[-2] &&
                prefix[-2].fetch("type") == (operation == "request_service" ? "service_claim" : "service_transition") &&
                prefix[-2].dig("payload", "record_digest") == Atoms::EvidenceDigest.digest(original) &&
                event.fetch("previous_digest") == prefix[-2].fetch("digest")
              raise AttemptErrors::EvidenceUnavailable, "cleanup acceptance is not its original canonical introduction"
            end
            dispatch_record = original if operation == "begin_dispatch"
          end
          freeze_projection(JSON.parse(JSON.generate(selectors.merge("commit" => commit, "dispatch_record" => dispatch_record))))
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "cleanup original dispatch proof is incomplete"
        end
      end
    end
  end
end
