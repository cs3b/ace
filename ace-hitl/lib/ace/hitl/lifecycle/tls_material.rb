# frozen_string_literal: true

require "openssl"

module Ace
  module Hitl
    module Lifecycle
      # Loads the certificate material referenced by a resolved TLS
      # credential and builds the mutual-TLS 1.3 SSL contexts of the
      # host/Incus crossing (spec 8xa.t.nh0).
      #
      # This module owns PEM parsing and context assembly only; the
      # deployment layout (ownership/modes/symlinks) is verified by
      # CredentialPathPolicy at the production entry points, and the
      # PEER identity (SAN/fingerprint/EKU/DNS/CA) is verified after
      # each handshake by the TLS service and the Hermes TLS client.
      module TlsMaterial
        Error = Class.new(Lifecycle::Error)

        class << self
          # @return [OpenSSL::SSL::SSLContext] server context requiring
          #   a client certificate issued by the configured CA
          def build_server_context(credential)
            leaf, chain, key = load_identity(credential)
            verify_server_identity!(leaf, credential, key)

            build_context(credential) do |ctx|
              ctx.cert = leaf
              ctx.extra_chain_cert = chain unless chain.empty?
              ctx.key = key
              ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
              ctx.verify_hostname = false
            end
          end

          # @return [OpenSSL::SSL::SSLContext] client context presenting
          #   the project-scoped client identity; DNS verification uses
          #   the hostname set on the SSLSocket before the handshake
          def build_client_context(credential)
            leaf, chain, key = load_identity(credential)
            verify_client_identity!(leaf)

            build_context(credential) do |ctx|
              ctx.cert = leaf
              ctx.extra_chain_cert = chain unless chain.empty?
              ctx.key = key
              ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
              ctx.verify_hostname = true
            end
          end

          def verify_server_identity!(leaf, credential, key)
            unless TlsCredentials.server_auth_eku?(leaf)
              raise Error, "the lifecycle server certificate lacks the serverAuth EKU"
            end
            TlsCredentials.single_uri_san!(leaf, credential.fetch("server_uri_san"),
              "lifecycle server")
            unless TlsCredentials.valid_time?(leaf)
              raise Error, "the lifecycle server certificate is outside its validity window"
            end
            unless leaf.public_key.compare?(key.public_key)
              raise Error, "the lifecycle server private key does not match its certificate"
            end
          end

          def verify_client_identity!(leaf)
            unless TlsCredentials.client_auth_eku?(leaf)
              raise Error, "the Hermes client certificate lacks the clientAuth EKU"
            end
            unless TlsCredentials.valid_time?(leaf)
              raise Error, "the Hermes client certificate is outside its validity window"
            end
          end

          # @return [Array(OpenSSL::X509::Certificate, Array, OpenSSL::PKey)]
          #   leaf certificate, remaining chain, private key
          def load_identity(credential)
            certificates = load_certificates(credential.fetch("certificate_file"))
            key = load_key(credential.fetch("private_key_file"))
            [certificates.first, certificates.drop(1), key]
          end

          def load_certificates(path)
            certificates = scan_pem(path, "CERTIFICATE").map do |pem|
              OpenSSL::X509::Certificate.new(pem)
            end
            raise Error, "the certificate file contains no certificate: #{path}" if certificates.empty?

            certificates
          end

          def load_key(path)
            pem = read_file(path)
            OpenSSL::PKey.read(pem)
          rescue OpenSSL::PKey::PKeyError
            raise Error, "the private key file is not a readable private key: #{path}"
          end

          private

          def build_context(credential)
            ctx = OpenSSL::SSL::SSLContext.new
            ctx.set_params
            ctx.min_version = OpenSSL::SSL::TLS1_3_VERSION
            ctx.max_version = OpenSSL::SSL::TLS1_3_VERSION
            # An explicit per-context trust store: the configured issuing
            # CA is the ONLY trust anchor of this authority or client,
            # never an accumulated or shared default store (identical
            # subject collisions in shared stores would poison issuer
            # selection across peers in one process).
            store = OpenSSL::X509::Store.new
            store.add_file(credential.fetch("ca_file"))
            ctx.cert_store = store
            yield ctx
            ctx
          rescue OpenSSL::SSL::SSLError => e
            raise Error, "the TLS context of the HITL crossing is not usable (#{e.message})"
          end

          def scan_pem(path, label)
            read_file(path).scan(%r{-----BEGIN #{label}-----.*?-----END #{label}-----}m)
          end

          def read_file(path)
            File.read(path)
          rescue SystemCallError, IOError
            raise Error, "the TLS credential file is not readable: #{path}"
          end
        end
      end
    end
  end
end
