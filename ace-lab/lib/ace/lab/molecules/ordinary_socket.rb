# frozen_string_literal: true

require "json"
require "socket"

module Ace
  module Lab
    module Molecules
      # Admission transport between the ordinary fixed merge producer and the
      # installed ordinary receiver: one bounded JSON document each way over
      # a configured unix stream socket with a fixed deadline. Authentication
      # is mutual through OS peer credentials — the producer verifies the receiver's
      # configured UID and transmits the verified local caller identity, so
      # no caller-selected credential, token or endpoint exists. This is not
      # an HTTP transport; a lost or unauthenticated response is a
      # caller-side blocker (ordinary_merge_unavailable), never a refusal.
      class OrdinarySocket
        LIMIT = 16_384
        HANDSHAKE = "ace-lab/ordinary-merge/v1"

        # @param socket_path [String] installed receiver endpoint (configuration)
        # @param receiver_uid [Integer] the only UID the receiver may run as
        # @param deadline [Time] absolute deadline for connect/write/read
        def initialize(socket_path:, receiver_uid:, deadline: Time.now.utc + 30)
          @socket_path = socket_path
          @receiver_uid = receiver_uid
          @deadline = deadline
        end

        # Submit one bounded request document; returns the parsed response
        # document. Any framing, deadline or identity failure raises
        # OrdinaryUnavailable so the producer can classify the blocker.
        def submit(document)
          payload = JSON.generate(document)
          raise OrdinaryUnavailable, "request document exceeds the wire bound" if payload.bytesize > LIMIT
          socket = nil
          begin
            socket = UNIXSocket.new(@socket_path)
            verify_peer!(socket)
            write_all!(socket, "#{HANDSHAKE} #{payload.bytesize}\n#{payload}")
            response = read_response!(socket)
          rescue OrdinaryUnavailable
            raise
          rescue SystemCallError, IOError, SocketError, NotImplementedError => e
            raise OrdinaryUnavailable, "receiver transport failed: #{e.class}"
          ensure
            begin
              socket&.close
            rescue IOError
              nil
            end
          end
          response
        end

        class OrdinaryUnavailable < ::StandardError; end

        private

        def verify_peer!(socket)
          peer_uid, = socket.getpeereid
          return if peer_uid == @receiver_uid
          raise OrdinaryUnavailable, "receiver endpoint identity is not the installed receiver"
        end

        def write_all!(socket, bytes)
          written = 0
          while written < bytes.bytesize
            begin
              raise OrdinaryUnavailable, "receiver write deadline expired" if expired?
              written += socket.write_nonblock(bytes.byteslice(written..))
            rescue IO::WaitWritable
              socket.wait_writable(remaining!) or raise OrdinaryUnavailable, "receiver write deadline expired"
            end
          end
        end

        def read_response!(socket)
          header = read_line!(socket)
          match = /\A#{Regexp.escape(HANDSHAKE)} (\d{1,5})\n\z/o.match(header)
          raise OrdinaryUnavailable, "receiver response header is invalid" unless match
          length = Integer(match[1])
          raise OrdinaryUnavailable, "receiver response exceeds the wire bound" if length > LIMIT
          body = read_exact!(socket, length)
          JSON.parse(body, allow_duplicate_key: false, create_additions: false, max_nesting: 16)
        rescue JSON::ParserError
          raise OrdinaryUnavailable, "receiver response is not valid JSON"
        end

        def read_line!(socket)
          line = +""
          until line.end_with?("\n")
            raise OrdinaryUnavailable, "receiver response header is unbounded" if line.bytesize > 128
            line << read_exact!(socket, 1)
          end
          line
        end

        def read_exact!(socket, length)
          buffer = +""
          while buffer.bytesize < length
            begin
              raise OrdinaryUnavailable, "receiver read deadline expired" if expired?
              chunk = socket.read_nonblock(length - buffer.bytesize)
              raise OrdinaryUnavailable, "receiver closed the connection" if chunk.nil?
              buffer << chunk
            rescue IO::WaitReadable
              socket.wait_readable(remaining!) or raise OrdinaryUnavailable, "receiver read deadline expired"
            end
          end
          buffer
        end

        def expired?
          Time.now.utc >= @deadline
        end

        def remaining!
          left = @deadline - Time.now.utc
          raise OrdinaryUnavailable, "receiver deadline expired" if left <= 0
          left
        end
      end
    end
  end
end
