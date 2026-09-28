# frozen_string_literal: true

require "json"
require "uri"

module Ace
  module Git
    module Github
      # GitHub provider implementation of the shared provider contract.
      #
      # Owns GitHub terminology and translates `gh` responses into the
      # normalized evidence types defined by the ace-git core. Every failure is
      # classified with the shared taxonomy; nothing falls back silently.
      class Provider < Ace::Git::Providers::Base
        STATE_MAP = {
          "OPEN" => :open,
          "MERGED" => :merged,
          "CLOSED" => :closed
        }.freeze

        # `gh` check bucket vocabulary mapped onto neutral conclusions
        BUCKET_MAP = {
          "pass" => :success,
          "fail" => :failure,
          "pending" => :pending,
          "skipping" => :skipped
        }.freeze

        PR_FIELDS = "number,state,isDraft,title,author,headRefName,baseRefName,url,headRefOid,mergeCommit,mergedAt,headRepositoryOwner,headRepository"
        LIST_FIELDS = PrFetcher::LIST_FIELDS
        REPO_FIELDS = "nameWithOwner,defaultBranchRef,url"
        ISSUE_FIELDS = "number,title,state,author,url"

        # Fields needed to match pull requests by exact base/head identity.
        LIFECYCLE_LIST_FIELDS = "number,title,state,isDraft,author,headRefName,baseRefName,url,headRefOid,headRepositoryOwner,headRepository"

        class << self
          # Human-facing provider type name used in failure messages.
          def display_name
            "GitHub"
          end
        end

        # @return [Boolean] true when the `gh` binary is installed
        def available?
          PrFetcher.installed?(runner: runner)
        end

        # @raise [Ace::Git::ProviderCliMissingError] when `gh` is missing
        def check_available!
          CliExecutor.check_installed!(runner: runner)
        end

        # @return [Boolean] true when `gh` is authenticated
        def authenticated?
          PrFetcher.authenticated?(runner: runner)
        end

        # @raise [Ace::Git::ProviderAuthenticationError] when unauthenticated
        def check_authenticated!
          CliExecutor.check_authenticated!(runner: runner)
        end

        # @return [ProviderPullRequest] normalized pull request evidence
        # @raise [ProviderObjectNotFoundError] when the PR does not exist
        # @raise [ProviderMalformedOutputError] when `gh` returns invalid JSON
        # @raise [ProviderUnreachableError] when the endpoint is unreachable
        def pull_request(number:)
          data = gh_json(["pr", "view", number.to_s, "--json", PR_FIELDS])
          normalize_pr(data, server.name)
        end

        # @return [ProviderPullRequest, nil] evidence for the branch's PR
        def pull_request_for_branch(branch:)
          candidates = recent_pull_requests(limit: 30)
          branch_prs = candidates.select { |pr| pr.head_ref == branch }
          return nil if branch_prs.empty?

          branch_prs.min_by { |pr| STATE_ORDER.fetch(pr.state, 3) }
        end

        # @return [String] unified diff text for the pull request
        def pull_request_diff(number:)
          result = PrFetcher.fetch_diff(number.to_s, timeout: timeout, runner: runner)
          result[:diff]
        end

        # @return [Array<ProviderPullRequest>] recent PRs, newest first
        def recent_pull_requests(limit:)
          result = PrFetcher.fetch_all_prs(limit: limit, timeout: timeout, runner: runner)
          result[:prs]
            .map { |pr| normalize_pr(pr, server.name) }
            .sort_by { |pr| -pr.number.to_i }
        end

        # @return [ProviderIssue] normalized issue evidence
        def issue(number:)
          output = gh_json(["issue", "view", number.to_s, "--json", ISSUE_FIELDS])
          normalize_issue(output)
        end

        # @return [Array<ProviderCheck>] normalized check evidence for a ref
        def checks(ref:)
          output = gh_json(["pr", "checks", ref.to_s, "--json", "name,state,bucket"])
          output.map do |check|
            bucket = check["bucket"].to_s.downcase
            Ace::Git::ProviderCheck.new(
              server_name: server.name,
              name: check["name"].to_s,
              state: check["state"].to_s.downcase.to_sym,
              conclusion: BUCKET_MAP.fetch(bucket, bucket.empty? ? nil : bucket.to_sym),
              url: nil
            )
          end
        end

        # @return [ProviderRepository] normalized repository evidence
        def repository
          output = gh_json(["repo", "view", "--json", REPO_FIELDS])
          Ace::Git::ProviderRepository.new(
            server_name: server.name,
            full_name: output["nameWithOwner"],
            default_branch: output.dig("defaultBranchRef", "name"),
            url: output["url"]
          )
        end

        # ---- PR lifecycle mutations ----

        # @return [Array<ProviderPullRequest>] open PRs matching the exact
        #   base/head identity (head repository URL/ref plus base URL/ref)
        def find_open_pull_requests(head_repository_url:, head_ref:, base_repository_url:, base_ref:)
          require_base_on_server!(base_repository_url)
          data = gh_json(["pr", "list", "--state", "open", "--limit", "200", "--json", LIFECYCLE_LIST_FIELDS])
          data.filter_map { |entry| normalize_pr(entry, server.name) }
            .select do |pr|
              pr.head_ref == head_ref &&
                pr.base_ref == base_ref &&
                Ace::Git::Atoms::ServerUrl.match?(pr.head_repository_url, head_repository_url)
            end
        end

        # Create a PR, reconciling to an exact open match first; proves the
        # created/reconciled head against `expected_head`.
        #
        # @return [ProviderMutationReceipt] idempotency :created/:existing
        def create_pull_request(head_ref:, head_repository_url:, base_ref:, expected_head:, title:, body: nil, draft: true)
          matches = find_open_pull_requests(
            head_repository_url: head_repository_url, head_ref: head_ref,
            base_repository_url: server.url, base_ref: base_ref
          )
          if matches.size > 1
            raise Ace::Git::ProviderConflictingMatchesError,
              "Multiple open pull requests match #{head_repository_url}@#{head_ref} -> " \
              "#{base_ref}: #{matches.map(&:number).join(", ")}; resolve the conflict first"
          end
          if matches.size == 1
            existing = matches.first
            return receipt(:create, verify_head!(existing, expected_head), :existing)
          end

          args = ["pr", "create", "--head", gh_head_arg(head_ref, head_repository_url), "--base", base_ref, "--title", title]
          args += ["--body", body] if body
          args << "--draft" if draft

          result = send_mutation(args, ambiguous: true, identity: identity_text(head_repository_url, head_ref, base_ref))
          number = result[:stdout].to_s.strip[%r{/pull/(\d+)\z}, 1]
          unless number
            raise Ace::Git::ProviderMalformedOutputError,
              "gh pr create did not return a pull request URL: #{result[:stdout].to_s.strip}"
          end

          created = verify_head!(pull_request(number: number), expected_head)
          receipt(:create, created, :created)
        end

        # @return [ProviderMutationReceipt] operation :update
        def update_pull_request(number:, expected_head:, title: nil, body: nil)
          verify_head!(pull_request(number: number), expected_head)
          args = ["pr", "edit", number.to_s]
          args += ["--title", title] if title
          args += ["--body", body] if body
          send_mutation(args, ambiguous: false)
          receipt(:update, pull_request(number: number), nil)
        end

        # @return [ProviderMutationReceipt] operation :ready
        def ready_pull_request(number:, expected_head:)
          verify_head!(pull_request(number: number), expected_head)
          send_mutation(["pr", "ready", number.to_s], ambiguous: false)
          receipt(:ready, pull_request(number: number), nil)
        end

        # Merge with atomic provider-side expected-head enforcement via
        # `gh pr merge --match-head-commit`.
        #
        # @return [ProviderMutationReceipt] operation :merge
        def merge_pull_request(number:, expected_head:, method:)
          unless %i[squash merge rebase].include?(method)
            raise ArgumentError, "Invalid merge method #{method.inspect}"
          end

          send_mutation(
            ["pr", "merge", number.to_s, "--#{method}", "--match-head-commit", expected_head],
            ambiguous: false
          )
          receipt(:merge, pull_request(number: number), nil)
        end

        private

        STATE_ORDER = {open: 0, merged: 1, closed: 2}.freeze

        # Send one mutating `gh` command. When `ambiguous` is true (create),
        # any transport-level failure is reported as an unknown outcome: the
        # request may have mutated the forge, so callers must reconcile by
        # exact identity instead of retrying blindly.
        def send_mutation(args, ambiguous:, identity: nil)
          result = CliExecutor.execute(args.first, args[1..] || [], timeout: timeout, runner: runner)
          return result if result[:success]

          classify_failure(result[:stderr], context: args.join(" "))
          result
        rescue Ace::Git::ProviderUnreachableError => e
          raise e unless ambiguous

          raise Ace::Git::ProviderUnknownOutcomeError,
            "PR create outcome unknown after transport failure (#{e.message}); " \
            "reconcile by exact identity before repeating: #{identity}"
        end

        # Exact base/head identity text for reconciliation contexts.
        def identity_text(head_repository_url, head_ref, base_ref)
          "#{head_repository_url}@#{head_ref} -> #{server.url}@#{base_ref}"
        end

        # Refuse when the live head differs from the caller's expected head.
        def verify_head!(pr, expected_head)
          unless pr.head_sha.is_a?(String) && !pr.head_sha.empty?
            raise Ace::Git::ProviderMalformedOutputError,
              "Provider evidence for PR ##{pr.number} is missing the exact head SHA"
          end
          return pr if pr.head_sha == expected_head

          raise Ace::Git::ProviderExpectedHeadConflictError,
            "PR ##{pr.number} head changed: expected #{expected_head}, found #{pr.head_sha}"
        end

        # `gh` head selector: "user:branch" for fork sources, plain ref for
        # the base repository. The owner comes from the declared URL only.
        def gh_head_arg(head_ref, head_repository_url)
          return head_ref if head_repository_url.nil? ||
            Ace::Git::Atoms::ServerUrl.match?(head_repository_url, server.url)

          path = Ace::Git::Atoms::ServerUrl.normalize(head_repository_url).split("/", 2)[1]
          owner = path.to_s.split("/").first
          raise ArgumentError, "Cannot derive fork owner from #{head_repository_url}" if owner.nil? || owner.empty?

          "#{owner}:#{head_ref}"
        end

        def require_base_on_server!(base_repository_url)
          return if Ace::Git::Atoms::ServerUrl.match?(base_repository_url, server.url)

          raise Ace::Git::ProviderUnsupportedCapabilityError,
            "GitHub provider operates on the resolved server repository (#{server.url}); " \
            "refusing base repository #{base_repository_url}"
        end

        def receipt(operation, pull_request, idempotency)
          Ace::Git::ProviderMutationReceipt.new(
            server_name: server.name, operation: operation,
            pull_request: pull_request, idempotency: idempotency
          )
        end

        # Run a `gh` command expecting JSON output; classify all failures.
        def gh_json(args)
          result = CliExecutor.execute(args.first, args[1..] || [], timeout: timeout, runner: runner)
          unless result[:success]
            classify_failure(result[:stderr], context: args.join(" "))
          end

          begin
            JSON.parse(result[:stdout])
          rescue JSON::ParserError => e
            raise Ace::Git::ProviderMalformedOutputError,
              "Malformed JSON from gh (#{args.join(" ")}): #{e.message}"
          end
        end

        def normalize_pr(data, server_name)
          Ace::Git::ProviderPullRequest.new(
            server_name: server_name,
            number: data["number"],
            title: data["title"],
            state: STATE_MAP.fetch(data["state"].to_s.upcase, data["state"].to_s.downcase.to_sym),
            head_ref: data["headRefName"],
            base_ref: data["baseRefName"],
            head_sha: data["headRefOid"],
            author: normalize_author(data["author"]),
            url: data["url"],
            draft: data["isDraft"],
            merged_at: merged_at_of(data),
            head_repository_url: head_repository_url_of(data),
            base_repository_url: server.url,
            merge_commit_sha: data.dig("mergeCommit", "oid")
          )
        end

        # Source repository URL for the PR head: the fork's owner/name against
        # the server host for cross-repository PRs, the configured repository
        # otherwise. Never inferred beyond what `gh` reported.
        def head_repository_url_of(data)
          owner = data.dig("headRepositoryOwner", "login")
          name = data.dig("headRepository", "name")
          return server.url if owner.nil? || name.nil?

          "#{server_host_root}/#{owner}/#{name}"
        end

        def server_host_root
          @server_host_root ||= begin
            uri = URI.parse(server.url.to_s)
            "#{uri.scheme || "https"}://#{uri.host}#{":#{uri.port}" if uri.port && uri.port != uri.default_port}"
          end
        end

        def merged_at_of(data)
          data["mergedAt"]
        end

        def normalize_author(author)
          return author["login"] if author.is_a?(Hash)

          author
        end

        def normalize_issue(data)
          Ace::Git::ProviderIssue.new(
            server_name: server.name,
            number: data["number"],
            title: data["title"],
            state: data["state"].to_s.upcase == "OPEN" ? :open : :closed,
            author: normalize_author(data["author"]),
            url: data["url"],
            labels: nil
          )
        end

        def classify_failure(stderr, context:)
          message = stderr.to_s
          if message.match?(PrFetcher::PR_NOT_FOUND_PATTERN)
            raise Ace::Git::ProviderObjectNotFoundError, "Object not found: #{context}: #{message}"
          elsif message.match?(PrFetcher::AUTH_ERROR_PATTERN)
            raise Ace::Git::ProviderAuthenticationError, "Not authenticated with GitHub: #{message}"
          elsif message.match?(/match[- ]head[- ]commit|head commit/i)
            raise Ace::Git::ProviderExpectedHeadConflictError,
              "GitHub refused the merge: pull request head does not match --match-head-commit (#{context}): #{message}"
          else
            raise Ace::Git::ProviderUnreachableError, "GitHub request failed (#{context}): #{message}"
          end
        end
      end
    end
  end
end
