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
          idle_seconds: DEFAULT_IDLE_SECONDS, proposal_clock: -> { Time.now.utc })
          @root = root
          @binding = binding
          @policy = policy
          @socket_path = socket_path.to_s
          @group = group
          @deadline_seconds = deadline_seconds
          @vault = vault || OtpVault::MemoryVault.new
          @logger = logger
          @idle_seconds = idle_seconds
          @proposal_clock = proposal_clock
          @max_connections = MAX_CONNECTIONS
          @connections = 0
          @connections_mutex = Mutex.new
          @stopping = false
          @server = nil
          @endpoint_identity = nil
          @endpoint_lock = nil
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
            acquire_endpoint_lock!
            recover_stale_endpoint!
            @server = UNIXServer.open(@socket_path)
            @endpoint_identity = endpoint_identity
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
          begin
            @server&.close
          rescue SystemCallError, IOError
            nil
          end
          begin
            File.unlink(@socket_path) if @endpoint_identity && endpoint_identity == @endpoint_identity
          rescue Errno::ENOENT
            nil
          ensure
            @endpoint_identity = nil
            @endpoint_lock&.close
            @endpoint_lock = nil
          end
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
          Peer.for_uid(peer_uid, gid: peer_gid, pid: peer_pid(socket))
        end

        def peer_credentials(socket)
          socket.getpeereid
        end

        # Kernel attribution only. Darwin sys/un.h defines SOL_LOCAL=0,
        # LOCAL_PEERPID=2; Linux SO_PEERCRED exposes pid/uid/gid. Unsupported
        # platforms keep nil, so exact requester claims can fail closed.
        def peer_pid(socket)
          if RUBY_PLATFORM.include?("darwin")
            socket.getsockopt(0, 2).int
          elsif Socket.const_defined?(:SO_PEERCRED)
            socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_PEERCRED).data.unpack("i!3").first
          end
        rescue SystemCallError, IOError, SocketError
          nil
        end

        def store_for(peer)
          Store.new(
            root: @root,
            binding: @binding,
            policy: @policy,
            identity: peer,
            vault: @vault,
            proposal_clock: @proposal_clock
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
          when "proposal-create" then store.proposal_create(**symbolize(params))
          when "proposal-show" then store.proposal_show(required(params, "id"), history_after: params.fetch("history_after", 0))
          when "proposal-revise" then store.proposal_revise(required(params, "id"), document: required(params, "document"))
          when "proposal-ack"
            store.proposal_acknowledge(required(params, "id"), submitted_at: required(params, "submitted_at"))
          when "proposal-reply"
            store.proposal_reply(required(params, "id"), answer: required(params, "answer"),
              received_at: required(params, "received_at"), sequence: required(params, "sequence"))
          when "proposal-reconcile"
            store.proposal_reconcile(required(params, "id"), checkpoint: required(params, "checkpoint"))
          when "proposal-wake" then store.proposal_wake(project: required(params, "project"), after: params["after"])
          when "proposal-due" then store.proposal_due(after: params["after"])
          when "proposal-history" then store.proposal_history(project: required(params, "project"),
            query: params.fetch("query", ""), after: params["after"])
          when "create" then store.create(**symbolize(params))
          when "read" then store.read(required(params, "id"))
          when "deliver" then store.deliver(required(params, "id"), answer_reader(params))
          when "consume"
            store.consume(required(params, "id"), timeout: Integer(params["timeout"] || 0),
              operation: params["operation"], native_delivery: params.fetch("native_delivery", false))
          when "cancel" then store.cancel(required(params, "id"), reason: params["reason"].to_s)
          when "pending" then store.pending_page(project: params["project"], after: params["after"])
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

        # Keep one stable lock inode for the endpoint. Holding the lock
        # through shutdown prevents simultaneous starters from recovering
        # or replacing a socket another invocation is still acquiring.
        # Never unlink the lock file: waiters must all use the same inode.
        def acquire_endpoint_lock!
          @endpoint_lock = File.open("#{@socket_path}.lock", File::RDWR | File::CREAT | File::NOFOLLOW, 0o600)
          stat = @endpoint_lock.stat
          unless stat.file? && stat.uid == Process.uid && stat.nlink == 1 && (stat.mode & 0o077).zero?
            raise TransportError, "HITL boundary endpoint lock is not protected"
          end
          return if @endpoint_lock.flock(File::LOCK_EX | File::LOCK_NB)

          raise TransportError,
            "a HITL boundary service is already serving #{@socket_path}; stop it before starting another"
        end

        def endpoint_identity
          stat = File.lstat(@socket_path)
          [stat.dev, stat.ino] if stat.socket?
        rescue Errno::ENOENT
          nil
        end

        # Only an owned socket whose connection is explicitly refused is
        # stale. Permission, type and other probe failures cannot grant
        # authority to delete an endpoint.
        def recover_stale_endpoint!
          stat = File.lstat(@socket_path)
          unless stat.socket? && stat.uid == Process.uid && (stat.mode & 0o002).zero?
            raise TransportError, "HITL boundary endpoint is not a protected service-owned socket"
          end
          identity = [stat.dev, stat.ino]
          begin
            probe = UNIXSocket.open(@socket_path)
          rescue Errno::ECONNREFUSED
            unless endpoint_identity == identity
              raise TransportError, "HITL boundary endpoint changed during stale socket recovery"
            end
            File.unlink(@socket_path)
            return
          ensure
            probe&.close
          end
          raise TransportError,
            "a HITL boundary service is already serving #{@socket_path}; stop it before starting another"
        rescue Errno::ENOENT
          nil
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
