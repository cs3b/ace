# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        private

        # Authentication binds the whole accepted original record, including
        # its native guard. A plain process-binding digest cannot substitute.
        def original_prompt_record!(events, state, params:)
          unless state.is_a?(Hash) && state["guarded_origin"].is_a?(Hash) && state["process_binding"].is_a?(Hash)
            raise AttemptErrors::EvidenceUnavailable, "Original guarded record is unavailable"
          end
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "Original guarded record chain is corrupt"
          end
          records = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "record_launch" }
          raise AttemptErrors::EvidenceUnavailable, "Original guarded record is ambiguous or absent" unless records.size == 1
          record = records.first
          data = record.fetch("payload").fetch("data")
          unless data.is_a?(Hash) && record["attempt_id"] == params.fetch("attempt_id") &&
              %w[mapping_id assignment_id attempt_id].all? { |key| data[key] == params.fetch(key) } &&
              data["process_binding"] == state.fetch("process_binding") && data["guarded_origin"] == state.fetch("guarded_origin")
            raise AttemptErrors::EvidenceUnavailable, "Original guarded record differs from accepted launch"
          end
          binding = data.fetch("process_binding")
          origin = Ace::Herdr::Molecules::GuardedNativeOrigin.verify!(data.fetch("guarded_origin"),
            terminal_id: binding.fetch("terminal_id"), child: binding.fetch("process_identity"))
          {"binding_digest" => record.fetch("digest").dup.freeze, "origin" => origin}.freeze
        rescue KeyError, TypeError, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "Original guarded record is malformed"
        end
      end
    end
  end
end
