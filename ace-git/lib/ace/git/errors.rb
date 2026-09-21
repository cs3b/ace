# frozen_string_literal: true

module Ace
  module Git
    # Error handling pattern:
    # - Atoms: Pure functions, raise exceptions for invalid inputs
    # - Molecules: May return error hashes for "expected" errors (e.g., not in git repo)
    #   or raise exceptions for unexpected failures
    # - Organisms: Orchestrate molecules, propagate or wrap exceptions
    # - Commands: Catch exceptions and return exit codes (0=success, 1=error)
    #
    # All custom exceptions inherit from Ace::Git::Error for consistent catching.
    class Error < StandardError; end
    class GitError < Error; end
    class ConfigError < Error; end
    class TimeoutError < Error; end

    # ---- Forge server resolution failures ----

    # Default requested but no default server is configured.
    class NoDefaultServerConfiguredError < Error; end

    # More than one server is marked as default in configuration.
    class MultipleDefaultServersError < Error; end

    # Multiple servers are configured with the same identifier.
    class DuplicateServerNameError < Error; end

    # A server references a provider type that no provider package registered.
    class UnknownProviderError < Error; end

    # The requested server name is not present in configuration.
    class UnknownServerNameError < Error; end

    # A remote URL matches multiple configured servers, or none, so the server
    # identity cannot be determined without caller input.
    class AmbiguousRemoteError < Error; end

    # ---- Provider interaction failures ----

    # The provider CLI binary is not installed in PATH.
    class ProviderCliMissingError < Error; end

    # The provider CLI is unauthenticated or its credential lease expired.
    class ProviderAuthenticationError < Error; end

    # The remote forge endpoint is offline or unreachable.
    class ProviderUnreachableError < Error; end

    # The provider CLI returned invalid JSON or an unexpected schema.
    class ProviderMalformedOutputError < Error; end

    # The requested pull request, issue, branch, or commit does not exist.
    class ProviderObjectNotFoundError < Error; end
  end
end
