# frozen_string_literal: true
require "securerandom"
require_relative "deployment"
require_relative "transfer_codec"

module Ace
  module Assign
    module Authority
      class Client
        Reply = Struct.new(:data, :replayed, :parts, keyword_init: true)
        attr_reader :mapping_id
        def initialize(mapping_id:, deployment: Deployment.load, kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @mapping_id, @deployment, @kernel = mapping_id, deployment, kernel
          @map = deployment.mapping(mapping_id)
          @service = deployment.authority(@map.fetch("authority_id"))
        end

        def call(operation, params, mutation_id: nil, timeout: 5, upload_parts: nil, download: false, purpose: nil)
          @deployment.verify!(mapping_id, kernel: @kernel)
          wire = Ace::Runtime::Molecules::ProtectedSocket
          path = @service.fetch("socket_path")
          before = wire.socket_identity(path)
          raise Ace::Runtime::RuntimeUnavailableError, "authority endpoint owner differs" unless before.last == @service.fetch("uid")
          raise ArgumentError, "cannot upload and download on one request" if upload_parts && download
          codec = transfer_codec if upload_parts || download
          descriptor = codec.descriptor(upload_parts, purpose: purpose) if upload_parts
          parameters = upload_parts ? params.merge("transfer" => descriptor) : params
          deadline = wire.deadline([timeout, 30].min)
          wire.connect(path, deadline: deadline) do |socket|
            peer = @kernel.peer(socket)
            unless peer["uid"] == @service.fetch("uid") && peer["gid"] == @service.fetch("gid") &&
                peer["groups"] == @service.fetch("groups") && wire.socket_identity(path) == before
              raise AttemptErrors::UnauthorizedIdentity, "authority endpoint peer changed"
            end
            wire.write(socket, {"version" => 1, "operation" => operation,
              "mutation_id" => mutation_id, "project_id" => @map.fetch("project_id"),
              "params" => parameters.merge("mapping_id" => mapping_id)}, deadline: deadline, limit: upload_parts || download ? 16_384 : wire::LIMIT)
            if upload_parts
              codec.send(socket, parts: upload_parts, descriptor: descriptor, purpose: purpose, deadline: deadline)
              socket.shutdown(Socket::SHUT_WR)
            end
            result = wire.read(socket, deadline: deadline, limit: 16_384)
            unless result.is_a?(Hash) && result["status"] == "ok" && result["data"].is_a?(Hash)
              code = result.is_a?(Hash) ? result.dig("error", "code") : nil
              raise AttemptErrors::EvidenceUnavailable, "protected authority refused (#{code || 'invalid_response'})"
            end
            transport = result.fetch("transport")
            unless transport.is_a?(Hash) && transport.keys == ["replayed"] && [true, false].include?(transport["replayed"])
              raise AttemptErrors::EvidenceUnavailable, "authority replay metadata is unavailable"
            end
            parts = if download
              codec.receive(socket, descriptor: result.fetch("data").fetch("transfer"), purpose: purpose, deadline: deadline) do |input|
                Array.new(input.count) { |index| input.bytes(index: index) }
              end
            end
            Reply.new(data: result.fetch("data"), replayed: transport.fetch("replayed"), parts: parts)
          end
        rescue SystemCallError, IOError
          raise AttemptErrors::EvidenceUnavailable, "protected authority connection unavailable; no local fallback"
        end
        private

        def transfer_codec
          peer = @kernel.capture(Process.pid)
          project = @deployment.project(@map.fetch("project_id"))
          installed = project.fetch("peer_credentials").fetch(peer.fetch("uid").to_s)
          unless peer["gid"] == installed["gid"] && peer["groups"] == installed["groups"]
            raise AttemptErrors::UnauthorizedIdentity, "transfer scratch principal differs"
          end
          TransferCodec.new(root: installed.fetch("scratch_root"))
        end
      end
    end
  end
end
