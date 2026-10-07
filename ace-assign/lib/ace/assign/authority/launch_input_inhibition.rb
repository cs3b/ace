# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        def launch_input_inhibit_selection!(request:, peer:, role:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id original_binding_digest seal_event_id journal_commit])
          raise ArgumentError, "Input inhibition selection requires null mutation ID" unless request.fetch("mutation_id").nil?
          map = steering_principal!(params, peer, role)
          raise AttemptErrors::UnauthorizedIdentity, "Input inhibition selection requires original launcher" unless role == :launcher
          LaunchControlChannel.validate_inhibit!(params.slice("attempt_id", "original_binding_digest", "seal_event_id", "journal_commit").merge(
            "version" => 1, "type" => "launch_input_inhibit"))
          journal = journal_for(map)
          commit = params.fetch("journal_commit")
          journal.verify_prompt_prefix!(commit: commit)
          events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          authenticate_input_inhibition!(events, params, map, peer: peer)
          {data: params.slice("attempt_id", "original_binding_digest", "seal_event_id", "journal_commit"), replayed: false}
        end

        def launch_input_inhibit_completion!(request:, peer:, role:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id original_binding_digest seal_event_id guarded_evidence])
          raise ArgumentError, "Input inhibition completion requires null mutation ID" unless request.fetch("mutation_id").nil?
          map = steering_principal!(params, peer, role)
          raise AttemptErrors::UnauthorizedIdentity, "Input inhibition completion requires original launcher" unless role == :launcher
          {data: record_original_input_inhibition!(params, map, params.fetch("guarded_evidence"), peer: peer), replayed: false}
        end

        private

        def request_original_input_inhibition!(params, map, journal)
          selected = with_exclusion(params, map, journal) do
            @mutex.synchronize do
              commit = journal.ref_value
              events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              next true if accepted_input_inhibition?(events, journal, commit)
              state = origin(events, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
              # Before native release there is no admitted outside-unit input
              # owner. Its existing native issuer/guarded abort gates remain.
              next true unless issued_input_actor?(events)
              original = original_prompt_record!(events, state, params: params)
              lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
                assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
              raise AttemptErrors::EvidenceUnavailable, "Original scope is not sealed" unless lineage.seal_event
              channel = @control_channels[steering_key(params, map)]
              next false unless channel && !channel.closed?
              frame = {"version" => 1, "type" => "launch_input_inhibit", "attempt_id" => params.fetch("attempt_id"),
                "original_binding_digest" => original.fetch("binding_digest"), "seal_event_id" => lineage.seal_event.fetch("digest"), "journal_commit" => commit}
              [channel, frame]
            end
          end
          return selected if selected == true || selected == false
          channel, frame = selected
          channel.inhibit_input(frame: frame, deadline: wire.deadline(30))
          true
        rescue AttemptErrors::EvidenceUnavailable, Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError
          false
        end

        def record_original_input_inhibition!(params, map, evidence, peer: nil)
          journal = journal_for(map)
          with_exclusion(params, map, journal) do
            @mutex.synchronize do
              commit = journal.ref_value
              current = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              @kernel.live!(peer) if peer
              original = authenticate_input_inhibition!(current, params, map, peer: peer)
              journal.verify_input_drained_evidence!(evidence, original.fetch("origin"))
              selection = params.slice("mapping_id", "assignment_id", "attempt_id", "original_binding_digest", "seal_event_id").merge("project_id" => map.fetch("project_id"))
              journal.observe_input_inhibition(selection: selection, evidence: evidence) do |events, _old, _generation|
                @kernel.live!(peer) if peer
                authenticate_input_inhibition!(events, params, map, peer: peer)
              end.fetch(:data).slice("original_binding_digest", "seal_event_id", "journal_commit")
            end
          end
        end

        def accepted_input_inhibition?(events, journal, commit)
          proofs = events.select { |event| event["type"] == "input_inhibited" }
          return false if proofs.empty?
          raise AttemptErrors::EvidenceUnavailable, "Original input inhibition proof is ambiguous" unless proofs.length == 1
          proof = proofs.first
          payload = proof.fetch("payload")
          unless payload.is_a?(Hash) && payload.keys.sort == (Molecules::JournalInputInhibition::INPUT_INHIBITION_FIELDS + ["guarded_evidence"]).sort
            raise AttemptErrors::EvidenceUnavailable, "Original input inhibition proof fields are malformed"
          end
          id = "input-inhibit.#{payload.fetch('seal_event_id')}"
          digest = Digest::SHA256.hexdigest(JSON.generate(journal.send(:canonical_prompt_value, payload)))
          journal.send(:verify_input_inhibition!, payload, mutation_id: id, digest: digest,
            assignment_id: payload.fetch("assignment_id"), attempt_id: payload.fetch("attempt_id"), commit: commit)
          accepted = events.find { |event| event["type"] == "authority_mutation" && event["previous_digest"] == proof.fetch("digest") &&
            event.dig("payload", "operation") == "input_inhibition_observation" && event.dig("payload", "mutation_id") == id }
          expected = payload.slice("original_binding_digest", "seal_event_id")
          data = accepted&.dig("payload", "data")
          unless accepted && accepted.dig("payload", "parameters_digest") == digest &&
              data.is_a?(Hash) && data.reject { |key, _| key == "generation" } == expected
            raise AttemptErrors::EvidenceUnavailable, "Original input inhibition acceptance differs"
          end
          true
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "Original input inhibition proof is malformed"
        end

        def authenticate_input_inhibition!(events, params, map, peer: nil)
          state = origin(events, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
          if peer && !@kernel.same?(state.fetch("launcher_identity"), peer)
            raise AttemptErrors::UnauthorizedIdentity, "Input inhibition belongs to another launcher incarnation"
          end
          original = original_prompt_record!(events, state, params: params)
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
          seal = lineage.seal_event
          acceptance = seal && events.find { |event| event["type"] == "authority_mutation" && event["previous_digest"] == seal.fetch("digest") &&
            %w[close_execution_scope stop_attempt].include?(event.dig("payload", "operation")) }
          unless original.fetch("binding_digest") == params.fetch("original_binding_digest") && seal && acceptance &&
              seal.fetch("digest") == params.fetch("seal_event_id")
            raise AttemptErrors::EvidenceUnavailable, "Input inhibition does not join accepted original seal"
          end
          if events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
            raise AttemptErrors::EvidenceUnavailable, "Released scope cannot request original input inhibition"
          end
          original
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "Original input inhibition lineage is malformed"
        end
      end
    end
  end
end
