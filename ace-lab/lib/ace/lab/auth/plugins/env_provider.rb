# frozen_string_literal: true

module Ace
  module Lab
    module Auth
      module Plugins
        # The env provider (task 8xs.t.pu0.7): exposes ONLY the named
        # values of the configured safe sources to the leased child
        # process. The host's whole environment and inherited
        # credential overrides are never passed through; a standalone
        # env profile declares process-scoped exposure only (the schema
        # rejects it for profiles demanding remote expiry/revoke).
        # When env is the HANDOFF of a provider lease, the same file
        # carries that provider's token — this class is the standalone
        # case.
        class EnvProvider
          def capabilities
            {"expiry_mode" => "process"}
          end

          # @param issuer_env [Hash] the issuer process environment (the
          #   trusted values the profile names)
          def initialize(issuer_env: ENV.to_h)
            @issuer_env = issuer_env
          end

          def issue(profile:, lease:)
            names = profile.fetch("env_names")
            raise Providers::RefusedError,
              "the env profile declares no env_names" if names.empty?

            values = names.to_h do |name|
              value = @issuer_env[name]
              raise Providers::RefusedError,
                "issuer environment does not provide '#{name}'" if value.nil? || value.empty?

              [name, value]
            end

            {"token" => JSON.generate(values), "token_ref" => "env:#{lease["id"]}",
             "provider_expiry" => nil,
             "via" => {"kind" => "env", "names" => names.sort}}
          end

          def revoke(profile:, token_ref:)
            # Process-scoped exposure ends with the process; there is no
            # remote state to revoke and never a claimed remote expiry.
            :revoked
          end
        end
      end
    end
  end
end
