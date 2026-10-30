# frozen_string_literal: true

require_relative "auth/profile_schema"
require_relative "auth/lease_store"
require_relative "auth/providers"
require_relative "auth/credential_handoff"
require_relative "auth/plugins/env_provider"
require_relative "auth/plugins/forgejo_provider"
require_relative "auth/plugins/github_provider"
require_relative "auth/service"

module Ace
  module Lab
    # ace-lab auth (task 8xs.t.pu0.7): short-lived, role-scoped access
    # for delegated work. The public contract and lease lifecycle live
    # here; provider protocols live in plugins. Explicit registration
    # of the bundled plugins — the same precedented pattern as the
    # ace-git provider registry.
    module Auth
      Providers.register("env", Plugins::EnvProvider.new)
      Providers.register("forgejo", Plugins::ForgejoProvider.new)
      Providers.register("github", Plugins::GithubProvider.new)
    end
  end
end
