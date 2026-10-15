# frozen_string_literal: true

require "ipaddr"
require "json"
require_relative "tls_credentials"
require_relative "credential_path_policy"
require_relative "tls_material"

module Ace
  module Hitl
    module Lifecycle
      # The authority configuration of one TLS lifecycle service (spec
      # 8xa.t.nh0): it owns the loopback listen address, the project ID
      # and the server credential reference. The file is a root-owned
      # runtime object (root:<service-group> mode 0640) and every field
      # is closed: unknown fields and nulls are rejected.
      #
      # lab-config owns accounts, file provisioning, the Incus proxy
      # device and the tailnet listener; this configuration only binds
      # the already-provisioned facts.
      class TlsAuthority
        SCHEMA = "ace.hitl.tls.authority/v1"
        FIELDS = %w[schema project_id listen port service_user service_group
          tls_server_credential].freeze

        attr_reader :project_id, :listen, :port, :service_user, :service_group,
          :credential, :path

        def self.load(path)
          config = JSON.parse(File.read(path))
          authority = new(config, path: path)
          CredentialPathPolicy.verify_runtime_file!(path, authority.service_group)
          authority
        rescue JSON::ParserError, SystemCallError, IOError
          raise TransportError, "the HITL TLS authority configuration is unavailable or malformed: #{path}"
        end

        def initialize(config, path: nil)
          unless config.is_a?(Hash) && (config.keys - FIELDS).empty? &&
              FIELDS.all? { |field| !config[field].nil? }
            raise TransportError, "#{SCHEMA} rejects unknown fields and nulls"
          end
          unless config.fetch("schema") == SCHEMA
            raise TransportError, "the HITL TLS authority requires #{SCHEMA}"
          end

          @path = path
          @project_id = TlsCredentials.project_id(config.fetch("project_id"))
          @listen = validate_listen(config.fetch("listen"))
          @port = validate_port(config.fetch("port"))
          @service_user = config.fetch("service_user")
          @service_group = config.fetch("service_group")
          validate_name(@service_user, "service_user")
          validate_name(@service_group, "service_group")
          @credential = TlsCredentials.parse_server(config.fetch("tls_server_credential"))
          validate_project_binding
          freeze
        end

        # Fail-closed startup ordering: the exact credential layout is
        # verified BEFORE any TLS material is loaded and BEFORE the
        # listener socket is opened.
        def ssl_context!
          CredentialPathPolicy.verify_credential_tree!(
            credential: @credential, service_user: @service_user, service_group: @service_group)
          TlsMaterial.build_server_context(@credential)
        end

        private

        # The container lifecycle service accepts its loopback port
        # only; a wildcard or non-loopback bind would expose the
        # authority beyond the Incus proxy device.
        def validate_listen(value)
          address = IPAddr.new(value.to_s)
          return value.to_s if address.loopback?

          raise TransportError,
            "the HITL TLS authority must bind a loopback address (got #{value.inspect})"
        rescue IPAddr::InvalidAddressError
          raise TransportError, "the HITL TLS authority listen address is invalid: #{value.inspect}"
        end

        def validate_port(value)
          unless value.is_a?(Integer) && (1..65_535).cover?(value)
            raise TransportError, "the HITL TLS authority port must be an integer in 1..65535"
          end

          value
        end

        def validate_name(value, label)
          return if value.is_a?(String) && value.match?(/\A[a-z_][a-z0-9_-]{0,31}\z/)

          raise TransportError, "the HITL TLS authority #{label} is not a valid account name"
        end

        # Both configured identities must name THIS authority's project:
        # a project's proxy reaches only its own lifecycle service.
        def validate_project_binding
          %w[server_uri_san allowed_client_uri_san].each do |field|
            san_project = TlsCredentials.uri_san_project(@credential.fetch(field))
            next if san_project == @project_id

            raise TransportError,
              "the configured #{field} names project #{san_project.inspect}, not #{@project_id.inspect}"
          end
        end
      end
    end
  end
end
