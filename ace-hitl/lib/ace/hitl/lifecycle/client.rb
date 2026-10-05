# frozen_string_literal: true

require "socket"
require_relative "protocol"

module Ace
  module Hitl
    module Lifecycle
      # The authenticated client of the scoped store boundary (spec
      # 8wq.t.34i). The CLI lifecycle operations run through this client;
      # direct shared-store access is not a client-side option.
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
        attr_reader :socket_path, :service_uid

        def initialize(socket_path:, service_uid:, deadline_seconds: Protocol::DEFAULT_DEADLINE_SECONDS)
          @socket_path = socket_path.to_s
          @service_uid = Integer(service_uid)
          @deadline_seconds = deadline_seconds
        end

        # @return [Hash] the result frame
        def request(op, params = {})
          verify_endpoint!
          socket = UNIXSocket.open(@socket_path)
          begin
            verify_service_peer!(socket)
            socket.write(Protocol.encode_request(op, params))
            socket.flush
            line = read_line(socket, deadline_for(op, params))
            Protocol.decode_response(line)
          ensure
            socket.close
          end
        rescue SystemCallError, IOError, EOFError => e
          raise TransportError, "HITL boundary is unavailable (#{e.class}: #{e.message})"
        rescue JSON::GeneratorError => e
          raise TransportError, "HITL boundary request is not serializable (#{e.message})"
        end

        def create(**params)
          request("create", params.transform_keys(&:to_s))
        end

        def read(id)
          request("read", {"id" => id})
        end

        def deliver(id, answer)
          request("deliver", {"id" => id, "answer" => answer.to_s})
        end

        def consume(id, timeout: 0, operation: nil, native_delivery: false)
          params = {"id" => id, "timeout" => Integer(timeout)}
          params["operation"] = operation if operation
          params["native_delivery"] = true if native_delivery
          request("consume", params)
        end

        def cancel(id, reason: "")
          request("cancel", {"id" => id, "reason" => reason.to_s})
        end

        def pending(project: nil)
          items = []
          after = nil
          loop do
            page = pending_page(project: project, after: after)
            items.concat(page.fetch("items"))
            cursor = page.fetch("next")
            break unless cursor
            unless cursor.is_a?(String) && (after.nil? || cursor > after)
              raise TransportError, "pending cursor did not advance"
            end
            after = cursor
          end
          items
        end

        def pending_page(project: nil, after: nil)
          request("pending", {"project" => project, "after" => after}.compact)
        end

        def states
          request("states")
        end

        def ping
          request("ping")
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

        # A consume without a timeout waits indefinitely at the client
        # boundary too; every bounded call gets a deadline slightly
        # beyond its own wait so the server result wins the race.
        def deadline_for(op, params)
          if op == "consume" && Integer(params["timeout"]) <= 0
            nil
          else
            Process.clock_gettime(Process::CLOCK_MONOTONIC) + @deadline_seconds + Integer(params["timeout"])
          end
        rescue ArgumentError, TypeError
          Process.clock_gettime(Process::CLOCK_MONOTONIC) + @deadline_seconds
        end

        def read_line(socket, deadline)
          data = +""
          loop do
            remaining = deadline && deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise TransportError, "HITL boundary deadline exceeded" if remaining && remaining <= 0
            ready = IO.select([socket], nil, nil, remaining)
            raise TransportError, "HITL boundary deadline exceeded" unless ready

            chunk = socket.read_nonblock(4096, exception: false)
            raise TransportError, "HITL boundary closed before responding" if chunk.nil?
            # A spurious not-ready result goes back to select; only the
            # deadline ends the wait (review 8x32r9b4).
            next if chunk == :wait_readable

            data << chunk
            if data.bytesize > Protocol::MAX_FRAME_BYTES
              raise TransportError, "HITL boundary response is too large"
            end
            return data if data.include?("\n")
          end
        end
      end
    end
  end
end
