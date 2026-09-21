# frozen_string_literal: true

require "json"

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

        PR_FIELDS = "number,state,isDraft,title,author,headRefName,baseRefName,url,headRefOid,mergeCommit,mergedAt"
        LIST_FIELDS = PrFetcher::LIST_FIELDS
        REPO_FIELDS = "nameWithOwner,defaultBranchRef,url"
        ISSUE_FIELDS = "number,title,state,author,url"

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

        private

        STATE_ORDER = {open: 0, merged: 1, closed: 2}.freeze

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
            merged_at: merged_at_of(data)
          )
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
          else
            raise Ace::Git::ProviderUnreachableError, "GitHub request failed (#{context}): #{message}"
          end
        end
      end
    end
  end
end
