# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        SCOPE_ABORT_FIELDS = %w[kind scope_generation scope_binding_event_id seal_event_id proof_id].freeze

        # Also used by the shared final release-before-reuse predicate. Calls
        # existing owners at the same immutable CAS input, without impersonating
        # a public evidence-fetch peer or inventing an alternate verifier.
        def scope_settlement_complete!(journal:, events:, params:, map:, commit:)
          if @result_owner
            @result_owner.service_settlement_complete!(journal: journal, events: events, params: params, map: map, commit: commit)
          else
            service_events = events.any? { |event| %w[service_claim service_transition].include?(event["type"]) }
            service_records = journal.service_request_records(commit: commit).any? do |record|
              record["assignment_id"] == params.fetch("assignment_id") && record["attempt_id"] == params.fetch("attempt_id")
            end
            if service_events || service_records
              raise AttemptErrors::EvidenceUnavailable, "canonical service settlement owner is unavailable"
            end
          end
          true
        end

        private

        def scope_abort_plan(params, map, events, peer, journal:, commit:, supervisor:)
          bytes = params.fetch("failure_evidence").dup.force_encoding(Encoding::UTF_8)
          raise ArgumentError, "scope failure must be UTF-8 JSON" unless bytes.valid_encoding?
          failure = JSON.parse(bytes, create_additions: false, max_nesting: 8, allow_duplicate_key: false, allow_comments: false)
          strict!(failure, SCOPE_ABORT_FIELDS)
          unless failure["kind"] == "protected_scope_before_release" && failure["scope_generation"].is_a?(Integer) && failure["scope_generation"].positive?
            raise ArgumentError, "scope failure selectors differ"
          end
          %w[scope_binding_event_id seal_event_id proof_id].each do |key|
            value = failure.fetch(key)
            raise ArgumentError, "invalid scope failure selector" unless value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)
          end
          state = states(events)[params.fetch("attempt_id")]
          unless state && state["mapping_id"] == params.fetch("mapping_id") && state["launch_ticket"] == params.fetch("launch_ticket") &&
              (supervisor || @kernel.same?(state.fetch("launcher_identity"), peer))
            raise AttemptErrors::UnauthorizedIdentity, "scope failure is not owned by this launcher"
          end
          chain = events.select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          lineage = Molecules::ExecutionScopeLineage.new(events: chain, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
          lineage.require_positive!(**failure.reject { |key, _| key == "kind" }.transform_keys(&:to_sym))
          scope_observer_for(params.fetch("mapping_id")).verify_closed!(lineage)
          if chain.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "release_launch" } ||
              state["phase"] == "issued" || state["execution"] == "potentially_executed"
            raise AttemptErrors::Conflict, "scope failure cannot undo issued launch permission"
          end
          scope_settlement_complete!(journal: journal, events: chain, params: params, map: map, commit: commit)
          current = journal.canonical_attempt_state(chain)
          unless %w[reserved running uncertain].include?(current)
            raise AttemptErrors::Conflict, "scope failure cannot change a terminal attempt"
          end
          proof = failure.merge("release" => "not_issued")
          reason = "protected_scope_closed_before_release"
          event = if current == "uncertain"
            {type: "reconciliation", payload: {"resolution" => "failed", "reason" => reason,
              "failure_digest" => params.fetch("failure_digest"), "abort_observation" => proof}}
          else
            # This is the sole reserved -> failed admission. The generic state
            # machine remains unchanged; no synthetic process_start is written.
            {type: "transition", payload: {"from" => current, "to" => "failed", "reason" => reason,
              "abort_observation" => proof}}
          end
          reference = "evidence/imports/launch-failure-#{params.fetch('attempt_id')}-#{params.fetch('failure_digest')}"
          {events: [event], blobs: {reference => params.fetch("failure_evidence")}, data: state.merge(
            "phase" => "failed", "failure_digest" => params.fetch("failure_digest"), "failure_ref" => reference,
            "abort_observation" => proof, "required_action" => nil)}
        rescue JSON::ParserError
          raise ArgumentError, "scope failure JSON is invalid"
        end
      end
    end
  end
end
