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
          # Issue operations talk to the HTTPS web endpoint derived from the
          # configured URL; a plain normalize would carry an SSH-style
          # host:port into gh --hostname/--repo.
          @repo_target ||= Ace::Git::Atoms::ServerUrl.normalize(
            Ace::Git::Atoms::ServerUrl.web_base(server.url)
          )
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

        def issue_tracking(number:)
          data = gh_json(["issue", "view", number.to_s, "--json", "number,title,state,author,url,labels"])
          evidence = normalize_issue(data)
          unless evidence.number.to_i == number.to_i && url_matches_server?(evidence.url, number)
            raise Ace::Git::ProviderIdentityMismatchError, "Issue ##{number} is not in #{server.url}"
          end
          uri = URI.parse(Ace::Git::Atoms::ServerUrl.web_base(server.url))
          owner_repo = uri.path.sub(%r{\A/}, "").chomp("/").sub(/\.git\z/, "")
          pages = gh_json(["api", "repos/#{owner_repo}/issues/#{number}/comments", "--hostname", forge_hostname(uri),
                           "--paginate", "--slurp"], bind_repo: false)
            unless pages.is_a?(Array) && pages.all? { |page| page.is_a?(Array) }
              raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub comment pagination for issue ##{number}"
            end
            {
            issue: evidence,
            comments: pages.flatten.map do |comment|
              id = comment["id"]
              raise Ace::Git::ProviderMalformedOutputError, "Issue comment has no API id" unless id.to_s.match?(/\A\d+\z/)

              {id: id.to_i, body: comment["body"].to_s}
            end,
            labels: Array(data["labels"]).map { |label| label["name"].to_s }
          }
        end

        def create_issue_comment(number:, body:)
          issue_api("POST", "issues/#{number}/comments", fields: ["body=#{body}"])
        end

        def update_issue_comment(number:, comment_id:, body:)
          assert_issue_comment_owned!(number, comment_id)
          issue_api("PATCH", "issues/comments/#{Integer(comment_id)}", fields: ["body=#{body}"])
        end

        def delete_issue_comment(number:, comment_id:)
          assert_issue_comment_owned!(number, comment_id)
          issue_api("DELETE", "issues/comments/#{Integer(comment_id)}")
        end

        def add_issue_label(number:, label:)
          issue_api("POST", "issues/#{number}/labels", fields: ["labels[]=#{label}"])
        rescue Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderUnknownOutcomeError => e
          raise unless e.message.match?(/label/i) && e.message.match?(/does not exist|not found/i)

          # Fresh repositories lack the tracking label; create it on demand so
          # linking cannot commit a tracking comment it could never label
          # (mirrors the Forgejo provider), then attach exactly once.
          create_repo_label(label)
          issue_api("POST", "issues/#{number}/labels", fields: ["labels[]=#{label}"])
        end

        def remove_issue_label(number:, label:)
          issue_api("DELETE", "issues/#{number}/labels/#{URI.encode_www_form_component(label)}")
        end

        def set_issue_state(number:, state:)
          raise ArgumentError, "Invalid issue state #{state.inspect}" unless %i[open closed].include?(state)

          issue_api("PATCH", "issues/#{number}", fields: ["state=#{state}"])
        end

        # A concurrent creator produces GitHub's already_exists error, which
        # is exactly the ensured state; any other failure keeps its
        # classification.
        def create_repo_label(label)
          issue_api("POST", "labels", fields: ["name=#{label}", "color=0e8a16"])
        rescue Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderUnknownOutcomeError => e
          raise unless e.message.match?(/already[_ ]exists/i)
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

        def assert_issue_comment_owned!(number, comment_id)
          return if issue_tracking(number: number)[:comments].any? { |comment| comment[:id].to_i == comment_id.to_i }

          raise Ace::Git::ProviderIdentityMismatchError,
            "Comment #{comment_id} is not on selected issue ##{number} in #{server.url}"
        end

        def issue_api(method, suffix, fields: [])
          uri = URI.parse(Ace::Git::Atoms::ServerUrl.web_base(server.url))
          owner_repo = uri.path.sub(%r{\A/}, "").chomp("/").sub(/\.git\z/, "")
          args = ["repos/#{owner_repo}/#{suffix}", "--hostname", forge_hostname(uri), "--method", method]
          fields.each { |field| args += ["--raw-field", field] }
          result = CliExecutor.execute("api", args, timeout: timeout, runner: runner)
          classify_failure(result[:stderr], context: "issue #{method} #{suffix}") unless result[:success]
          result
        rescue Ace::Git::ProviderUnreachableError => e
          raise Ace::Git::ProviderUnknownOutcomeError,
            "Unknown outcome for issue mutation on #{server.url} (#{suffix}): #{e.message}"
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
            "#{uri.scheme || "https"}://#{forge_hostname(uri)}"
          end
        end

        # gh --hostname accepts "host:port"; a bare uri.host would silently
        # retarget a port-configured server to the default authority.
        # Issue evidence must match the configured server URL including its
        # scheme; ServerUrl.match? intentionally ignores schemes for git
        # remotes, but a web issue URL must not downgrade the authority.
        def url_matches_server?(evidence_url, number)
          expected = "#{Ace::Git::Atoms::ServerUrl.web_base(server.url)}/issues/#{number.to_i}"
          return false unless evidence_url.to_s.chomp("/").casecmp?(expected)

          configured = URI.parse(Ace::Git::Atoms::ServerUrl.web_base(server.url)).scheme
          supplied = URI.parse(evidence_url.to_s).scheme
          configured.nil? || supplied.nil? || configured.downcase == supplied.downcase
        end

        # Unrecognized or missing state is malformed evidence: mapping it to
        # :closed would let sync close an issue without valid state proof.
        def normalize_state(value)
          case value.to_s.upcase
          when "OPEN" then :open
          when "CLOSED" then :closed
          else raise Ace::Git::ProviderMalformedOutputError, "Unknown issue state #{value.inspect}"
          end
        end

        def forge_hostname(uri)
          uri.port && uri.port != uri.default_port ? "#{uri.host}:#{uri.port}" : uri.host
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
            state: normalize_state(data["state"]),
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
