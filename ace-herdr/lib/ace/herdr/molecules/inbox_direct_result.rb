# frozen_string_literal: true
require_relative "inbox_direct_effect_binding"

module Ace
  module Herdr
    module Molecules
      module InboxDirectResult
        SCHEMA = "ace.herdr.inbox-direct-result/v1"
        RECORD_FIELDS = %w[event_id attempt_id payload_sha256 receipt_key_sha256 claim_generation state original_context original_binding_digest origin_target target binding session pane submission_intent wake].freeze
        module_function

        def build(operation:, record:, admission_state: nil)
          projected = record.slice(*RECORD_FIELDS)
          projected["wake"] = record["wake"].is_a?(Hash) ? record.fetch("wake").slice("status") : nil
          result = {"schema" => SCHEMA, "operation" => operation, "record" => projected}
          result["admission_state"] = admission_state unless operation == "status_context"
          verify!(result, operation: operation, event_id: record.fetch("event_id"), attempt_id: record.fetch("attempt_id"), original: record.fetch("original_context"))
        end

        def verify!(value, operation:, event_id:, attempt_id:, original:)
          fields = %w[schema operation record]
          fields << "admission_state" unless operation == "status_context"
          InboxDirectEffectBinding.object!(value, fields)
          unless value["schema"] == SCHEMA && value["operation"] == operation &&
              %w[enqueue_context deliver_context status_context].include?(operation) &&
              (operation == "status_context" || %w[idle unknown].include?(value["admission_state"])) &&
              (operation != "enqueue_context" || value["admission_state"] == "idle")
            raise ValidationError, "direct context result differs"
          end
          record = value.fetch("record")
          InboxDirectEffectBinding.object!(record, RECORD_FIELDS)
          InboxDirectEffectBinding.original!(record.fetch("original_context"))
          raise ValidationError, "direct result original selection differs" unless record.fetch("original_context") == original
          raise ValidationError, "direct result original record differs" unless record["original_binding_digest"].is_a?(String) && InboxDirectEffectBinding::SHA.match?(record["original_binding_digest"])
          unless record.values_at("event_id", "attempt_id") == [event_id, attempt_id] &&
              %w[payload_sha256 receipt_key_sha256].all? { |key| record[key].is_a?(String) && InboxDirectEffectBinding::SHA.match?(record[key]) } &&
              record["claim_generation"].is_a?(Integer) && record["claim_generation"] >= 0 &&
              %w[queued claimed uncertain delivered completed].include?(record["state"]) &&
              [true, false].include?(record["submission_intent"])
            raise ValidationError, "direct context retained result association differs"
          end
          Ace::Hitl::Providers::Ref.new(session: record["session"], pane: record["pane"], canonical: true)
          %w[origin_target target binding].each do |key|
            target = record[key]
            base = %w[session pane terminal_id agent thread thread_kind]
            allowed = base + (key == "binding" ? %w[agent_status payload_sha256] : key == "target" ? %w[agent_status] : [])
            unless target.is_a?(Hash) && (target.keys - allowed).empty? && (base - target.keys).empty? &&
                target.values.all? { |item| item.is_a?(String) && item.valid_encoding? && item.bytesize.between?(1, 1024) && !item.include?("\0") } &&
                %w[codex pi].include?(target["agent"]) && target["thread_kind"] == "id" &&
                (key != "binding" || target["payload_sha256"] == record["payload_sha256"])
              raise ValidationError, "direct context result target differs"
            end
          end
          if record["wake"]
            InboxDirectEffectBinding.object!(record["wake"], %w[status])
            raise ValidationError, "direct context wake observation differs" unless %w[none sent pending].include?(record.dig("wake", "status"))
          end
          value
        rescue KeyError, TypeError, Ace::Hitl::Providers::InvalidRefError
          raise ValidationError, "direct context result is unavailable"
        end
      end
    end
  end
end
