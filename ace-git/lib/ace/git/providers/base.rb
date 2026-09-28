# frozen_string_literal: true

module Ace
  module Git
    module Providers
      # Abstract provider contract implemented by provider packages.
      #
      # The core defines the interface and the normalized evidence types;
      # implementations own all provider CLI invocation, output parsing, and
      # authentication verification. The core itself never executes a provider
      # CLI and never parses provider output.
      #
      # Subclasses receive the resolved server identity and may accept two
      # optional constructor keywords (see {Providers.for}):
      # - timeout: operation timeout in seconds
      # - runner: injectable command runner for tests; a callable receiving
      #   keyword arguments (args:, timeout:, env:) and returning a Hash with
      #   :stdout, :stderr, :exit_code
      class Base
        attr_reader :server, :timeout

        # @param server [ResolvedServer] resolved server identity
        # @param timeout [Integer, nil] operation timeout (default: config)
        # @param runner [Proc, nil] injectable command runner for tests
        def initialize(server:, timeout: nil, runner: nil)
          @server = server
          @timeout = timeout || Ace::Git.network_timeout
          @runner = runner
        end

        # @return [Boolean] true when the provider CLI binary is installed
        def available?
          raise NotImplementedError, "Providers must implement #{self.class}#available?"
        end

        # @raise [ProviderCliMissingError] when the provider CLI is missing
        def check_available!
          raise NotImplementedError, "Providers must implement #{self.class}#check_available!"
        end

        # @return [Boolean] true when the provider CLI is authenticated
        def authenticated?
          raise NotImplementedError, "Providers must implement #{self.class}#authenticated?"
        end

        # @raise [ProviderAuthenticationError] when unauthenticated
        def check_authenticated!
          raise NotImplementedError, "Providers must implement #{self.class}#check_authenticated!"
        end

        # Fetch one pull request.
        #
        # @param number [Integer, String] pull request number
        # @return [ProviderPullRequest] normalized pull request evidence
        def pull_request(number:)
          raise NotImplementedError, "Providers must implement #{self.class}#pull_request"
        end

        # Find the pull request associated with a branch.
        #
        # @param branch [String] branch name
        # @return [ProviderPullRequest, nil] evidence, or nil when no pull
        #   request is associated with the branch
        def pull_request_for_branch(branch:)
          raise NotImplementedError, "Providers must implement #{self.class}#pull_request_for_branch"
        end

        # Fetch the full diff of one pull request.
        #
        # @param number [Integer, String] pull request number
        # @return [String] unified diff text
        def pull_request_diff(number:)
          raise NotImplementedError, "Providers must implement #{self.class}#pull_request_diff"
        end

        # List recent pull requests across states (newest first).
        #
        # @param limit [Integer] maximum number of pull requests
        # @return [Array<ProviderPullRequest>] normalized pull requests
        def recent_pull_requests(limit:)
          raise NotImplementedError, "Providers must implement #{self.class}#recent_pull_requests"
        end

        # Fetch one issue.
        #
        # @param number [Integer, String] issue number
        # @return [ProviderIssue] normalized issue evidence
        def issue(number:)
          raise NotImplementedError, "Providers must implement #{self.class}#issue"
        end

        # Fetch check/CI status evidence for a reference.
        #
        # @param ref [String] commit sha or branch name
        # @return [Array<ProviderCheck>] normalized check evidence
        def checks(ref:)
          raise NotImplementedError, "Providers must implement #{self.class}#checks"
        end

        # Fetch repository metadata for the resolved server.
        #
        # @return [ProviderRepository] normalized repository evidence
        def repository
          raise NotImplementedError, "Providers must implement #{self.class}#repository"
        end

        # ---- PR lifecycle mutations ----
        #
        # Contract requirements (enforced by every provider implementation):
        # - Exact identity: lookup and create operate on the exact
        #   head repository URL/ref and base repository URL/ref; no fork
        #   inference and no branch-name-only matching.
        # - Expected head: every head-dependent operation receives the exact
        #   head SHA the caller saw and must fail with
        #   ProviderExpectedHeadConflictError when the live head differs. For
        #   merge the enforcement must be atomic provider-side; a provider CLI
        #   without such support raises ProviderUnsupportedCapabilityError
        #   instead of emulating a check-then-merge race.
        # - Idempotent create: one exact open base/head match returns the
        #   existing PR (`:existing` receipt); zero matches create; more than
        #   one match raises ProviderConflictingMatchesError.
        # - Unknown outcomes: a transport failure after a request that may
        #   have mutated state raises ProviderUnknownOutcomeError carrying the
        #   exact identity; implementations never retry automatically.
        # - Receipts: mutations return a ProviderMutationReceipt whose
        #   evidence carries source/base repository provenance and exact head.

        # Find open pull requests matching an exact base/head identity.
        #
        # @param head_repository_url [String] source repository URL
        # @param head_ref [String] source branch/ref
        # @param base_repository_url [String] base repository URL
        # @param base_ref [String] base branch/ref
        # @return [Array<ProviderPullRequest>] matching open pull requests
        def find_open_pull_requests(head_repository_url:, head_ref:, base_repository_url:, base_ref:)
          raise NotImplementedError, "Providers must implement #{self.class}#find_open_pull_requests"
        end

        # Create a pull request, reconciling against an exact open match.
        #
        # @param head_ref [String] source branch/ref
        # @param head_repository_url [String] source repository URL
        # @param base_ref [String] base branch/ref
        # @param expected_head [String] exact SHA the pushed source ref must
        #   resolve to; the created/reconciled PR head is proven against it
        # @param title [String] pull request title
        # @param body [String, nil] pull request body text
        # @param draft [Boolean] request a draft pull request when the
        #   provider supports draft state; the returned evidence always
        #   reports the provider's actual draft state
        # @return [ProviderMutationReceipt] with idempotency :created/:existing
        # @raise [ProviderConflictingMatchesError] on multiple exact matches
        # @raise [ProviderExpectedHeadConflictError] when the head differs
        # @raise [ProviderUnknownOutcomeError] on unknown post-send outcome
        def create_pull_request(head_ref:, head_repository_url:, base_ref:, expected_head:, title:, body: nil, draft: true)
          raise NotImplementedError, "Providers must implement #{self.class}#create_pull_request"
        end

        # Update title/body of a pull request after head verification.
        #
        # @param number [Integer, String] pull request number
        # @param expected_head [String] exact SHA the PR head must still be
        # @param title [String, nil] new title
        # @param body [String, nil] new body text
        # @return [ProviderMutationReceipt]
        # @raise [ProviderExpectedHeadConflictError] when the head differs
        def update_pull_request(number:, expected_head:, title: nil, body: nil)
          raise NotImplementedError, "Providers must implement #{self.class}#update_pull_request"
        end

        # Mark a draft pull request ready for review after head verification.
        #
        # @param number [Integer, String] pull request number
        # @param expected_head [String] exact SHA the PR head must still be
        # @return [ProviderMutationReceipt]
        # @raise [ProviderExpectedHeadConflictError] when the head differs
        # @raise [ProviderUnsupportedCapabilityError] when the provider cannot
        #   change draft state
        def ready_pull_request(number:, expected_head:)
          raise NotImplementedError, "Providers must implement #{self.class}#ready_pull_request"
        end

        # Merge a pull request with provider-side expected-head enforcement.
        #
        # @param number [Integer, String] pull request number
        # @param expected_head [String] exact SHA enforced atomically by the
        #   provider before merging
        # @param method [Symbol, String] :squash, :merge, or :rebase; there
        #   is no implicit default
        # @return [ProviderMutationReceipt]
        # @raise [ProviderExpectedHeadConflictError] when the provider refuses
        #   the merge because the head changed
        # @raise [ProviderUnsupportedCapabilityError] when the provider CLI
        #   cannot enforce the head precondition atomically
        def merge_pull_request(number:, expected_head:, method:)
          raise NotImplementedError, "Providers must implement #{self.class}#merge_pull_request"
        end

        private

        # Command runner: injected fake or nil (implementations use their own
        # executor when nil).
        attr_reader :runner

        # Shared lifecycle guard: refuse when the live head differs from the
        # caller's expected head. Providers must use this so the classified
        # failure shape stays identical across forges.
        def verify_expected_head!(pull_request, expected_head)
          unless pull_request.head_sha.is_a?(String) && !pull_request.head_sha.empty?
            raise ProviderMalformedOutputError,
              "Provider evidence for PR ##{pull_request.number} is missing the exact head SHA"
          end
          return pull_request if pull_request.head_sha == expected_head

          raise ProviderExpectedHeadConflictError,
            "PR ##{pull_request.number} head changed: expected #{expected_head}, found #{pull_request.head_sha}"
        end
      end
    end
  end
end
