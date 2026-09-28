# frozen_string_literal: true

require "ace/git"

module Ace
  module Git
    module Worktree
      module Molecules
        # Fetches the exact source repository/ref declared by PR evidence and
        # proves the fetched commit before any worktree is created.
        #
        # Canonical-repository and fork source URLs are equally valid: the
        # fetch goes through a matching local remote when one exists, and by
        # explicit URL otherwise (no remote ref is created for URL fetches).
        class PullRequestCheckoutPreparer
          DEFAULT_TIMEOUT = 60

          # @param timeout [Integer] git command timeout in seconds
          def initialize(timeout: DEFAULT_TIMEOUT)
            @timeout = timeout
          end

          # Fetch the declared source ref and verify its SHA against the
          # evidence head.
          #
          # @param evidence [Ace::Git::ProviderPullRequest] normalized PR evidence
          # @return [Hash] {success:, local_ref:, sha:, remote_tracking:, error:}
          #   `local_ref` is a ref suitable for `git worktree add`; the branch
          #   head was verified to equal evidence.head_sha.
          def prepare(evidence)
            head_url = evidence.head_repository_url
            head_ref = evidence.head_ref
            return error_result("PR evidence is missing the source repository URL") if head_url.nil? || head_url.empty?
            return error_result("PR evidence is missing the source branch") if head_ref.nil? || head_ref.empty?
            return error_result("PR evidence is missing the exact head SHA") unless evidence.head_sha

            local_remote = matching_local_remote(head_url)
            fetch_source = local_remote || head_url
            fetch_desc = "#{head_url}@#{head_ref}"

            fetch_result = Ace::Git::Worktree::Atoms::GitCommand.execute(
              "fetch", fetch_source, head_ref, timeout: @timeout
            )
            return error_result("Failed to fetch #{fetch_desc}: #{fetch_result[:error]}") unless fetch_result[:success]

            sha = resolve_fetch_head
            return error_result("Cannot resolve fetched commit for #{fetch_desc}") unless sha

            if sha != evidence.head_sha
              return error_result(
                "Fetched head #{sha} does not match PR evidence head #{evidence.head_sha} " \
                "(#{head_url}@#{head_ref}); the PR head moved since the evidence was captured"
              )
            end

            {
              success: true,
              local_ref: "FETCH_HEAD",
              sha: sha,
              remote_tracking: local_remote ? "#{local_remote}/#{head_ref}" : nil,
              error: nil
            }
          end

          private

          # Find a configured local git remote whose URL matches the evidence
          # source repository; nil means fetch by explicit URL instead.
          def matching_local_remote(head_url)
            result = Ace::Git::Worktree::Atoms::GitCommand.execute("remote", "-v", timeout: 5)
            return nil unless result[:success]

            remotes = {}
            result[:output].to_s.each_line do |line|
              name, url, = line.strip.split(/\s+/)
              remotes[name] = url if url
            end

            remotes.find do |_name, url|
              Ace::Git::Atoms::ServerUrl.match?(url, head_url)
            end&.first
          end

          def resolve_fetch_head
            result = Ace::Git::Worktree::Atoms::GitCommand.execute(
              "rev-parse", "--verify", "FETCH_HEAD^{commit}", timeout: 10
            )
            result[:success] ? result[:output].to_s.strip : nil
          end

          def error_result(message)
            {success: false, local_ref: nil, sha: nil, remote_tracking: nil, error: message}
          end
        end
      end
    end
  end
end
