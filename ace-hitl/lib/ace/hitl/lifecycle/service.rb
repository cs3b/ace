# frozen_string_literal: true

require "socket"
require "fileutils"
require "etc"
require_relative "protocol"
require_relative "peer"
require_relative "store"
require_relative "otp_vault"

module Ace
  module Hitl
    module Lifecycle
      # The installed scoped store boundary (spec 8wq.t.34i): one
      # service process owns the private HITL store and speaks the
      # bounded protocol over a UNIX socket. Every connection is
      # authenticated from KERNEL PEER CREDENTIALS — payload fields,
      # environment variables, and claim strings are never authority —
      # and one store view is built per peer identity.
      #
      # The OTP vault is process memory: secret bytes are persisted
      # nowhere, transfer exactly once, and die with the challenge or
      # the service.
      class Service
        DEFAULT_SOCKET_MODE = 0o660
        # An idle connection holds a thread; bounded idleness keeps a
        # wedged peer from pinning the service (review 8x327buo).
        DEFAULT_IDLE_SECONDS = 120.0
        # Bound total concurrency: each connection is a thread (and may
        # hold one consume wait), so the cap bounds service load
        # (review 8x333sqv).
        MAX_CONNECTIONS = 64

        attr_reader :socket_path

        def initialize(root:, binding:, policy:, socket_path:, group: Store::DEFAULT_GROUP,
          deadline_seconds: Protocol::DEFAULT_DEADLINE_SECONDS, vault: nil, logger: nil,
          idle_seconds: DEFAULT_IDLE_SECONDS)
          @root = root
          @binding = binding
          @policy = policy
          @socket_path = socket_path.to_s
          @group = group
          @deadline_seconds = deadline_seconds
          @vault = vault || OtpVault::MemoryVault.new
          @logger = logger
          @idle_seconds = idle_seconds
          @max_connections = MAX_CONNECTIONS
          @connections = 0
          @connections_mutex = Mutex.new
          @stopping = false
          @server = nil
        end

        # Serve until #stop. Installs TERM/INT handlers for a clean
        # shutdown that unlinks the socket file.
        def run
          prepare!
          if Thread.current == Thread.main
            %i[TERM INT].each do |signal|
              trap(signal) { stop }
            end
          end
          loop do
            break if @stopping

            ready = IO.select([@server], nil, nil, 0.5)
            next unless ready

            connection = @server.accept
            slot = @connections_mutex.synchronize do
              break nil if @connections >= @max_connections

              @connections += 1
            end
            if slot.nil?
              begin
                connection.write(Protocol.encode_error(
                  TransportError.new("the HITL boundary is at its connection limit; retry shortly")))
                connection.close
              rescue SystemCallError, IOError
                nil
              end
              next
            end
            Thread.new(connection) do |socket|
              begin
                serve_connection(socket)
              ensure
                @connections_mutex.synchronize { @connections -= 1 }
              end
            end
          end
        ensure
          shutdown!
        end

        def stop
          @stopping = true
        end

        # Serve exactly one already-connected socket — the seam the
        # multi-UID acceptance fixture uses to drive real peers through
        # the real dispatch path.
        def serve_connection(socket)
          peer = authenticate!(socket)
          store = store_for(peer)
          loop do
            line = read_frame(socket)
            break if line.nil?

            response = dispatch(store, line)
            write_frame(socket, response)
          end
        rescue Lifecycle::Error => e
          write_frame(socket, Protocol.encode_error(e)) rescue nil
        rescue SystemCallError, IOError
          nil
        ensure
          socket.close rescue nil
        end

        private

        def prepare!
          begin
            verify_socket_directory!
            refuse_live_service!
            FileUtils.rm_f(@socket_path)
            @server = UNIXServer.open(@socket_path)
          rescue SystemCallError, IOError => e
            raise TransportError, "the HITL boundary endpoint is not usable (#{e.class}: #{e.message})"
          end
          File.chmod(DEFAULT_SOCKET_MODE, @socket_path)
          begin
            File.chown(nil, Etc.getgrnam(@group).gid, @socket_path)
          rescue ArgumentError, SystemCallError
            # A service that cannot set the control group keeps the
            # owner-only socket; the peer-credential gate still applies.
            nil
          end
          begin
            root_store.ensure_layout!
          rescue SystemCallError => e
            raise TransportError, "the HITL store layout is not usable (#{e.class}: #{e.message})"
          end
          log("serving #{@socket_path}")
        end

        def shutdown!
          @server&.close rescue nil
          FileUtils.rm_f(@socket_path)
          log("stopped")
        end

        # The socket's parent directory is part of the trust boundary: it
        # must exist, must not be world-writable, and must be owned by
        # the service identity or root — otherwise anyone who can replace
        # the socket can impersonate the service.
        def verify_socket_directory!
          dir = File.dirname(@socket_path)
          FileUtils.mkdir_p(dir)
          stat = File.lstat(dir)
          return if (stat.uid.zero? || stat.uid == Process.uid) && (stat.mode & 0o002).zero?

          raise TransportError,
            "HITL boundary socket directory is not protected: #{dir} " \
            "(must be service/root-owned and not world-writable)"
        end

        def authenticate!(socket)
          peer_uid, peer_gid = peer_credentials(socket)
          Peer.for_uid(peer_uid, gid: peer_gid)
        end

        def peer_credentials(socket)
          socket.getpeereid
        end

        def store_for(peer)
          Store.new(
            root: @root,
            binding: @binding,
            policy: @policy,
            identity: peer,
            vault: @vault
          )
        end

        # One request frame per dispatch; lifecycle failures return
        # classified error frames, transport/frame failures close the
        # connection (serve_connection's rescues).
        def dispatch(store, line)
          request = Protocol.decode_request(line)
          result = execute(store, request[:op], request[:params])
          Protocol.encode_result(result)
        rescue Protocol::FrameError, Lifecycle::Error, ArgumentError, TypeError => e
          Protocol.encode_error(e)
        end

        def execute(store, op, params)
          case op
          when "ping" then {"pong" => true}
          when "create" then store.create(**symbolize(params))
          when "read" then store.read(required(params, "id"))
          when "deliver" then store.deliver(required(params, "id"), answer_reader(params))
          when "consume"
            store.consume(required(params, "id"), timeout: Integer(params["timeout"] || 0),
              operation: params["operation"])
          when "cancel" then store.cancel(required(params, "id"), reason: params["reason"].to_s)
          when "pending" then store.pending
          when "states" then store.states
          end
        end

        def symbolize(params)
          params.transform_keys { |key| key.to_sym }
        end

        def required(params, key)
          value = params[key]
          raise Protocol::FrameError, "boundary parameter '#{key}' is required" if value.nil? || value.to_s.empty?

          value
        end

        def answer_reader(params)
          answer = params["answer"].to_s
          ->(limit) { answer[0, limit] }
        end

        # A connectable socket has a live listener: a second service must
        # refuse to start instead of stealing the endpoint (review
        # 8x327buq). Only a dead socket (ECONNREFUSED) is removed.
        def refuse_live_service!
          return unless File.exist?(@socket_path)

          begin
            probe = UNIXSocket.open(@socket_path)
          rescue SystemCallError, IOError
            return
          end
          begin
            probe.write(Protocol.encode_request("ping"))
            probe.flush
          rescue SystemCallError, IOError
            nil
          ensure
            probe.close rescue nil
          end
          raise TransportError,
            "a HITL boundary service is already serving #{@socket_path}; stop it before starting another"
        end

        def read_frame(socket)
          data = +""
          loop do
            ready = IO.select([socket], nil, nil, @idle_seconds)
            return nil unless ready

            chunk = socket.read_nonblock(4096, exception: false)
            return nil if chunk.nil?
            next sleep(0.01) if chunk == :wait_readable

            data << chunk
            if data.bytesize > Protocol::MAX_FRAME_BYTES
              write_frame(socket, Protocol.encode_error(Protocol::FrameError.new("request frame is too large"))) rescue nil
              return nil
            end
            return data if data.include?("\n")
          end
        end

        def write_frame(socket, frame)
          socket.write(frame)
          socket.flush
        end

        def root_store
          Store.new(root: @root, binding: @binding, policy: @policy)
        end

        def log(message)
          @logger&.call("[ace-hitl] #{message}")
        end
      end
    end
  end
end
