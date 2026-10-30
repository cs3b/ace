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
      #   issue(profile:, lease:) ->
      #     {"token" => secret (never serialized), "token_ref" => provider id,
      #      "provider_expiry" => time-ish | nil, "via" => handoff descriptor}
      #     or raises RefusedError / TransientError / OutcomeUnknownError
      #   revoke(profile:, token_ref:) -> :revoked | :already_invalid |
      #     raises TransientError / OutcomeUnknownError
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
