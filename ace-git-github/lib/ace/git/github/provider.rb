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

        # @return [String] HOST/OWNER/REPO for the resolved server; appended
        #   to every data/mutation command so a `--server` selection can never
        #   be silently retargeted to the checkout's repository.
        def repo_target
          @repo_target ||= Ace::Git::Atoms::ServerUrl.normalize(server.url)
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
          result = PrFetcher.fetch_diff(number.to_s, timeout: timeout, runner: runner, repo: repo_target)
          result[:diff]
        end

        # @return [Array<ProviderPullRequest>] recent PRs, newest first
        def recent_pull_requests(limit:)
          result = PrFetcher.fetch_all_prs(limit: limit, timeout: timeout, runner: runner, repo: repo_target)
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
          # `gh repo view` rejects `--repo`; the repository is positional.
          output = gh_json(["repo", "view", repo_target, "--json", REPO_FIELDS], bind_repo: false)
          Ace::Git::ProviderRepository.new(
            server_name: server.name,
            full_name: output["nameWithOwner"],
            default_branch: output.dig("defaultBranchRef", "name"),
            url: output["url"]
          )
        end

        def pull_request_review_evidence(number:, expected_head:)
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          comments = gh_api_pages("issues/#{pr.number}/comments").map do |entry|
            review_comment(entry, pr, expected_head)
          end
          inline = gh_api_pages("pulls/#{pr.number}/comments").map do |entry|
            review_comment(entry, pr, expected_head)
          end
          reviews = gh_api_pages("pulls/#{pr.number}/reviews").map do |entry|
            review_entry(entry, pr, expected_head)
          end
          verify_expected_head!(pull_request(number: pr.number), expected_head)
          Ace::Git::ProviderReviewEvidence.new(
            server_name: server.name, repository_url: server.url,
            pr_number: pr.number, head_sha: expected_head,
            comments: comments + inline, reviews: reviews
          )
        end

        def pull_request_review_details(number:)
          number = Integer(number)
          data = gh_api("pulls/#{number}")
          files = gh_api_pages("pulls/#{number}/files").map do |entry|
            entry.is_a?(Hash) && entry["filename"]
          end
          unless data.is_a?(Hash) && data["number"] == number &&
              data.dig("base", "sha").to_s.match?(/\A[0-9a-f]{40}\z/) &&
              data["changed_files"].is_a?(Integer) && data["changed_files"] == files.length &&
              files.all? { |path| path.is_a?(String) && !path.empty? }
            raise Ace::Git::ProviderMalformedOutputError, "Malformed or incomplete GitHub PR file evidence"
          end
          Ace::Git::ProviderReviewDetails.new(
            server_name: server.name, repository_url: server.url, pr_number: number,
            base_sha: data.dig("base", "sha"), files: files
          )
        end

        def pull_request_checks(number:, head_sha:)
          verify_expected_head!(pull_request(number: number), head_sha)
          data = gh_api("commits/#{head_sha}/check-runs?per_page=100")
          runs = data.is_a?(Hash) && data["check_runs"]
          unless runs.is_a?(Array) && runs.all? { |run| run.is_a?(Hash) && run["name"].is_a?(String) }
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR check evidence"
          end
          runs.map do |run|
            Ace::Git::ProviderCheck.new(
              server_name: server.name, name: run["name"],
              state: run["status"].to_s.downcase.to_sym,
              conclusion: run["conclusion"]&.downcase&.to_sym,
              url: run["html_url"]
            )
          end
        end

        def repository_file(path:, ref:)
          require "base64"
          escaped = path.split("/").map { |part| URI.encode_www_form_component(part) }.join("/")
          data = gh_api("contents/#{escaped}?ref=#{ref}")
          unless data.is_a?(Hash) && data["encoding"] == "base64" && data["content"].is_a?(String)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub repository file evidence"
          end
          Base64.strict_decode64(data["content"].delete("\n"))
        rescue ArgumentError => e
          raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub repository file content: #{e.message}"
        end

        def create_pull_request_comment(number:, expected_head:, body:, correlation:)
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          require_open_pr!(pr)
          marker = comment_marker(correlation)
          existing = matching_review_comments(pr, marker, expected_head)
          if existing.length > 1
            raise Ace::Git::ProviderConflictingMatchesError,
              "Multiple comments match review session #{correlation} on PR ##{pr.number}"
          end
          return review_mutation(pr, expected_head, existing.first, :existing) if existing.one?

          verify_expected_head!(pull_request(number: pr.number), expected_head)
          begin
            gh_api("issues/#{pr.number}/comments", method: :post, body: "#{body}\n\n#{marker}")
          rescue Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment outcome unknown for #{server.name}/#{pr.number}, head #{expected_head}, " \
              "session #{correlation}: #{e.message}; reconcile before repeating"
          end
          matches = matching_review_comments(pr, marker, expected_head)
          unless matches.one?
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment sent but reconciliation found #{matches.length} matches for session #{correlation}"
          end
          review_mutation(pr, expected_head, matches.first, :created)
        end

        def update_pull_request_comment(number:, expected_head:, comment_id:, body:)
          comment_id = Integer(comment_id)
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          matches = gh_api_pages("issues/#{pr.number}/comments").select { |entry| entry["id"] == comment_id }
          unless matches.one?
            raise Ace::Git::ProviderIdentityMismatchError,
              "Comment #{comment_id} does not belong to selected PR ##{pr.number}"
          end
          comment = review_comment(matches.first, pr, expected_head)
          return review_mutation(pr, expected_head, comment, :existing) if comment.body == body

          verify_expected_head!(pull_request(number: number), expected_head)
          begin
            gh_api("issues/comments/#{comment_id}", method: :patch, body: body)
          rescue Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update outcome unknown for #{server.name}/#{pr.number}, " \
              "head #{expected_head}, comment #{comment_id}: #{e.message}"
          end
          updated = gh_api_pages("issues/#{pr.number}/comments").find { |entry| entry["id"] == comment_id }
          unless updated && updated["body"] == body
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update sent but exact PR comment #{comment_id} could not be verified"
          end
          review_mutation(pr, expected_head, review_comment(updated, pr, expected_head), :updated)
        end

        def resolve_pull_request_thread(number:, expected_head:, thread_id:)
          unless thread_id.to_s.match?(/\APRRT_[A-Za-z0-9_=-]+\z/)
            raise Ace::Git::ConfigError, "Invalid GitHub review thread ID"
          end
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          query = <<~GRAPHQL
            query($id: ID!) {
              node(id: $id) {
                ... on PullRequestReviewThread {
                  id isResolved
                  pullRequest { number headRefOid repository { url } }
                }
              }
            }
          GRAPHQL
          thread = gh_graphql(query, id: thread_id).dig("data", "node")
          verify_review_thread!(thread, pr, expected_head)
          return true if thread["isResolved"] == true

          verify_expected_head!(pull_request(number: number), expected_head)
          mutation = <<~GRAPHQL
            mutation($id: ID!) {
              resolveReviewThread(input: {threadId: $id}) {
                thread { id isResolved pullRequest { number headRefOid repository { url } } }
              }
            }
          GRAPHQL
          begin
            resolved = gh_graphql(mutation, id: thread_id).dig("data", "resolveReviewThread", "thread")
          rescue Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Thread resolution outcome unknown for #{server.name}/#{pr.number}, " \
              "head #{expected_head}, thread #{thread_id}: #{e.message}"
          end
          verify_review_thread!(resolved, pr, expected_head)
          unless resolved["isResolved"] == true
            raise Ace::Git::ProviderMalformedOutputError, "GitHub did not confirm thread resolution"
          end
          true
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

        def require_open_pr!(pr)
          return if pr.state == :open

          raise Ace::Git::ProviderUnsupportedCapabilityError,
            "Cannot post review comment to PR ##{pr.number} in #{pr.state} state"
        end

        def verify_review_thread!(thread, pr, expected_head)
          unless thread.is_a?(Hash) && thread["id"] && thread["pullRequest"].is_a?(Hash) &&
              thread.dig("pullRequest", "number") == pr.number &&
              Ace::Git::Atoms::ServerUrl.match?(thread.dig("pullRequest", "repository", "url"), server.url)
            raise Ace::Git::ProviderIdentityMismatchError,
              "GitHub review thread does not belong to selected PR ##{pr.number}"
          end
          unless thread.dig("pullRequest", "headRefOid") == expected_head
            raise Ace::Git::ProviderExpectedHeadConflictError,
              "GitHub review thread PR head changed before resolution"
          end
        end

        def gh_graphql(query, id:)
          host = Ace::Git::Atoms::ServerUrl.normalize(server.url).split("/", 2).first
          args = ["graphql", "-f", "query=#{query}", "-F", "id=#{id}", "--hostname", host]
          result = CliExecutor.execute("api", args, timeout: timeout, runner: runner)
          classify_failure(result[:stderr], context: "api graphql") unless result[:success]
          data = JSON.parse(result[:stdout])
          if data.is_a?(Hash) && data["errors"].is_a?(Array) && data["errors"].any?
            raise Ace::Git::ProviderUnreachableError,
              "GitHub GraphQL rejected review operation: #{data["errors"].first["message"]}"
          end
          unless data.is_a?(Hash) && data["data"].is_a?(Hash)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub GraphQL response"
          end
          data
        rescue JSON::ParserError => e
          raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub GraphQL JSON: #{e.message}"
        end

        def comment_marker(correlation)
          unless correlation.to_s.match?(/\A[a-zA-Z0-9._:-]+\z/)
            raise Ace::Git::ConfigError, "Invalid review session correlation"
          end
          "<!-- ace-review-session:#{correlation} -->"
        end

        def matching_review_comments(pr, marker, head)
          gh_api_pages("issues/#{pr.number}/comments").filter_map do |entry|
            next unless entry.is_a?(Hash) && entry["body"].is_a?(String) && entry["body"].include?(marker)

            review_comment(entry, pr, head)
          end
        end

        def review_comment(entry, pr, head)
          unless entry.is_a?(Hash) && entry["id"] && entry["body"].is_a?(String) &&
              entry.dig("user", "login").is_a?(String)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR comment evidence"
          end
          Ace::Git::ProviderReviewComment.new(
            server_name: server.name, repository_url: server.url, pr_number: pr.number,
            id: entry["id"], author: entry.dig("user", "login"), body: entry["body"],
            url: entry["html_url"], path: entry["path"], line: entry["line"],
            head_sha: entry["commit_id"] || head, resolved: nil, thread_id: nil
          )
        end

        def review_entry(entry, pr, head)
          unless entry.is_a?(Hash) && entry["id"] && entry.dig("user", "login").is_a?(String)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR review evidence"
          end
          Ace::Git::ProviderReview.new(
            server_name: server.name, repository_url: server.url, pr_number: pr.number,
            id: entry["id"], author: entry.dig("user", "login"), body: entry["body"],
            state: entry["state"], url: entry["html_url"], head_sha: entry["commit_id"] || head
          )
        end

        def review_mutation(pr, head, comment, idempotency)
          Ace::Git::ProviderReviewMutation.new(
            server_name: server.name, repository_url: server.url, pr_number: pr.number,
            head_sha: head, comment: comment, idempotency: idempotency
          )
        end

        def gh_api_pages(suffix)
          data = gh_api(suffix, paginate: true)
          pages = data.is_a?(Array) ? data : nil
          unless pages && pages.all? { |page| page.is_a?(Array) }
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR collection"
          end
          pages.flatten(1)
        end

        def gh_api(suffix, method: :get, body: nil, paginate: false)
          target = Ace::Git::Atoms::ServerUrl.normalize(server.url)
          host, repository = target.split("/", 2)
          unless repository&.match?(%r{\A[^/]+/[^/]+\z})
            raise Ace::Git::ConfigError, "Invalid selected GitHub repository #{server.url}"
          end
          args = ["repos/#{repository}/#{suffix}", "--hostname", host]
          args += ["--paginate", "--slurp"] if paginate
          args += ["-X", method.to_s.upcase, "-f", "body=#{body}"] if %i[post patch].include?(method)
          result = CliExecutor.execute("api", args, timeout: timeout, runner: runner)
          classify_failure(result[:stderr], context: "api #{suffix}") unless result[:success]
          JSON.parse(result[:stdout])
        rescue JSON::ParserError => e
          raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub API JSON: #{e.message}"
        end

        STATE_ORDER = {open: 0, merged: 1, closed: 2}.freeze

        # Send one mutating `gh` command. When `ambiguous` is true (create),
        # any transport-level failure is reported as an unknown outcome: the
        # request may have mutated the forge, so callers must reconcile by
        # exact identity instead of retrying blindly.
        def send_mutation(args, ambiguous:, identity: nil)
          result = CliExecutor.execute(args.first, (args[1..] || []) + ["--repo", repo_target], timeout: timeout, runner: runner)
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

        # Refuse when the live head differs from the caller's expected head
        # (shared guard from Providers::Base).
        def verify_head!(pr, expected_head)
          verify_expected_head!(pr, expected_head)
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
        # Every command is bound to the resolved server repository via
        # `--repo`, except commands that take the repository positionally.
        def gh_json(args, bind_repo: true)
          argv = args[1..] || []
          argv += ["--repo", repo_target] if bind_repo
          result = CliExecutor.execute(args.first, argv, timeout: timeout, runner: runner)
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
