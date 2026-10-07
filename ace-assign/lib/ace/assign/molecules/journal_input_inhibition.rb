# frozen_string_literal: true
require_relative "execution_scope_lineage"

module Ace
  module Assign
    module Molecules
      module JournalInputInhibition
        INPUT_INHIBITION_FIELDS = %w[assignment_id attempt_id mapping_id original_binding_digest project_id seal_event_id].freeze

        def observe_input_inhibition(selection:, evidence:, &authentication)
          raise ArgumentError, "Original inhibition authentication is required" unless authentication
          input = selection.merge("guarded_evidence" => evidence)
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical_prompt_value(input)))
          mutate(assignment_id: selection.fetch("assignment_id"), attempt_id: selection.fetch("attempt_id"),
            mutation_id: "input-inhibit.#{selection.fetch('seal_event_id')}", operation: "input_inhibition_observation",
            parameters_digest: digest, expected_generation: nil, generation_mode: :input_inhibition,
            input_inhibition: input, with_replay: true) do |events, commit, generation|
            original = authentication.call(events, commit, generation)
            unless original.is_a?(Hash) && original.keys.sort == %w[binding_digest origin] && original["binding_digest"] == selection.fetch("original_binding_digest")
              raise AttemptErrors::EvidenceUnavailable, "Original input inhibition record differs"
            end
            verify_input_drained_evidence!(evidence, original.fetch("origin"))
            {events: [{type: "input_inhibited", payload: selection.merge("guarded_evidence" => evidence)}], blobs: {},
              data: selection.slice("original_binding_digest", "seal_event_id")}
          end
        end

        def verify_input_drained_evidence!(evidence, original)
          unless original.is_a?(Hash) && evidence.is_a?(Hash) && evidence.keys.sort == %w[input_state origin outcome pending_input] &&
              evidence["outcome"] == "inhibited" && evidence["input_state"] == "inhibited" &&
              evidence["pending_input"].is_a?(Integer) && evidence["pending_input"].zero?
            raise AttemptErrors::EvidenceUnavailable, "Native input drainage is unconfirmed"
          end
          received = Ace::Herdr::Molecules::GuardedNativeOrigin.verify!(evidence.fetch("origin"),
            terminal_id: original.fetch("terminal_id"), child: original.fetch("child"))
          raise AttemptErrors::EvidenceUnavailable, "Native input drainage origin differs" unless received == original
          true
        rescue Ace::Runtime::RuntimeUnavailableError, KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "Native input drainage is unverifiable"
        end

        private

        def verify_input_inhibition!(input, mutation_id:, digest:, assignment_id:, attempt_id:, commit:)
          unless input.is_a?(Hash) && input.keys.sort == (INPUT_INHIBITION_FIELDS + ["guarded_evidence"]).sort &&
              INPUT_INHIBITION_FIELDS.all? { |key| input[key].is_a?(String) } &&
              %w[original_binding_digest seal_event_id].all? { |key| input.fetch(key).match?(/\A[0-9a-f]{64}\z/) } &&
              input["assignment_id"] == assignment_id && input["attempt_id"] == attempt_id &&
              mutation_id == "input-inhibit.#{input.fetch('seal_event_id')}" &&
              digest == Digest::SHA256.hexdigest(JSON.generate(canonical_prompt_value(input)))
            raise ArgumentError, "Invalid fixed input inhibition selector"
          end
          events = read_events(assignment_id, commit: commit).select { |event| event["attempt_id"] == attempt_id }
          authority_generation(events)
          record = events.find { |event| event["digest"] == input.fetch("original_binding_digest") && event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "record_launch" }
          data = record&.dig("payload", "data")
          seal = events.find { |event| event["digest"] == input.fetch("seal_event_id") && event["type"] == "scope_sealed" }
          accepted_seal = seal && events.find { |event| event["type"] == "authority_mutation" && event["previous_digest"] == seal.fetch("digest") &&
            %w[close_execution_scope stop_attempt].include?(event.dig("payload", "operation")) }
          lineage = ExecutionScopeLineage.new(events: events, project_id: input.fetch("project_id"), assignment_id: assignment_id,
            attempt_id: attempt_id, mapping_id: input.fetch("mapping_id"))
          unless data.is_a?(Hash) && %w[assignment_id attempt_id mapping_id].all? { |key| data[key] == input.fetch(key) } &&
              seal && accepted_seal && lineage.seal_event == seal && events.index(record) < events.index(seal) &&
              events.drop(events.index(seal) + 1).none? { |event| event["type"] == "prompt_issued" } &&
              events.none? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
            raise AttemptErrors::EvidenceUnavailable, "Input inhibition does not join accepted original seal"
          end
          origin = Ace::Herdr::Molecules::GuardedNativeOrigin.verify!(data.fetch("guarded_origin"),
            terminal_id: data.fetch("process_binding").fetch("terminal_id"), child: data.fetch("process_binding").fetch("process_identity"))
          verify_input_drained_evidence!(input.fetch("guarded_evidence"), origin)
        rescue KeyError, TypeError, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "Input inhibition canonical selection is malformed"
        end
      end
    end
  end
end
