# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # Caller owns the existing slot/assignment exclusion. This verifies
        # an already accepted closure; it never seals, stops or observes anew.
        def completion_scope!(journal:, events:, params:, map:, commit:)
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
            mapping_id: params.fetch("mapping_id"))
          unless lineage.proof_event && !pending_prompt_issuers?(events, journal, commit)
            raise AttemptErrors::EvidenceUnavailable, "Original scope closure is unavailable"
          end
          scope_observer_for(params.fetch("mapping_id")).verify_closed!(lineage)
          lineage
        end

        # Reuse the complete immutable inventory/terminal/release owner for
        # recovery and finish replay; no current process grants terminality.
        def completion_terminal!(journal:, commit:, params:, map:)
          entries = inventory_index!(journal, commit, params.fetch("mapping_id"), map).select do |entry|
            entry.fetch(:selector).values_at("assignment_id", "attempt_id") == params.values_at("assignment_id", "attempt_id")
          end
          raise AttemptErrors::NotFound, "Canonical attempt is missing" if entries.empty?
          raise AttemptErrors::EvidenceUnavailable, "Canonical attempt is ambiguous" unless entries.one?
          inventory_row!(journal, commit, entries.first)
        end

        def recovery_observation!(journal:, events:, params:, map:, commit:)
          state = origin(events, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
          return {"liveness" => "unknown"} unless %w[bound issued].include?(state["phase"])
          original, original_map = inventory_original_deployment!(journal, events, params.fetch("mapping_id"), map)
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: original_map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
          return {"liveness" => "unknown"} if lineage.sealed?
          # Disposable local cache is not a checkpoint authority. Authenticate
          # the retained original prepared selection with the existing owner.
          if state.fetch("phase") == "issued"
            original_prepared_registration!(journal: journal, params: params, commit: commit)
          else
            original_bound_prepared_registration!(journal: journal, params: params, commit: commit)
          end
          Molecules::AttemptReconciler.protected_observation(kernel: @kernel, binding: state.fetch("process_binding"),
            observer: maintenance_scope_observer_for(original, params.fetch("mapping_id")), lineage: lineage)
        end
      end
    end
  end
end
