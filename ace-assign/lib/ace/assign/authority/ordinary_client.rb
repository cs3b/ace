# frozen_string_literal: true

require_relative "ordinary_peer"
require_relative "transfer_codec"

module Ace
  module Assign
    module Authority
      # Installed selection is supplied by the caller's trusted composition.
      # This client never selects a journal, local fallback or execution identity.
      class OrdinaryClient
        Reply = Struct.new(:data, :replayed, keyword_init: true)

        def initialize(project_id:, service:, verify_selection:, peer: OrdinaryPeer.new)
          @project_id, @service, @verify_selection, @peer = project_id, service, verify_selection, peer
        end

        def call(operation, params, mutation_id: nil, upload_parts: nil, purpose: nil, timeout: 30)
          unless operation.is_a?(String) && params.is_a?(Hash) && !params.key?("transfer") &&
              timeout.is_a?(Numeric) && timeout.finite? && timeout.positive?
            raise ArgumentError, "invalid ordinary authority request"
          end
          @verify_selection.call
          wire = Ace::Runtime::Molecules::ProtectedSocket
          path = @service.fetch("socket_path")
          wire.root_path!(File.dirname(path), directory: true, owner: @service.fetch("uid"))
          before = wire.socket_identity(path, mode: 0o660)
          raise AttemptErrors::UnauthorizedIdentity, "ordinary endpoint owner differs" unless before.last == @service.fetch("uid")
          codec = TransferCodec.new
          descriptor = codec.descriptor(upload_parts, purpose: purpose) if upload_parts
          parameters = descriptor ? params.merge("transfer" => descriptor) : params
          deadline = wire.deadline([timeout, 30].min)
          wire.connect(path, deadline: deadline) do |socket|
            observed = @peer.capture(socket, deadline: deadline)
            unless observed.values_at("uid", "gid") == @service.values_at("uid", "gid") && wire.socket_identity(path, mode: 0o660) == before
              raise AttemptErrors::UnauthorizedIdentity, "ordinary endpoint peer changed"
            end
            @verify_selection.call
            wire.write(socket, {"version" => 1, "operation" => operation, "mutation_id" => mutation_id,
              "project_id" => @project_id, "params" => parameters}, deadline: deadline, limit: 16_384)
            codec.send(socket, parts: upload_parts, descriptor: descriptor, purpose: purpose, deadline: deadline) if upload_parts
            socket.shutdown(Socket::SHUT_WR)
            result = wire.read(wire::Ingress.new(socket), deadline: deadline, limit: 16_384)
            unless result.is_a?(Hash) && result.keys.sort == %w[data status transport] && result["status"] == "ok" &&
                result["data"].is_a?(Hash) && result["transport"].is_a?(Hash) &&
                result["transport"].keys == ["replayed"] && [true, false].include?(result["transport"]["replayed"])
              code = result.is_a?(Hash) && result["error"].is_a?(Hash) ? result["error"]["code"] : nil
              raise AttemptErrors::EvidenceUnavailable, "ordinary authority refused (#{code || 'invalid_response'}); retain original mutation"
            end
            Reply.new(data: result.fetch("data"), replayed: result.fetch("transport").fetch("replayed"))
          end
        rescue SystemCallError, IOError, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "ordinary authority outcome unavailable; retain original mutation; no local fallback"
        end
      end
    end
  end
end
