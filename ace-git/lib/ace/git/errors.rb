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

    # ---- PR lifecycle mutation failures ----

    # A supplied PR URL or repository identity does not match the resolved
    # server (or the explicit selection contradicts the identifier). Detected
    # before any mutation.
    class ProviderIdentityMismatchError < Error; end

    # More than one open pull request exactly matches the requested
    # base/head identity, so no single object can be selected.
    class ProviderConflictingMatchesError < Error; end

    # The pull request head changed relative to the expected head SHA the
    # caller supplied. The operation did not proceed (or the provider refused
    # it atomically).
    class ProviderExpectedHeadConflictError < Error; end

    # The provider CLI cannot enforce a required precondition atomically
    # (e.g. expected-head merge) or does not offer the requested operation.
    # Never worked around with a check-then-act fallback.
    class ProviderUnsupportedCapabilityError < Error; end

    # A mutation request was sent but its outcome is unknown (e.g. transport
    # failure after the send). Contains the exact base/head identity needed to
    # reconcile by lookup; never retried automatically.
    class ProviderUnknownOutcomeError < Error; end

    # Reconciliation reads all completed and the tracked marker never
    # appeared: authoritative absence of a prior create. The only outcome
    # that may authorize a fresh create POST.
    class ProviderReconcileAbsenceError < ProviderUnknownOutcomeError; end
  end
end
