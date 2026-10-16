# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # Replacement transfers only result ownership, never worker execution.
      # The existing definition chain serializes it with canonical generation.
      module OrdinarySupervisor
        SUPERVISOR_OPERATIONS = %w[supervisor_status adopt_supervisor].freeze

        private

        def supervisor_operation(request, peer, role, deadline)
          params = request.fetch("params")
          assignment = params.fetch("assignment_id")
          token!(assignment)
          registered = registration(assignment, commit: @journal.ref_value)
          raise AttemptErrors::NotFound, "ordinary work is not registered" unless registered
          if request.fetch("operation") == "supervisor_status"
            strict!(params, %w[assignment_id])
            raise ArgumentError, "supervisor status mutation must be null" unless request.fetch("mutation_id").nil?
            commit = @journal.ref_value
            selected = supervisor_selection(registered, commit)
            authorize!(request, peer, role, deadline)
            return {data: selected.merge("journal_commit" => commit), replayed: false}
          end
          strict!(params, %w[assignment_id expected_generation pane previous_binding_sha256])
          token!(request.fetch("mutation_id"))
          unless role == :supervisor && params.fetch("expected_generation").is_a?(Integer) &&
              params.fetch("expected_generation").positive? && params.fetch("previous_binding_sha256").is_a?(String) &&
              params.fetch("previous_binding_sha256").match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::UnauthorizedIdentity, "supervisor adoption requires exact current selection"
          end
          observed = @admission.identity!(peer: peer, pane: params.fetch("pane"), deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity, "replacement is not an installed coordinator" unless observed.role == "coordinator"
          binding = observed.runtime_binding
          digest = Atoms::EvidenceDigest.digest({"project_id" => @project, "params" => params, "binding" => binding})
          @exclusion.with_shared_multi([@exclusion.task_key(registered.fetch("task_id")), @exclusion.assignment_key(assignment)], deadline: deadline) do
            @journal.mutate(assignment_id: assignment, attempt_id: "definition-#{assignment}",
              mutation_id: request.fetch("mutation_id"), operation: "adopt_supervisor", parameters_digest: digest,
              expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
              replay_authorizer: -> {
                verify_new_supervisor!(request, peer, role, deadline, observed)
                unless supervisor_selection(registered, @journal.ref_value).fetch("binding") == binding
                  raise AttemptErrors::UnauthorizedIdentity, "supervisor adoption was superseded"
                end
              }) do |_events, prefix, _generation|
              verify_new_supervisor!(request, peer, role, deadline, observed)
              previous = supervisor_selection(registered, prefix)
              unless previous.fetch("binding_sha256") == params.fetch("previous_binding_sha256") && previous.fetch("binding") != binding
                raise AttemptErrors::Conflict, "original supervisor selection changed"
              end
              ended = @admission.supervisor_ended!(binding: previous.fetch("binding"), deadline: deadline)
              unless ended.is_a?(Hash) && ended["liveness"] == "ended"
                raise AttemptErrors::EvidenceUnavailable, "original supervisor generation has not ended"
              end
              verify_new_supervisor!(request, peer, role, deadline, observed)
              {events: [], data: {"authority" => "ordinary", "assignment_id" => assignment, "project_id" => @project,
                "previous_binding" => previous.fetch("binding"), "binding" => binding,
                "binding_sha256" => Atoms::EvidenceDigest.digest(binding), "ended_observation" => ended}}
            end
          end
        end

        def verify_new_supervisor!(request, peer, role, deadline, observed)
          authorize!(request, peer, role, deadline)
          unless @admission.identity!(peer: peer, pane: request.fetch("params").fetch("pane"), deadline: deadline) == observed
            raise AttemptErrors::UnauthorizedIdentity, "replacement supervisor changed during adoption"
          end
        end

        def supervisor_selection(registered, commit)
          assignment = registered.fetch("assignment_id")
          events = @journal.read_events(assignment, commit: commit).select { |event| event.fetch("attempt_id") == "definition-#{assignment}" }
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "ordinary supervisor history is corrupt"
          end
          selected = registered.fetch("supervisor_binding")
          generation = 1
          # Validate the entire old→new chain rather than trusting a local cache.
          events.select { |event| event["type"] == "authority_mutation" }.each do |event|
            payload = event.fetch("payload")
            next if payload.fetch("operation") == "register_assignment"
            data = payload.fetch("data")
            unless payload.fetch("operation") == "adopt_supervisor" && data.fetch("previous_binding") == selected &&
                data.values_at("authority", "assignment_id", "project_id", "generation") == ["ordinary", assignment, @project, generation + 1] &&
                data.fetch("binding_sha256") == Atoms::EvidenceDigest.digest(data.fetch("binding")) &&
                data.dig("ended_observation", "liveness") == "ended"
              raise AttemptErrors::EvidenceUnavailable, "ordinary supervisor adoption chain differs"
            end
            selected, generation = data.fetch("binding"), data.fetch("generation")
          end
          {"project_id" => @project, "assignment_id" => assignment, "generation" => generation,
            "binding" => selected, "binding_sha256" => Atoms::EvidenceDigest.digest(selected)}
        end
      end
    end
  end
end
