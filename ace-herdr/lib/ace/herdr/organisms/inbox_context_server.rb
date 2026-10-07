# frozen_string_literal: true

require_relative "inbox_context_owner"
require_relative "../molecules/inbox_context_wire"

module Ace
  module Herdr
    module Organisms
      # Fixed authenticated transport for the existing Herdr context owner.
      # Lifecycle embedding selects endpoint/startup; public callers never select paths.
      class InboxContextServer
        FIELDS = {
          "status" => [],
          "snapshot_context" => %w[event_id key_generation operation_id],
          "reconcile_context" => %w[effect_binding proof_sizes],
          "verify_context_reconciliation" => %w[event_id expected_registration key_generation operation_id proof_sizes],
          "confirm_context_completion" => %w[effect_binding reconciliation_digest],
          "begin_context_operation" => %w[context_id event_id process_binding purpose],
          "end_context_operation" => %w[operation_id],
          "begin_rotation" => %w[context_id expected_key_generation],
          "rotation_challenge" => %w[disposition installed_config_digest new_public_key_bytes rotation_id],
          "attest_rotation" => %w[disposition expected_key_generation installed_config_digest new_public_key_bytes rotation_id signature],
          "commit_rotation" => %w[expected_key_generation installed_config_digest new_public_key_bytes rotation_id signer_keypair_attestation],
          "abort_rotation" => %w[rotation_id signer_keypair_attestation]
        }.freeze

        def initialize(owner:, context_id:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @owner, @context_id, @kernel = owner, context_id, kernel
        end

        # One bounded exchange; EOF never releases an operation/rotation grant.
        def handle(socket)
          deadline = Molecules::InboxContextWire.deadline
          peer = @kernel.peer(socket)
          request = Molecules::InboxContextWire.read(socket, deadline: deadline)
          unless request.is_a?(Hash) && request.keys.sort == %w[context_id operation params version] &&
              request["version"].is_a?(Integer) && request["version"] == 1 && request["context_id"] == @context_id &&
              FIELDS.key?(request["operation"]) && request["params"].is_a?(Hash) &&
              request["params"].keys.sort == FIELDS.fetch(request["operation"])
            raise ValidationError, "context request fields differ"
          end
          options = request.fetch("params").transform_keys(&:to_sym)
          if %w[reconcile_context verify_context_reconciliation].include?(request.fetch("operation"))
            bytes, signature = Molecules::InboxContextWire.read_proof(socket, sizes: options.delete(:proof_sizes), deadline: deadline)
            options.merge!(signed_bytes: bytes, signature: signature)
          end
          Molecules::InboxContextWire.require_eof!(socket, deadline: deadline)
          result = @owner.public_send(request.fetch("operation"), **options, peer: peer)
          Molecules::InboxContextWire.write(socket, {"version" => 1, "context_id" => @context_id, "result" => result}, deadline: deadline)
        rescue ValidationError, Ace::Runtime::RuntimeUnavailableError
          # Never echo caller key/signature/config/payload or filesystem errors.
          Molecules::InboxContextWire.write(socket,
            {"version" => 1, "context_id" => @context_id, "error" => {"code" => "context_blocked"}},
            deadline: deadline || Molecules::InboxContextWire.deadline)
        end
      end
    end
  end
end
