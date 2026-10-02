# frozen_string_literal: true

require "digest"
require "open3"
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

        PR_FIELDS = "number,state,isDraft,title,body,author,headRefName,baseRefName,url,headRefOid,mergeCommit,mergedAt,headRepositoryOwner,headRepository"
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
          return result[:diff] if result[:success]
          # API size-limit rejections (HTTP 406) fall back to a local git
          # diff at the exact reviewed head, never an approximation.
          raise Ace::Git::ProviderObjectNotFoundError, "gh pr diff failed: #{result[:error]}" if result[:error].to_s.match?(PrFetcher::PR_NOT_FOUND_PATTERN)
          raise Ace::Git::ProviderAuthenticationError, result[:error].to_s if result[:error].to_s.match?(PrFetcher::AUTH_ERROR_PATTERN)
          if result[:error].to_s.match?(/\bHTTP 406\b|Not Acceptable|exceeded the maximum/)
            return local_diff_fallback(number)
          end
          raise Ace::Git::ProviderUnreachableError, "gh pr diff failed: #{result[:error]}"
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
        end

        def remove_issue_label(number:, label:)
          issue_api("DELETE", "issues/#{number}/labels/#{URI.encode_www_form_component(label)}")
        end

        def set_issue_state(number:, state:)
          raise ArgumentError, "Invalid issue state #{state.inspect}" unless %i[open closed].include?(state)

          issue_api("PATCH", "issues/#{number}", fields: ["state=#{state}"])
        end

        # @return [Array<ProviderCheck>] normalized check evidence for a ref
        def checks(ref:)
          output = gh_json(["pr", "checks", ref.to_s, "--json", "name,state,bucket"])
          output.map do |check|
            state = check["state"].to_s.downcase
            raise Ace::Git::ProviderMalformedOutputError,
              "Malformed GitHub check entry: missing state" if state.empty?
            bucket = check["bucket"].to_s.downcase
            unless bucket.empty? || BUCKET_MAP.key?(bucket)
              raise Ace::Git::ProviderMalformedOutputError,
                "Malformed GitHub check entry: unrecognized bucket #{bucket}"
            end
            Ace::Git::ProviderCheck.new(
              server_name: server.name,
              name: check["name"].to_s,
              state: state.to_sym,
              conclusion: BUCKET_MAP.fetch(bucket, nil),
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

def pull_request_body(number:)
  pull_request(number: number).body
end

        def pull_request_review_evidence(number:, expected_head:)
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          threads = review_thread_index(pr)
          comments = gh_api_pages("issues/#{pr.number}/comments").map do |entry|
            review_comment(entry, pr, expected_head, threads)
          end
          inline = gh_api_pages("pulls/#{pr.number}/comments").map do |entry|
            review_comment(entry, pr, expected_head, threads)
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

        # Map REST comment database ids to their review thread (GraphQL id,
        # resolution state). A truncated thread listing would silently
        # understate resolution evidence, so pagination limits fail closed.
def review_thread_index(pr)
  host, repository = Ace::Git::Atoms::ServerUrl.normalize(server.url).split("/", 2)
  owner, name = repository.to_s.split("/", 2)
  unless owner && name
    raise Ace::Git::ConfigError, "Invalid selected GitHub repository #{server.url}"
  end
  threads = []
  cursor = nil
  seen_thread_pages = {}
  seen_thread_ids = {}
  total_count = nil
  loop do
    query = <<~GRAPHQL
      query($id: Int!, $cursor: String) {
        repository(owner: "#{owner}", name: "#{name}") {
          pullRequest(number: $id) {
            reviewThreads(first: 100, after: $cursor) {
              totalCount
              pageInfo { hasNextPage endCursor }
              nodes {
                id
                isResolved
                comments(first: 100) {
                  pageInfo { hasNextPage endCursor }
                  nodes { databaseId }
                }
              }
            }
          }
        }
      }
    GRAPHQL
    pull_request_node = gh_graphql(query, id: pr.number, cursor: cursor).dig("data", "repository", "pullRequest")
    threads_page = pull_request_node.is_a?(Hash) && pull_request_node["reviewThreads"]
    unless threads_page.is_a?(Hash) && threads_page["totalCount"].is_a?(Integer) &&
        threads_page["pageInfo"].is_a?(Hash) && threads_page["nodes"].is_a?(Array)
      raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub review thread evidence"
    end
    if total_count && total_count != threads_page["totalCount"]
      raise Ace::Git::ProviderMalformedOutputError, "Inconsistent GitHub review thread total"
    end
    total_count = threads_page["totalCount"]
    threads.concat(threads_page["nodes"])
    page_digest = Digest::SHA256.hexdigest(threads_page["nodes"].to_s)
    raise Ace::Git::ProviderMalformedOutputError,
      "GitHub review thread pagination repeated a page" if seen_thread_pages[page_digest]

    seen_thread_pages[page_digest] = true
    break unless threads_page["pageInfo"]["hasNextPage"] == true
    cursor = threads_page["pageInfo"]["endCursor"]
    raise Ace::Git::ProviderMalformedOutputError,
      "Incomplete GitHub review thread evidence" unless cursor.is_a?(String)
  end
  if total_count != threads.length
    raise Ace::Git::ProviderMalformedOutputError, "Incomplete GitHub review thread evidence"
  end
  threads.each do |thread|
    next unless thread.is_a?(Hash)
    if seen_thread_ids[thread["id"]]
      raise Ace::Git::ProviderMalformedOutputError, "Duplicate GitHub review thread id"
    end
    seen_thread_ids[thread["id"]] = true
  end
  index = {}
  threads.each do |thread|
    page_info = thread.is_a?(Hash) && thread["comments"].is_a?(Hash) && thread["comments"]["pageInfo"]
    unless thread.is_a?(Hash) && thread["id"].is_a?(String) &&
        [true, false].include?(thread["isResolved"]) &&
        thread["comments"].is_a?(Hash) && thread["comments"]["nodes"].is_a?(Array) &&
        page_info.is_a?(Hash) && [true, false].include?(page_info["hasNextPage"])
      raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub review thread evidence"
    end
    resolved = thread["isResolved"]
    thread_comment_ids(thread["id"], thread["comments"]).each do |database_id|
      index[database_id] = [thread["id"], resolved]
    end
  end
  index
end

# A thread's comment list may itself be paginated; follow its cursor
# so resolution state covers every comment in the thread.
        def thread_comment_ids(thread_id, first_page)
          cursor = nil
          ids = []
          seen_cursors = {}
          comments_page = first_page
          loop do
            unless comments_page.is_a?(Hash) && comments_page["pageInfo"].is_a?(Hash) &&
                [true, false].include?(comments_page["pageInfo"]["hasNextPage"]) &&
                comments_page["nodes"].is_a?(Array)
              raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub review thread evidence"
            end
            comments_page["nodes"].each do |comment|
              unless comment.is_a?(Hash) && comment["databaseId"].is_a?(Integer)
                raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub review thread evidence"
              end
              ids << comment["databaseId"]
            end
            break unless comments_page["pageInfo"]["hasNextPage"] == true
            cursor = comments_page["pageInfo"]["endCursor"]
            raise Ace::Git::ProviderMalformedOutputError,
              "Incomplete GitHub review thread evidence" unless cursor.is_a?(String)
            raise Ace::Git::ProviderMalformedOutputError,
              "GitHub review thread comment pagination repeated a cursor" if seen_cursors[cursor]

            seen_cursors[cursor] = true

            query = <<~GRAPHQL
              query($id: ID!, $cursor: String) {
                node(id: $id) {
                  ... on PullRequestReviewThread {
                    comments(first: 100, after: $cursor) {
                      pageInfo { hasNextPage endCursor }
                      nodes { databaseId }
                    }
                  }
                }
              }
            GRAPHQL
            node = gh_graphql(query, id: thread_id, cursor: cursor).dig("data", "node")
            comments_page = node.is_a?(Hash) ? node["comments"] : nil
          end
  ids
end

        def pull_request_review_details(number:)
          number = Integer(number)
          data = gh_api("pulls/#{number}")
          files = gh_api_pages("pulls/#{number}/files").map do |entry|
            entry.is_a?(Hash) && entry["filename"]
          end
          unless data.is_a?(Hash) && data["base"].is_a?(Hash) && data["number"] == number &&
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
          pages = gh_api("commits/#{head_sha}/check-runs?per_page=100", paginate: true)
          # --paginate --slurp returns one payload per page; a single-page
          # response stays a bare object.
          page_payloads = pages.is_a?(Array) ? pages : [pages]
          unless page_payloads.is_a?(Array) && page_payloads.all? { |page| page.is_a?(Hash) && page["check_runs"].is_a?(Array) }
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR check evidence"
          end
          runs = page_payloads.flat_map { |page| page["check_runs"] }
          unless runs.all? { |run| run.is_a?(Hash) && run["name"].is_a?(String) }
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR check evidence"
          end
          total = page_payloads.filter_map { |page| page["total_count"] }.last
          # The accumulated pages must account for every reported run; a
          # shortfall would silently understate check evidence. GitHub
      # caps the check-runs endpoint at the 1,000 most recent check
      # suites, so a maxed-out page cannot be exhausted further and the
      # snapshot is marked incomplete instead.
          if total.is_a?(Integer) && total > runs.length && runs.length >= 1000
            raise Ace::Git::ProviderMalformedOutputError,
              "Incomplete GitHub PR check evidence: endpoint capped at the 1,000 most recent check suites"
          end
          unless total.is_a?(Integer) && total <= runs.length
            raise Ace::Git::ProviderMalformedOutputError, "Incomplete GitHub PR check evidence"
          end
          checks = runs.map do |run|
            status = run["status"].to_s.downcase
            raise Ace::Git::ProviderMalformedOutputError,
              "Malformed GitHub check run entry: missing status" if status.empty?
            conclusion = run["conclusion"]
            unless conclusion.nil? || conclusion.is_a?(String)
              raise Ace::Git::ProviderMalformedOutputError,
                "Malformed GitHub check run entry: conclusion must be a string or null"
            end
            Ace::Git::ProviderCheck.new(
              server_name: server.name, name: run["name"],
              state: status.to_sym,
              conclusion: conclusion&.downcase&.to_sym,
              url: run["html_url"]
            )
          end
          checks + commit_statuses(head_sha)
        end

        # Combined commit statuses are a separate GitHub evidence stream from
        # check runs; both must appear or the snapshot overstates success.
        def commit_statuses(head_sha)
          data = gh_api("commits/#{head_sha}/status")
          statuses = data.is_a?(Hash) && data["statuses"]
          unless statuses.is_a?(Array) && statuses.all? { |s| s.is_a?(Hash) && s["context"].is_a?(String) }
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub commit status evidence"
          end
          total = data["total_count"]
          unless total.is_a?(Integer)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub commit status evidence"
          end
          # The combined view can cap its inline statuses array; the
          # paginated statuses endpoint is the complete stream.
          if total > statuses.length
            statuses = gh_api("commits/#{head_sha}/statuses?per_page=100", paginate: true)
            statuses = statuses.is_a?(Array) ? statuses.flat_map { |page| page.is_a?(Array) ? page : [page] } : [statuses]
            unless statuses.all? { |st| st.is_a?(Hash) && st["context"].is_a?(String) }
              raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub commit status evidence"
            end
            # The statuses stream is reverse-chronological with one entry
            # per state change; the combined total counts distinct
            # contexts. Keep the first (latest) entry per context.
            statuses = statuses.uniq { |st| st["context"] }
          end
          unless statuses.length == total
            raise Ace::Git::ProviderMalformedOutputError, "Incomplete GitHub commit status evidence"
          end
          statuses.map do |status|
            Ace::Git::ProviderCheck.new(
              server_name: server.name, name: status["context"],
              state: status["state"].to_s.downcase.to_sym,
              conclusion: nil,
              url: status["target_url"]
            )
          end
        end

        def repository_file(path:, ref:)
          require "base64"
          # %20, not form encoding: "+" in a path segment is a literal plus.
          # Explicit unreserved-character allowlist: percent-encode
          # everything else (DEFAULT_PARSER leaves ? and + ambiguous).
          escaped = path.split("/").map { |part|
            part.gsub(/[^A-Za-z0-9._~!$&'()*+,;=@:-]/) { |c| c.bytes.map { |b| format("%%%02X", b) }.join }
          }.join("/")
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
          with_session_lock(correlation) do
          existing = matching_review_comments(pr, marker, expected_head)
          if existing.length > 1
            raise Ace::Git::ProviderConflictingMatchesError,
              "Multiple comments match review session #{correlation} on PR ##{pr.number}"
          end
          if existing.one?
            # A repeat reconciles only the exact session comment; a marker
            # match with different content is a conflict, never our post.
            sent = "#{body}\n\n#{marker}"
            if existing.first.body == sent
              verify_post_mutation_head!(pr, expected_head, correlation)
              return review_mutation(pr, expected_head, existing.first, :existing)
            end

            raise Ace::Git::ProviderConflictingMatchesError,
              "Review session #{correlation} comment exists on PR ##{pr.number} with different content"
          end

          second = verify_expected_head!(pull_request(number: pr.number), expected_head)
          require_open_pr!(second)
          begin
            gh_api("issues/#{pr.number}/comments", method: :post, body: "#{body}\n\n#{marker}")
          rescue Ace::Git::ProviderMalformedOutputError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment sent but response unreadable for #{server.name}/#{pr.number}, head #{expected_head}, session #{correlation}: #{e.message}; reconcile before repeating"
          rescue Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment outcome unknown for #{server.name}/#{pr.number}, head #{expected_head}, " \
              "session #{correlation}: #{e.message}; reconcile before repeating"
          end
          begin
            matches = matching_review_comments(pr, marker, expected_head)
          rescue Ace::Git::ProviderMalformedOutputError, Ace::Git::ProviderAuthenticationError, Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment sent but reconciliation read failed for session #{correlation}: #{e.message}; reconcile before repeating"
          end
          unless matches.one? && matches.first.body == "#{body}\n\n#{marker}"
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment sent but reconciliation found #{matches.length} exact-content match(es) for session #{correlation}"
          end
          verify_post_mutation_head!(pr, expected_head, correlation)
          review_mutation(pr, expected_head, matches.first, :created)
          end
        end

        def update_pull_request_comment(number:, expected_head:, comment_id:, body:)
          comment_id = Integer(comment_id)
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          # Collected evidence includes issue and inline comments; the
          # update must locate the id in both and use the matching route.
          # Inline (review) comments take precedence: if an id exists in
          # both collections, editing must target the inline comment the
          # reviewer thread actually references.
          inline_matches = gh_api_pages("pulls/#{pr.number}/comments").select { |entry| entry["id"] == comment_id }
          issue_matches = inline_matches.empty? ? gh_api_pages("issues/#{pr.number}/comments").select { |entry| entry["id"] == comment_id } : []
          matches = inline_matches + issue_matches
          update_route = inline_matches.any? ? "pulls/comments/#{comment_id}" : "issues/comments/#{comment_id}"
          unless matches.one?
            raise Ace::Git::ProviderIdentityMismatchError,
              "Comment #{comment_id} does not belong to selected PR ##{pr.number}"
          end
          comment = review_comment(matches.first, pr, expected_head)
          if comment.body == body
            verify_post_mutation_head!(pr, expected_head, "comment #{comment_id}")
            return review_mutation(pr, expected_head, comment, :existing)
          end

          verify_expected_head!(pull_request(number: number), expected_head)
          begin
            gh_api(update_route, method: :patch, body: body)
          rescue Ace::Git::ProviderMalformedOutputError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update sent but response unreadable for #{server.name}/#{pr.number}, comment #{comment_id}: #{e.message}; reconcile before repeating"
          rescue Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update outcome unknown for #{server.name}/#{pr.number}, " \
              "head #{expected_head}, comment #{comment_id}: #{e.message}"
          end
          begin
            # Fetch the edited comment individually (both patch routes are
            # valid GET item endpoints) and validate its PR identity.
            begin
              updated = gh_api(update_route)
            rescue Ace::Git::ProviderMalformedOutputError, Ace::Git::ProviderAuthenticationError, Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderUnreachableError => e
              raise Ace::Git::ProviderUnknownOutcomeError,
                "Comment update sent but verification read failed for comment #{comment_id}: #{e.message}; reconcile before repeating"
            end
            unless comment_belongs_to_pr?(updated, pr.number)
              raise Ace::Git::ProviderUnknownOutcomeError,
                "Comment update sent but edited comment #{comment_id} does not verify against PR ##{pr.number}; reconcile before repeating"
            end
          rescue Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update sent but verification read failed for comment #{comment_id}: #{e.message}; reconcile before repeating"
          end
          unless updated && updated["id"] == comment_id && updated["body"] == body
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update sent but exact PR comment #{comment_id} could not be verified"
          end
          verify_post_mutation_head!(pr, expected_head, "comment #{comment_id}")
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
          verify_review_thread!(thread, pr, expected_head, thread_id: thread_id)
          if thread["isResolved"] == true
            verify_post_mutation_head!(pr, expected_head, "thread #{thread_id}")
            return true
          end

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
            raise Ace::Git::ProviderMalformedOutputError, "Missing thread confirmation" unless resolved.is_a?(Hash)
          rescue Ace::Git::ProviderMalformedOutputError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Thread resolution sent but confirmation unreadable for #{server.name}/#{pr.number}, thread #{thread_id}: #{e.message}; reconcile before repeating"
          rescue Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Thread resolution outcome unknown for #{server.name}/#{pr.number}, " \
              "head #{expected_head}, thread #{thread_id}: #{e.message}"
          end
          begin
            verify_review_thread!(resolved, pr, expected_head, thread_id: thread_id)
          rescue Ace::Git::ProviderIdentityMismatchError, Ace::Git::ProviderMalformedOutputError, Ace::Git::ProviderExpectedHeadConflictError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Thread resolution sent but confirmation unreadable for #{server.name}/#{pr.number}, thread #{thread_id}: #{e.message}; reconcile before repeating"
          end
          unless resolved["isResolved"] == true
            # The resolution mutation may have landed; only its evidence
            # is unreadable. Reconcile via the thread id.
            raise Ace::Git::ProviderUnknownOutcomeError,
              "GitHub did not confirm thread resolution for #{server.name}/#{pr.number}, thread #{thread_id}; reconcile before repeating"
          end
          verify_post_mutation_head!(pr, expected_head, "thread #{thread_id}")
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

        def verify_review_thread!(thread, pr, expected_head, thread_id: nil)
          unless thread.is_a?(Hash) && thread["id"] && thread["pullRequest"].is_a?(Hash) &&
              thread.dig("pullRequest", "number") == pr.number &&
              Ace::Git::Atoms::ServerUrl.match?(thread.dig("pullRequest", "repository", "url"), server.url)
            raise Ace::Git::ProviderIdentityMismatchError,
              "GitHub review thread does not belong to selected PR ##{pr.number}"
          end
          if thread_id && thread["id"] != thread_id
            raise Ace::Git::ProviderIdentityMismatchError,
              "GitHub returned thread #{thread["id"]} instead of #{thread_id}"
          end
          unless thread.dig("pullRequest", "headRefOid") == expected_head
            raise Ace::Git::ProviderExpectedHeadConflictError,
              "GitHub review thread PR head changed before resolution"
          end
        end

        def gh_graphql(query, id:, cursor: nil)
          host = Ace::Git::Atoms::ServerUrl.normalize(server.url).split("/", 2).first
          args = ["graphql", "-f", "query=#{query}", "-F", "id=#{id}", "--hostname", host]
          args += ["-F", "cursor=#{cursor}"] if cursor
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

        # A mutation receipt may only bind the expected head; if the PR head
        # moved during the mutation the outcome stays uncertain.
        def verify_post_mutation_head!(pr, expected_head, correlation)
          current = begin
            pull_request(number: pr.number)
          rescue Ace::Git::ProviderMalformedOutputError, Ace::Git::ProviderAuthenticationError, Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Head verification read failed after mutation for #{server.name}: #{e.message}; reconcile before repeating"
          end
          return if current.head_sha == expected_head

          raise Ace::Git::ProviderUnknownOutcomeError,
            "PR head moved during mutation for #{server.name}/##{pr.number} " \
            "(#{expected_head} -> #{current.head_sha}), session #{correlation}: reconcile before repeating"
        end

        # GitHub identity URLs end with the PR number for both comment kinds.
        def comment_belongs_to_pr?(entry, number)
          return false unless entry.is_a?(Hash)
          issue_url = entry["issue_url"].to_s
          # Review comments expose pull_request_url as a plain string.
          pr_url = (entry.dig("pull_request", "url") || entry["pull_request_url"]).to_s
          issue_url.end_with?("/issues/#{number}") || pr_url.end_with?("/pulls/#{number}")
        end

        # Serialize the read/post/reconcile sequence per session so two
      # concurrent callers cannot both observe "no marker" and post.
        def with_session_lock(correlation)
          require "tmpdir"
          lock_path = File.join(Dir.tmpdir, "ace-review-session-#{correlation}.lock")
          File.open(lock_path, File::CREAT | File::RDWR, 0600) do |lock|
            lock.flock(File::LOCK_EX)
            yield
          end
        end

        def comment_marker(correlation)
          unless correlation.to_s.match?(/\A[a-zA-Z0-9._:-]+\z/)
            raise Ace::Git::ConfigError, "Invalid review session correlation"
          end
          "<!-- ace-review-session:#{correlation} -->"
        end

        def matching_review_comments(pr, marker, head)
          gh_api_pages("issues/#{pr.number}/comments").filter_map do |entry|
            # Every row must be a valid comment; a row without a body
      # means malformed collection and must not hide our session post.
            unless entry.is_a?(Hash) && entry["body"].is_a?(String)
              raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR comment collection"
            end
            next unless entry["body"].include?(marker)

            review_comment(entry, pr, head)
          end
        end

        def review_comment(entry, pr, head, threads = {})
          user = entry.is_a?(Hash) ? entry["user"] : nil
          unless entry.is_a?(Hash) && entry["id"].is_a?(Integer) && entry["id"].positive? && entry["body"].is_a?(String) &&
              user.is_a?(Hash) && user["login"].is_a?(String)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR comment evidence"
          end
          thread_id, resolved = threads[entry["id"]] || [nil, nil]
          Ace::Git::ProviderReviewComment.new(
            server_name: server.name, repository_url: server.url, pr_number: pr.number,
            id: entry["id"], author: user["login"], body: entry["body"],
            url: entry["html_url"], path: entry["path"], line: entry["line"],
            head_sha: entry["commit_id"], resolved: resolved, thread_id: thread_id
          )
        end

        def review_entry(entry, pr, head)
          user = entry.is_a?(Hash) ? entry["user"] : nil
          unless entry.is_a?(Hash) && entry["id"].is_a?(Integer) && entry["id"].positive? &&
              user.is_a?(Hash) && user["login"].is_a?(String) &&
              entry["state"].is_a?(String) && !entry["state"].empty?
            raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub PR review evidence"
          end
          Ace::Git::ProviderReview.new(
            server_name: server.name, repository_url: server.url, pr_number: pr.number,
            id: entry["id"], author: user["login"], body: entry["body"],
            state: entry["state"], url: entry["html_url"], head_sha: entry["commit_id"]
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
          stdin = nil
          if %i[post patch].include?(method)
            # The body travels on stdin (`--input -`), never as a
            # command argument: argv leaks into process listings and
            # timeout errors, and huge review bodies exceed arg limits.
            args += ["-X", method.to_s.upcase, "--input", "-"]
            stdin = JSON.generate(body: body)
          end
          result = CliExecutor.execute("api", args, timeout: timeout, runner: runner, stdin: stdin)
          classify_failure(result[:stderr], context: "api #{suffix}") unless result[:success]
          JSON.parse(result[:stdout])
        rescue JSON::ParserError => e
          raise Ace::Git::ProviderMalformedOutputError, "Malformed GitHub API JSON: #{e.message}"
        end

        # Exact-head local fallback for oversized API diffs: fetch the PR
        # head ref from the selected host into a temp ref, verify the SHA
        # matches, and diff base..head locally.
        def local_diff_fallback(number)
          base_oid = pull_request_review_details(number: number).base_sha
          head_oid = pull_request(number: number).head_sha
          # Preserve the configured scheme (http or https) rather than
          # assuming https, and never use scp-style host:path remotes.
          scheme = server.url.to_s[/\A[a-z][a-z0-9+.-]*:\/\//i].to_s.downcase
          scheme = "https://" if scheme.empty?
          host = Ace::Git::Atoms::ServerUrl.normalize(server.url).split("/", 2).first
          remote = "#{scheme}#{host}/#{repo_path}"
          head_ref = "refs/ace/review/pr-#{number}-#{Process.pid}"
          base_ref = "#{head_ref}-base"
          begin
            run_git("fetch", "--no-tags", remote, "+refs/pull/#{number}/head:#{head_ref}")
            fetched = run_git("rev-parse", head_ref).strip
            unless fetched == head_oid
              raise Ace::Git::ProviderMalformedOutputError,
                "Local fallback fetched #{fetched[0, 12]} but the reviewed head is #{head_oid[0, 12]}"
            end
            # The base commit may not exist locally and a two-dot diff
            # would include unrelated target-branch changes: fetch the
            # exact base SHA and diff from the merge base.
            run_git("fetch", "--no-tags", remote, "+#{base_oid}:#{base_ref}")
            merge_base = run_git("merge-base", base_ref, head_ref).strip
            diff = run_git("diff", "#{merge_base}..#{head_ref}")
            raise Ace::Git::ProviderMalformedOutputError, "Local fallback produced an empty diff" if diff.strip.empty?
            diff
          ensure
            run_git("update-ref", "-d", head_ref) rescue nil
            run_git("update-ref", "-d", base_ref) rescue nil
          end
        end

        def repo_path
          Ace::Git::Atoms::ServerUrl.normalize(server.url).split("/", 2).last
        end

        def run_git(*args)
          require "open3"
          require "timeout"
          out, status = Timeout.timeout(timeout) do
            Open3.capture2({"LC_ALL" => "C"}, "git", *args)
          end
        rescue Timeout::Error
          raise Ace::Git::ProviderUnreachableError, "git #{args.first} timed out after #{timeout}s"
        else
          raise Ace::Git::ProviderUnreachableError, "git #{args.first} failed" unless status.success?
          out
        end

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
            body: data["body"],
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
