# frozen_string_literal: true
require_relative "../molecules/inbox_direct_effect_binding"

module Ace
  module Herdr
    module Organisms
      # DeliveryRecord owns notification intent; native IO is outside its lock.
      module InboxGuardedWake
        def guarded_wake_pending?(event:, binding:, claim:)
          with_event(event, create_lock: false) do |record|
            next false unless record&.state == "delivered"
            guarded_queue_record!(record, binding, claim)
            %w[pending not_issued].include?(record.inbox.dig("wake", "status"))
          end
        end

        def prepare_guarded_wake(event:, binding:, claim:, operation_id:)
          with_event(event, create_lock: false) do |record|
            next nil unless record&.state == "delivered"
            guarded_queue_record!(record, binding, claim)
            wake = record.inbox.fetch("wake")
            next nil unless %w[pending not_issued].include?(wake.fetch("status"))
            unless wake.values_at("operation_id", "input_sha256") == [operation_id, binding.fetch("input_sha256")]
              raise ValidationError, "guarded wake invocation differs"
            end
            issuing = wake.reject { |key, _| key == "code" }.merge("status" => "issuing")
            save(record.advance_inbox(state: "delivered", inbox: record.inbox.merge("wake" => issuing),
              detail: {"action" => "wake-issuing"}, timestamp: Time.now.utc.iso8601))
            issuing
          end
        end

        def finish_guarded_wake(event:, binding:, claim:, issuing:, result:)
          with_event(event, create_lock: false) do |record|
            guarded_queue_record!(record, binding, claim)
            unless record.state == "delivered" && record.inbox.fetch("wake") == issuing && issuing.fetch("status") == "issuing"
              raise ValidationError, "guarded wake completion changed"
            end
            status = case result.fetch("outcome")
            when "submitted" then "sent"
            when "not_issued" then "not_issued"
            else "uncertain"
            end
            wake = issuing.merge("status" => status)
            wake["code"] = result.fetch("code") if status == "not_issued"
            record = record.advance_inbox(state: "delivered", inbox: record.inbox.merge("wake" => wake),
              detail: {"action" => "wake-#{status}"}, timestamp: Time.now.utc.iso8601)
            save(record)
            public_record(record)
          end
        end

        def verify_guarded_wake_admission!(binding:, claim:, operation_id:)
          with_event(binding.fetch("event_id"), create_lock: false) do |record|
            guarded_queue_record!(record, binding, claim)
            unless claim.slice("claim_generation", "claim_owner") == record.inbox.slice("claim_generation", "claim_owner") &&
                record.inbox.fetch("wake").values_at("operation_id", "input_sha256") == [operation_id, binding.fetch("input_sha256")]
              raise ValidationError, "guarded wake admission association differs"
            end
            true
          end
        end

        private

        def queue_issuer!(record)
          issuer = record.inbox.fetch("queue_issuer")
          generation = record.inbox.fetch("claim_generation")
          unless issuer.is_a?(Hash) && issuer.keys.sort == %w[input_sha256 key_generation operation_id] &&
              issuer["operation_id"].is_a?(String) && issuer["operation_id"].match?(/\A[0-9a-f]{32}\z/) &&
              issuer["key_generation"].is_a?(Integer) && issuer["key_generation"].positive? && generation.positive?
            raise ValidationError, "guarded queue issuer differs"
          end
          original = record.inbox.fetch("original_context")
          expected = Molecules::InboxDirectEffectBinding.build(purpose: "deliver", event_id: record.event_id,
            attempt_id: record.inbox.fetch("attempt_id"), key_generation: issuer.fetch("key_generation"),
            selection: {"expected_claim_generation" => generation - 1}, original: original)
          owner = Digest::SHA256.hexdigest(JSON.generate([original.fetch("inbox_context_id"), issuer.fetch("operation_id")]))
          retained_owner = record.inbox["claim_owner"]
          superseded = record.state == "queued" && record.inbox.dig("reconciliation", "outcome") == "superseded" &&
            record.inbox.dig("reconciliation", "claim_generation") == generation
          unless issuer.fetch("input_sha256") == expected.fetch("input_sha256") &&
              (retained_owner == owner || (retained_owner.nil? && superseded)) &&
              record.history.count { |entry| entry.slice("action", "claim_generation", "claim_owner") ==
                {"action" => "claim", "claim_generation" => generation, "claim_owner" => owner} } == 1
            raise ValidationError, "guarded queue claim attribution differs"
          end
          issuer
        end

        def guarded_queue_record!(record, binding, claim)
          issuer = queue_issuer!(record)
          receipt = record.inbox.fetch("receipt")
          unless binding.fetch("purpose") == "deliver" && binding.fetch("event_id") == record.event_id &&
              record.inbox.fetch("original_context") == binding.slice(*Molecules::InboxDirectEffectBinding::ORIGINAL_FIELDS) &&
              record.inbox.fetch("attempt_id") == binding.fetch("attempt_id") && record.inbox.fetch("receipt_key_sha256") == key_fingerprint &&
              claim.slice("claim_generation", "claim_owner") == record.inbox.slice("claim_generation", "claim_owner") &&
              receipt.is_a?(Hash) && receipt.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding") ==
                {"event_id" => record.event_id, "attempt_id" => record.inbox.fetch("attempt_id"), "claim_generation" => record.inbox.fetch("claim_generation"),
                  "payload_sha256" => record.answer_digest, "binding" => record.inbox.fetch("binding")}
            raise ValidationError, "guarded wake queue receipt differs"
          end
          wake = record.inbox.fetch("wake")
          fields = %w[binding_digest claim_generation input_sha256 operation_id status]
          fields << "code" if wake.is_a?(Hash) && wake["status"] == "not_issued"
          unless wake.is_a?(Hash) && wake.keys.sort == fields.sort &&
              %w[pending issuing sent not_issued uncertain none].include?(wake["status"]) &&
              wake["claim_generation"] == record.inbox.fetch("claim_generation") && wake["binding_digest"] == record.inbox.fetch("original_binding_digest") &&
              wake["operation_id"].is_a?(String) && wake["operation_id"].match?(/\A[0-9a-f]{32}\z/) &&
              wake["input_sha256"].is_a?(String) && wake["input_sha256"].match?(/\A[0-9a-f]{64}\z/) &&
              (wake["status"] != "not_issued" || %w[guard_mismatch origin_unavailable origin_exited agent_blocked agent_not_ready target_missing submission_busy].include?(wake["code"]))
            raise ValidationError, "guarded wake retention differs"
          end
          issuer
        end
      end
    end
  end
end
