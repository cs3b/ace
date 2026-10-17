# frozen_string_literal: true

require "ace/support/cli"
require_relative "../../lifecycle"
require_relative "../../providers/lab"

module Ace
  module Hitl
    module CLI
      module Commands
        # The operator-only local scoped store boundary: serves explicitly
        # granted nonsecret operator questions over a peer-authenticated
        # UNIX socket. Authorization facts come only from the trusted grants
        # document; the store root and socket paths come from the deployment
        # (options/environment), never from caller payloads.
        #
        # The installed managed-attempt authority and the host/Incus mTLS
        # crossing were removed with the old authority model.
        class Serve < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Run the operator-only HITL store boundary service (peer-credential access)"

          option :socket, type: :string, desc: "Boundary socket path (default: ACE_HITL_SOCKET or /run/lab/hitl.sock)"
          option :group, type: :string,
            desc: "Dedicated lifecycle group allowed to connect (required; root and lab-control are refused)"
          option :store_root, type: :string, desc: "Private store root (default: ACE_HITL_STORE_ROOT or /run/lab/hitl)"
          option :grants_path, type: :string,
            desc: "Trusted grants document (default: ACE_HITL_GRANTS_PATH or /etc/lab/ace-lab/authorization.yml)"
          option :operator_only, type: :boolean,
            desc: "Serve explicitly granted nonsecret operator questions without a managed execution authority"
          option :repo_root, type: :string, desc: "(removed) managed attempt authority repository"
          option :tls_authority, type: :string, desc: "(removed) host/Incus mTLS crossing authority"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"

          def call(**options)
            if options[:repo_root] || options[:tls_authority]
              raise_cli_error(
                "managed and TLS serve were removed with the installed attempt authority; " \
                "serve supports --operator-only only"
              )
            end
            unless options[:operator_only]
              raise_cli_error(
                "the installed managed attempt authority is removed; serve requires --operator-only"
              )
            end

            group = dedicated_group(options)
            policy = Providers::Lab.grants_policy(grants_path: grants_path(options))
            unless policy.service_uid
              raise_cli_error(
                "the HITL service requires trusted grants with hitl.service_uid " \
                "(#{grants_path(options)}); serving without a trusted service identity would " \
                "fail every client endpoint verification"
              )
            end
            service = Lifecycle::Service.new(
              root: store_root(options),
              binding: Lifecycle::OperatorOnlyBinding.new,
              policy: policy,
              socket_path: socket_path(options),
              group: group,
              logger: options[:verbose] ? ->(message) { warn message } : nil
            )
            service.run
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_cli_error(e.message)
          end

          private

          def dedicated_group(options)
            group = options[:group].to_s
            return group unless group.empty?

            raise_cli_error("--group is required and must name a dedicated lifecycle group")
          end

          def socket_path(options)
            options[:socket] || ENV[Providers::Lab::SOCKET_PATH_ENV] || Providers::Lab::DEFAULT_SOCKET_PATH
          end

          def store_root(options)
            options[:store_root] || ENV[Providers::Lab::STORE_ROOT_ENV] || Providers::Lab::DEFAULT_STORE_ROOT
          end

          def grants_path(options)
            options[:grants_path] || ENV[Providers::Lab::GRANTS_PATH_ENV] || Providers::Lab::DEFAULT_GRANTS_PATH
          end
        end
      end
    end
  end
end
