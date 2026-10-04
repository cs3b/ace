# frozen_string_literal: true

require "ace/support/cli"
require_relative "../../lifecycle"
require_relative "../../providers/providers"

module Ace
  module Hitl
    module CLI
      module Commands
        # The installed scoped store boundary (spec 8wq.t.34i): serves
        # the private HITL store over a peer-authenticated UNIX socket.
        # Authorization facts come only from the trusted grants
        # document; the store root and socket paths come from the
        # deployment (options/environment), never from caller payloads.
        class Serve < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Run the authenticated HITL store boundary service (peer-credential access)"

          option :socket, type: :string, desc: "Boundary socket path (default: ACE_HITL_SOCKET or /run/lab/hitl.sock)"
          option :store_root, type: :string, desc: "Private store root (default: ACE_HITL_STORE_ROOT or /run/lab/hitl)"
          option :grants_path, type: :string, desc: "Trusted grants document (default: ACE_HITL_GRANTS_PATH or /etc/lab/ace-lab/authorization.yml)"
          option :repo_root, type: :string, desc: "Candidate repository for the managed attempt authority"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"

          def call(**options)
            policy = Providers::Lab.grants_policy(grants_path: grants_path(options))
            unless policy.service_uid
              raise_cli_error(
                "the HITL service requires trusted grants with hitl.service_uid " \
                "(#{grants_path(options)}); serving without a trusted service identity would " \
                "fail every client endpoint verification"
              )
            end
            binding_policy = Providers::Lab.assignment_binding(repo_root: options[:repo_root])
            service = Lifecycle::Service.new(
              root: store_root(options),
              binding: binding_policy,
              policy: policy,
              socket_path: socket_path(options),
              logger: options[:verbose] ? ->(message) { warn message } : nil
            )
            service.run
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_cli_error(e.message)
          end

          private

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
