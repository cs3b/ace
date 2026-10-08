# frozen_string_literal: true

require "ace/runtime/molecules/protected_linux"
require "ace/runtime/molecules/protected_socket"
require_relative "inbox_context_effect_binding"
require_relative "guarded_native_origin"

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
          params = binding.slice("mapping_id", "assignment_id", "attempt_id", "inbox_context_id", "event_id")
            .merge("effect_binding" => binding, "reconciliation_digest" => reconciliation_digest)
          query!(operation: "inbox_context_completion", params: params) { |data| verify_data!(data, binding, reconciliation_digest) }
        end

        # Identity evidence only: callers must independently own admission and
        # exact native context/thread selection before any native effect.
        def original!(assignment_id:, attempt_id:, event_id:, inbox_context_id:, purpose:, payload_sha256:, receipt_key_sha256:)
          params = {"mapping_id" => @mapping_id, "assignment_id" => assignment_id, "attempt_id" => attempt_id,
            "event_id" => event_id, "inbox_context_id" => inbox_context_id, "purpose" => purpose,
            "payload_sha256" => payload_sha256, "receipt_key_sha256" => receipt_key_sha256}
          unless %w[assignment_id attempt_id event_id inbox_context_id mapping_id].all? { |key|
              params[key].is_a?(String) && params[key].match?(/\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/) } &&
              %w[enqueue deliver].include?(purpose) && %w[payload_sha256 receipt_key_sha256].all? { |key| InboxContextEffectBinding.digest?(params[key]) }
            raise ValidationError, "original context selection differs"
          end
          query!(operation: "inbox_context_original", params: params) { |data| verify_original!(data, params) }
        end

        private

        def query!(operation:, params:)
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
            @wire.write(socket, {"version" => 1, "project_id" => @project_id, "operation" => operation,
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
            yield reply.fetch("data")
          end
        rescue KeyError, TypeError, ArgumentError, Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
          raise ValidationError, "context canonical query is unavailable"
        end

        def verify_original!(data, params)
          fields = %w[assignment_id attempt_id commit event_id guarded_origin inbox_context_id mapping_id native_binding native_channel original_binding_digest process_binding project_id purpose registered registration schema]
          registration = params.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
          unless data.is_a?(Hash) && data.keys.sort == fields && data["schema"] == "ace.assign.inbox-context-original/v1" &&
              data.slice("assignment_id", "attempt_id", "event_id", "inbox_context_id", "mapping_id", "purpose") ==
                params.slice("assignment_id", "attempt_id", "event_id", "inbox_context_id", "mapping_id", "purpose") &&
              data["project_id"] == @project_id && data["registration"] == registration &&
              [true, false].include?(data["registered"]) && (params.fetch("purpose") != "deliver" || data["registered"]) &&
              data["commit"].is_a?(String) && data["commit"].match?(/\A[0-9a-f]{40}\z/) &&
              InboxContextEffectBinding.digest?(data["original_binding_digest"]) &&
              data["process_binding"].is_a?(Hash) && data["native_binding"].is_a?(Hash)
            raise ValidationError, "original context projection differs"
          end
          process = data.fetch("process_binding")
          native = data.fetch("native_binding")
          channel = data.fetch("native_channel")
          path = channel["socket_path"] if channel.is_a?(Hash)
          unless channel.is_a?(Hash) && channel.keys.sort == %w[socket_path version] && channel["version"] == "0.9.3" &&
              path.is_a?(String) && path.valid_encoding? && path.bytesize.between?(1, 107) && path.start_with?("/") &&
              !path.include?("\0") && File.expand_path(path) == path
            raise ValidationError, "original context native channel differs"
          end
          origin = process["native_origin"]
          unless process.keys.sort == %w[native_origin pane process_identity runtime session shell_identity terminal_id] &&
              native.keys.sort == %w[scope_binding_event_id scope_generation server_identity service_invocation_id socket_identity workspace_id] &&
              origin.is_a?(Hash) && origin.keys.sort == %w[command cwd pane server_identity socket_identity tab workspace] &&
              process["runtime"] == "herdr" && process["shell_identity"] == process["process_identity"] &&
              process["session"] == native["workspace_id"] && origin["workspace"] == process["session"] &&
              origin["pane"] == process["pane"] && origin["server_identity"] == native["server_identity"] &&
              origin["socket_identity"] == native["socket_identity"] && native["server_identity"].is_a?(Hash) &&
              process.dig("process_identity", "parent_pid") == native.dig("server_identity", "pid")
            raise ValidationError, "original context native association differs"
          end
          GuardedNativeOrigin.verify!(data.fetch("guarded_origin"), terminal_id: process.fetch("terminal_id"), child: process.fetch("process_identity"))
          immutable(data)
        end

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
