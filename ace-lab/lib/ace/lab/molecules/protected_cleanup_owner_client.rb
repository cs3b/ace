# frozen_string_literal: true

require "ace/runtime/molecules/protected_socket"
require "ace/assign/authority/transfer_codec"
require "ace/assign/atoms/evidence_digest"
require_relative "../atoms/protected_workspace_prune_input"
require_relative "../atoms/service_input"

module Ace
  module Lab
    module Molecules
      # Fixed installed endpoint. A fresh execute connection must independently
      # match the original canonical binding; identity EOF is never permission.
      class ProtectedCleanupOwnerClient
        PATH = "/run/lab/protected-workspace-cleanup.sock"
        SCHEMA = "lab.protected-workspace-cleanup-control/v1"
        LIMIT = 16_384

        def initialize(observer:, scratch_root:, wire: Ace::Runtime::Molecules::ProtectedSocket)
          @observer, @wire = observer, wire
          @codec = Ace::Assign::Authority::TransferCodec.new(root: scratch_root)
        end

        def identity!
          deadline = @wire.deadline(5)
          connect(deadline) do |socket, binding|
            @wire.write(socket, {"schema" => SCHEMA, "kind" => "identity"}, deadline: deadline, limit: LIMIT)
            socket.shutdown(Socket::SHUT_WR)
            reply = @wire.read(socket, deadline: deadline, limit: LIMIT)
            eof!(socket, deadline)
            unless reply.is_a?(Hash) && reply.keys.sort == %w[kind operation_owner_binding schema] &&
                reply["schema"] == SCHEMA && reply["kind"] == "identity" &&
                digest(reply["operation_owner_binding"]) == digest(binding)
              raise SecurityError, "cleanup identity reply differs from observed original owner"
            end
            binding
          end
        end

        def execute!(request:, operation_owner_binding:)
          request = JSON.parse(JSON.generate(request), create_additions: false, max_nesting: 16)
          fields = %w[request_id input_digest claim_binding request_event_digest dispatch_event_digest input]
          Atoms::ProtectedWorkspacePruneInput.object!(request, fields)
          Atoms::ProtectedWorkspacePruneInput.token!(request.fetch("request_id"))
          (fields - %w[request_id input]).each { |key| Atoms::ProtectedWorkspacePruneInput.digest!(request.fetch(key)) }
          bytes = JSON.generate(request.fetch("input"))
          input = Atoms::ProtectedWorkspacePruneInput.parse(bytes)
          unless Atoms::ServiceInput.digest(input) == request.fetch("input_digest")
            raise SecurityError, "cleanup execute input differs"
          end
          Atoms::ProtectedWorkspacePruneInput.freeze_value(request)
          deadline = @wire.deadline(300)
          admission_deadline = [deadline, @wire.deadline(5)].min
          connect(admission_deadline) do |socket, observed|
            unless digest(observed) == digest(operation_owner_binding)
              raise SecurityError, "cleanup execute owner differs from original dispatch"
            end
            frame = request.merge("schema" => SCHEMA, "kind" => "execute",
              "operation_owner_binding_digest" => digest(observed))
            @wire.write(socket, frame, deadline: admission_deadline, limit: 65_536)
            socket.shutdown(Socket::SHUT_WR)
            reply = @wire.read(socket, deadline: deadline, limit: LIMIT)
            unless reply.is_a?(Hash) && reply.keys.sort == %w[input_digest kind receipt_ref request_id schema] &&
                reply.values_at("schema", "kind", "request_id", "input_digest") ==
                  [SCHEMA, "result", request.fetch("request_id"), request.fetch("input_digest")]
              raise SecurityError, "cleanup result identity differs"
            end
            ref = reply.fetch("receipt_ref")
            Atoms::ProtectedWorkspacePruneInput.reference!(ref)
            descriptor = {"version" => 1, "bytes" => ref.fetch("bytes"), "sha256" => ref.fetch("sha256"),
              "parts" => [ref.slice("bytes", "sha256")]}
            @codec.receive(socket, descriptor: descriptor, purpose: :artifacts, deadline: deadline) do |received|
              Atoms::ProtectedWorkspacePruneInput.freeze_value(ref)
              {receipt_ref: ref, bytes: received.bytes.freeze}.freeze
            end
          end
        end

        private

        def digest(value) = Ace::Assign::Atoms::EvidenceDigest.digest(value)

        def connect(deadline)
          @wire.root_path!(PATH)
          before = @wire.socket_identity(PATH)
          raise SecurityError, "cleanup endpoint owner differs" unless before.last == 0
          @wire.connect(PATH, deadline: deadline) do |socket|
            observed = @observer.observe!(socket: socket, deadline: deadline)
            raise SecurityError, "cleanup endpoint was replaced" unless @wire.socket_identity(PATH) == before
            yield socket, observed
          end
        end

        def eof!(socket, deadline)
          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            unless remaining.positive? && IO.select([socket], nil, nil, remaining)
              raise Ace::Runtime::RuntimeUnavailableError, "cleanup reply EOF deadline expired"
            end
            byte = socket.read_nonblock(1, exception: false)
            next if byte == :wait_readable
            raise SecurityError, "cleanup reply has trailing bytes" unless byte.nil?
            return
          end
        end
      end
    end
  end
end
