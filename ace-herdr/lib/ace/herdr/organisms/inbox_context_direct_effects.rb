# frozen_string_literal: true
require_relative "../molecules/inbox_direct_effect_binding"
require_relative "../molecules/inbox_direct_result"

require_relative "../molecules/protected_native_control"

module Ace
  module Herdr
    module Organisms
      # Fixed methods on the same context admission and DeliveryRecord owner.
      module InboxContextDirectEffects
        def enqueue_context(operation_id:, key_generation:, event_id:, attempt_id:, reverse:, payload_bytes:, payload_sha256:, payload:, original:, peer:)
          authorize!(peer, purpose: "enqueue")
          binding = Molecules::InboxDirectEffectBinding.build(purpose: "enqueue", event_id: event_id,
            attempt_id: attempt_id, key_generation: key_generation, original: original,
            selection: {"reverse" => reverse, "payload_bytes" => payload_bytes, "payload_sha256" => payload_sha256})
          unless payload.is_a?(String) && payload.bytesize == payload_bytes &&
              payload.encoding == Encoding::UTF_8 && payload.valid_encoding? && !payload.include?("\0") &&
              Digest::SHA256.hexdigest(payload) == payload_sha256
            raise ValidationError, "direct enqueue payload differs"
          end
          selected = @keys.selected
          original_query = direct_original_query!(operation_id, binding, selected, peer, payload_sha256: payload_sha256)
          unless original_query.fetch("process_binding").values_at("session", "pane") == reverse.values_at("session", "pane")
            raise ValidationError, "direct reverse address differs from original launch"
          end
          dispatch = false
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation.values_at("purpose", "event_id", "key_generation") == ["enqueue", event_id, key_generation] && operation.fetch("original") == original.merge("attempt_id" => attempt_id) &&
                selected.fetch(:snapshot) == state.fetch("key")
              raise ValidationError, "direct enqueue admission differs"
            end
            if operation["original_binding_digest"] && operation.fetch("original_binding_digest") != original_query.fetch("original_binding_digest")
              raise ValidationError, "direct original launch record changed"
            end
            if operation["effect_binding"]
              raise ValidationError, "direct enqueue input changed" unless operation.fetch("effect_binding") == binding
              raise ValidationError, "direct enqueue issuer remains unresolved" if @effect_issuers.key?(operation_id) || operation.fetch("in_flight") == 1
              direct_idle_readback!(state, operation)
            else
              raise ValidationError, "direct enqueue admission is uncertain" unless operation.fetch("in_flight").zero?
              operation["original_binding_digest"] = original_query.fetch("original_binding_digest")
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
            box.enqueue(event: event_id, attempt: attempt_id, ref: reverse, payload: payload, original_context: original, original_binding_digest: original_query.fetch("original_binding_digest"))
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

        def deliver_context(operation_id:, key_generation:, event_id:, attempt_id:, expected_claim_generation:, original:, peer:)
          authorize!(peer, purpose: "deliver")
          binding = Molecules::InboxDirectEffectBinding.build(purpose: "deliver", event_id: event_id,
            attempt_id: attempt_id, key_generation: key_generation, original: original,
            selection: {"expected_claim_generation" => expected_claim_generation})
          selected = @keys.selected
          record = source_inbox!(selected).retained_status(event: event_id)
          original_query = direct_original_query!(operation_id, binding, selected, peer, payload_sha256: record.fetch("payload_sha256"))
          unless record.fetch("original_binding_digest") == original_query.fetch("original_binding_digest")
            raise ValidationError, "direct retained original record differs"
          end
          dispatch = false
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation.values_at("purpose", "event_id", "key_generation") == ["deliver", event_id, key_generation] && operation.fetch("original") == original.merge("attempt_id" => attempt_id) &&
                selected.fetch(:snapshot) == state.fetch("key")
              raise ValidationError, "direct delivery admission differs"
            end
            direct_delivery_predecessors!(state, operation_id, event_id, key_generation)
            if operation["original_binding_digest"] && operation.fetch("original_binding_digest") != original_query.fetch("original_binding_digest")
              raise ValidationError, "direct original launch record changed"
            end
            if operation["effect_binding"]
              raise ValidationError, "direct delivery input changed" unless operation.fetch("effect_binding") == binding
              raise ValidationError, "direct delivery issuer remains live" if @effect_issuers.key?(operation_id)
              # Unknown replay is observation only; it cannot become known idle.
              direct_idle_readback!(state, operation) if operation.fetch("in_flight").zero?
            else
              raise ValidationError, "direct delivery admission is uncertain" unless operation.fetch("in_flight").zero?
              source_inbox!(selected).verify_direct_delivery(binding)
              operation["original_binding_digest"] = original_query.fetch("original_binding_digest")
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
                claim_owner: Digest::SHA256.hexdigest(JSON.generate([@context_id, operation_id])),
                operation_id: operation_id, key_generation: key_generation, effect_binding: binding)
            end
            claim = transaction { |state| copy(operation!(state, operation_id, peer)["admitted_claim"]) }
            unless claim && claim.fetch("kind") == "wake"
              box.deliver(event: event_id, expected_claim_generation: expected_claim_generation,
                expected_attempt: attempt_id, prepared_claim: claim && claim.slice("claim_generation", "claim_owner"))
            end
            direct_guarded_wake!(operation_id, peer, binding, claim, original_query, box) if claim
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

        def status_context(event_id:, attempt_id:, original:, peer:)
          grant = authorize!(peer)
          unless (grant.fetch("purposes") & %w[enqueue deliver observe_to_sign reconcile]).any?
            raise ValidationError, "context event observation is unauthorized"
          end
          token!(event_id); token!(attempt_id)
          Molecules::InboxDirectEffectBinding.original!(original)
          context!(original.fetch("inbox_context_id"))
          record = source_inbox!(@keys.selected).retained_status(event: event_id)
          raise ValidationError, "context event attempt differs" unless record.fetch("attempt_id") == attempt_id && record.fetch("original_context") == original
          immutable_effect(Molecules::InboxDirectResult.build(operation: "status_context", record: record))
        end

        private

        # Remote canonical identity read occurs outside the store transaction.
        # Both sides recheck the original durable admission/key before effects.
        def direct_original_query!(operation_id, binding, selected, peer, payload_sha256:)
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless selected.fetch(:snapshot) == state.fetch("key") &&
                operation.fetch("original") == binding.slice(*Molecules::InboxDirectEffectBinding::ORIGINAL_FIELDS, "attempt_id") &&
                operation.values_at("purpose", "event_id") == binding.values_at("purpose", "event_id")
              raise ValidationError, "original query admission differs"
            end
          end
          result = @completion.original!(assignment_id: binding.fetch("assignment_id"), attempt_id: binding.fetch("attempt_id"),
            event_id: binding.fetch("event_id"), inbox_context_id: binding.fetch("inbox_context_id"), purpose: binding.fetch("purpose"),
            payload_sha256: payload_sha256, receipt_key_sha256: selected.fetch(:snapshot).fetch("fingerprint"))
          unless result.slice(*Molecules::InboxDirectEffectBinding::ORIGINAL_FIELDS, "attempt_id", "event_id", "purpose") ==
              binding.slice(*Molecules::InboxDirectEffectBinding::ORIGINAL_FIELDS, "attempt_id", "event_id", "purpose")
            raise ValidationError, "original authority association differs"
          end
          result
        rescue NoMethodError, KeyError, TypeError
          raise ValidationError, "original authority identity is unavailable"
        end

        def direct_queue_control!(original)
          native = original.fetch("native_binding")
          server = native.fetch("server_identity")
          mapping = {"worker_uid" => server.fetch("uid"), "worker_gid" => server.fetch("gid"), "worker_groups" => server.fetch("groups"),
            "native" => original.fetch("native_channel").merge("server_identity" => server, "socket_identity" => native.fetch("socket_identity"))}
          Molecules::ProtectedNativeControl.new(mapping: mapping, kernel: @kernel)
        end

        def direct_guarded_wake!(operation_id, peer, binding, claim, original, box)
          return unless box.guarded_wake_pending?(event: binding.fetch("event_id"), binding: binding, claim: claim)
          control = direct_queue_control!(original)
          native_binding = original.fetch("process_binding").merge("guarded_origin" => original.fetch("guarded_origin"))
          begin
            control.prompt_preflight!(native_binding)
          rescue Ace::Runtime::RuntimeUnavailableError
            # This readonly preflight never entered notification IO. Pending
            # stays positively unissued; a fresh explicit retry owns recovery.
            return
          end
          issuing = transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation["admitted_claim"] == claim && operation["effect_binding"] == binding &&
                operation["issuer_state"] == "running" && @effect_issuers[operation_id].equal?(Thread.current) &&
                operation.fetch("original_binding_digest") == original.fetch("original_binding_digest")
              raise ValidationError, "guarded wake issuer changed"
            end
            direct_delivery_predecessors!(state, operation_id, binding.fetch("event_id"), operation.fetch("key_generation"))
            box.prepare_guarded_wake(event: binding.fetch("event_id"), binding: binding, claim: claim, operation_id: operation_id)
          end
          return unless issuing
          result = control.queue_wake(binding: native_binding)
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation["admitted_claim"] == claim && operation["effect_binding"] == binding &&
                operation["issuer_state"] == "running" && @effect_issuers[operation_id].equal?(Thread.current)
              raise ValidationError, "guarded wake finish admission changed"
            end
            box.finish_guarded_wake(event: binding.fetch("event_id"), binding: binding, claim: claim, issuing: issuing, result: result)
          end
        end

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
          record = if binding.fetch("purpose") == "enqueue"
            box.verify_direct_enqueue(binding)
          else
            claim = operation["admitted_claim"]
            if claim && claim["kind"] == "wake"
              operation_id = state.fetch("operations").find { |_id, retained| retained.equal?(operation) }&.first
              box.verify_guarded_wake_admission!(binding: binding, claim: claim, operation_id: operation_id)
            end
            box.verify_direct_delivery(binding, require_idle: true).fetch("record")
          end
          unless record.fetch("original_binding_digest") == operation.fetch("original_binding_digest")
            raise ValidationError, "direct readback original record changed"
          end
          record
        end
      end
    end
  end
end
