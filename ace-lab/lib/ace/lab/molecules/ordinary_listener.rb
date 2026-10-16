# frozen_string_literal: true

require "json"
require "socket"
require_relative "../errors"
require_relative "ordinary_socket"

module Ace
  module Lab
    module Molecules
      # The ordinary receiver's serve-side transport (spec 8x3.t.xz9.4 serve
      # entrypoint). Binds the configured unix socket and answers the exact
      # framed protocol the OrdinarySocket client speaks: one bounded JSON
      # document each way behind the shared handshake line. Authentication is
      # MUTUAL through OS peer credentials: every connection's peer UID must equal
      # the configured producer principal UID, and the listener itself runs
      # as the configured receiver UID — the identity the client verifies on
      # its side. Every identity, framing, deadline or parse failure is
      # fail-closed: the peer receives the closed refusal envelope (or the
      # connection closes) and nothing is ever dispatched. This is not an
      # HTTP transport and there is no cross-VM fallback.
      class OrdinaryListener
        HANDSHAKE = OrdinarySocket::HANDSHAKE
        LIMIT = OrdinarySocket::LIMIT
        DEADLINE_SECONDS = 30

        def initialize(socket_path:, peer_uid:, handler:, socket_gid: nil, lock_path: nil, logger: nil)
          unless socket_path.is_a?(String) && socket_path.start_with?("/") &&
              peer_uid.is_a?(Integer) && peer_uid >= 0 && handler.respond_to?(:call)
            raise ArgumentError, "ordinary listener needs an absolute socket path, a peer uid and a handler"
          end
          unless socket_gid.nil? || (socket_gid.is_a?(Integer) && socket_gid >= 0)
            raise ArgumentError, "ordinary listener socket_gid must be a non-negative integer"
          end
          @socket_gid = socket_gid
          @socket_path = socket_path
          @peer_uid = peer_uid
          @handler = handler
          @lock_path = lock_path || "#{@socket_path}.lock"
          @logger = logger
          @stopping = false
        end

        # Serve until #stop. Excludes a second listener through one owned
        # lock file, removes only its own stale endpoint, and always removes
        # the endpoint it created.
        def serve
          acquire_lock!
          remove_stale_endpoint!
          @listener = UNIXServer.new(@socket_path)
          @endpoint_identity = File.stat(@socket_path)
          File.chown(nil, @socket_gid, @socket_path) if @socket_gid
          File.chmod(@socket_gid ? 0o660 : 0o600, @socket_path)
          until @stopping
            socket = @listener.accept
            serve_connection(socket)
          end
        rescue IOError, Errno::EBADF
          raise unless @stopping
        ensure
          @listener&.close
          remove_owned_endpoint!
          @lock&.flock(File::LOCK_UN)
          @lock&.close
        end

        def stop
          @stopping = true
          @listener&.close
        rescue IOError
          nil
        end

        # One bounded connection: verify the peer identity, read one framed
        # request, answer one framed envelope, close. Fail-closed on every
        # violation; a dispatch never happens from an unverified frame.
        def serve_connection(socket)
          deadline = Time.now.utc + DEADLINE_SECONDS
          begin
            verify_peer!(socket)
            submission = read_request!(socket, deadline)
            response = @handler.call(submission)
            write_response!(socket, response, deadline)
            if response.is_a?(Hash) && response["status"] == "ok" && @handler.respond_to?(:execute)
              begin
                # The durable acknowledgment is already on the wire; the
                # execution lifetime belongs to the canonical record, not
                # the short connection. A lost lifecycle stays pending or
                # uncertain and reconciles by the original reference.
                @handler.execute(response.dig("data", "request_id"))
              rescue StandardError
                nil
              end
            end
          rescue OrdinaryRefused => e
            write_response!(socket, e.envelope, deadline)
          rescue OrdinaryListenerError
            # Fail closed without a fabricated envelope; the client classifies
            # a lost/unreadable response as ordinary_merge_unavailable.
            nil
          rescue StandardError
            write_response!(socket, refusal_envelope("ordinary_merge_unavailable",
              "receiver failed to handle the request"), deadline)
          ensure
            begin
              socket.close
            rescue IOError
              nil
            end
          end
        end

        class OrdinaryListenerError < ::StandardError; end

        # A verified-connection refusal that still carries a closed envelope.
        class OrdinaryRefused < OrdinaryListenerError
          attr_reader :envelope

          def initialize(envelope)
            @envelope = envelope
            super(envelope.dig("error", "message").to_s)
          end
        end

        private

        # Mutual half of OS peer authentication: the connecting process must run as the
        # configured producer principal UID. Anything else is refused before
        # one byte of request is read.
        def verify_peer!(socket)
          peer_uid, = socket.getpeereid
          return if peer_uid == @peer_uid
          raise OrdinaryRefused, refusal_envelope("ordinary_merge_unauthenticated",
            "connecting principal is not the configured ordinary overseer")
        rescue SystemCallError, IOError, SocketError, NotImplementedError
          raise OrdinaryListenerError, "peer credentials are unavailable"
        end

        def read_request!(socket, deadline)
          header = read_line!(socket, deadline)
          match = /\A#{Regexp.escape(HANDSHAKE)} (\d{1,5})\n\z/o.match(header)
          raise OrdinaryListenerError, "request header is invalid" unless match
          length = Integer(match[1])
          raise OrdinaryListenerError, "request exceeds the wire bound" if length > LIMIT
          payload = read_exact!(socket, length, deadline)
          JSON.parse(payload, allow_duplicate_key: false, create_additions: false, max_nesting: 16)
        rescue JSON::ParserError
          raise OrdinaryRefused, refusal_envelope("ordinary_merge_invalid_request",
            "request document is not valid JSON")
        end

        def write_response!(socket, response, deadline)
          payload = JSON.generate(response)
          raise OrdinaryListenerError, "response exceeds the wire bound" if payload.bytesize > LIMIT
          frame = "#{HANDSHAKE} #{payload.bytesize}\n#{payload}"
          written = 0
          while written < frame.bytesize
            raise OrdinaryListenerError, "response write deadline expired" if Time.now.utc >= deadline
            begin
              written += socket.write_nonblock(frame.byteslice(written..))
            rescue IO::WaitWritable
              socket.wait_writable(remaining!(deadline)) or
                raise OrdinaryListenerError, "response write deadline expired"
            end
          end
        rescue JSON::GeneratorError
          raise OrdinaryListenerError, "response is not serializable"
        end

        def refusal_envelope(code, message)
          {"status" => "error", "error" => {
            "schema" => "ace.lab.service.ordinary-merge-refusal/v1",
            "code" => code,
            "message" => message.to_s.scrub.gsub(/\s+/, " ").strip[0, 512],
            "request_id" => "unknown",
            "input_digest" => nil
          }}
        end

        def read_line!(socket, deadline)
          line = +""
          until line.end_with?("\n")
            raise OrdinaryListenerError, "request header is unbounded" if line.bytesize > 128
            line << read_exact!(socket, 1, deadline)
          end
          line
        end

        def read_exact!(socket, length, deadline)
          buffer = +""
          while buffer.bytesize < length
            raise OrdinaryListenerError, "request read deadline expired" if Time.now.utc >= deadline
            begin
              chunk = socket.read_nonblock(length - buffer.bytesize)
              raise OrdinaryListenerError, "peer closed the connection" if chunk.nil?
              buffer << chunk
            rescue IO::WaitReadable
              socket.wait_readable(remaining!(deadline)) or
                raise OrdinaryListenerError, "request read deadline expired"
            end
          end
          buffer
        end

        def remaining!(deadline)
          left = deadline - Time.now.utc
          raise OrdinaryListenerError, "connection deadline expired" if left <= 0
          left
        end

        def acquire_lock!
          @lock = File.open(@lock_path, File::RDWR | File::CREAT | File::NOFOLLOW, 0o600)
          stat = @lock.stat
          unless stat.file? && stat.uid == Process.uid && stat.nlink == 1 && (stat.mode & 0o7777) == 0o600
            raise Ace::Lab::InvalidConfigurationError, "receiver listener lock differs"
          end
          unless @lock.flock(File::LOCK_EX | File::LOCK_NB)
            raise Ace::Lab::InvalidConfigurationError, "receiver listener already active"
          end
        end

        def remove_stale_endpoint!
          stat = File.lstat(@socket_path)
          unless stat.socket? && stat.uid == Process.uid
            raise Ace::Lab::InvalidConfigurationError, "receiver endpoint differs"
          end
          File.unlink(@socket_path)
        rescue Errno::ENOENT
          nil
        end

        def remove_owned_endpoint!
          return unless @endpoint_identity
          stat = File.stat(@socket_path)
          File.unlink(@socket_path) if stat.socket? && stat.ino == @endpoint_identity.ino
        rescue Errno::ENOENT
          nil
        end
      end
    end
  end
end
