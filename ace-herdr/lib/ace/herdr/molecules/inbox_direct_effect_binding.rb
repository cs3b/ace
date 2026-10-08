# frozen_string_literal: true
require "digest"
require "ace/hitl/contract"
require_relative "inbox_context_store"

module Ace
  module Herdr
    module Molecules
      # Original selectors only; DeliveryRecord is the sole effect ledger.
      module InboxDirectEffectBinding
        SCHEMA = "ace.herdr.inbox-direct-effect/v1"
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        SHA = /\A[0-9a-f]{64}\z/
        module_function

        def build(purpose:, event_id:, attempt_id:, key_generation:, selection:)
          value = {"schema" => SCHEMA, "purpose" => purpose, "event_id" => event_id,
            "attempt_id" => attempt_id, "selection" => selection}
          value["input_sha256"] = digest_input(value, key_generation)
          verify!(value, key_generation: key_generation)
        end

        def verify!(value, key_generation:)
          object!(value, %w[schema purpose event_id attempt_id selection input_sha256])
          unless value["schema"] == SCHEMA && %w[enqueue deliver].include?(value["purpose"]) &&
              %w[event_id attempt_id].all? { |key| value[key].is_a?(String) && TOKEN.match?(value[key]) } &&
              key_generation.is_a?(Integer) && key_generation.between?(1, (1 << 63) - 1)
            raise ValidationError, "direct context binding differs"
          end
          selection = value.fetch("selection")
          if value.fetch("purpose") == "enqueue"
            object!(selection, %w[reverse payload_bytes payload_sha256])
            reverse!(selection.fetch("reverse"))
            unless selection["payload_bytes"].is_a?(Integer) && selection["payload_bytes"].between?(1, 65_536) &&
                selection["payload_sha256"].is_a?(String) && SHA.match?(selection["payload_sha256"])
              raise ValidationError, "direct payload selection differs"
            end
          else
            object!(selection, %w[expected_claim_generation])
            unless selection["expected_claim_generation"].is_a?(Integer) && selection["expected_claim_generation"] >= 0
              raise ValidationError, "direct claim generation differs"
            end
          end
          unless value["input_sha256"].is_a?(String) && SHA.match?(value["input_sha256"]) &&
              value["input_sha256"] == digest_input(value, key_generation)
            raise ValidationError, "direct context input digest differs"
          end
          JSON.parse(JSON.generate(value))
        end

        def reverse!(value)
          object!(value, %w[schema session pane])
          raise ValidationError, "direct reverse schema differs" unless value["schema"] == Ace::Hitl::Providers::Ref::SCHEMA
          Ace::Hitl::Providers::Ref.new(session: value["session"], pane: value["pane"], canonical: true)
          value
        rescue Ace::Hitl::Providers::InvalidRefError
          raise ValidationError, "direct reverse address differs"
        end

        def digest_input(value, generation)
          selection = value.fetch("selection")
          normalized = if value.fetch("purpose") == "enqueue"
            {"reverse" => selection.fetch("reverse").slice("schema", "session", "pane"),
              "payload_bytes" => selection.fetch("payload_bytes"), "payload_sha256" => selection.fetch("payload_sha256")}
          else
            {"expected_claim_generation" => selection.fetch("expected_claim_generation")}
          end
          Digest::SHA256.hexdigest(JSON.generate(value.slice("purpose", "event_id", "attempt_id")
            .merge("key_generation" => generation, "selection" => normalized)))
        rescue KeyError, TypeError, NoMethodError
          raise ValidationError, "direct context selectors differ"
        end

        def object!(value, fields)
          raise ValidationError, "direct context fields differ" unless value.is_a?(Hash) && value.keys.sort == fields.sort
        end
      end
    end
  end
end
