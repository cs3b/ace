# frozen_string_literal: true

require "ace/git"

require_relative "forgejo/version"
require_relative "forgejo/cli_executor"
require_relative "forgejo/pr_identifier"
require_relative "forgejo/parsers"
require_relative "forgejo/provider"

module Ace
  module Git
    # Forgejo provider package for the forge-neutral ace-git core.
    #
    # Owns all Forgejo-specific behavior: `fj` CLI invocation, minimal-style
    # output parsing, authentication verification, and Forgejo terminology.
    # Implements the shared provider contract exposed by the core and
    # registers itself in the core provider registry.
    module Forgejo
      PROVIDER_TYPE = :forgejo
    end
  end
end

Ace::Git::Providers.register(Ace::Git::Forgejo::PROVIDER_TYPE, Ace::Git::Forgejo::Provider)
