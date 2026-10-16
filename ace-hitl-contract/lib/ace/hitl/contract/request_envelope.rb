# frozen_string_literal: true
require_relative "operator_envelope"

module Ace
  module Hitl
    module Contract
      # Explicit tagged union; unknown schemas never become an operator context.
      module RequestEnvelope
        VALIDATORS = {ManagedEnvelope::SCHEMA => ManagedEnvelope, OperatorEnvelope::SCHEMA => OperatorEnvelope}.freeze
        module_function
        def load(value, expected: {})
          data = value.is_a?(String) ? JSON.parse(value) : value
          validator = data.is_a?(Hash) && VALIDATORS[data["schema"]]
          raise InvalidEnvelope, "unsupported request context schema" unless validator
          validator.load(data, expected: expected)
        rescue JSON::ParserError
          raise InvalidEnvelope, "invalid request context JSON"
        end

        def from_facts(facts)
          envelope = load(facts.fetch("envelope"))
          expected = {request_id: facts["id"], correlation_id: facts["id"], project: facts["project"],
            requester: facts["requester"], kind: facts["kind"]}
          if envelope["schema"] == ManagedEnvelope::SCHEMA
            expected.merge!(assignment_id: facts["assignment"], attempt_id: facts["attempt"])
          else
            expected[:requester_uid] = facts["requester_uid"]
            if facts.key?("question") && (!facts["question"].is_a?(String) ||
                Digest::SHA256.hexdigest(facts["question"]) != envelope.fetch("payload_sha256"))
              raise InvalidEnvelope, "operator question payload differs from its binding"
            end
            unless facts["sensitive"] == false && !facts["effect"] && !facts["otp"] &&
                !facts["assignment"] && !facts["attempt"] && !facts["publication_binding"]
              raise InvalidEnvelope, "operator question facts cannot claim managed or secret authority"
            end
          end
          load(envelope, expected: expected)
        end
      end
    end
  end
end
