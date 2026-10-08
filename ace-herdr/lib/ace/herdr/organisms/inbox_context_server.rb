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
          "enqueue_context" => %w[attempt_id event_id key_generation operation_id original payload_bytes payload_sha256 reverse],
          "status_context" => %w[attempt_id event_id original],
          "deliver_context" => %w[attempt_id event_id expected_claim_generation key_generation operation_id original],
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

        def fields_for(request)
          fields = FIELDS.fetch(request.fetch("operation"))
          if request["operation"] == "begin_context_operation" && %w[enqueue deliver].include?(request.dig("params", "purpose"))
            (fields + ["original"]).sort
          else
            fields
          end
        end
        private :fields_for

        # One bounded exchange; EOF never releases an operation/rotation grant.
        def handle(socket)
          deadline = Molecules::InboxContextWire.deadline
          peer = @kernel.peer(socket)
          request = Molecules::InboxContextWire.read(socket, deadline: deadline)
          unless request.is_a?(Hash) && request.keys.sort == %w[context_id operation params version] &&
              request["version"].is_a?(Integer) && request["version"] == 1 && request["context_id"] == @context_id &&
              FIELDS.key?(request["operation"]) && request["params"].is_a?(Hash) &&
              request["params"].keys.sort == fields_for(request)
            raise ValidationError, "context request fields differ"
          end
          options = request.fetch("params").transform_keys(&:to_sym)
          if request.fetch("operation") == "enqueue_context"
            options[:payload] = Molecules::InboxContextWire.read_payload(socket, size: options.fetch(:payload_bytes), deadline: deadline)
            unless Digest::SHA256.hexdigest(options.fetch(:payload)) == options.fetch(:payload_sha256)
              raise ValidationError, "context payload digest differs"
            end
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
