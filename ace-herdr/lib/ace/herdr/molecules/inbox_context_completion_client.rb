# frozen_string_literal: true

require "ace/runtime/molecules/protected_linux"
require "ace/runtime/molecules/protected_socket"
require_relative "inbox_context_effect_binding"

module Ace
  module Herdr
    module Molecules
      # Fixed installed authority selection; there is no caller-selected verifier
      # callback, generic finished flag, current Inbox lookup or local fallback.
      class InboxContextCompletionClient
        FIELDS = %w[binding claim_generation commit effect_binding effect_binding_digest receipt_ref reconciliation_digest registration reply_digest schema signature_ref state].freeze
        LIMIT = 16_384

        def initialize(authority:, project_id:, mapping_id:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new,
          wire: Ace::Runtime::Molecules::ProtectedSocket)
          @authority, @project_id, @mapping_id, @kernel, @wire = authority, project_id, mapping_id, kernel, wire
        end

        def verify!(effect_binding:, reconciliation_digest:)
          binding = InboxContextEffectBinding.verify!(effect_binding)
          unless binding.values_at("project_id", "mapping_id") == [@project_id, @mapping_id] && InboxContextEffectBinding.digest?(reconciliation_digest)
            raise ValidationError, "context completion selection differs"
          end
          path = @authority.fetch("socket_path")
          @wire.root_path!(File.dirname(path), directory: true, owner: @authority.fetch("uid"))
          endpoint = @wire.socket_identity(path)
          raise ValidationError, "context completion authority endpoint differs" unless endpoint.last == @authority.fetch("uid")
          deadline = @wire.deadline(30)
          @wire.connect(path, deadline: deadline) do |socket|
            original = @kernel.peer(socket)
            unless original.values_at("uid", "gid", "groups") == @authority.values_at("uid", "gid", "groups") && @wire.socket_identity(path) == endpoint
              raise ValidationError, "context completion authority principal differs"
            end
            @kernel.live!(original)
            params = binding.slice("mapping_id", "assignment_id", "attempt_id", "inbox_context_id", "event_id")
              .merge("effect_binding" => binding, "reconciliation_digest" => reconciliation_digest)
            @wire.write(socket, {"version" => 1, "project_id" => @project_id, "operation" => "inbox_context_completion",
              "mutation_id" => nil, "params" => params}, deadline: deadline, limit: LIMIT)
            socket.shutdown(Socket::SHUT_WR)
            reply = @wire.read(socket, deadline: deadline, limit: LIMIT)
            unless @kernel.same?(original, @kernel.peer(socket)) && @wire.socket_identity(path) == endpoint
              raise ValidationError, "context completion authority incarnation changed"
            end
            @kernel.live!(original)
            unless reply.is_a?(Hash) && reply.keys.sort == %w[data status transport] && reply["status"] == "ok" &&
                reply["transport"] == {"replayed" => false}
              raise ValidationError, "context completion canonical query refused"
            end
            verify_data!(reply.fetch("data"), binding, reconciliation_digest)
          end
        rescue KeyError, TypeError, ArgumentError, Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
          raise ValidationError, "context completion is unavailable"
        end

        private

        def verify_data!(data, expected, reconciliation_digest)
          unless data.is_a?(Hash) && data.keys.sort == FIELDS && data["schema"] == "ace.assign.inbox-context-completion/v1" &&
              InboxContextEffectBinding.verify!(data.fetch("effect_binding")) == expected &&
              data["effect_binding_digest"] == InboxContextEffectBinding.digest(expected) && data["reconciliation_digest"] == reconciliation_digest &&
              data["commit"].is_a?(String) && data["commit"].match?(/\A[0-9a-f]{40}\z/) && InboxContextEffectBinding.digest?(data["reply_digest"]) &&
              %w[completed queued].include?(data["state"]) && data["claim_generation"].is_a?(Integer) && data["claim_generation"].positive? &&
              data["registration"] == expected.fetch("registration") && data["binding"].is_a?(Hash) &&
              data["binding"].slice("project_id", "assignment_id", "attempt_id", "mapping_id", "inbox_context_id", "event_id", "registration", "receipt_sha256", "signature_sha256") ==
                expected.slice("project_id", "assignment_id", "attempt_id", "mapping_id", "inbox_context_id", "event_id", "registration", "receipt_sha256", "signature_sha256") &&
              data.dig("binding", "claim_generation").is_a?(Integer) && data.dig("binding", "claim_generation") == data["claim_generation"]
            raise ValidationError, "context completion proof binding differs"
          end
          %w[receipt signature].each do |kind|
            reference = data.fetch("#{kind}_ref")
            unless reference.is_a?(Hash) && reference.keys.sort == %w[artifact_id bytes ref sha256] &&
                reference["artifact_id"].is_a?(String) && reference["artifact_id"].match?(/\A[0-9a-f]{32}\z/) &&
                reference["ref"] == "evidence/imports/#{reference['artifact_id']}" && reference["sha256"] == expected.fetch("#{kind}_sha256") &&
                reference["bytes"].is_a?(Integer) && reference["bytes"].between?(1, 16_384)
              raise ValidationError, "context completion immutable reference differs"
            end
          end
          immutable(data)
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
      end
    end
  end
end
