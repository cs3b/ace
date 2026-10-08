# frozen_string_literal: true

require_relative "../molecules/inbox_context_effect_binding"
require_relative "../molecules/inbox_context_completion_client"

module Ace
  module Herdr
    module Organisms
      # Source effect methods on the same context owner and admission metadata.
      module InboxContextEffects
        SNAPSHOT_FIELDS = %w[event_id attempt_id payload_sha256 receipt_key_sha256 claim_generation state origin_target target binding codex_submission codex_receipt].freeze

        def observe_context(operation_id:, key_generation:, event_id:, attempt_id:, claim_generation:, peer:, deadline:)
          authorize!(peer, purpose: "observe_to_sign")
          before = snapshot_context(operation_id: operation_id, key_generation: key_generation, event_id: event_id, peer: peer, deadline: deadline)
          transaction do |state|
            unless operation!(state, operation_id, peer).fetch("purpose") == "observe_to_sign"
              raise ValidationError, "native observation admission purpose differs"
            end
          end
          selected = @keys.selected
          result = source_inbox!(selected).observe_consumption(event: event_id, expected_attempt: attempt_id,
            expected_claim_generation: claim_generation, deadline: deadline)
          after = snapshot_context(operation_id: operation_id, key_generation: key_generation, event_id: event_id, peer: peer, deadline: deadline)
          raise ValidationError, "native observation admission changed" unless before == after
          immutable_effect(before.slice("context_id", "operation_id", "key_generation").merge(result))
        end

        def snapshot_context(operation_id:, key_generation:, event_id:, peer:, deadline: nil)
          authorize!(peer)
          generation!(key_generation)
          selected = @keys.selected
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation.values_at("key_generation", "event_id") == [key_generation, event_id] &&
                %w[observe_to_sign reconcile].include?(operation.fetch("purpose"))
              raise ValidationError, "context snapshot admission differs"
            end
            raise ValidationError, "context snapshot key changed" unless selected.fetch(:snapshot) == state.fetch("key")
          end
          record = source_inbox!(selected).retained_observation_status(event: event_id, deadline: deadline)
          projection = record.slice(*SNAPSHOT_FIELDS)
          immutable_effect({"context_id" => @context_id, "operation_id" => operation_id,
            "key_generation" => key_generation, "record" => projection})
        end

        def verify_context_reconciliation(operation_id:, key_generation:, event_id:, expected_registration:, signed_bytes:, signature:, peer:)
          authorize!(peer, role: "authority", purpose: "reconcile")
          selected = @keys.selected
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation.values_at("key_generation", "purpose", "event_id") == [key_generation, "reconcile", event_id] &&
                selected.fetch(:snapshot) == state.fetch("key")
              raise ValidationError, "context proof read admission differs"
            end
          end
          receipt = Molecules::InboxContextStore.decode(signed_bytes, limit: 16_384)
          unless signature.is_a?(String) && signature.bytesize.between?(1, 16_384)
            raise ValidationError, "context signature exceeds bounds"
          end
          verified = source_inbox!(selected).verify_reconciliation(event: event_id, receipt: receipt,
            signed_bytes: signed_bytes, signature: signature, expected_registration: expected_registration)
          raise ValidationError, "context retained signed proof refused" if verified["reconciliation_refusal"]
          immutable_effect(verified.slice(*SNAPSHOT_FIELDS).merge("registration" => expected_registration))
        end

        def reconcile_context(effect_binding:, signed_bytes:, signature:, peer:)
          authorize!(peer, role: "authority", purpose: "reconcile")
          binding = Molecules::InboxContextEffectBinding.verify!(effect_binding)
          unless binding.fetch("inbox_context_id") == @context_id &&
              [signed_bytes, signature].all? { |bytes| bytes.is_a?(String) && bytes.bytesize.between?(1, 16_384) } &&
              [signed_bytes, signature].map { |bytes| Digest::SHA256.hexdigest(bytes.b) } == binding.values_at("receipt_sha256", "signature_sha256")
            raise ValidationError, "context signed effect bytes differ"
          end
          receipt = Molecules::InboxContextStore.decode(signed_bytes, limit: 16_384)
          selected = @keys.selected
          dispatch = false
          id = binding.fetch("operation_id")
          transaction do |state|
            operation = operation!(state, id, peer)
            unless operation.values_at("key_generation", "purpose", "event_id") == binding.values_at("key_generation") + ["reconcile", binding.fetch("event_id")] &&
                selected.fetch(:snapshot) == state.fetch("key") && binding.dig("registration", "receipt_key_sha256") == state.dig("key", "fingerprint")
              raise ValidationError, "context signed effect admission differs"
            end
            if operation["effect_binding"]
              raise ValidationError, "context signed effect changed" unless operation.fetch("effect_binding") == binding
              raise ValidationError, "context effect producer remains live" if @effect_issuers.key?(id)
            else
              raise ValidationError, "context operation is already uncertain" unless operation.fetch("in_flight").zero?
              operation["effect_binding"] = binding
              operation["in_flight"] = 1
              @effect_issuers[id] = Thread.current
              dispatch = true
            end
          end
          box = source_inbox!(selected)
          arguments = {event: binding.fetch("event_id"), receipt: receipt, signed_bytes: signed_bytes,
            signature: signature, expected_registration: binding.fetch("registration")}
          if dispatch
            result = box.reconcile(**arguments)
            raise ValidationError, "context signed reconciliation refused" if result["reconciliation_refusal"]
          end
          verified = box.verify_reconciliation(**arguments)
          raise ValidationError, "context accepted reconciliation is unavailable" if verified["reconciliation_refusal"]
          immutable_effect({"effect_binding" => binding, "effect_binding_digest" => Molecules::InboxContextEffectBinding.digest(binding),
            "state" => verified.fetch("state"), "claim_generation" => verified.fetch("claim_generation"),
            "registration" => binding.fetch("registration"), "binding" => verified.fetch("binding")})
        ensure
          if dispatch && id
            transaction do |_state|
              @effect_issuers.delete(id) if @effect_issuers[id].equal?(Thread.current)
            end
          end
        end

        # Called after Assign exclusions and its canonical commit have settled.
        # The only positive authority is the fixed authenticated read-only query.
        def confirm_context_completion(effect_binding:, reconciliation_digest:, peer:)
          authorize!(peer, role: "authority", purpose: "reconcile")
          binding = Molecules::InboxContextEffectBinding.verify!(effect_binding)
          raise ValidationError, "context completion selection differs" unless binding.fetch("inbox_context_id") == @context_id
          unless @completion.is_a?(Molecules::InboxContextCompletionClient)
            raise ValidationError, "fixed canonical completion authority is unavailable"
          end
          transaction do |state|
            completion_admission!(state, binding, peer)
          end
          proof = @completion.verify!(effect_binding: binding, reconciliation_digest: reconciliation_digest)
          transaction do |state|
            operation = completion_admission!(state, binding, peer)
            completion = proof.slice("commit", "reconciliation_digest", "reply_digest")
            if operation && operation["completion"]
              unless operation.fetch("completion").values_at("reconciliation_digest", "reply_digest") == completion.values_at("reconciliation_digest", "reply_digest")
                raise ValidationError, "context canonical completion changed"
              end
              completion = operation.fetch("completion")
            end
            if operation
              operation["completion"] = completion
              operation["in_flight"] = 0
            end
            source_inbox!(@keys.selected).record_canonical_completion!(proof: proof)
            retire_returned_direct_issuers!(state, binding, proof)
            {"operation_id" => binding.fetch("operation_id"), "effect_binding_digest" => Molecules::InboxContextEffectBinding.digest(binding),
              "state" => "confirmed", "completion" => completion}
          end
        end

        private

        def completion_admission!(state, binding, peer)
          state.fetch("operations").each do |id, other|
            next if id == binding.fetch("operation_id") || other.fetch("purpose") != "reconcile" ||
              other.fetch("event_id") != binding.fetch("event_id") || other.fetch("key_generation") != binding.fetch("key_generation")
            unless other.fetch("in_flight").zero? && other["effect_binding"].nil? && !@effect_issuers.key?(id) &&
                @kernel.same?(other.fetch("peer"), peer)
              raise ValidationError, "another original-event reconciliation admission remains unresolved or foreign"
            end
          end
          return nil unless state.fetch("operations").key?(binding.fetch("operation_id"))
          operation = operation!(state, binding.fetch("operation_id"), peer)
          unless operation["effect_binding"] == binding && !@effect_issuers.key?(binding.fetch("operation_id"))
            raise ValidationError, "context completion effect differs or producer remains live"
          end
          operation
        end

        def retire_returned_direct_issuers!(state, binding, proof)
          selected = @keys.selected
          unless selected.fetch(:snapshot) == state.fetch("key") &&
              binding.fetch("key_generation") == state.fetch("key").fetch("key_generation") &&
              binding.fetch("registration").fetch("receipt_key_sha256") == state.fetch("key").fetch("fingerprint")
            raise ValidationError, "direct settlement key selection differs"
          end
          ids = state.fetch("operations").filter_map do |id, operation|
            next unless direct_binding?(operation) && operation["issuer_state"] == "returned" &&
              operation.fetch("event_id") == binding.fetch("event_id") &&
              operation.fetch("effect_binding").fetch("attempt_id") == binding.fetch("attempt_id")
            unless operation.fetch("effect_binding").slice(*Molecules::InboxDirectEffectBinding::ORIGINAL_FIELDS) == binding.slice(*Molecules::InboxDirectEffectBinding::ORIGINAL_FIELDS)
              raise ValidationError, "direct settlement original context differs"
            end
            raise ValidationError, "direct settlement producer remains live" if @effect_issuers.key?(id)
            if operation.fetch("purpose") == "deliver" && operation["admitted_claim"].nil? && operation.fetch("in_flight").zero?
              # A source-returned known-idle observation created no claim.
              # It still requires exact retained record plus canonical proof.
              direct_idle_readback!(state, operation)
              source_inbox!(selected).verify_direct_canonical_observation(binding: operation.fetch("effect_binding"), proof: proof)
            else
              source_inbox!(selected).verify_direct_canonical_settlement(binding: operation.fetch("effect_binding"),
                admitted_claim: operation["admitted_claim"], proof: proof, operation_id: id)
            end
            id
          end
          ids.each { |id| state.fetch("operations").delete(id) }
        end

        def source_inbox!(selected)
          raise ValidationError, "fixed context Inbox owner is unavailable" unless @inbox.is_a?(Inbox)
          @inbox.with_receipt_public_key(selected.fetch(:key))
        end

        def immutable_effect(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable_effect(item)] }.freeze
          when Array then value.map { |item| immutable_effect(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
      end
    end
  end
end
