# frozen_string_literal: true

require "ace/git"

module Ace
  module Git
    module Worktree
      module Molecules
        # Resolves normalized pull request evidence for worktree consumers.
        #
        # The server is selected once (explicit `--server`, `--default-server`,
        # or remote resolution) and the PR is fetched through the registered
        # provider contract. Local-only callers never construct this molecule,
        # so no forge resolution happens without a PR-aware request.
        class PullRequestEvidenceResolver
          # @param server_name [String, nil] explicit server selection
          # @param use_default [Boolean] resolve the configured default server
          # @param remote_name [String, nil] git remote for fallback resolution
          # @param timeout [Integer, nil] provider timeout
          # @param runner [Proc, nil] injectable provider runner (tests)
          def initialize(server_name: nil, use_default: false, remote_name: nil, timeout: nil, runner: nil)
            @selection = {server_name: server_name, use_default: use_default, remote_name: remote_name}
            @timeout = timeout
            @runner = runner
          end

          # Fetch exact PR evidence with source/base provenance.
          #
          # @param number [Integer, String] pull request number
          # @return [Hash] {server: ResolvedServer, evidence: ProviderPullRequest}
          def resolve(number)
            server = Ace::Git::ServerRegistry.resolve_for(**@selection)
            provider = Ace::Git::Providers.for(server, timeout: @timeout, runner: @runner)
            {server: server, evidence: provider.pull_request(number: number)}
          end
        end
      end
    end
  end
end
