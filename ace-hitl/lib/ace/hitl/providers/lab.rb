# frozen_string_literal: true

require "ace/hitl/contract"
require_relative "../lifecycle/store"
require_relative "../lifecycle/policy"
require_relative "../lifecycle/client"

module Ace
  module Hitl
    module Providers
      # Deployment facts for the host-installed HITL lifecycle transport:
      # the trusted grants policy and the authenticated boundary client.
      # The managed `ask`/native-delivery path and its attempt-bound
      # assignment binding were removed with the old authority model; the
      # local file-based commands and the lifecycle/relay transport remain.
      class Lab
        DEFAULT_STORE_ROOT = "/run/lab/hitl"
        STORE_ROOT_ENV = "ACE_HITL_STORE_ROOT"
        DEFAULT_SOCKET_PATH = "/run/lab/hitl.sock"
        SOCKET_PATH_ENV = "ACE_HITL_SOCKET"
        # The trusted deployment grants document, shared with the operator
        # question and transport authorization facts. The PATH may be
        # overridden for tests; the document's trust is verified absolutely
        # (root-owned, protected traversal), so an override cannot inject
        # authority.
        DEFAULT_GRANTS_PATH = "/etc/lab/ace-lab/authorization.yml"
        GRANTS_PATH_ENV = "ACE_HITL_GRANTS_PATH"

        # The transport/service authorization policy from the trusted
        # grants document.
        def self.grants_policy(grants_path: nil, document: nil)
          Lifecycle::GrantsPolicy.new(
            grants_path: grants_path || ENV[GRANTS_PATH_ENV] || DEFAULT_GRANTS_PATH,
            document: document
          )
        end

        # The authenticated boundary client for CLI operations. The service
        # identity comes ONLY from the trusted grants document; without it
        # the boundary is unconfigured and every lifecycle operation fails
        # closed with a visible transport error.
        def self.boundary_client(socket_path: nil, policy: nil)
          policy ||= grants_policy
          service_uid = policy.service_uid
          unless service_uid
            raise ProviderUnavailableError,
              "the HITL service is not configured: #{ENV[GRANTS_PATH_ENV] || DEFAULT_GRANTS_PATH} " \
              "must define hitl.service_uid"
          end

          Lifecycle::Client.new(
            socket_path: socket_path || ENV[SOCKET_PATH_ENV] || DEFAULT_SOCKET_PATH,
            service_uid: service_uid
          )
        end
      end
    end
  end
end
