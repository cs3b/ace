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

        private

        # Command runner: injected fake or nil (implementations use their own
        # executor when nil).
        attr_reader :runner
      end
    end
  end
end
