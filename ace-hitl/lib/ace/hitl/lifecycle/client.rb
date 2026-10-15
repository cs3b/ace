# frozen_string_literal: true

require "socket"
require_relative "protocol"
require_relative "frame_exchange"
require_relative "lifecycle_requests"

module Ace
  module Hitl
    module Lifecycle
      # The authenticated Unix-socket client of the scoped store
      # boundary (spec 8wq.t.34i). The CLI lifecycle operations run
      # through this client; direct shared-store access is not a
      # client-side option. Cross-runtime clients use the mutual-TLS
      # Hermes client of the host/Incus crossing (spec 8xa.t.nh0)
      # instead; both share the request surface and frame exchange.
      #
      # Both endpoint directions are authenticated:
      # - the client authenticates the SERVICE: the socket must be a
      #   socket owned by the configured service uid, not group/world
      #   writable, and the connected peer must BE the service uid;
      # - the service authenticates the client from kernel peer
      #   credentials (server side).
      #
      # Transport failures raise classified Lifecycle::TransportError;
      # classified lifecycle errors arrive from the service and are
      # re-raised under their own classes.
      class Client
        include FrameExchange
        include LifecycleRequests

        attr_reader :socket_path, :service_uid

        def initialize(socket_path:, service_uid:, deadline_seconds: Protocol::DEFAULT_DEADLINE_SECONDS)
          @socket_path = socket_path.to_s
          @service_uid = Integer(service_uid)
          @deadline_seconds = deadline_seconds
        end

        # @return [Hash] the result frame
        def request(op, params = {}, deadline: nil)
          deadline = request_deadline(op, params, deadline)
          verify_endpoint!
          socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
          begin
            connect!(socket, deadline)
            verify_service_peer!(socket)
            write_frame!(socket, Protocol.encode_request(op, params), deadline)
            line = read_line(socket, deadline)
            Protocol.decode_response(line)
          ensure
            socket.close
          end
        rescue SystemCallError, IOError, EOFError => e
          raise TransportError, "HITL boundary is unavailable (#{e.class}: #{e.message})"
        rescue JSON::GeneratorError => e
          raise TransportError, "HITL boundary request is not serializable (#{e.message})"
        end

        private

        # The endpoint must be owned by the trusted service identity and
        # safe to write: an attacker-owned or world-writable socket is a
        # credential-disclosure channel (answers, OTP) and is refused
        # before any byte is sent.
        def verify_endpoint!
          stat = File.lstat(@socket_path)
          unless stat.socket?
            raise TransportError, "HITL boundary endpoint is not a socket: #{@socket_path}"
          end
          if stat.uid != @service_uid
            raise TransportError,
              "HITL boundary endpoint is owned by uid #{stat.uid}, not the trusted service uid #{@service_uid}"
          end
          # The designed endpoint mode is 0660 service:control-group —
          # group-write is the legitimate access path; WORLD-write is
          # never acceptable (no chmod-to-world workaround, spec 8wq.t.34i).
          if (stat.mode & 0o002) != 0
            raise TransportError, "HITL boundary endpoint is world-writable"
          end
        rescue Errno::ENOENT
          raise TransportError, "HITL boundary endpoint does not exist: #{@socket_path}"
        rescue SystemCallError
          raise TransportError, "HITL boundary endpoint is not verifiable: #{@socket_path}"
        end

        def verify_service_peer!(socket)
          peer_uid, = peer_credentials(socket)
          return if peer_uid == @service_uid

          raise TransportError,
            "HITL boundary peer is uid #{peer_uid}, not the trusted service uid #{@service_uid}"
        end

        def peer_credentials(socket)
          socket.getpeereid
        end

        def connect!(socket, deadline)
          if deadline && deadline <= Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise TransportError, "HITL boundary deadline exceeded"
          end
          result = socket.connect_nonblock(Socket.sockaddr_un(@socket_path), exception: false)
          return if result == 0
          await!(socket, :write, deadline)
          error = socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_ERROR).int
          raise SystemCallError.new("HITL boundary connection failed", error) unless error.zero?
        end
      end
    end
  end
end
