# frozen_string_literal: true

require "securerandom"
require "ace/runtime/molecules/protected_linux"
require_relative "../molecules/inbox_context_store"
require_relative "../molecules/inbox_context_key"
require_relative "inbox"
require_relative "inbox_context_effects"
require_relative "inbox_context_direct_effects"

module Ace
  module Herdr
    module Organisms
      # The existing inbox owner grants admission; this metadata never contains delivery outcomes.
      class InboxContextOwner
        include InboxContextEffects
        include InboxContextDirectEffects
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        DIGEST = /\A[0-9a-f]{64}\z/
        ID = /\A[0-9a-f]{32}\z/
        PURPOSES = %w[deliver enqueue maintenance_inventory observe_to_sign reconcile].freeze
        PEER_FIELDS = %w[gid groups host parent_pid pid started_at uid].freeze
        KEY_FIELDS = %w[config_sha256 fingerprint key_generation public_key_sha256].freeze
        OPERATION_LIMIT = 256

        def initialize(context_id:, deliveries_dir:, grants:, store:, keys:,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new, inbox: nil, completion: nil)
          token!(context_id)
          @context_id, @deliveries_dir, @store, @keys, @kernel = context_id, deliveries_dir, store, keys, kernel
          if inbox && (!inbox.is_a?(Inbox) || inbox.context_root != deliveries_dir)
            raise ValidationError, "context Inbox selection differs"
          end
          @inbox, @completion, @effect_issuers = inbox, completion, {}
          @grants = JSON.parse(JSON.generate(grants))
          validate_grants!
        end

        # Called explicitly by the trusted provisioner. Missing state on restart is never empty.
        def provision!
          key = @keys.snapshot
          validate_key!(key)
          @store.provision!({"schema" => "ace.herdr.inbox-context-control/v1", "context_id" => @context_id,
            "key" => key, "operations" => {}, "rotation" => nil, "last_rotation" => nil})
        end

        def status(peer:)
          authorize!(peer)
          transaction do |state|
            projected = state["rotation"] ? "rotation_blocked" : state.fetch("operations").empty? ? "open" : "operations_active"
            unless state["rotation"]
              begin
                projected = "key_unverifiable" unless @keys.snapshot == state.fetch("key")
              rescue ValidationError
                projected = "key_unverifiable"
              end
            end
            {"context_id" => @context_id, "key_generation" => state.fetch("key").fetch("key_generation"),
              "fingerprint" => state.fetch("key").fetch("fingerprint"),
              "active_operations" => state.fetch("operations").size,
              "state" => projected}
          end
        end

        def begin_context_operation(context_id:, purpose:, event_id:, process_binding:, peer:)
          context!(context_id)
          authorize!(peer, purpose: purpose)
          token!(event_id)
          peer!(process_binding)
          raise ValidationError, "context process binding differs from kernel peer" unless @kernel.same?(process_binding, peer)
          transaction do |state|
            raise ValidationError, "context rotation blocks admission" if state["rotation"]
            key_current!(state)
            existing = state.fetch("operations").find do |_id, operation|
              @kernel.same?(operation.fetch("peer"), peer) && operation.fetch("event_id") == event_id
            end
            if existing
              id, operation = existing
              raise ValidationError, "context admission retry binding differs" unless operation.fetch("purpose") == purpose
              direct_idle_readback!(state, operation) if operation["effect_binding"] && operation.fetch("in_flight").zero? && direct_binding?(operation)
              next operation_projection(state, id, operation)
            end
            raise ValidationError, "context admission count exceeds bounds" if state.fetch("operations").size >= OPERATION_LIMIT
            id = SecureRandom.hex(16)
            state.fetch("operations")[id] = {"peer" => copy(peer), "purpose" => purpose, "event_id" => event_id,
              "key_generation" => state.fetch("key").fetch("key_generation"), "in_flight" => 0,
              "effect_binding" => nil, "completion" => nil}
            operation_projection(state, id, state.fetch("operations").fetch(id))
          end
        end

        # Exact caller retains this grant through signing and its downstream accepted response.
        def end_context_operation(operation_id:, peer:)
          authorize!(peer)
          transaction do |state|
            operation = operation!(state, operation_id, peer)
            raise ValidationError, "context operation is still executing" unless operation.fetch("in_flight").zero?
            direct_idle_readback!(state, operation) if direct_binding?(operation)
            state.fetch("operations").delete(operation_id)
            {"operation_id" => operation_id, "state" => "ended"}
          end
        end

        # Source-owned effects must use this admission before any lifecycle/cache/event lock.
        # No metadata mutex survives the effect or a remote response wait.
        def with_operation(operation_id:, key_generation:, purpose:, event_id:, peer:)
          generation!(key_generation)
          authorize!(peer, purpose: purpose)
          key = transaction do |state|
            operation = operation!(state, operation_id, peer)
            unless operation.values_at("key_generation", "purpose", "event_id") == [key_generation, purpose, event_id]
              raise ValidationError, "context operation binding differs"
            end
            key_current!(state)
            raise ValidationError, "context operation already executing" unless operation.fetch("in_flight").zero?
            operation["in_flight"] = 1
            copy(state.fetch("key"))
          end
          # A transport return/exception is not positive downstream completion.
          # The integrating source handler must reauthenticate its canonical
          # result before clearing this count; there is no generic callback grant.
          yield key.freeze
        end

        def begin_rotation(context_id:, expected_key_generation:, peer:)
          context!(context_id)
          authorize!(peer, role: "maintenance")
          transaction do |state|
            generation!(expected_key_generation)
            if state["rotation"]
              rotation = rotation!(state, state.fetch("rotation").fetch("rotation_id"), expected_key_generation, peer)
              next rotation_projection(rotation)
            end
            expected!(state, expected_key_generation)
            key_current!(state)
            raise ValidationError, "context operations have not positively ended" unless state.fetch("operations").empty?
            Inbox.with_retained_records(deliveries_dir: @deliveries_dir) do |records|
              unless records.all? { |record| completed_record?(record) }
                raise ValidationError, "context contains unresolved events"
              end
              raise ValidationError, "context key generation is exhausted" if expected_key_generation == (1 << 63) - 1
              state["rotation"] = {"rotation_id" => SecureRandom.hex(16), "peer" => copy(peer),
                "old_key" => copy(state.fetch("key")), "challenge" => SecureRandom.hex(32), "attestation" => nil}
              rotation_projection(state.fetch("rotation"))
            end
          end
        end

        # Only the actual fixed signer account can attest, never a maintainer's claimed signer UID.
        def attest_rotation(rotation_id:, expected_key_generation:, new_public_key_bytes:,
          installed_config_digest:, disposition:, signature:, peer:)
          authorize!(peer, role: "signer")
          proposed = proposed_key!(new_public_key_bytes, installed_config_digest)
          transaction do |state|
            rotation = rotation!(state, rotation_id, expected_key_generation, nil)
            payload = attestation_payload(rotation, proposed, disposition)
            bytes = JSON.generate(payload)
            unless signature.is_a?(String) && signature.bytesize.between?(1, 16_384)
              raise ValidationError, "context signer attestation exceeds bounds"
            end
            decoded = signature.unpack1("m0")
            raise ValidationError, "context signer signature is noncanonical" unless [decoded].pack("m0") == signature
            key = Molecules::InboxContextKey.public_key!(new_public_key_bytes)
            unless key.verify(OpenSSL::Digest::SHA256.new, decoded, bytes)
              raise ValidationError, "context signer pair attestation differs"
            end
            attestation = {"attestation_id" => SecureRandom.hex(16), "peer" => copy(peer),
              "payload_sha256" => Digest::SHA256.hexdigest(bytes), "proposed_key" => proposed, "disposition" => disposition}
            previous = rotation["attestation"]
            if previous && !(previous.fetch("disposition") == "replacement" && disposition == "rollback")
              unless previous.reject { |k, _| k == "attestation_id" } == attestation.reject { |k, _| k == "attestation_id" }
                raise ValidationError, "context signer attestation conflicts"
              end
              next {"attestation_id" => previous.fetch("attestation_id")}
            end
            rotation["attestation"] = attestation
            {"attestation_id" => attestation.fetch("attestation_id")}
          end
        rescue ArgumentError, OpenSSL::PKey::PKeyError
          raise ValidationError, "context signer attestation is invalid"
        end

        def commit_rotation(rotation_id:, expected_key_generation:, new_public_key_bytes:,
          installed_config_digest:, signer_keypair_attestation:, peer:)
          authorize!(peer, role: "maintenance")
          proposed = proposed_key!(new_public_key_bytes, installed_config_digest)
          strict!(signer_keypair_attestation, %w[attestation_id])
          id!(signer_keypair_attestation.fetch("attestation_id"))
          transaction do |state|
            if !state["rotation"]
              next completed_rotation!(state, rotation_id, expected_key_generation, peer, "committed", proposed)
            end
            rotation = rotation!(state, rotation_id, expected_key_generation, peer)
            attestation = rotation.fetch("attestation")
            unless attestation && attestation.fetch("attestation_id") == signer_keypair_attestation.fetch("attestation_id") &&
                attestation.fetch("proposed_key") == proposed && attestation.fetch("disposition") == "replacement"
              raise ValidationError, "authenticated signer attestation is unavailable"
            end
            installed = @keys.snapshot
            validate_key!(installed)
            unless installed == proposed.merge("key_generation" => expected_key_generation + 1)
              raise ValidationError, "installed replacement pair/config differs"
            end
            state["key"] = installed
            finish_rotation!(state, rotation, "committed", installed)
          end
        end

        def abort_rotation(rotation_id:, signer_keypair_attestation:, peer:)
          authorize!(peer, role: "maintenance")
          strict!(signer_keypair_attestation, %w[attestation_id])
          id!(signer_keypair_attestation.fetch("attestation_id"))
          transaction do |state|
            if !state["rotation"]
              last = state.fetch("last_rotation")
              raise ValidationError, "context rotation is unavailable" unless last
              next completed_rotation!(state, rotation_id, last.fetch("old_generation"), peer, "aborted", nil)
            end
            rotation = state.fetch("rotation")
            rotation!(state, rotation_id, rotation.fetch("old_key").fetch("key_generation"), peer)
            attestation = rotation["attestation"]
            old = rotation.fetch("old_key").reject { |key, _| key == "key_generation" }
            unless attestation && attestation.fetch("attestation_id") == signer_keypair_attestation.fetch("attestation_id") &&
                attestation.fetch("disposition") == "rollback" && attestation.fetch("proposed_key") == old
              raise ValidationError, "authenticated original signer pair rollback is unavailable"
            end
            unless @keys.snapshot == rotation.fetch("old_key")
              raise ValidationError, "context original pair rollback is unverified"
            end
            finish_rotation!(state, rotation, "aborted", rotation.fetch("old_key"))
          end
        end

        # Signer receives this exact closed challenge body; never signs arbitrary caller content.
        def rotation_challenge(rotation_id:, new_public_key_bytes:, installed_config_digest:, disposition:, peer:)
          authorize!(peer, role: "signer")
          proposed = proposed_key!(new_public_key_bytes, installed_config_digest)
          transaction do |state|
            rotation = state.fetch("rotation")
            raise ValidationError, "context rotation is unavailable" unless rotation && rotation["rotation_id"] == rotation_id
            attestation_payload(rotation, proposed, disposition)
          end
        end

        private

        def transaction(&block)
          @store.transaction do |state|
            validate_state!(state)
            result = block.call(state)
            validate_state!(state)
            copy(result)
          end
        end

        def authorize!(peer, role: nil, purpose: nil)
          peer!(peer)
          @kernel.live!(peer)
          grant = @grants.find { |item| item.values_at("uid", "gid", "groups") == peer.values_at("uid", "gid", "groups") }
          unless grant && (!role || grant["role"] == role) && (!purpose || grant.fetch("purposes").include?(purpose))
            raise ValidationError, "context peer is unauthorized"
          end
          grant
        rescue Ace::Runtime::RuntimeUnavailableError
          raise ValidationError, "context original peer is unobservable"
        end

        def operation!(state, id, peer, live: true)
          id!(id)
          operation = state.fetch("operations")[id]
          unless operation && @kernel.same?(operation.fetch("peer"), peer) &&
              operation.fetch("key_generation") == state.fetch("key").fetch("key_generation")
            raise ValidationError, "context admission is stale or belongs to another process"
          end
          @kernel.live!(peer) if live
          operation
        end

        def rotation!(state, id, generation, peer)
          id!(id)
          generation!(generation)
          rotation = state["rotation"]
          unless rotation && rotation["rotation_id"] == id && rotation.fetch("old_key").fetch("key_generation") == generation &&
              (!peer || @kernel.same?(rotation.fetch("peer"), peer))
            raise ValidationError, "context rotation is stale or belongs to another process"
          end
          rotation
        end

        def rotation_projection(rotation)
          {"rotation_id" => rotation.fetch("rotation_id"), "key_generation" => rotation.fetch("old_key").fetch("key_generation"),
            "fingerprint" => rotation.fetch("old_key").fetch("fingerprint")}
        end

        def operation_projection(state, id, operation)
          {"operation_id" => id, "key_generation" => state.fetch("key").fetch("key_generation"),
            "fingerprint" => state.fetch("key").fetch("fingerprint"),
            "state" => operation.fetch("in_flight").zero? ? "admitted" : "unknown"}
        end

        def attestation_payload(rotation, proposed, disposition)
          unless %w[replacement rollback].include?(disposition) &&
              (disposition != "rollback" || proposed == rotation.fetch("old_key").reject { |k, _| k == "key_generation" })
            raise ValidationError, "context pair attestation disposition differs"
          end
          {"schema" => "ace.herdr.inbox-key-attestation/v1", "context_id" => @context_id,
            "rotation_id" => rotation.fetch("rotation_id"), "expected_key_generation" => rotation.fetch("old_key").fetch("key_generation"),
            "new_key_generation" => rotation.fetch("old_key").fetch("key_generation") + (disposition == "replacement" ? 1 : 0),
            "disposition" => disposition,
            "challenge" => rotation.fetch("challenge"), "fingerprint" => proposed.fetch("fingerprint"),
            "public_key_sha256" => proposed.fetch("public_key_sha256"), "installed_config_digest" => proposed.fetch("config_sha256")}
        end

        def proposed_key!(bytes, digest)
          digest!(digest)
          key = Molecules::InboxContextKey.public_key!(bytes)
          {"fingerprint" => Digest::SHA256.hexdigest(key.public_to_der),
            "public_key_sha256" => Digest::SHA256.hexdigest(bytes), "config_sha256" => digest}
        end

        def finish_rotation!(state, rotation, kind, key)
          state["last_rotation"] = {"rotation_id" => rotation.fetch("rotation_id"), "peer" => rotation.fetch("peer"),
            "old_generation" => rotation.fetch("old_key").fetch("key_generation"), "kind" => kind, "key" => copy(key)}
          state["rotation"] = nil
          {"rotation_id" => rotation.fetch("rotation_id"), "state" => kind,
            "key_generation" => key.fetch("key_generation"), "fingerprint" => key.fetch("fingerprint")}
        end

        def completed_rotation!(state, id, generation, peer, kind, proposed)
          id!(id)
          generation!(generation)
          last = state["last_rotation"]
          unless last && last["rotation_id"] == id && last["old_generation"] == generation && last["kind"] == kind &&
              @kernel.same?(last.fetch("peer"), peer) && (!proposed || last.fetch("key").reject { |k, _| k == "key_generation" } == proposed)
            raise ValidationError, "context completed rotation conflicts"
          end
          {"rotation_id" => id, "state" => kind, "key_generation" => last.fetch("key").fetch("key_generation"),
            "fingerprint" => last.fetch("key").fetch("fingerprint")}
        end

        def key_current!(state)
          raise ValidationError, "installed context key/config changed outside admitted rotation" unless @keys.snapshot == state.fetch("key")
        end

        def completed_record?(record)
          return false unless record.state == "completed" && record.inbox.is_a?(Hash)
          inbox = record.inbox
          receipt = inbox["reconciliation"]
          inbox["receipt_key_sha256"].is_a?(String) && DIGEST.match?(inbox["receipt_key_sha256"]) &&
            inbox["claim_generation"].is_a?(Integer) && inbox["claim_generation"].positive? &&
            inbox["binding"].is_a?(Hash) && receipt.is_a?(Hash) && receipt["outcome"] == "consumed" &&
            receipt.values_at("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding") ==
              [record.event_id, inbox["attempt_id"], inbox["claim_generation"], record.answer_digest, inbox["binding"]] &&
            Molecules::InboxReceiptAuthentication.proof_refusal(receipt).nil?
        end

        def expected!(state, expected)
          raise ValidationError, "context key generation differs" unless state.fetch("key").fetch("key_generation") == expected
        end

        def validate_grants!
          unless @grants.is_a?(Array) && @grants.size.between?(1, 64) && @grants.all? { |grant| grant.is_a?(Hash) } &&
              @grants.map { |g| g["uid"] }.uniq.size == @grants.size
            raise ValidationError, "context peer grants exceed bounds or overlap"
          end
          @grants.each do |grant|
            strict!(grant, %w[gid groups purposes role uid])
            unless %w[authority maintenance observer signer supervisor].include?(grant["role"]) &&
                grant.values_at("uid", "gid").all? { |v| v.is_a?(Integer) && v >= 0 } && groups?(grant["groups"]) &&
                grant["purposes"].is_a?(Array) && grant["purposes"] == grant["purposes"].sort.uniq &&
                (grant["purposes"] - PURPOSES).empty? && (grant["role"] != "maintenance" || grant["purposes"] == ["maintenance_inventory"])
              raise ValidationError, "context peer grant is invalid"
            end
          end
        end

        def validate_state!(state)
          strict!(state, %w[context_id key last_rotation operations rotation schema])
          unless state["schema"] == "ace.herdr.inbox-context-control/v1" && state["context_id"] == @context_id
            raise ValidationError, "context metadata belongs to another context"
          end
          validate_key!(state.fetch("key"))
          operations = state.fetch("operations")
          raise ValidationError, "context admission map exceeds bounds" unless operations.is_a?(Hash) && operations.size <= OPERATION_LIMIT
          operations.each do |id, operation|
            id!(id)
            strict!(operation, %w[completion effect_binding event_id in_flight key_generation peer purpose])
            peer!(operation.fetch("peer"))
            token!(operation.fetch("event_id"))
            unless PURPOSES.include?(operation["purpose"]) && [0, 1].include?(operation["in_flight"]) &&
                operation["in_flight"].is_a?(Integer) && operation["key_generation"] == state.fetch("key").fetch("key_generation")
              raise ValidationError, "context admission metadata differs"
            end
            if operation["effect_binding"]
              if direct_binding?(operation)
                effect = Molecules::InboxDirectEffectBinding.verify!(operation.fetch("effect_binding"), key_generation: operation.fetch("key_generation"))
                unless effect.values_at("purpose", "event_id") == operation.values_at("purpose", "event_id") && operation["completion"].nil?
                  raise ValidationError, "context retained direct binding differs"
                end
                next
              end
              effect = Molecules::InboxContextEffectBinding.verify!(operation.fetch("effect_binding"))
              unless effect.values_at("operation_id", "key_generation", "event_id", "inbox_context_id") ==
                  [id, operation.fetch("key_generation"), operation.fetch("event_id"), @context_id] && operation.fetch("purpose") == "reconcile"
                raise ValidationError, "context retained effect binding differs"
              end
              unless operation["completion"] || operation.fetch("in_flight") == 1
                raise ValidationError, "context retained effect lacks canonical completion"
              end
            end
            if operation["completion"]
              strict!(operation.fetch("completion"), %w[commit reconciliation_digest reply_digest])
              completion = operation.fetch("completion")
              unless operation["effect_binding"] && operation.fetch("in_flight").zero? &&
                  completion["commit"].is_a?(String) && completion["commit"].match?(/\A[0-9a-f]{40}\z/) &&
                  %w[reconciliation_digest reply_digest].all? { |key| completion[key].is_a?(String) && DIGEST.match?(completion[key]) }
                raise ValidationError, "context retained canonical completion differs"
              end
            end
          end
          if (rotation = state["rotation"])
            strict!(rotation, %w[attestation challenge old_key peer rotation_id])
            id!(rotation.fetch("rotation_id")); digest!(rotation.fetch("challenge")); peer!(rotation.fetch("peer"))
            validate_key!(rotation.fetch("old_key"))
            unless operations.empty? && rotation.fetch("old_key") == state.fetch("key")
              raise ValidationError, "context exclusive admission conflicts"
            end
            if (attestation = rotation["attestation"])
              strict!(attestation, %w[attestation_id disposition payload_sha256 peer proposed_key])
              id!(attestation.fetch("attestation_id")); digest!(attestation.fetch("payload_sha256")); peer!(attestation.fetch("peer"))
              strict!(attestation.fetch("proposed_key"), KEY_FIELDS - ["key_generation"])
              attestation.fetch("proposed_key").each_value { |value| digest!(value) }
              unless Digest::SHA256.hexdigest(JSON.generate(attestation_payload(rotation,
                  attestation.fetch("proposed_key"), attestation.fetch("disposition")))) == attestation.fetch("payload_sha256")
                raise ValidationError, "context retained attestation binding differs"
              end
            end
          end
          if (last = state["last_rotation"])
            strict!(last, %w[key kind old_generation peer rotation_id])
            id!(last.fetch("rotation_id")); peer!(last.fetch("peer")); generation!(last.fetch("old_generation")); validate_key!(last.fetch("key"))
            unless %w[aborted committed].include?(last["kind"]) &&
                last.fetch("key").fetch("key_generation") == last.fetch("old_generation") + (last["kind"] == "committed" ? 1 : 0)
              raise ValidationError, "context completed rotation metadata differs"
            end
          end
        end

        def validate_key!(key)
          strict!(key, KEY_FIELDS)
          generation!(key.fetch("key_generation"))
          (KEY_FIELDS - ["key_generation"]).each { |field| digest!(key.fetch(field)) }
        end

        def peer!(peer)
          strict!(peer, PEER_FIELDS)
          unless peer.values_at("pid", "parent_pid").all? { |v| v.is_a?(Integer) && v.positive? } &&
              peer.values_at("uid", "gid").all? { |v| v.is_a?(Integer) && v >= 0 } && groups?(peer["groups"]) &&
              peer["host"].is_a?(String) && peer["host"].bytesize.between?(1, 255) &&
              peer["started_at"].is_a?(String) && peer["started_at"].match?(/\Alinux:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}:[1-9][0-9]*\z/)
            raise ValidationError, "context kernel peer is invalid"
          end
        end

        def groups?(groups) = groups.is_a?(Array) && groups.size <= 64 && groups.all? { |v| v.is_a?(Integer) && v >= 0 } && groups == groups.sort.uniq
        def strict!(value, fields)
          raise ValidationError, "context fields differ" unless value.is_a?(Hash) && value.keys.all? { |key| key.is_a?(String) } && value.keys.sort == fields.sort
        end
        def token!(value)
          raise ValidationError, "context selector is invalid" unless value.is_a?(String) && TOKEN.match?(value)
        end
        def id!(value)
          raise ValidationError, "context admission id is invalid" unless value.is_a?(String) && ID.match?(value)
        end
        def digest!(value)
          raise ValidationError, "context digest is invalid" unless value.is_a?(String) && DIGEST.match?(value)
        end
        def generation!(value)
          raise ValidationError, "context generation is invalid" unless value.is_a?(Integer) && value.between?(1, (1 << 63) - 1)
        end
        def context!(value)
          raise ValidationError, "context selector differs" unless value == @context_id
        end
        def copy(value) = JSON.parse(JSON.generate(value))
      end
    end
  end
end
