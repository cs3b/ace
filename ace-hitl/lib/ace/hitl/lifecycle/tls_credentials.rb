# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # The closed configuration schemas of the selected host/Incus
      # crossing (spec 8xa.t.nh0): configuration contains credential
      # REFERENCES, never secret bytes, and both credential objects
      # reject unknown fields and nulls. The certificate identity is a
      # single URI SAN of the form
      # `urn:ace:hitl:<project-id>:hermes-client` or
      # `urn:ace:hitl:<project-id>:lifecycle-server`; fingerprints are
      # exact lowercase SHA-256 hex digests of the peer leaf certificate.
      #
      # Filesystem layout enforcement lives in CredentialPathPolicy;
      # this module owns only the configuration contract and the
      # certificate-identity helpers shared by the TLS service and the
      # Hermes TLS client.
      module TlsCredentials
        CLIENT_SCHEMA = "ace.hitl.tls.client_credential/v1"
        SERVER_SCHEMA = "ace.hitl.tls.server_credential/v1"

        CLIENT_FIELDS = %w[certificate_file private_key_file ca_file
          expected_server_uri_san expected_server_certificate_sha256].freeze
        SERVER_FIELDS = %w[certificate_file private_key_file ca_file
          server_uri_san allowed_client_uri_san allowed_client_certificate_sha256].freeze

        CLIENT_AUTH_EKU = "TLS Web Client Authentication"
        SERVER_AUTH_EKU = "TLS Web Server Authentication"
        CLIENT_AUTH_EKU_OID = "1.3.6.1.5.5.7.3.2"
        SERVER_AUTH_EKU_OID = "1.3.6.1.5.5.7.3.1"

        # Project ids inside URI SANs exclude ":" so the closed URN form
        # stays unambiguous; every other token rule matches the Hermes
        # token pattern family.
        PROJECT_ID_PATTERN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,62}\z/
        FINGERPRINT_PATTERN = /\A[0-9a-f]{64}\z/
        URI_SAN_PREFIX = "urn:ace:hitl:"
        ROLES = %w[hermes-client lifecycle-server].freeze

        # Exactly `tls+tcp://HOST_TAILNET_DNS:PORT`. Literal wildcard,
        # loopback, Unix and cleartext TCP endpoints are invalid; the
        # host is a DNS name (never an IP literal) with at least two
        # labels, and the port is 1..65535.
        REMOTE_ENDPOINT_PATTERN = %r{\Atls\+tcp://((?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?):(\d{1,5})\z}

        Error = Class.new(Lifecycle::Error)

        module_function

        # @return [Hash] resolved client credential reference
        def parse_client(config)
          fields = parse_fields(config, CLIENT_FIELDS, CLIENT_SCHEMA)
          validate_uri_san(fields.fetch("expected_server_uri_san"), "lifecycle-server",
            "expected_server_uri_san")
          validate_fingerprint(fields.fetch("expected_server_certificate_sha256"),
            "expected_server_certificate_sha256")
          fields
        end

        # @return [Hash] resolved server credential reference
        def parse_server(config)
          fields = parse_fields(config, SERVER_FIELDS, SERVER_SCHEMA)
          validate_uri_san(fields.fetch("server_uri_san"), "lifecycle-server", "server_uri_san")
          validate_uri_san(fields.fetch("allowed_client_uri_san"), "hermes-client",
            "allowed_client_uri_san")
          validate_fingerprint(fields.fetch("allowed_client_certificate_sha256"),
            "allowed_client_certificate_sha256")
          fields
        end

        # @return [Array(String, String, Integer)] dns name, port for a
        #   valid remote endpoint string
        def parse_endpoint(value)
          unless value.is_a?(String) && (match = REMOTE_ENDPOINT_PATTERN.match(value))
            raise Error,
              "remote HITL endpoint must be exactly tls+tcp://HOST_TAILNET_DNS:PORT " \
              "(literal wildcard, loopback, IP, Unix and cleartext TCP endpoints are invalid; got #{value.inspect})"
          end

          port = Integer(match[2])
          raise Error, "remote HITL endpoint port is out of range: #{port}" unless (1..65_535).cover?(port)

          host = match[1].delete_suffix(".")
          if host.split(".").all? { |label| label.match?(/\A\d+\z/) }
            raise Error,
              "remote HITL endpoint host must be a DNS name; IP literals are invalid (got #{value.inspect})"
          end

          [host, port]
        end

        def project_id(value)
          return value if value.is_a?(String) && value.match?(PROJECT_ID_PATTERN)

          raise Error, "HITL project id must match #{PROJECT_ID_PATTERN.inspect} (got #{value.inspect})"
        end

        # The project encoded in a closed-form URI SAN.
        # @return [String] project id
        def uri_san_project(uri_san)
          validate_uri_san(uri_san, nil, "uri san")
          uri_san.delete_prefix(URI_SAN_PREFIX).rpartition(":").first
        end

        def validate_uri_san(value, role, label)
          unless value.is_a?(String) && value.start_with?(URI_SAN_PREFIX)
            raise Error, "#{label} must be a closed-form urn:ace:hitl:<project-id>:<role> URI SAN (got #{value.inspect})"
          end

          body = value.delete_prefix(URI_SAN_PREFIX)
          project, _, actual_role = body.rpartition(":")
          project_id(project)
          return if role.nil? || actual_role == role

          raise Error, "#{label} must name the #{role} role (got #{value.inspect})"
        end

        def validate_fingerprint(value, label)
          return if value.is_a?(String) && value.match?(FINGERPRINT_PATTERN)

          raise Error, "#{label} must be 64 lowercase hex characters (got #{value.inspect})"
        end

        # ---- certificate identity helpers (shared by both peers) -----

        # @return [Array<String>] the URI entries of the subjectAltName
        def uri_sans(certificate)
          san = certificate.extensions.find { |extension| extension.oid == "subjectAltName" }
          return [] unless san

          san.value.split(/\s*,\s*/).select { |entry| entry.start_with?("URI:") }
            .map { |entry| entry.delete_prefix("URI:") }
        end

        # @return [Array<String>] rendered extended key usages (short
        #   names or dotted OIDs, depending on the OpenSSL build)
        def extended_key_usages(certificate)
          eku = certificate.extensions.find { |extension| extension.oid == "extendedKeyUsage" }
          return [] unless eku

          eku.value.split(/\s*,\s*/)
        end

        def client_auth_eku?(certificate)
          usages = extended_key_usages(certificate)
          usages.include?(CLIENT_AUTH_EKU) || usages.include?(CLIENT_AUTH_EKU_OID)
        end

        def server_auth_eku?(certificate)
          usages = extended_key_usages(certificate)
          usages.include?(SERVER_AUTH_EKU) || usages.include?(SERVER_AUTH_EKU_OID)
        end

        def sha256_fingerprint(certificate)
          require "digest"
          Digest::SHA256.hexdigest(certificate.to_der)
        end

        # Exactly one URI SAN, equal to the expected identity. CA
        # membership alone never grants a project: the single SAN is the
        # certificate's whole identity.
        def single_uri_san!(certificate, expected, label)
          sans = uri_sans(certificate)
          unless sans == [expected]
            raise Error,
              "#{label} certificate identity is not the exact single expected URI SAN " \
              "(expected #{expected.inspect}, got #{sans.inspect})"
          end

          true
        end

        def valid_time?(certificate, now: Time.now)
          certificate.not_before <= now && now <= certificate.not_after
        end

        def parse_fields(config, fields, schema)
          unless config.is_a?(Hash)
            raise Error, "#{schema} must be a mapping (got #{config.class})"
          end

          unknown = config.keys - fields
          unless unknown.empty?
            raise Error, "#{schema} rejects unknown fields: #{unknown.sort.join(", ")}"
          end

          fields.to_h do |field|
            value = config[field]
            raise Error, "#{schema} field #{field} is missing or null" if value.nil?
            unless value.is_a?(String) && !value.empty?
              raise Error, "#{schema} field #{field} must be a non-empty string"
            end

            [field, field.end_with?("_file") ? canonical_path(value, schema, field) : value]
          end
        end

        def canonical_path(value, schema, field)
          unless File.absolute_path?(value) && File.expand_path(value) == value
            raise Error,
              "#{schema} field #{field} must be an absolute canonical path (got #{value.inspect})"
          end

          value
        end
      end
    end
  end
end
