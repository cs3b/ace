# frozen_string_literal: true

require "json"

module Ace
  module Lab
    module Auth
      # Explicit provider registration (task 8xs.t.pu0.7) — the same
      # precedented pattern as Ace::Git::Providers and the ace-hitl
      # adapter registry. A plugin owns its protocol; the auth core owns
      # the contract and the lease lifecycle. No marketplace, no
      # generic workflow engine.
      #
      # Plugin contract (duck type):
      #   capabilities -> {expiry_mode:} which the profile must accept
      #   token_ref_for(lease_id:) -> String | nil — the provider's
      #     DETERMINISTIC remote identity for the lease, written to the
      #     record at creation; nil when the identity is only knowable
      #     from the creation response (an unresolved issue then waits
      #     for reconcile/native expiry instead of deterministic
      #     settlement)
      #   issue(profile:, lease:) ->
      #     {"token" => secret (never serialized), "token_ref" => provider id,
      #      "provider_expiry" => time-ish | nil, "via" => handoff descriptor}
      #     or raises RefusedError / TransientError / OutcomeUnknownError
      #   revoke(profile:, token_ref:, token:) -> :revoked | :already_invalid |
      #     raises TransientError / OutcomeUnknownError
      #     (`token` is the issued secret from the handoff — providers
      #     that revoke BY the token value, e.g. GitHub's installation
      #     token endpoint, require it; providers revoking by a server
      #     id ignore it; a 404-shaped unknown id settles as
      #     :already_invalid so interrupted issues recover
      #     deterministically)
      class Providers
        class RefusedError < StandardError; end
        class TransientError < StandardError; end
        class OutcomeUnknownError < StandardError; end
        class UnsupportedError < StandardError; end

        @registry = {}
        @mutex = Mutex.new

        class << self
          def register(name, plugin)
            @mutex.synchronize { @registry[name.to_s] = plugin }
          end

          def resolve(name)
            plugin = @mutex.synchronize { @registry[name.to_s] }
            raise UnsupportedError, "no auth provider registered for '#{name}'" unless plugin

            plugin
          end

          def reset!
            @mutex.synchronize { @registry.clear }
          end

          def registered
            @mutex.synchronize { @registry.keys.sort }
          end
        end
      end
    end
  end
end
