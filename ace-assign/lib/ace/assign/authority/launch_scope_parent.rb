# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        private

        # Called inside the existing slot/assignment exclusion, after the fresh
        # reservation CAS and outside its authority mutex/journal ref lock.
        # Mutation replay and restart never call this activation path.
        def provision_reserved_parent_held!(reservation, map, journal)
          params = reservation.slice("mapping_id", "assignment_id", "attempt_id")
          context = params.merge("project_id" => map.fetch("project_id"),
            "reservation_generation" => reservation.fetch("reservation_generation"),
            "scope_generation" => reservation.fetch("generation") + 1)
          observer = scope_observer_for(params.fetch("mapping_id"))
          binding = observer.activate_parent!(context)
          @mutex.synchronize do
            journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: "scope-parent-#{Digest::SHA256.hexdigest(params.fetch('attempt_id'))[0, 48]}",
              operation: "scope_parent_binding", parameters_digest: Digest::SHA256.hexdigest(JSON.generate(canonical(context))),
              expected_generation: reservation.fetch("generation"), with_replay: true) do |events, _commit, _generation|
              state = states(events)[params.fetch("attempt_id")]
              unless state && state["phase"] == "reserved" && state["launch_ticket"] == reservation.fetch("launch_ticket") &&
                  events.none? { |event| %w[scope_bound scope_native_bound scope_child_bound scope_sealed].include?(event["type"]) ||
                    event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_service_admission" }
                raise AttemptErrors::Conflict, "parent activation cannot replace or reopen an existing generation"
              end
              at = Time.now.utc
              event = Models::EvidenceEvent.build(type: "scope_bound", attempt_id: params.fetch("attempt_id"),
                payload: binding, previous_digest: events.last&.fetch("digest"), recorded_at: at)
              lineage = Molecules::ExecutionScopeLineage.new(events: events + [event], project_id: map.fetch("project_id"),
                assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
              observer.observe(lineage)
              {events: [{type: "scope_bound", payload: binding, recorded_at: at}], blobs: {}, data: state.merge(
                "scope_generation" => binding.fetch("scope_generation"), "scope_binding_event_id" => event.fetch("digest"))}
            end
          end
        end
      end
    end
  end
end
