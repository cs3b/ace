# frozen_string_literal: true

require_relative "../molecules/canonical_evidence"
require_relative "service_cleanup_evidence"
require_relative "service_cleanup_dispatch"
require_relative "../molecules/execution_scope_lineage"

module Ace
  module Assign
    module Authority
      # One source-owned context for initial and retained service evidence.
      # The journal supplies the record and transient pending view; callers
      # never supply an alternate reader, artifact path or trusted flag.
      class ServiceEvidence
        include ServiceCleanupEvidence
        include ServiceCleanupDispatch
        FIELDS = (Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS +
          %w[dispatch_ticket_id claim_binding candidate_generation claim_generation policy_digest]).freeze
        CHALLENGE_FIELDS = %w[version request_id input_digest claim_binding dispatch_ticket_id no_effect_challenge
          challenge_generation failure_event_digest failure_generation].freeze
        INSPECTION_FIELDS = %w[version request_id input_digest claim_binding no_effect_challenge challenge_generation
          challenge_event_digest failure_event_digest failure_generation target dispatch_phase effect_absent
          handler_terminated writers_absent].freeze

        def initialize(journal:, cleanup_artifacts: nil)
          @journal = journal
          @canonical = Molecules::CanonicalEvidence.new(journal: journal)
          @cleanup_artifacts = cleanup_artifacts
        end

        # Executor-only projection from the same authenticated original record;
        # selectors never come from the receiver or a caller-supplied target.
        def settlement_context(record, commit: @journal.ref_value, read_view: nil)
          pending = {commit: commit, service_read_view: read_view}
          context(record, pending: pending)
          challenge = challenge!(record, pending: pending, current: false) if
            %w[no_effect_challenge challenge_generation challenge_event_digest].any? { |key| record.key?(key) }
          proof = cleanup_dispatch_context!(record, commit: commit, pending: pending) if
            record.values_at("operation", "dispatch_phase") == ["prune-preserved-workspace", "dispatch_started"]
          settlement_projection(record, pending, challenge, proof)
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "original service settlement context is incomplete"
        end

        def context(record, no_effect: false, pending: nil)
          binding = FIELDS.to_h { |key| [key, record.fetch(key)] }
          if record.fetch("operation") == "prune-preserved-workspace" && record["dispatch_phase"] == "dispatch_started"
            binding["operation_owner_binding"] = record.fetch("operation_owner_binding")
            executor = record.fetch("executor_process_binding")
            boot = record.fetch("worker_process_binding").fetch("started_at").split(":").fetch(1)
            Molecules::ExecutionScopeLineage.validate_process_identity!(executor, boot_id: boot)
            raise AttemptErrors::EvidenceUnavailable, "original cleanup executor differs" unless executor.fetch("uid") == record.fetch("executor_uid")
            binding["executor_process_binding"] = executor
          end
          unless %w[claim_binding policy_digest].all? { |key| binding[key].is_a?(String) && binding[key].match?(/\A[0-9a-f]{64}\z/) } &&
              %w[candidate_generation claim_generation].all? { |key| binding[key].is_a?(Integer) && binding[key].positive? } &&
              binding["dispatch_ticket_id"].is_a?(String) && binding["dispatch_ticket_id"].match?(Molecules::JournalMutation::ID)
            raise AttemptErrors::EvidenceUnavailable, "canonical dispatch binding is invalid"
          end
          if no_effect
            return context_for_challenge(record, challenge!(record, pending: pending))
          end
          {kind: "service", project_id: record.fetch("project_id"), assignment_id: record.fetch("assignment_id"),
            attempt_id: record.fetch("attempt_id"), peer_uid: record.fetch("executor_uid"), binding: binding,
            request_id_or_event_id: record.fetch("request_id"), generation: record.fetch("claim_generation")}
        rescue KeyError
          raise AttemptErrors::EvidenceUnavailable, "canonical service evidence binding is incomplete"
        end

        # Exact original challenge and failure selected from the same immutable
        # canonical prefix as its import. Pending events are the journal owner's
        # held CAS plan, never caller-supplied alternative history.
        def challenge!(record, pending: nil, current: true)
          context(record)
          selector = record.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest")
          unless selector.keys.sort == %w[no_effect_challenge challenge_generation challenge_event_digest].sort &&
              selector["no_effect_challenge"].is_a?(String) && selector["no_effect_challenge"].match?(/\A[0-9a-f]{32}\z/) &&
              selector["challenge_generation"].is_a?(Integer) && selector["challenge_generation"].positive? &&
              selector["challenge_event_digest"].is_a?(String) && selector["challenge_event_digest"].match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::EvidenceUnavailable, "canonical challenge selector is invalid"
          end
          commit = pending && pending[:commit] || @journal.ref_value
          events = if pending && pending[:pending_events]
            pending.fetch(:current_events) + pending.fetch(:pending_events)
          else
            service_read_events(record, pending)
          end
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "canonical challenge chain is corrupt"
          end
          selected = events.select { |event| event["digest"] == record.fetch("challenge_event_digest") }
          unless selected.size == 1 && selected.first["type"] == "service_no_effect_challenge"
            raise AttemptErrors::EvidenceUnavailable, "canonical challenge event is missing"
          end
          challenge = selected.first
          payload = challenge.fetch("payload")
          before = events.take_while { |event| event["digest"] != challenge.fetch("digest") }
          failures = events.select do |event|
            %w[service_claim service_transition].include?(event["type"]) &&
              event.dig("payload", "request_id") == record.fetch("request_id") &&
              %w[uncertain failed].include?(event.dig("payload", "state"))
          end
          failure = before.reverse.find { |event| failures.include?(event) }
          failure_prefix = before.take_while { |event| event["digest"] != failure&.fetch("digest") }
          generation = failure_prefix.count { |event| event["type"] == "authority_mutation" } + 1
          unless payload.is_a?(Hash) && payload.keys.sort == CHALLENGE_FIELDS.sort &&
              payload["version"].is_a?(Integer) && payload["version"] == 1 &&
              %w[challenge_generation failure_generation].all? { |key| payload[key].is_a?(Integer) && payload[key].positive? } &&
              payload["no_effect_challenge"].is_a?(String) && payload["no_effect_challenge"].match?(/\A[0-9a-f]{32}\z/) &&
              %w[request_id input_digest claim_binding dispatch_ticket_id no_effect_challenge challenge_generation].all? { |key| payload[key] == record[key] } &&
              failure && (!current || failures.last == failure) && before.any? { |event| event["digest"] == failure.fetch("digest") } &&
              payload["failure_event_digest"] == failure.fetch("digest") && payload["failure_generation"] == generation &&
              payload["challenge_generation"] == before.count { |event| event["type"] == "authority_mutation" } + 1
            raise AttemptErrors::EvidenceUnavailable, "canonical challenge or current failure binding differs"
          end
          position = events.index(challenge)
          if pending && pending[:pending_events]&.any? { |event| event["digest"] == challenge.fetch("digest") }
            unless pending[:operation] == "claim_service_settlement"
              raise AttemptErrors::EvidenceUnavailable, "pending challenge has no fixed authority owner"
            end
          else
            update, accepted = events.values_at(position + 1, position + 2)
            expected_params = record.slice("mapping_id", "assignment_id", "attempt_id", "request_id", "candidate_generation").merge(
              "head" => record.fetch("candidate_head"), "expected_generation" => payload.fetch("challenge_generation") - 1)
            unless update && update["type"] == "service_challenge" && update.dig("payload", "request_id") == record.fetch("request_id") &&
                accepted && accepted["type"] == "authority_mutation" && accepted.dig("payload", "operation") == "claim_service_settlement" &&
                accepted.dig("payload", "assignment_id") == record.fetch("assignment_id") && accepted.dig("payload", "attempt_id") == record.fetch("attempt_id") &&
                accepted.dig("payload", "parameters_digest") == Atoms::EvidenceDigest.digest(expected_params) &&
                accepted.dig("payload", "data", "generation").is_a?(Integer) &&
                accepted.dig("payload", "data", "generation") == payload.fetch("challenge_generation") &&
                accepted.dig("payload", "data", "reconciliation_challenge", "challenge_generation").is_a?(Integer) &&
                accepted.dig("payload", "data", "request_id") == record.fetch("request_id") &&
                accepted.dig("payload", "data", "reconciliation_challenge") == record.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest")
              raise AttemptErrors::EvidenceUnavailable, "canonical challenge lacks its accepted authority mutation"
            end
            commits = service_read_introductions(record,
              [challenge.fetch("digest"), failure.fetch("digest"), update.fetch("digest"), accepted.fetch("digest")], pending)
            unless commits.fetch(challenge.fetch("digest")) == commits.fetch(update.fetch("digest")) &&
                commits.fetch(challenge.fetch("digest")) == commits.fetch(accepted.fetch("digest"))
              raise AttemptErrors::EvidenceUnavailable, "challenge record and authority acceptance were not atomic"
            end
            original = @journal.service_request(record.fetch("request_id"), commit: commits.fetch(challenge.fetch("digest")))
            unless original && %w[uncertain failed].include?(original["state"]) &&
                update.dig("payload", "record_digest") == Atoms::EvidenceDigest.digest(original) &&
                (FIELDS + %w[mapping_id service_id caller_uid authorization worker_process_binding launch_ticket reservation_generation dispatch_phase]).all? { |key| original[key] == record[key] } &&
                original.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest") ==
                  record.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest")
              raise AttemptErrors::EvidenceUnavailable, "challenge accepted record differs from original binding"
            end
          end
          challenge
        rescue KeyError, TypeError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "canonical challenge binding is incomplete"
        end

        def inspection!(content, record, challenge)
          unless content.is_a?(String) && content.bytesize <= Molecules::CanonicalEvidence::MAX_ARTIFACT_BYTES
            raise AttemptErrors::EvidenceUnavailable, "no-effect inspection exceeds artifact bounds"
          end
          text = content.dup.force_encoding(Encoding::UTF_8)
          raise AttemptErrors::EvidenceUnavailable, "no-effect inspection is invalid UTF8" unless text.valid_encoding?
          lines = text.lines.filter_map { |line| line.delete_prefix("ace-service-no-effect ").chomp if line.start_with?("ace-service-no-effect ") }
          raise AttemptErrors::EvidenceUnavailable, "no-effect inspection is missing or repeated" unless lines.size == 1
          inspection = JSON.parse(lines.first, create_additions: false, max_nesting: 8,
            allow_duplicate_key: false, allow_comments: false)
          inspection_projection!(inspection, record, challenge)
        rescue JSON::ParserError, KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "no-effect inspection is malformed"
        end

        def inspection_projection!(inspection, record, challenge)
          expected = challenge.fetch("payload").slice("request_id", "input_digest", "claim_binding", "no_effect_challenge",
            "challenge_generation", "failure_event_digest", "failure_generation").merge("version" => 1,
              "challenge_event_digest" => challenge.fetch("digest"), "target" => record.fetch("target"),
              "dispatch_phase" => record.fetch("dispatch_phase"), "effect_absent" => true,
              "handler_terminated" => true, "writers_absent" => true)
          unless inspection.is_a?(Hash) && inspection.keys.sort == INSPECTION_FIELDS.sort &&
              %w[version challenge_generation failure_generation].all? { |key| inspection[key].is_a?(Integer) } &&
              inspection == expected
            raise AttemptErrors::EvidenceUnavailable, "no-effect inspection differs from original challenge"
          end
          true
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "no-effect inspection is malformed"
        end

        def call(reference, record, state, pending)
          return cleanup_collection!(reference, record, state, pending) if reference.is_a?(Array)
          no_effect = state == "failed-settled"
          expected = context(record, no_effect: no_effect, pending: pending)
          bytes = if pending && pending[:pending_events]
            @canonical.read_pending(reference, **expected, **pending.slice(:current_events, :pending_events, :blobs, :commit))
          else
            @canonical.read(reference, **expected, commit: pending && pending[:commit] || @journal.ref_value)
          end
          if no_effect
            challenge = challenge!(record, pending: pending)
            inspection!(bytes, record, challenge)
          end
          bytes
        end

        private

        def settlement_projection(record, pending, challenge, proof)
          selected = nil
          if challenge
            latest_failure = service_read_events(record, pending).reverse.find do |event|
              event["attempt_id"] == record.fetch("attempt_id") &&
                %w[service_claim service_transition].include?(event["type"]) &&
                event.dig("payload", "request_id") == record.fetch("request_id") &&
                %w[uncertain failed].include?(event.dig("payload", "state"))
            end
            if latest_failure && latest_failure.fetch("digest") == challenge.dig("payload", "failure_event_digest")
              selected = challenge.fetch("payload").slice("request_id", "input_digest", "claim_binding",
                "no_effect_challenge", "challenge_generation", "failure_event_digest", "failure_generation")
                .merge("challenge_event_digest" => challenge.fetch("digest"))
            end
          end
          execution = record.slice("mapping_id", "candidate_generation", "claim_binding", "dispatch_phase")
            .merge("head" => record.fetch("candidate_head"))
          if record["operation"] == "prune-preserved-workspace" && record["dispatch_phase"] == "dispatch_started"
            execution.merge!(record.slice("operation_owner_binding", "executor_process_binding"))
            execution.merge!(proof.slice("request_event_digest", "dispatch_event_digest"))
          end
          value = {"version" => 1, "request" => record.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS),
            "execution" => execution, "challenge" => selected}
          freeze_projection(JSON.parse(JSON.generate(value)))
        end

        def context_for_challenge(record, selection)
          expected = context(record)
          binding = expected.fetch(:binding)
          binding.merge!(record.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest"))
          binding.merge!(selection.fetch("payload").slice("failure_event_digest", "failure_generation"))
          binding["dispatch_phase"] = record.fetch("dispatch_phase")
          expected
        end

        def service_read_view(pending)
          view = pending && pending[:service_read_view]
          return nil unless view
          unless view.is_a?(Molecules::EvidenceJournal::ServiceReadView) && view.journal.equal?(@journal) &&
              view.commit == pending.fetch(:commit) && view.inventory.fetch("commit") == view.commit
            raise AttemptErrors::EvidenceUnavailable, "service read view differs from its selected owner"
          end
          view
        end

        def service_read_events(record, pending)
          view = service_read_view(pending)
          selected = view ? view.inventory.fetch("events").fetch(record.fetch("assignment_id")) :
            @journal.read_events(record.fetch("assignment_id"), commit: pending && pending[:commit] || @journal.ref_value)
          selected.select { |event| event.fetch("attempt_id") == record.fetch("attempt_id") }
        end

        def service_read_introductions(record, selectors, pending)
          view = service_read_view(pending)
          return @journal.event_commits!(assignment_id: record.fetch("assignment_id"), event_digests: selectors,
            commit: pending && pending[:commit] || @journal.ref_value) unless view
          facts = view.inventory.fetch("introductions").fetch(record.fetch("assignment_id"))
          selectors.to_h { |selector| [selector, facts.fetch(selector)] }.freeze
        end

        def freeze_projection(value)
          value.each_value { |child| freeze_projection(child) } if value.is_a?(Hash)
          value.each { |child| freeze_projection(child) } if value.is_a?(Array)
          value.freeze
        end
      end
    end
  end
end
