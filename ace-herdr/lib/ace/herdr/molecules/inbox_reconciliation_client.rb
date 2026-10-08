# frozen_string_literal: true
require_relative "inbox_context_wire"
require_relative "inbox_context_effect_binding"
require "ace/runtime/molecules/protected_linux"

module Ace
  module Herdr
    module Molecules
      # Actual caller owns the existing fixed reconcile_inbox wire request.
      # Selection supplies endpoints, never mutation authorization or fallback.
      class InboxReconciliationClient
        TOKEN = InboxContextEffectBinding::TOKEN
        DATA = %w[attempt_id context_operation event_id generation inbox_context_id journal_commit receipt_ref registration signature_ref state].freeze

        def initialize(selection:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new, wire: Ace::Runtime::Molecules::ProtectedSocket)
          @selection, @kernel, @wire = selection, kernel, wire
        end

        def reconcile(assignment_id:, mutation_id:, expected_generation:, event_id:, attempt_id:, receipt_key_sha256:, signed_bytes:, signature:)
          unless [assignment_id, mutation_id, event_id, attempt_id].all? { |id| id.is_a?(String) && TOKEN.match?(id) } &&
              expected_generation.is_a?(Integer) && expected_generation >= 0 && InboxContextEffectBinding.digest?(receipt_key_sha256) &&
              [signed_bytes, signature].all? { |part| part.is_a?(String) && part.bytesize.between?(1, 16_384) }
            raise ValidationError, "protected reconciliation original input differs"
          end
          receipt = InboxContextStore.decode(signed_bytes, limit: 16_384)
          unless receipt.values_at("event_id", "attempt_id") == [event_id, attempt_id] && InboxContextEffectBinding.digest?(receipt["payload_sha256"])
            raise ValidationError, "protected reconciliation signed association differs"
          end
          expected_state = {"consumed" => "completed", "superseded" => "queued"}[receipt["outcome"]]
          raise ValidationError, "protected reconciliation signed outcome differs" unless expected_state
          registration = receipt.slice("event_id", "attempt_id", "payload_sha256").merge("receipt_key_sha256" => receipt_key_sha256)
          parts = [signed_bytes, signature]
          descriptor = {"version" => 1, "bytes" => parts.sum(&:bytesize), "sha256" => Digest::SHA256.hexdigest(parts.join),
            "parts" => parts.map { |part| {"bytes" => part.bytesize, "sha256" => Digest::SHA256.hexdigest(part)} }}
          params = {"mapping_id" => @selection.fetch("mapping_id"), "assignment_id" => assignment_id, "attempt_id" => attempt_id,
            "expected_generation" => expected_generation, "event_id" => event_id, "inbox_context_id" => @selection.fetch("inbox_context_id"),
            "expected_registration" => registration, "receipt_sha256" => descriptor.fetch("parts")[0].fetch("sha256"),
            "signature_sha256" => descriptor.fetch("parts")[1].fetch("sha256"), "transfer" => descriptor}
          authority = @selection.fetch("authority")
          path = authority.fetch("socket_path")
          @wire.root_path!(File.dirname(path), directory: true, owner: authority.fetch("uid"))
          endpoint = @wire.socket_identity(path)
          raise ValidationError, "protected reconciliation authority endpoint differs" unless endpoint.last == authority.fetch("uid")
          deadline = @wire.deadline(30)
          @wire.connect(path, deadline: deadline) do |socket|
            original = @kernel.peer(socket)
            verify_peer!(original, authority, path, endpoint)
            @wire.write(socket, {"version" => 1, "project_id" => @selection.fetch("project_id"), "operation" => "reconcile_inbox",
              "mutation_id" => mutation_id, "params" => params}, deadline: deadline, limit: 16_384)
            InboxContextWire.write_proof(socket, parts: parts, deadline: deadline)
            socket.shutdown(Socket::SHUT_WR)
            reply = InboxContextWire.read(socket, deadline: deadline)
            unless @kernel.same?(original, @kernel.peer(socket))
              raise ValidationError, "protected reconciliation authority incarnation changed"
            end
            verify_peer!(original, authority, path, endpoint)
            verify_reply!(reply, params, mutation_id, expected_state)
          end
        rescue KeyError, TypeError, ArgumentError, Ace::Runtime::Error, IOError, SystemCallError
          raise ValidationError, "protected reconciliation is unconfirmed; retain the original mutation for exact recovery"
        end

        private

        def verify_peer!(peer, authority, path, endpoint)
          unless peer.values_at("uid", "gid", "groups") == authority.values_at("uid", "gid", "groups") && @wire.socket_identity(path) == endpoint
            raise ValidationError, "protected reconciliation authority principal differs"
          end
          @kernel.live!(peer)
        end

        def verify_reply!(reply, params, mutation_id, expected_state)
          unless reply.is_a?(Hash) && reply.keys.sort == %w[data status transport] && reply["status"] == "ok" &&
              reply["transport"].is_a?(Hash) && reply["transport"].keys == ["replayed"] && [true, false].include?(reply.dig("transport", "replayed"))
            raise ValidationError, "protected reconciliation authority refused or completion is unconfirmed"
          end
          data = reply.fetch("data")
          unless data.is_a?(Hash) && data.keys.sort == DATA &&
              data.values_at("event_id", "attempt_id", "inbox_context_id", "registration") == params.values_at("event_id", "attempt_id", "inbox_context_id", "expected_registration") &&
              data["state"] == expected_state && data["generation"].is_a?(Integer) && data["generation"] == params.fetch("expected_generation") + 1 &&
              data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A[0-9a-f]{40}\z/)
            raise ValidationError, "protected reconciliation accepted projection differs"
          end
          effect = InboxContextEffectBinding.verify!(data.fetch("context_operation"))
          expected = params.slice("mapping_id", "assignment_id", "attempt_id", "event_id", "inbox_context_id", "receipt_sha256", "signature_sha256")
            .merge("project_id" => @selection.fetch("project_id"), "mutation_id" => mutation_id, "registration" => params.fetch("expected_registration"))
          raise ValidationError, "protected reconciliation original effect differs" unless expected.all? { |key, value| effect.fetch(key) == value }
          %w[receipt signature].each do |kind|
            ref = data.fetch("#{kind}_ref")
            part = params.fetch("transfer").fetch("parts")[kind == "receipt" ? 0 : 1]
            unless ref.is_a?(Hash) && ref.keys.sort == %w[artifact_id bytes ref sha256] && ref["artifact_id"].is_a?(String) &&
                ref["artifact_id"].match?(/\A[0-9a-f]{32}\z/) && ref["ref"] == "evidence/imports/#{ref['artifact_id']}" &&
                ref.values_at("bytes", "sha256") == part.values_at("bytes", "sha256")
              raise ValidationError, "protected reconciliation imported proof differs"
            end
          end
          data.reject { |key, _| key == "context_operation" }.merge("replayed" => reply.fetch("transport").fetch("replayed"))
        end
      end
    end
  end
end
