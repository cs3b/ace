# frozen_string_literal: true

require "ace/git"

require_relative "github/version"
require_relative "github/cli_executor"
require_relative "github/pr_identifier"
require_relative "github/pr_fetcher"
require_relative "github/issue_sync"
require_relative "github/provider"

module Ace
  module Git
    # GitHub provider package for the forge-neutral ace-git core.
    #
    # Owns all GitHub-specific behavior: `gh` CLI invocation, output parsing,
    # authentication verification, and GitHub terminology. Implements the
    # shared provider contract exposed by the core and registers itself in the
    # core provider registry.
    module Github
      PROVIDER_TYPE = :github
    end
  end
end

Ace::Git::Providers.register(Ace::Git::Github::PROVIDER_TYPE, Ace::Git::Github::Provider)
