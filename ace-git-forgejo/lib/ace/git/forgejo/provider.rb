# frozen_string_literal: true

require "json"
require "uri"
require_relative "cli_executor"
require_relative "parsers"
require_relative "issue_api"
require_relative "pull_request_api"

module Ace
  module Git
    module Forgejo
      # Forgejo provider implementation of the shared provider contract.
      #
      # Owns Forgejo terminology and translates `fj` and Forgejo API v1
      # responses into the normalized evidence types defined by the ace-git
      # core. Every repository-scoped call is bound to the selected server's
      # exact host/owner/repository: `fj` commands through the {CliExecutor}
      # repository boundary, API calls through the repository-bound
      # {HttpClient}/{PullRequestApi} routes. The selected identity is
      # mandatory, unobserved operations refuse before launch, and returned
      # evidence is checked for conflicting identity. Every failure is
      # classified with the shared taxonomy; provider failures are never
      # hidden behind ad-hoc curl calls or silent fallbacks.
      class Provider < Ace::Git::Providers::Base
        # Fill color for repo labels created on demand by issue linking.
        TRACKED_LABEL_COLOR = "0e8a16"

        # Forgejo's default work-in-progress title prefixes; the server
        # derives its API `draft` field from them (case-insensitive).
        WIP_PREFIXES = ["WIP:", "[WIP]"].freeze

        class << self
          def display_name
            "Forgejo"
          end
        end

        # @return [Boolean] true when the `fj` binary is installed
        def available?
          CliExecutor.installed?(runner: runner)
        end

        # @raise [Ace::Git::ProviderCliMissingError] when `fj` is missing
        def check_available!
          CliExecutor.check_installed!(runner: runner)
        end

        # @return [Boolean] true when the selected server's host has a
        #   configured `fj` login
        def authenticated?
          CliExecutor.authenticated?(repository_target.authority, runner: runner)
        end

        # @raise [Ace::Git::ProviderAuthenticationError] when unauthenticated
        def check_authenticated!
          CliExecutor.check_authenticated!(authority: repository_target.authority, runner: runner)
        end

        # Authoritative pull request read. One API payload binds the exact
        # head repository/ref/SHA, draft state, and merge evidence that the
        # fj surface cannot report (no draft field, head SHA only via a
        # second command); contradictory or missing identity fails closed.
        #
        # @return [ProviderPullRequest] normalized pull request evidence
        # @raise [Ace::Git::ProviderObjectNotFoundError] when the PR does not exist
        # @raise [Ace::Git::ProviderMalformedOutputError] when the payload is unexpected
        # @raise [Ace::Git::ProviderUnreachableError] when the endpoint is unreachable
        def pull_request(number:)
          number = request_number!(number)
          normalize_api_pr(pr_api.pull_request(number))
        end

        # @return [ProviderPullRequest, nil] evidence for the branch's PR
        def pull_request_for_branch(branch:)
          # `fj pr search` has no --limit flag (observed v0.6.0); fetch all
          # and order newest-first.
          listing = fj(:pr_search, "all")
          entries = Parsers.parse_search(listing).sort_by { |entry| -entry[:number] }

          entries.each do |entry|
            parsed = view_pr(entry[:number])
            next unless parsed && parsed[:head_ref] == branch

            parsed[:head_sha] = head_sha_of(entry[:number])
            return normalize_pr(parsed)
          end

          nil
        end

        # @return [String] unified diff text for the pull request
        def pull_request_diff(number:)
          fj(:pr_diff, request_number!(number))
        end

        # `fj pr search` has no --limit flag; cap client-side after sorting
        # newest-first so the returned window is deterministic.
        #
        # @return [Array<ProviderPullRequest>] recent PRs, newest first
        def recent_pull_requests(limit:)
          listing = fj(:pr_search, "all")
          Parsers.parse_search(listing)
            .map { |entry| normalize_search_entry(entry) }
            .sort_by { |pr| -pr.number }
            .first(limit)
        end

        # @return [ProviderIssue] normalized issue evidence
        def issue(number:)
          view = fj(:issue_view, request_number!(number))
          parsed = Parsers.parse_issue_view(view) ||
            raise(Ace::Git::ProviderMalformedOutputError,
              "Unrecognized `fj issue view #{number}` output; update the Forgejo provider parser")
          verify_returned_number!(parsed, number, "issue")

          Ace::Git::ProviderIssue.new(
            server_name: server.name,
            number: parsed[:number],
            title: parsed[:title],
            state: parsed[:state],
            author: parsed[:author],
            url: issue_url(parsed[:number]),
            labels: nil
          )
        end

        def issue_tracking(number:)
          data = issue_api.issue(request_number!(number))
          unless data.is_a?(Hash) && data["number"].to_i == number.to_i &&
              data["html_url"].to_s == issue_url(number.to_i)
            raise Ace::Git::ProviderIdentityMismatchError, "Issue ##{number} is not in #{server.url}"
          end
          evidence = Ace::Git::ProviderIssue.new(
            server_name: server.name, number: data["number"], title: data["title"],
            state: normalize_state(data["state"]),
            author: data.dig("user", "login"), url: data["html_url"],
            labels: Array(data["labels"]).map { |label| label["name"] }
          )
          {issue: evidence,
           comments: Array(issue_api.comments(number)).map { |c| {id: c.fetch("id"), body: c["body"].to_s} },
           labels: evidence.labels}
        end

        # Unrecognized or missing state is malformed evidence: mapping it to
        # :closed would let sync close an issue without valid state proof.
        def normalize_state(value)
          case value.to_s
          when "open" then :open
          when "closed" then :closed
          else raise Ace::Git::ProviderMalformedOutputError, "Unknown issue state #{value.inspect}"
          end
        end

        def create_issue_comment(number:, body:)
          issue_api.create_comment(request_number!(number), body)
        end

        def update_issue_comment(number:, comment_id:, body:)
          assert_issue_comment_owned!(number, comment_id)
          issue_api.update_comment(Integer(comment_id), body)
        end

        def delete_issue_comment(number:, comment_id:)
          assert_issue_comment_owned!(number, comment_id)
          issue_api.delete_comment(Integer(comment_id))
        end

        def add_issue_label(number:, label:)
          issue_api.add_label(request_number!(number), ensure_repo_label_id(label))
        end

        def remove_issue_label(number:, label:)
          match = Array(issue_api.repository_labels(wanted: label)).find { |entry| entry["name"] == label }
          return unless match

          issue_api.remove_label(request_number!(number), match.fetch("id"))
        end

        # Fresh repositories lack the tracking label; creating it on demand
        # keeps issue linking from committing a tracking comment it could
        # never label. A concurrent creator surfaces as an uncertain mutation
        # outcome, which only means re-list and attach what appeared.
        def ensure_repo_label_id(label)
          match = Array(issue_api.repository_labels(wanted: label)).find { |entry| entry["name"] == label }
          return match["id"] if match && match["id"].to_i.positive?

          begin
            issue_api.create_repo_label(name: label, color: TRACKED_LABEL_COLOR)
          rescue Ace::Git::ProviderUnknownOutcomeError
            nil
          end
          match = Array(issue_api.repository_labels(wanted: label)).find { |entry| entry["name"] == label }
          unless match && match["id"].to_i.positive?
            raise Ace::Git::ProviderObjectNotFoundError,
              "Forgejo label #{label.inspect} could not be created or found on #{server.url}"
          end
          match["id"]
        end

        def set_issue_state(number:, state:)
          raise ArgumentError, "Invalid issue state #{state.inspect}" unless %i[open closed].include?(state)

          issue_api.set_state(request_number!(number), state)
        end

        # @return [Array<ProviderCheck>] normalized check evidence for a ref
        def checks(ref:)
          tasks = fj(:actions_tasks)
          Parsers.parse_actions_tasks(tasks)
            # Exact-head evidence binds each task to the reviewed head by SHA
            # prefix: a full or abbreviated SHA that prefixes the reviewed
            # head identifies that commit, and anything else is another
            # head's task. No matching evidence is silently dropped.
            .select { |task| ref.to_s.downcase.start_with?(task[:sha].downcase) }
            .map do |task|
              Ace::Git::ProviderCheck.new(
                server_name: server.name,
                name: task[:name],
                state: task[:state],
                conclusion: task[:state],
                url: nil
              )
            end
        rescue Ace::Git::ProviderObjectNotFoundError
          # A repository with Actions disabled serves no tasks endpoint. The
          # review flows resolve the repository binding and the PR before
          # collecting checks, so a not-found here means CI is unavailable,
          # not a missing repository; empty check evidence keeps the review
          # collectable. Parse and transport failures still fail closed.
          []
        end

        # @return [ProviderRepository] normalized repository evidence
        # @raise [ProviderIdentityMismatchError] when the CLI reports a
        #   repository other than the selected one
        def repository
          target = repository_target
          view = fj(:repo_view)
          parsed = Parsers.parse_repo_view(view)
          verify_returned_repository!(parsed, target)

          Ace::Git::ProviderRepository.new(
            server_name: server.name,
            full_name: parsed[:full_name],
            default_branch: nil,
            url: parsed[:url] || target.url
          )
        end

        # The fj CLI surface omits the PR body; the repository-bound API
        # supplies it for review evidence. Malformed payloads fail closed.
        def pull_request_body(number:)
          number = request_number!(number)
          data = review_http.request(:get, "pulls/#{number}")
          unless data.is_a?(Hash) && data["number"] == number && data.key?("body") &&
                    (data["body"].nil? || data["body"].is_a?(String))
            raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo PR body evidence"
          end
          data["body"]
        end

        def pull_request_review_evidence(number:, expected_head:)
          number = request_number!(number)
          verify_expected_head!(pull_request(number: number), expected_head)
          comments = review_http.paginate("issues/#{number}/comments").map do |entry|
            review_comment(entry, number, expected_head)
          end
          reviews = review_http.paginate("pulls/#{number}/reviews").map do |entry|
            review_entry(entry, number, expected_head)
          end
          # Review comments live under each review, not at the PR level.
          inline = reviews.flat_map do |review|
            # The per-review endpoint returns the complete list (no
            # pagination); a repeated nonempty page would trip the loop
            # guard, so fetch once and require an array.
            entries = review_http.request(:get, "pulls/#{number}/reviews/#{review.id}/comments")
            unless entries.is_a?(Array)
              raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo review comment evidence"
            end
            entries.map { |entry| review_comment(entry, number, expected_head) }
          end
          verify_expected_head!(pull_request(number: number), expected_head)
          Ace::Git::ProviderReviewEvidence.new(
            server_name: server.name, repository_url: server.url,
            pr_number: number, head_sha: expected_head,
            comments: comments + inline, reviews: reviews
          )
        end

        def pull_request_review_details(number:)
          number = request_number!(number)
          data = review_http.request(:get, "pulls/#{number}")
          files = review_http.paginate("pulls/#{number}/files").map do |entry|
            entry.is_a?(Hash) && entry["filename"]
          end
          unless data.is_a?(Hash) && data["base"].is_a?(Hash) && data["number"] == number &&
              data.dig("base", "sha").to_s.match?(/\A[0-9a-f]{40}\z/) &&
              data["changed_files"].is_a?(Integer) && data["changed_files"] == files.length &&
              files.all? { |path| path.is_a?(String) && !path.empty? }
            raise Ace::Git::ProviderMalformedOutputError, "Malformed or incomplete Forgejo PR file evidence"
          end
          Ace::Git::ProviderReviewDetails.new(
            server_name: server.name, repository_url: server.url, pr_number: number,
            base_sha: data.dig("base", "sha"), files: files
          )
        end

        def pull_request_checks(number:, head_sha:)
          verify_expected_head!(pull_request(number: number), head_sha)
          checks(ref: head_sha)
        end

        def repository_file(path:, ref:)
          require "base64"
          # %20, not form encoding: "+" in a path segment is a literal plus.
          # Explicit unreserved-character allowlist: percent-encode
          # everything else (DEFAULT_PARSER leaves ? and + ambiguous).
          escaped = path.split("/").map { |part|
            part.gsub(/[^A-Za-z0-9._~!$&'()*+,;=@:-]/) { |c| c.bytes.map { |b| format("%%%02X", b) }.join }
          }.join("/")
          data = review_http.request(:get, "contents/#{escaped}?ref=#{ref}")
          unless data.is_a?(Hash) && data["encoding"] == "base64" && data["content"].is_a?(String)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo repository file evidence"
          end
          Base64.strict_decode64(data["content"].delete("\n"))
        rescue ArgumentError => e
          raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo repository file content: #{e.message}"
        end

        def create_pull_request_comment(number:, expected_head:, body:, correlation:)
          number = request_number!(number)
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          require_open_pr!(pr)
          marker = comment_marker(correlation)
          with_session_lock(correlation) do
          existing = matching_review_comments(number, marker, expected_head)
          if existing.length > 1
            raise Ace::Git::ProviderConflictingMatchesError,
              "Multiple comments match review session #{correlation} on PR ##{number}"
          end
          if existing.one?
            # A repeat reconciles only the exact session comment; a marker
            # match with different content is a conflict, never our post.
            sent = "#{body}\n\n#{marker}"
            if existing.first.body == sent
              verify_post_mutation_head!(number, expected_head, correlation)
              return review_mutation(number, expected_head, existing.first, :existing)
            end

            raise Ace::Git::ProviderConflictingMatchesError,
              "Review session #{correlation} comment exists on PR ##{number} with different content"
          end
          second = verify_expected_head!(pull_request(number: number), expected_head)
          require_open_pr!(second)
          begin
            review_http.request(:post, "issues/#{number}/comments", body: {body: "#{body}\n\n#{marker}"})
          rescue Ace::Git::ProviderMalformedOutputError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment sent but response unreadable for #{server.name}/#{number}, head #{expected_head}, session #{correlation}: #{e.message}; reconcile before repeating"
          rescue Ace::Git::ProviderUnknownOutcomeError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment outcome unknown for #{server.name}/#{number}, head #{expected_head}, " \
              "session #{correlation}: #{e.message}; reconcile before repeating"
          end
          begin
          matches = matching_review_comments(number, marker, expected_head)
          rescue Ace::Git::ProviderMalformedOutputError, Ace::Git::ProviderAuthenticationError, Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment sent but reconciliation read failed for session #{correlation}: #{e.message}; reconcile before repeating"
          end
          unless matches.one? && matches.first.body == "#{body}\n\n#{marker}"
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR comment sent but reconciliation found #{matches.length} exact-content match(es) for session #{correlation}"
          end
          verify_post_mutation_head!(number, expected_head, correlation)
          review_mutation(number, expected_head, matches.first, :created)
          end
        end

        def update_pull_request_comment(number:, expected_head:, comment_id:, body:)
          number = request_number!(number)
          comment_id = Integer(comment_id)
          verify_expected_head!(pull_request(number: number), expected_head)
          issue_matches = review_http.paginate("issues/#{number}/comments").select { |entry| entry["id"] == comment_id }
          # Inline ids live under individual reviews; locate them there
          # so an unsupported edit is classified explicitly instead of
          # being misread as not-belonging to this PR.
          inline_found = issue_matches.empty? && review_comment_ids(number).include?(comment_id)
          if inline_found
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Editing inline review comments is unsupported by the observed fj v0.6.0 surface (comment #{comment_id})"
          end
          matches = issue_matches
          update_route = "issues/comments/#{comment_id}"
          unless matches.one?
            raise Ace::Git::ProviderIdentityMismatchError,
              "Comment #{comment_id} does not belong to selected PR ##{number}"
          end
          comment = review_comment(matches.first, number, expected_head)
          if comment.body == body
            verify_post_mutation_head!(number, expected_head, "comment #{comment_id}")
            return review_mutation(number, expected_head, comment, :existing)
          end

          verify_expected_head!(pull_request(number: number), expected_head)
          begin
            review_http.request(:patch, update_route, body: {body: body})
          rescue Ace::Git::ProviderMalformedOutputError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update sent but response unreadable for #{server.name}/#{number}, comment #{comment_id}: #{e.message}; reconcile before repeating"
          rescue Ace::Git::ProviderUnknownOutcomeError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update outcome unknown for #{server.name}/#{number}, " \
              "head #{expected_head}, comment #{comment_id}: #{e.message}"
          end
          begin
            # Fetch individually and validate the Forgejo issue identity.
            begin
              updated = review_http.request(:get, update_route)
            rescue Ace::Git::ProviderMalformedOutputError, Ace::Git::ProviderAuthenticationError, Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderUnreachableError => e
              raise Ace::Git::ProviderUnknownOutcomeError,
                "Comment update sent but verification read failed for comment #{comment_id}: #{e.message}; reconcile before repeating"
            end
            unless updated.is_a?(Hash) && updated["issue_url"].to_s.end_with?("/#{number}")
              raise Ace::Git::ProviderUnknownOutcomeError,
                "Comment update sent but edited comment #{comment_id} does not verify against PR ##{number}; reconcile before repeating"
            end
          rescue Ace::Git::ProviderUnreachableError => e
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update sent but verification read failed for comment #{comment_id}: #{e.message}; reconcile before repeating"
          end
          unless updated && updated["id"] == comment_id && updated["body"] == body
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Comment update sent but exact PR comment #{comment_id} could not be verified"
          end
          verify_post_mutation_head!(number, expected_head, "comment #{comment_id}")
          review_mutation(number, expected_head, review_comment(updated, number, expected_head), :updated)
        end

        def resolve_pull_request_thread(number:, expected_head:, thread_id:)
          raise Ace::Git::ProviderUnsupportedCapabilityError,
            "Forgejo does not expose an observed repository-bound review thread resolution capability"
        end

        # ---- PR lifecycle mutations ----
        #
        # Delivery-capable lifecycle on the documented Forgejo API v1
        # (capability evidence in the task report): canonical and
        # same-server fork heads via the "owner:branch" head form, draft
        # state via the WIP title convention the server itself derives
        # draft from, and merges guarded by the server-enforced
        # `head_commit_id` precondition.

        # @return [Array<ProviderPullRequest>] open PRs matching the exact
        #   base/head identity, with head SHA provenance from the API list
        def find_open_pull_requests(head_repository_url:, head_ref:, base_repository_url:, base_ref:)
          require_base_on_server!(base_repository_url)
          # An absent head repository names the base repository itself,
          # mirroring the lifecycle organism's default.
          head_repository_url = server.url if head_repository_url.to_s.empty?
          pr_api.open_pull_requests.filter_map do |payload|
            next unless payload.dig("head", "ref") == head_ref && payload.dig("base", "ref") == base_ref
            next unless Ace::Git::Atoms::ServerUrl.match?(api_head_repository_url(payload), head_repository_url)

            normalize_api_pr(payload)
          end
        end

        # Create (or reconcile to) a pull request for the exact identity.
        # Same-server fork sources are encoded with the documented
        # "owner:branch" API form; cross-host sources are refused before
        # any request. The requested draft state is preserved exactly, and
        # an existing exact match is reusable only when its draft state
        # agrees; a duplicate-create race reconciles to the winner.
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
            existing = verify_expected_head!(matches.first, expected_head)
            ensure_draft_agreement!(existing, draft)
            return receipt(:create, existing, :existing)
          end

          head_arg = api_head_argument!(head_repository_url, head_ref)
          send_title = draft_title!(title, draft)
          pr_api.ensure_version_supported!
          outcome = send_lifecycle_mutation(identity_text(head_repository_url, head_ref, base_ref)) do
            pr_api.create_pull_request(head: head_arg, base: base_ref, title: send_title, body: body)
          end

          if outcome.status == 409
            # A concurrent create won the race: the exact match is
            # authoritative, and repeating the send would never be ours.
            return reconcile_raced_create(head_repository_url: head_repository_url, head_ref: head_ref,
              base_ref: base_ref, expected_head: expected_head, draft: draft)
          end
          unless outcome.status == 201 && outcome.payload.is_a?(Hash) && outcome.payload["number"].is_a?(Integer)
            classify_create_refusal(outcome, head_repository_url, head_ref, base_ref)
          end

          created = verify_expected_head!(pull_request(number: outcome.payload["number"]), expected_head)
          ensure_draft_outcome!(created, draft)
          receipt(:create, created, :created)
        end

        # Edit title/body after exact-head verification through the same
        # API mutation path as the rest of the lifecycle.
        #
        # @return [ProviderMutationReceipt] operation :update
        def update_pull_request(number:, expected_head:, title: nil, body: nil)
          number = request_number!(number)
          verify_expected_head!(pull_request(number: number), expected_head)
          if title || body
            pr_api.ensure_version_supported!
            outcome = send_lifecycle_mutation("PR ##{number} on #{server.name}, head #{expected_head}") do
              pr_api.edit_pull_request(number, title: title, body: body)
            end
            unless (200..299).cover?(outcome.status)
              raise Ace::Git::ProviderUnknownOutcomeError,
                "PR update refused for ##{number} (HTTP #{outcome.status}: #{outcome.message}); " \
                "reconcile before repeating"
            end
            verify_post_mutation_head!(number, expected_head, "update")
          end
          receipt(:update, pull_request(number: number), nil)
        end

        # Mark a draft ready on the exact head. Forgejo derives draft state
        # from the WIP title prefix, so the transition is the documented
        # title edit with the prefix removed; the resulting ready state and
        # unchanged head are proven by an authoritative read-back.
        #
        # @return [ProviderMutationReceipt] operation :ready
        def ready_pull_request(number:, expected_head:)
          number = request_number!(number)
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          unless pr.state == :open
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Cannot mark PR ##{number} ready in #{pr.state} state"
          end
          # Already-ready at the same head is idempotent.
          return receipt(:ready, pr, nil) unless pr.draft

          # Refuse an impossible transition before any server traffic; the
          # capability gate sits directly in front of the mutation.
          stripped_title = strip_wip_prefix!(pr.title, number)
          pr_api.ensure_version_supported!
          outcome = send_lifecycle_mutation("ready transition for PR ##{number} on #{server.name}, head #{expected_head}") do
            pr_api.edit_pull_request(number, title: stripped_title)
          end
          unless (200..299).cover?(outcome.status)
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Ready transition refused for PR ##{number} (HTTP #{outcome.status}: #{outcome.message}); " \
              "reconcile before repeating"
          end

          after = verify_post_mutation_head!(number, expected_head, "ready")
          unless after.draft == false
            raise Ace::Git::ProviderUnknownOutcomeError,
              "Ready title applied but PR ##{number} still reports draft on #{server.name}; " \
              "reconcile before repeating"
          end
          receipt(:ready, after, nil)
        end

        # Merge with the server-enforced atomic precondition: Forgejo
        # re-resolves the head ref inside the merge and refuses with 409
        # when it is not exactly `head_commit_id`. There is deliberately no
        # pre-read fallback guard. Success (and a refused race that turns
        # out already merged) is proven by merged state plus the merge
        # commit on the selected PR at the expected source SHA.
        #
        # @return [ProviderMutationReceipt] operation :merge
        def merge_pull_request(number:, expected_head:, method:)
          unless %i[squash merge rebase].include?(method)
            raise ArgumentError, "Invalid merge method #{method.inspect}"
          end
          number = request_number!(number)
          pr = verify_expected_head!(pull_request(number: number), expected_head)
          case pr.state
          when :open
            nil # proceed to the guarded merge
          when :merged
            # Already merged at the expected source SHA: authoritative
            # evidence is reusable without another mutation attempt.
            prove_merged!(pr, expected_head)
            return receipt(:merge, pr, nil)
          else
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Cannot merge PR ##{number} in #{pr.state} state"
          end

          pr_api.ensure_version_supported!
          outcome = send_lifecycle_mutation("merge of PR ##{number} on #{server.name}, head #{expected_head}") do
            pr_api.merge_pull_request(number, do_method: method.to_s, head_commit_id: expected_head)
          end

          case outcome.status
          when 200..299
            after = verify_post_mutation_head!(number, expected_head, "merge")
            prove_merged!(after, expected_head)
            receipt(:merge, after, nil)
          when 409
            if outcome.message.to_s.match?(/head out of date/i)
              raise Ace::Git::ProviderExpectedHeadConflictError,
                "Forgejo refused the merge of PR ##{number}: the head moved past #{expected_head} " \
                "before the server-side expected-head check (#{outcome.message})"
            end
            reconcile_refused_merge(number, expected_head, outcome)
          when 405
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Forgejo refused to merge PR ##{number} as #{method}: #{outcome.message || "merge style unavailable"}"
          when 404
            raise Ace::Git::ProviderObjectNotFoundError, "Forgejo pull request ##{number} not found"
          when 422
            raise Ace::Git::ProviderIdentityMismatchError,
              "Forgejo rejected the merge request for PR ##{number} (#{outcome.message})"
          end
        end

        private

        # Send one lifecycle mutation: a transport-level failure after the
        # send stays an unknown outcome and gains the exact reconciliation
        # identity; the mutation is never retried inside the provider.
        def send_lifecycle_mutation(identity)
          yield
        rescue Ace::Git::ProviderUnknownOutcomeError => e
          raise Ace::Git::ProviderUnknownOutcomeError,
            "#{e.message}; reconcile by exact identity before repeating: #{identity}"
        end

        # Server-derived draft state must agree with the request for an
        # existing exact match to be reusable.
        def ensure_draft_agreement!(existing, draft)
          return if existing.draft == draft

          raise Ace::Git::ProviderConflictingMatchesError,
            "Open pull request ##{existing.number} matches the exact identity but reports " \
            "draft #{existing.draft.inspect} while draft #{draft.inspect} was requested"
        end

        # The read-back of an accepted create must prove the requested draft
        # state; anything else is a contradictory outcome, never a receipt.
        def ensure_draft_outcome!(created, draft)
          return if created.draft == draft

          raise Ace::Git::ProviderUnknownOutcomeError,
            "PR ##{created.number} was created but reports draft #{created.draft.inspect} " \
            "while draft #{draft.inspect} was requested; reconcile before repeating"
        end

        # Forgejo derives draft state from WIP title prefixes (server
        # defaults, compared case-insensitively without trimming); the API
        # create form has no draft field.
        def draft_title!(title, draft)
          if draft
            work_in_progress_title?(title) ? title : "WIP: #{title}"
          elsif work_in_progress_title?(title)
            raise Ace::Git::ProviderConflictingMatchesError,
              "Requested draft:false conflicts with the WIP-prefixed title #{title.inspect}; " \
              "Forgejo would create the pull request as a draft"
          else
            title
          end
        end

        def work_in_progress_title?(title)
          WIP_PREFIXES.any? { |prefix| title.to_s.upcase.start_with?(prefix) }
        end

        # Remove one leading WIP prefix for the ready transition. A draft
        # whose title carries none of the known prefixes means the server
        # uses configured prefixes this provider cannot strip: refusing
        # before the mutation keeps the draft state truthful.
        def strip_wip_prefix!(title, number)
          prefix = WIP_PREFIXES.find { |candidate| title.to_s.upcase.start_with?(candidate) }
          unless prefix
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "PR ##{number} reports draft but its title carries no known WIP prefix " \
              "(#{WIP_PREFIXES.join(", ")}); the server likely uses configured prefixes " \
              "this provider cannot strip safely"
          end
          title.to_s.slice(prefix.length..).to_s.sub(/\A +/, "")
        end

        # Same-server fork heads ride the documented "owner:branch" API
        # form. The declared source must resolve to the selected host with
        # an owner path; cross-host sources are refused before any request.
        def api_head_argument!(head_repository_url, head_ref)
          return head_ref if head_repository_url.nil? ||
            Ace::Git::Atoms::ServerUrl.match?(head_repository_url, server.url)
          unless same_server_authority?(head_repository_url)
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "PR create cannot target head repository #{head_repository_url} outside the " \
              "selected server #{server.url}; only canonical and same-server fork sources are supported"
          end

          owner = URI.parse(head_repository_url.to_s).path.to_s.split("/").reject(&:empty?).first
          unless owner
            raise Ace::Git::ProviderIdentityMismatchError,
              "Head repository #{head_repository_url.inspect} has no owner path; " \
              "cannot encode the fork head for #{server.url}"
          end
          "#{owner}:#{head_ref}"
        end

        def same_server_authority?(url)
          authority = Ace::Git::Atoms::ServerUrl.normalize(url).split("/", 2).first.to_s
          !authority.empty? && authority == selected_server_authority
        end

        def selected_server_authority
          @selected_server_authority ||= Ace::Git::Atoms::ServerUrl.normalize(server.url).split("/", 2).first.to_s
        end

        # Head repository URL provenance from an API payload: canonical
        # pulls carry the selected repository; fork pulls carry their own;
        # a deleted fork repository reports none, and that absence stays
        # honest instead of being relabelled.
        def api_head_repository_url(payload)
          full_name = payload.dig("head", "repo", "full_name")
          return nil if !full_name.is_a?(String) || full_name.empty?

          "#{server_host_root}/#{full_name}"
        end

        # Authoritative API evidence for one pull request. The base
        # repository must be the selected one: a misrouted payload is never
        # relabelled.
        def normalize_api_pr(payload)
          base_full_name = payload.dig("base", "repo", "full_name").to_s
          unless !base_full_name.empty? && base_full_name.casecmp(repository_target.repo).zero?
            raise Ace::Git::ProviderIdentityMismatchError,
              "Forgejo returned pull request ##{payload["number"]} with base repository " \
              "#{base_full_name.inspect} for selected #{repository_target.repo}; refusing misrouted evidence"
          end
          state = if payload["state"] == "open"
            :open
          elsif payload["merged"] == true
            :merged
          else
            :closed
          end
          merge_commit = payload["merge_commit_sha"]
          Ace::Git::ProviderPullRequest.new(
            server_name: server.name,
            number: payload["number"],
            title: payload["title"],
            body: payload["body"].is_a?(String) ? payload["body"] : nil,
            state: state,
            head_ref: payload.dig("head", "ref"),
            base_ref: payload.dig("base", "ref"),
            head_sha: payload.dig("head", "sha"),
            author: payload.dig("user", "login"),
            url: pr_url(payload["number"]),
            draft: payload["draft"],
            merged_at: payload["merged_at"].is_a?(String) ? payload["merged_at"] : nil,
            head_repository_url: api_head_repository_url(payload),
            base_repository_url: repository_target.url,
            merge_commit_sha: merge_commit.is_a?(String) && !merge_commit.empty? ? merge_commit : nil
          )
        end

        # A merge receipt requires authoritative merged evidence: the merged
        # state, the merge commit, and the exact source SHA that was merged.
        def prove_merged!(pull_request, expected_head)
          return if pull_request.state == :merged && pull_request.head_sha == expected_head &&
            pull_request.merge_commit_sha.to_s.match?(/\A[0-9a-f]{40}\z/)

          raise Ace::Git::ProviderUnknownOutcomeError,
            "Merge accepted but PR ##{pull_request.number} does not prove merged state at " \
            "#{expected_head} with a merge commit on #{server.name}; reconcile before repeating"
        end

        # A merge refusal that is not the stale-head case: reconcile by read
        # before deciding — an authoritative already-merged result at the
        # expected source SHA is reusable; a closed-unmerged pull request is
        # a classified refusal; everything else stays an unknown outcome.
        def reconcile_refused_merge(number, expected_head, outcome)
          after = verify_post_mutation_head!(number, expected_head, "merge reconciliation")
          if after.state == :merged && after.head_sha == expected_head &&
              after.merge_commit_sha.to_s.match?(/\A[0-9a-f]{40}\z/)
            return receipt(:merge, after, nil)
          end
          if after.state == :closed
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "PR ##{number} is closed without merge; Forgejo refused the merge " \
              "(HTTP #{outcome.status}: #{outcome.message})"
          end
          raise Ace::Git::ProviderUnknownOutcomeError,
            "Merge outcome unknown for #{server.name}/##{number}, head #{expected_head}: " \
            "server returned HTTP #{outcome.status} (#{outcome.message}) and the read-back does not " \
            "prove a merge; reconcile before repeating"
        end

        # A duplicate-create race: the exact match is the authoritative
        # winner of the concurrent create.
        def reconcile_raced_create(head_repository_url:, head_ref:, base_ref:, expected_head:, draft:)
          matches = find_open_pull_requests(
            head_repository_url: head_repository_url, head_ref: head_ref,
            base_repository_url: server.url, base_ref: base_ref
          )
          if matches.size == 1
            existing = verify_expected_head!(matches.first, expected_head)
            ensure_draft_agreement!(existing, draft)
            return receipt(:create, existing, :existing)
          end
          raise Ace::Git::ProviderUnknownOutcomeError,
            "PR create refused as duplicate but #{matches.size} open pull requests match " \
            "#{identity_text(head_repository_url, head_ref, base_ref)}; reconcile by exact identity before repeating"
        end

        # A refused create (404/422) mutated nothing: classify the server's
        # own explanation instead of racing a retry.
        def classify_create_refusal(outcome, head_repository_url, head_ref, base_ref)
          error = outcome.status == 404 ? Ace::Git::ProviderObjectNotFoundError : Ace::Git::ProviderIdentityMismatchError
          raise error,
            "Forgejo refused the create of #{identity_text(head_repository_url, head_ref, base_ref)} " \
            "(HTTP #{outcome.status}: #{outcome.message})"
        end

        def pr_api
          @pr_api ||= PullRequestApi.new(server: server, timeout: timeout, runner: runner)
        end

        def require_open_pr!(pr)
          return if pr.state == :open

          raise Ace::Git::ProviderUnsupportedCapabilityError,
            "Cannot post review comment to PR ##{pr.number} in #{pr.state} state"
        end

        def review_http
          @review_http ||= HttpClient.new(server: server, timeout: timeout, runner: runner)
        end

  # A mutation receipt may only bind the expected head; if the PR head
  # moved during the mutation the outcome stays uncertain. Returns the
  # authoritative read-back when the head still matches.
  def verify_post_mutation_head!(number, expected_head, correlation)
    current = begin
      pull_request(number: number)
    rescue Ace::Git::ProviderMalformedOutputError, Ace::Git::ProviderAuthenticationError, Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderUnreachableError => e
      raise Ace::Git::ProviderUnknownOutcomeError,
        "Head verification read failed after mutation for #{server.name}: #{e.message}; reconcile before repeating"
    end
    return current if current.head_sha == expected_head

    raise Ace::Git::ProviderUnknownOutcomeError,
      "PR head moved during mutation for #{server.name}/##{number} " \
      "(#{expected_head} -> #{current.head_sha}), session #{correlation}: reconcile before repeating"
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

        def matching_review_comments(number, marker, expected_head)
          review_http.paginate("issues/#{number}/comments").filter_map do |entry|
            unless entry.is_a?(Hash) && entry["body"].is_a?(String)
              raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo PR comment collection"
            end
            next unless entry["body"].include?(marker)

            review_comment(entry, number, expected_head)
          end
        end

        def review_comment(entry, number, head)
          user = entry.is_a?(Hash) ? entry["user"] : nil
          unless entry.is_a?(Hash) && entry["id"].is_a?(Integer) && entry["id"].positive? && entry["body"].is_a?(String) &&
              user.is_a?(Hash) && user["login"].is_a?(String)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo PR comment evidence"
          end
          Ace::Git::ProviderReviewComment.new(
            server_name: server.name, repository_url: server.url, pr_number: number,
            id: entry["id"], author: user["login"], body: entry["body"],
            url: entry["html_url"], path: entry["path"],
            # Forgejo supplies position/original_position rather than
            # line; the positive side position is the normalized line.
            line: entry["line"] || [entry["position"], entry["original_position"]].compact.reject { |v| !v.is_a?(Integer) || v <= 0 }.first,
            head_sha: entry["commit_id"], resolved: entry.key?("resolver") ? !entry["resolver"].nil? : nil,
            thread_id: nil
          )
        end

        # Collect inline (review) comment ids by walking each review.
        def review_comment_ids(number)
          review_http.paginate("pulls/#{number}/reviews").flat_map do |review|
            entries = review_http.request(:get, "pulls/#{number}/reviews/#{review["id"]}/comments")
            unless entries.is_a?(Array)
              raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo review comment evidence"
            end
            entries.filter_map { |entry| entry["id"] if entry.is_a?(Hash) && entry["id"].is_a?(Integer) }
          end
        end

        def review_entry(entry, number, head)
          unless entry.is_a?(Hash)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo PR review evidence"
          end
          user, team = entry["user"], entry["team"]
          unless user.nil? || user.is_a?(Hash)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo PR review evidence: user must be an object"
          end
          unless team.nil? || team.is_a?(Hash)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo PR review evidence: team must be an object"
          end
          reviewer = user&.[]("login") || team&.[]("name")
          unless entry["id"].is_a?(Integer) && entry["id"].positive? && reviewer.is_a?(String) &&
              entry["state"].is_a?(String) && !entry["state"].empty?
            raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo PR review evidence"
          end
          Ace::Git::ProviderReview.new(
            server_name: server.name, repository_url: server.url, pr_number: number,
            id: entry["id"], author: reviewer, body: entry["body"],
            # Forgejo reports REQUEST_CHANGES; consumers count only the
            # canonical CHANGES_REQUESTED spelling.
            state: (entry["state"] == "REQUEST_CHANGES") ? "CHANGES_REQUESTED" : entry["state"],
            url: entry["html_url"], head_sha: entry["commit_id"]
          )
        end

        def review_mutation(number, head, comment, idempotency)
          Ace::Git::ProviderReviewMutation.new(
            server_name: server.name, repository_url: server.url, pr_number: number,
            head_sha: head, comment: comment, idempotency: idempotency
          )
        end

        def assert_issue_comment_owned!(number, comment_id)
          return if issue_tracking(number: number)[:comments].any? { |comment| comment[:id].to_i == comment_id.to_i }

          raise Ace::Git::ProviderIdentityMismatchError,
            "Comment #{comment_id} is not on selected issue ##{number} in #{server.url}"
        end

        def issue_api
          @issue_api ||= IssueApi.new(server: server, timeout: timeout, runner: runner)
        end

        # Validated selected repository identity. Built once; malformed
        # selections fail as configuration errors before any subprocess.
        def repository_target
          @repository_target ||= RepositoryBinding::Target.resolve(server.url)
        end

        # Refuse before any repository subprocess when the installed fj was
        # never observed; a different version must not inherit capabilities.
        def ensure_observed_version!
          return if @version_checked

          CliExecutor.check_version_supported!(runner: runner)
          @version_checked = true
        end

        # Run one repository-scoped `fj` command bound to the selected
        # target, classifying every failure with the taxonomy.
        def fj(operation, *arguments)
          result = execute_repository(operation, arguments)
          return result[:stdout] if result[:success]

          classify_failure(result[:stderr], context: operation_context(operation, arguments))
        end

        # Run one repository-scoped `fj` operation on the validated target.
        def execute_repository(operation, arguments)
          target = repository_target
          ensure_observed_version!
          ensure_not_redirecting!(target)
          CliExecutor.execute_repository(
            target: target, operation: operation,
            arguments: arguments, timeout: timeout, runner: runner
          )
        end

        # Refuse before any subprocess when the readable fj configuration
        # aliases the selected host to a different endpoint: `-H` cannot
        # prevent that redirect, and returned-identity checks cannot see it.
        def ensure_not_redirecting!(target)
          return if @redirect_checked

          RepositoryBinding.reject_selected_host_redirect!(target.host_url)
          @redirect_checked = true
        end

        def operation_context(operation, arguments)
          "#{operation} #{arguments.compact.join(" ")}".strip
        end

        def classify_failure(message, context:)
          message = message.to_s
          case message
          when /not found|does not exist|no pull request|no issue/i
            raise Ace::Git::ProviderObjectNotFoundError, "Object not found (#{context}): #{message}"
          when /access denied|unauthorized|token|only signed in|not logged in|log ?in required/i
            raise Ace::Git::ProviderAuthenticationError, "Not authenticated with Forgejo: #{message}"
          else
            raise Ace::Git::ProviderUnreachableError, "Forgejo request failed (#{context}): #{message}"
          end
        end

        # Complete a parsed PR view with its exact head SHA evidence.
        def with_head_sha(parsed)
          parsed[:head_sha] = head_sha_of(parsed[:number])
          normalize_pr(parsed)
        end

        # View one PR and parse its stable minimal-style output. The
        # qualified `owner/repo#N` reference binds the read to the selected
        # repository; a returned number that disagrees with the request is a
        # routed mismatch and fails closed.
        def view_pr(number)
          view = fj(:pr_view, number)
          parsed = Parsers.parse_pr_view(view) ||
            raise(Ace::Git::ProviderMalformedOutputError,
              "Unrecognized `fj pr view #{number}` output; update the Forgejo provider parser")
          verify_returned_number!(parsed, number, "pull request")
          parsed
        end

        def require_base_on_server!(base_repository_url)
          return if Ace::Git::Atoms::ServerUrl.match?(base_repository_url, server.url)

          raise Ace::Git::ProviderUnsupportedCapabilityError,
            "Forgejo provider operates on the resolved server repository (#{server.url}); " \
            "refusing base repository #{base_repository_url}"
        end

        def identity_text(head_repository_url, head_ref, base_ref)
          "#{head_repository_url}@#{head_ref} -> #{server.url}@#{base_ref}"
        end

        def receipt(operation, pull_request, idempotency)
          Ace::Git::ProviderMutationReceipt.new(
            server_name: server.name, operation: operation,
            pull_request: pull_request, idempotency: idempotency
          )
        end

        def head_sha_of(number)
          commits = fj(:pr_commits, number)
          Parsers.parse_head_sha(commits)
        end

        def normalize_pr(parsed)
          Ace::Git::ProviderPullRequest.new(
            server_name: server.name,
            number: parsed[:number],
            title: parsed[:title],
            body: parsed[:body],
            state: parsed[:state],
            head_ref: parsed[:head_ref],
            base_ref: parsed[:base_ref],
            head_sha: parsed[:head_sha],
            author: parsed[:author],
            url: pr_url(parsed[:number]),
            draft: nil,
            merged_at: nil,
            head_repository_url: head_repository_url_of(parsed),
            base_repository_url: repository_target.url,
            # fj v0.6.0 exposes no authoritative merge-commit field for a
            # selected PR (observed; see the task capability evidence), so
            # merge evidence stays empty and cleanup retains the checkout.
            merge_commit_sha: nil
          )
        end

        # Source repository URL for the PR head: forks are reported by the
        # `From `owner/repo:branch`` segment and live on the same host as the
        # base repository; canonical PRs use the configured repository.
        def head_repository_url_of(parsed)
          repo = parsed[:head_repository]
          return repository_target.url if repo.nil? || repo.empty?

          "#{server_host_root}/#{repo}"
        end

        def server_host_root
          @server_host_root ||= begin
            uri = URI.parse(repository_target.url)
            "#{uri.scheme || "https"}://#{uri.host}#{":#{uri.port}" if uri.port && uri.port != uri.default_port}"
          end
        end

        def normalize_search_entry(entry)
          Ace::Git::ProviderPullRequest.new(
            server_name: server.name,
            number: entry[:number],
            title: entry[:title],
            body: nil,
            state: nil,
            head_ref: nil,
            base_ref: nil,
            head_sha: nil,
            author: entry[:author],
            url: pr_url(entry[:number]),
            draft: nil,
            merged_at: nil,
            head_repository_url: nil,
            base_repository_url: repository_target.url,
            merge_commit_sha: nil
          )
        end

        # Reject non-numeric or non-positive PR/issue numbers as
        # configuration failures before any subprocess.
        def request_number!(number)
          text = number.to_s
          unless /\A\d+\z/.match?(text) && text.to_i.positive?
            raise Ace::Git::ConfigError,
              "Pull request and issue numbers must be positive integers, got #{number.inspect}"
          end

          text.to_i
        end

        # PR and issue numbers are not globally unique: evidence whose
        # number disagrees with the selected reference was not routed to the
        # selected repository and must never be relabelled.
        def verify_returned_number!(parsed, requested, kind)
          return if parsed[:number] == requested.to_i

          raise Ace::Git::ProviderIdentityMismatchError,
            "Forgejo returned #{kind} ##{parsed[:number]} for selected #{kind} " \
            "##{requested} on #{repository_target.repo}; refusing misrouted evidence"
        end

        # `fj repo view` was bound to the selected owner/repository, so
        # returned identity fields must agree with the selection.
        def verify_returned_repository!(parsed, target)
          full_name = parsed[:full_name].to_s.sub(%r{\.git\z}i, "")
          unless !full_name.empty? && full_name.casecmp(target.repo).zero?
            raise Ace::Git::ProviderIdentityMismatchError,
              "Forgejo repo view returned #{full_name.inspect} for selected repository " \
              "#{target.repo}; refusing misrouted evidence"
          end
          return if parsed[:url].nil? || parsed[:url].empty? ||
            Ace::Git::Atoms::ServerUrl.match?(parsed[:url], target.url)

          raise Ace::Git::ProviderIdentityMismatchError,
            "Forgejo repo view returned URL #{parsed[:url].inspect} for selected repository " \
            "#{target.url}; refusing misrouted evidence"
        end

        def pr_url(number)
          # A configured URL may end in .git (clone form); the web URL
          # must be built from the repository page base instead.
          base = repository_target.url.to_s.chomp("/").sub(/\.git\z/i, "")
          "#{base}/pulls/#{number}"
        end

        def issue_url(number)
          # Identity evidence comes from the web endpoint, not the clone URL
          # (which may be SSH-style and is not a parseable web URL).
          "#{Ace::Git::Atoms::ServerUrl.web_base(server.url)}/issues/#{number}"
        end
      end
    end
  end
end
