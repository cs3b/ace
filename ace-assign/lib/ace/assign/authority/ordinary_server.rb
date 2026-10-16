# frozen_string_literal: true

require_relative "socket_server"

module Ace
  module Assign
    module Authority
      # Explicit ordinary admission over Assign's existing wire/transfer owner.
      # The Lab composition supplies a trusted installed admission object and
      # closed handlers. No protected Deployment or kernel adapter is replaced.
      class OrdinaryServer < SocketServer
        def initialize(admission:, lifecycle:, hitl_service: nil)
          @admission = admission
          super(service: admission.service, lifecycle: lifecycle, hitl_service: hitl_service)
        end

        private

        def verify_listener!
          @admission.verify_listener!
        end

        def authorize_transfer!(request:, peer:, role:, deadline:)
          @lifecycle.authorize_transfer!(request: request, peer: peer, role: role, deadline: deadline)
        end

        def dispatch_lifecycle(request:, peer:, role:, deadline:, transfer: nil)
          @lifecycle.dispatch(request: request, peer: peer, role: role, deadline: deadline, transfer: transfer)
        end

        def receive(socket)
          deadline = wire.deadline(30)
          peer = @admission.peer(socket, deadline: deadline)
          ingress = Ace::Runtime::Molecules::ProtectedSocket::Ingress.new(socket)
          frame = wire.read(ingress, deadline: [deadline, wire.deadline(5)].min, limit: 16_384, with_size: true)
          request = frame.fetch(:data)
          unless request.is_a?(Hash) && request.keys.sort == %w[mutation_id operation params project_id version] &&
              request["version"].is_a?(Integer) && request["version"] == 1 &&
              request["operation"].is_a?(String) && request["params"].is_a?(Hash)
            raise ArgumentError, "invalid ordinary authority envelope"
          end
          role = @admission.authorize!(request: request, peer: peer, deadline: deadline)
          binding = @lifecycle.transfer_binding(request)
          bodyless_read!(ingress, deadline) unless binding && binding.fetch(:direction) == :upload
          # Both binary bodies and EOF use ancillary-rejecting reads. Replies
          # use the original duplex socket through the wrapper below.
          dispatch_request(Duplex.new(socket, ingress), request, peer, role, deadline, frame_bytes: frame.fetch(:bytesize))
        rescue ArgumentError, KeyError, AttemptErrors::MalformedTransfer
          refusal(socket, "invalid_input")
        rescue AttemptErrors::UnauthorizedIdentity, SecurityError
          refusal(socket, "unauthorized")
        rescue AttemptErrors::Conflict
          refusal(socket, "conflict")
        rescue AttemptErrors::NotFound
          refusal(socket, "missing")
        rescue AttemptErrors::BoundedResultUnavailable
          refusal(socket, "bounded_result")
        rescue StandardError
          refusal(socket, "evidence_unavailable")
        ensure
          socket.close unless socket.closed?
          @mutex.synchronize { @connections.delete(socket) }
        end

        class Duplex
          def initialize(socket, ingress) = (@socket, @ingress = socket, ingress)
          def to_io = @socket
          def read_nonblock(*args, **options) = @ingress.read_nonblock(*args, **options)
          def write_nonblock(*args, **options) = @socket.write_nonblock(*args, **options)
        end
        private_constant :Duplex
      end
    end
  end
end
