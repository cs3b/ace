# frozen_string_literal: true

require "socket"
require "openssl"
require_relative "protocol"
require_relative "store"
require_relative "otp_vault"
require_relative "remote_peer"
require_relative "tls_access_policy"
require_relative "frame_serving"
require_relative "tls_project_scope"

module Ace
  module Hitl
    module Lifecycle
      # The host/Incus crossing of the scoped store boundary (spec
      # 8xa.t.nh0): the bounded lifecycle framing protocol over mutual
      # TLS 1.3/TCP. One authority serves ONE project on a loopback TCP
      # endpoint where the project's Incus TCP proxy device connects;
      # the proxy performs no TLS termination and is not an identity
      # authority.
      #
      # Every connection is authenticated from the VERIFIED project-
      # scoped client certificate — exactly one allowed URI SAN, the
      # exact configured SHA-256 fingerprint, the configured issuing CA
      # and the clientAuth EKU, all checked BEFORE any lifecycle frame
      # is decoded. TLS failure, EOF, malformed frame or identity
      # mismatch never falls back to Unix, HTTP or unauthenticated TCP.
      class TlsService
        include FrameServing

        DEFAULT_IDLE_SECONDS = Service::DEFAULT_IDLE_SECONDS
        MAX_CONNECTIONS = Service::MAX_CONNECTIONS
        HANDSHAKE_SECONDS = 10.0

        def initialize(root:, binding:, project:, credential:, ssl_context:,
          listen: "127.0.0.1", port:, group: Store::DEFAULT_GROUP, vault: nil, logger: nil,
          idle_seconds: DEFAULT_IDLE_SECONDS, proposal_clock: -> { Time.now.utc }, decision_policy: AccessPolicy.new)
          @root = root
          @binding = binding
          @project = TlsCredentials.project_id(project)
          @credential = credential
          @ssl_context = ssl_context
          @listen = listen
          @port = Integer(port)
          @group = group
          @vault = vault || OtpVault::MemoryVault.new
          @logger = logger
          @idle_seconds = idle_seconds
          @proposal_clock = proposal_clock
          @policy = TlsAccessPolicy.new(project: @project, decision_policy: decision_policy)
          @max_connections = MAX_CONNECTIONS
          @connections = 0
          @handler_threads = []
          @handler_sockets = []
          @connections_mutex = Mutex.new
          @stopping = false
          @server = nil
        end

        attr_reader :port

        # Serve until #stop. Installs TERM/INT handlers for a clean
        # shutdown that closes the listener.
        def run(on_ready: nil)
          prepare!
          on_ready.call if on_ready
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
            @connections_mutex.synchronize do
              @handler_sockets << connection
              @handler_threads.reject! { |thread| !thread.alive? }
              thread = Thread.new(connection) do |tcp|
                begin
                  serve_tls_connection(tcp)
                ensure
                  @connections_mutex.synchronize do
                    @connections -= 1
                    @handler_sockets.delete(tcp)
                  end
                end
              end
              thread.report_on_exception = false
              @handler_threads << thread
            end
          end
        ensure
          shutdown!
        end

        def stop
          @stopping = true
        end

        private

        def prepare!
          begin
            root_store.ensure_layout!
            @server = TCPServer.new(@listen, @port)
            port = @server.addr[1]
            @port = port if port.positive?
          rescue SystemCallError, IOError => e
            raise TransportError, "the HITL TLS boundary cannot bind (#{e.class}: #{e.message})"
          end
          log("serving tls://#{@listen}:#{@port} for project #{@project}")
        end

        def shutdown!
          stop
          @connections_mutex.synchronize { @handler_sockets.dup }.each { |socket| socket.close rescue nil }
          failures = []
          @connections_mutex.synchronize { @handler_threads.dup }.each do |thread|
            begin
              thread.join
            rescue Exception => error
              failures << error
            end
          end
          begin
            @server&.close
          rescue SystemCallError, IOError
            nil
          end
          log("stopped")
          raise failures.first unless failures.empty?
        end

        # Handshake with a bounded deadline, then certificate identity
        # authorization. Any failure refuses the connection BEFORE any
        # lifecycle read/write: no frame is written to an unverified
        # peer and the refusal never becomes a fallback.
        def serve_tls_connection(tcp)
          ssl = accept_tls!(tcp)
          serve_connection(ssl)
        rescue TransportError, OpenSSL::SSL::SSLError, SystemCallError, IOError
          # Sanitized refusal only: handshake and identity failures are
          # observability facts, never fallback triggers.
          log("refused an unauthenticated TLS connection")
          tcp.close rescue nil
        end

        def accept_tls!(tcp)
          ssl = OpenSSL::SSL::SSLSocket.new(tcp, @ssl_context)
          ssl.sync_close = true
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + HANDSHAKE_SECONDS
          loop do
            result = ssl.accept_nonblock(exception: false)
            break if result.is_a?(OpenSSL::SSL::SSLSocket)

            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise TransportError, "the HITL TLS handshake deadline exceeded" if remaining <= 0
            IO.select([ssl], [ssl], nil, remaining) or
              raise TransportError, "the HITL TLS handshake deadline exceeded"
          end
          ssl
        rescue OpenSSL::SSL::SSLError, SystemCallError, IOError, TransportError
          ssl.close rescue nil
          raise
        end

        # The verified certificate is the whole identity: CA membership
        # alone (OpenSSL handshake verification) never grants a project.
        def authorize!(ssl)
          verify_handshake!(ssl)
          certificate = ssl.peer_cert
          unless TlsCredentials.valid_time?(certificate)
            raise TransportError, "the peer certificate is outside its validity window"
          end
          unless TlsCredentials.client_auth_eku?(certificate)
            raise TransportError, "the peer certificate lacks the clientAuth EKU"
          end
          TlsCredentials.single_uri_san!(certificate,
            @credential.fetch("allowed_client_uri_san"), "peer")
          fingerprint = TlsCredentials.sha256_fingerprint(certificate)
          unless fingerprint == @credential.fetch("allowed_client_certificate_sha256")
            raise TransportError, "the peer certificate fingerprint does not match the configured pin"
          end

          RemotePeer.new(project: @project,
            identity: @credential.fetch("allowed_client_uri_san"))
        end

        def verify_handshake!(ssl)
          result = ssl.verify_result
          return if result == OpenSSL::X509::V_OK

          raise TransportError, "the peer certificate did not verify (#{result})"
        rescue OpenSSL::SSLError
          raise TransportError, "the peer certificate verification is unavailable"
        end

        def authenticate!(socket)
          authorize!(socket)
        end

        def store_for(peer)
          TlsProjectScope.new(
            Store.new(
              root: @root,
              binding: @binding,
              policy: @policy,
              identity: peer,
              vault: @vault,
              proposal_clock: @proposal_clock, stopping: -> { @stopping }, group: @group
            ),
            project: @project
          )
        end

        def root_store
          Store.new(root: @root, binding: @binding, policy: @policy, group: @group)
        end
      end
    end
  end
end
