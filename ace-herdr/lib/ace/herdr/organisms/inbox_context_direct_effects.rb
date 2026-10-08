# frozen_string_literal: true
require_relative "../molecules/inbox_direct_effect_binding"
require_relative "../molecules/inbox_direct_result"

module Ace
  module Herdr
    module Organisms
      # Fixed methods on the same context admission and DeliveryRecord owner.
      module InboxContextDirectEffects
        def enqueue_context(operation_id:, key_generation:, event_id:, attempt_id:, reverse:, payload_bytes:, payload_sha256:, payload:, peer:)
          authorize!(peer, purpose: "enqueue")
          binding = Molecules::InboxDirectEffectBinding.build(purpose: "enqueue", event_id: event_id,
            attempt_id: attempt_id, key_generation: key_generation,
            selection: {"reverse" => reverse, "payload_bytes" => payload_bytes, "payload_sha256" => payload_sha256})
          unless payload.is_a?(String) && payload.bytesize == payload_bytes &&
              payload.encoding == Encoding::UTF_8 && payload.valid_encoding? && !payload.include?("\0") &&
              Digest::SHA256.hexdigest(payload) == payload_sha256
            raise ValidationError, "direct enqueue payload differs"
          end
          selected = @keys.selected
          dispatch = false
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation.values_at("purpose", "event_id", "key_generation") == ["enqueue", event_id, key_generation] &&
                selected.fetch(:snapshot) == state.fetch("key")
              raise ValidationError, "direct enqueue admission differs"
            end
            if operation["effect_binding"]
              raise ValidationError, "direct enqueue input changed" unless operation.fetch("effect_binding") == binding
              raise ValidationError, "direct enqueue issuer remains unresolved" if @effect_issuers.key?(operation_id) || operation.fetch("in_flight") == 1
              direct_idle_readback!(state, operation)
            else
              raise ValidationError, "direct enqueue admission is uncertain" unless operation.fetch("in_flight").zero?
              operation["effect_binding"] = binding
              operation["in_flight"] = 1
              operation["issuer_state"] = "running"
              operation["issuer_epoch"] = @epoch
              @effect_issuers[operation_id] = Thread.current
              dispatch = true
            end
          end
          box = source_inbox!(selected)
          if dispatch
            box.enqueue(event: event_id, attempt: attempt_id, ref: reverse, payload: payload)
            record_direct_return!(operation_id, peer, binding)
          end
          result = box.verify_direct_enqueue(binding)
          if dispatch
            transaction do |state|
              operation = operation!(state, operation_id, peer)
              unless operation["effect_binding"] == binding && @effect_issuers[operation_id].equal?(Thread.current) &&
                  selected.fetch(:snapshot) == state.fetch("key")
                raise ValidationError, "direct enqueue completion changed"
              end
              direct_idle_readback!(state, operation)
              operation["in_flight"] = 0
            end
          end
          immutable_effect(Molecules::InboxDirectResult.build(operation: "enqueue_context", record: result, admission_state: "idle"))
        ensure
          if dispatch
            transaction { |_state| @effect_issuers.delete(operation_id) if @effect_issuers[operation_id].equal?(Thread.current) }
          end
        end

        def deliver_context(operation_id:, key_generation:, event_id:, attempt_id:, expected_claim_generation:, peer:)
          authorize!(peer, purpose: "deliver")
          binding = Molecules::InboxDirectEffectBinding.build(purpose: "deliver", event_id: event_id,
            attempt_id: attempt_id, key_generation: key_generation,
            selection: {"expected_claim_generation" => expected_claim_generation})
          selected = @keys.selected
          dispatch = false
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation.values_at("purpose", "event_id", "key_generation") == ["deliver", event_id, key_generation] &&
                selected.fetch(:snapshot) == state.fetch("key")
              raise ValidationError, "direct delivery admission differs"
            end
            direct_delivery_predecessors!(state, operation_id, event_id, key_generation)
            if operation["effect_binding"]
              raise ValidationError, "direct delivery input changed" unless operation.fetch("effect_binding") == binding
              raise ValidationError, "direct delivery issuer remains live" if @effect_issuers.key?(operation_id)
              # Unknown replay is observation only; it cannot become known idle.
              direct_idle_readback!(state, operation) if operation.fetch("in_flight").zero?
            else
              raise ValidationError, "direct delivery admission is uncertain" unless operation.fetch("in_flight").zero?
              source_inbox!(selected).verify_direct_delivery(binding)
              operation["effect_binding"] = binding
              operation["in_flight"] = 1
              operation["issuer_state"] = "running"
              operation["issuer_epoch"] = @epoch
              @effect_issuers[operation_id] = Thread.current
              dispatch = true
            end
          end
          box = source_inbox!(selected)
          if dispatch
            transaction do |state|
              operation = operation!(state, operation_id, peer)
              unless operation["effect_binding"] == binding && operation["issuer_state"] == "running" &&
                  @effect_issuers[operation_id].equal?(Thread.current)
                raise ValidationError, "direct claim preparation ownership differs"
              end
              direct_delivery_predecessors!(state, operation_id, event_id, key_generation)
              operation["admitted_claim"] = box.prepare_direct_delivery(event: event_id,
                expected_claim_generation: expected_claim_generation, expected_attempt: attempt_id,
                claim_owner: Digest::SHA256.hexdigest(JSON.generate([@context_id, operation_id])))
            end
            claim = transaction { |state| copy(operation!(state, operation_id, peer)["admitted_claim"]) }
            box.deliver(event: event_id, expected_claim_generation: expected_claim_generation,
              expected_attempt: attempt_id, prepared_claim: claim)
            record_direct_return!(operation_id, peer, binding)
          end
          verified = box.verify_direct_delivery(binding)
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation["effect_binding"] == binding && selected.fetch(:snapshot) == state.fetch("key")
              raise ValidationError, "direct delivery completion changed"
            end
            if dispatch && verified.fetch("idle") && @effect_issuers[operation_id].equal?(Thread.current)
              direct_idle_readback!(state, operation)
              operation["in_flight"] = 0
            end
            Molecules::InboxDirectResult.build(operation: "deliver_context", record: verified.fetch("record"),
              admission_state: operation.fetch("in_flight").zero? ? "idle" : "unknown")
          end
        ensure
          if dispatch
            transaction { |_state| @effect_issuers.delete(operation_id) if @effect_issuers[operation_id].equal?(Thread.current) }
          end
        end

        def status_context(event_id:, attempt_id:, peer:)
          grant = authorize!(peer)
          unless (grant.fetch("purposes") & %w[enqueue deliver observe_to_sign reconcile]).any?
            raise ValidationError, "context event observation is unauthorized"
          end
          token!(event_id); token!(attempt_id)
          record = source_inbox!(@keys.selected).retained_status(event: event_id)
          raise ValidationError, "context event attempt differs" unless record.fetch("attempt_id") == attempt_id
          immutable_effect(Molecules::InboxDirectResult.build(operation: "status_context", record: record))
        end

        private

        def record_direct_return!(operation_id, peer, binding)
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation["effect_binding"] == binding && operation["issuer_state"] == "running" &&
                @effect_issuers[operation_id].equal?(Thread.current)
              raise ValidationError, "direct issuer return ownership differs"
            end
            operation["issuer_state"] = "returned"
          end
        end

        def direct_binding?(operation)
          operation.dig("effect_binding", "schema") == Molecules::InboxDirectEffectBinding::SCHEMA
        end

        def direct_delivery_predecessors!(state, operation_id, event_id, key_generation)
          state.fetch("operations").each do |id, other|
            next if id == operation_id || other.fetch("event_id") != event_id || other.fetch("key_generation") != key_generation
            if other.fetch("in_flight") == 1 || other.fetch("purpose") == "reconcile" || @effect_issuers.key?(id)
              raise ValidationError, "direct delivery preceding issuer remains unresolved"
            end
          end
        end

        def direct_idle_readback!(state, operation)
          selected = @keys.selected
          raise ValidationError, "direct readback key changed" unless selected.fetch(:snapshot) == state.fetch("key")
          binding = Molecules::InboxDirectEffectBinding.verify!(operation.fetch("effect_binding"), key_generation: operation.fetch("key_generation"))
          box = source_inbox!(selected)
          if binding.fetch("purpose") == "enqueue"
            box.verify_direct_enqueue(binding)
          else
            box.verify_direct_delivery(binding, require_idle: true)
          end
        end
      end
    end
  end
end
