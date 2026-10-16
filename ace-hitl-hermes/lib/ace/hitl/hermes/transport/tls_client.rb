# frozen_string_literal: true

require "socket"
require "openssl"
require "ace/hitl/lifecycle"

module Ace
  module Hitl
    module Hermes
      module Transport
        # The TLS lifecycle client of the host/Incus crossing (spec
        # 8xa.t.nh0): the existing bounded ace-hitl lifecycle frames,
        # unchanged, over mutually authenticated TLS 1.3/TCP through the
        # project's Incus TCP proxy device.
        #
        # The remote endpoint is exactly `tls+tcp://HOST_TAILNET_DNS:PORT`
        # — literal wildcard, loopback, IP, Unix and cleartext TCP
        # endpoints are invalid and refused before any connection. On
        # every new connection the client authenticates the SERVICE:
        # issuing CA, the DNS name, the exact single expected server URI
        # SAN, the clientAuth/serverAuth EKU and the required configured
        # SHA-256 certificate fingerprint (the sole configured server
        # pin) — all BEFORE any lifecycle frame is written. TLS failure
        # or identity mismatch raises the classified transport error and
        # never falls back to Unix, HTTP or unauthenticated TCP.
        class TlsClient
          include Ace::Hitl::Lifecycle::FrameExchange
          include Ace::Hitl::Lifecycle::LifecycleRequests

          HANDSHAKE_SECONDS = 10.0

          attr_reader :dns, :port

          # @param endpoint [String, Hash] exactly `tls+tcp://HOST_TAILNET_DNS:PORT`
          #   or the resolved {dns:, port:} route form
          # @param credential [Hash] resolved `tls_client_credential`
          # @param context_builder [Proc] injectable SSLContext builder
          #   (production: Lifecycle::TlsMaterial.build_client_context)
          def initialize(endpoint:, credential:, deadline_seconds: Ace::Hitl::Lifecycle::Protocol::DEFAULT_DEADLINE_SECONDS,
            context_builder: ->(resolved) { Ace::Hitl::Lifecycle::TlsMaterial.build_client_context(resolved) })
            @dns, @port = resolve_endpoint(endpoint)
            @credential = Ace::Hitl::Lifecycle::TlsCredentials.parse_client(credential)
            @deadline_seconds = deadline_seconds
            @context = context_builder.call(@credential)
            freeze
          end

          # @return [Hash] the result frame
          def request(op, params = {}, deadline: nil)
            deadline = request_deadline(op, params, deadline)
            ssl = connect!(deadline)
            begin
              verify_server!(ssl)
              write_frame!(ssl, Ace::Hitl::Lifecycle::Protocol.encode_request(op, params), deadline)
              Ace::Hitl::Lifecycle::Protocol.decode_response(read_line(ssl, deadline))
            ensure
              ssl.close
            end
          rescue SystemCallError, IOError, EOFError, SocketError => e
            raise Ace::Hitl::Lifecycle::TransportError,
              "HITL TLS boundary is unavailable (#{e.class}: #{e.message})"
          rescue OpenSSL::SSL::SSLError => e
            raise Ace::Hitl::Lifecycle::TransportError,
              "HITL TLS boundary handshake failed (#{e.class}: #{e.message})"
          rescue JSON::GeneratorError => e
            raise Ace::Hitl::Lifecycle::TransportError,
              "HITL boundary request is not serializable (#{e.message})"
          end

          private

          def resolve_endpoint(value)
            case value
            when String then Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint(value)
            when Hash
              Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint(
                "tls+tcp://#{value[:dns] || value['dns']}:#{value[:port] || value['port']}")
            else
              raise Ace::Hitl::Lifecycle::TlsCredentials::Error,
                "remote HITL endpoint must be exactly tls+tcp://HOST_TAILNET_DNS:PORT (got #{value.inspect})"
            end
          end

          def connect!(deadline)
            tcp = connect_tcp!(deadline)
            begin
              ssl = OpenSSL::SSL::SSLSocket.new(tcp, @context)
              ssl.sync_close = true
              ssl.hostname = @dns
              handshake!(ssl, deadline)
              ssl
            rescue StandardError
              tcp.close rescue nil
              raise
            end
          end

          def connect_tcp!(deadline)
            remaining = deadline && deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise Ace::Hitl::Lifecycle::TransportError, "HITL TLS connection deadline exceeded" if remaining && remaining <= 0
            budget = [remaining, HANDSHAKE_SECONDS].compact.min
            Socket.tcp(@dns, @port, resolv_timeout: budget, connect_timeout: budget)
          end

          def handshake!(ssl, request_deadline)
            deadline = [request_deadline, Process.clock_gettime(Process::CLOCK_MONOTONIC) + HANDSHAKE_SECONDS].compact.min
            loop do
              result = ssl.connect_nonblock(exception: false)
              break if result.is_a?(OpenSSL::SSL::SSLSocket)

              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              raise Ace::Hitl::Lifecycle::TransportError, "HITL TLS handshake deadline exceeded" if remaining <= 0
              IO.select([ssl], [ssl], nil, remaining) or
                raise Ace::Hitl::Lifecycle::TransportError, "HITL TLS handshake deadline exceeded"
            end
          end

          # The verified certificate is the whole service identity: CA
          # membership and DNS alone never grant the authority. Every
          # identity refusal is the classified transport error.
          def verify_server!(ssl)
            result = ssl.verify_result
            unless result == OpenSSL::X509::V_OK
              raise Ace::Hitl::Lifecycle::TransportError,
                "the lifecycle server certificate did not verify (#{result})"
            end
            certificate = ssl.peer_cert
            unless Ace::Hitl::Lifecycle::TlsCredentials.valid_time?(certificate)
              raise Ace::Hitl::Lifecycle::TransportError,
                "the lifecycle server certificate is outside its validity window"
            end
            unless Ace::Hitl::Lifecycle::TlsCredentials.server_auth_eku?(certificate)
              raise Ace::Hitl::Lifecycle::TransportError,
                "the lifecycle server certificate lacks the serverAuth EKU"
            end
            Ace::Hitl::Lifecycle::TlsCredentials.single_uri_san!(certificate,
              @credential.fetch("expected_server_uri_san"), "lifecycle server")
            fingerprint = Ace::Hitl::Lifecycle::TlsCredentials.sha256_fingerprint(certificate)
            unless fingerprint == @credential.fetch("expected_server_certificate_sha256")
              raise Ace::Hitl::Lifecycle::TransportError,
                "the lifecycle server certificate fingerprint does not match the configured pin"
            end
          rescue Ace::Hitl::Lifecycle::TlsCredentials::Error => e
            raise Ace::Hitl::Lifecycle::TransportError, e.message
          end
        end
      end
    end
  end
end
