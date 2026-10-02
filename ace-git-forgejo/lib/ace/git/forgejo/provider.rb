# frozen_string_literal: true

require "json"
require "uri"
require_relative "cli_executor"
require_relative "parsers"
require_relative "issue_api"

module Ace
  module Git
    module Forgejo
      # Forgejo provider implementation of the shared provider contract.
      #
      # Owns Forgejo terminology and translates `fj` responses into the
      # normalized evidence types defined by the ace-git core. Every
      # repository-scoped call is bound to the selected server's exact
      # host/owner/repository through the {CliExecutor} repository boundary:
      # the selected identity is mandatory, unobserved operations refuse
      # before launch, and returned evidence is checked for conflicting
      # identity. Every failure is classified with the shared taxonomy;
      # `fj` failures are never hidden behind ad-hoc curl calls or silent
      # fallbacks.
      class Provider < Ace::Git::Providers::Base
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

        # @return [ProviderPullRequest] normalized pull request evidence
        # @raise [ProviderObjectNotFoundError] when the PR does not exist
        # @raise [ProviderMalformedOutputError] when `fj` output is unexpected
        # @raise [ProviderUnreachableError] when the endpoint is unreachable
        def pull_request(number:)
          fetch_pr(number)
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
          match = Array(issue_api.repository_labels(wanted: label)).find { |entry| entry["name"] == label }
          unless match && match["id"].to_i.positive?
            raise Ace::Git::ProviderObjectNotFoundError, "Forgejo label #{label.inspect} is not configured on #{server.url}"
          end
          issue_api.add_label(request_number!(number), match["id"])
        end

        def remove_issue_label(number:, label:)
          match = Array(issue_api.repository_labels(wanted: label)).find { |entry| entry["name"] == label }
          return unless match

          issue_api.remove_label(request_number!(number), match.fetch("id"))
        end

        def set_issue_state(number:, state:)
          raise ArgumentError, "Invalid issue state #{state.inspect}" unless %i[open closed].include?(state)

          issue_api.set_state(request_number!(number), state)
        end

        # @return [Array<ProviderCheck>] normalized check evidence for a ref
        def checks(ref:)
          tasks = fj(:actions_tasks)
          Parsers.parse_actions_tasks(tasks)
            .select { |task| task[:sha].start_with?(ref.to_s) || ref.to_s.start_with?(task[:sha]) }
            .map do |task|
              Ace::Git::ProviderCheck.new(
                server_name: server.name,
                name: task[:name],
                state: task[:state],
                conclusion: task[:state],
                url: nil
              )
            end
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

        # ---- PR lifecycle mutations ----

        # @return [Array<ProviderPullRequest>] open PRs matching the exact
        #   base/head identity, with head SHA provenance
        def find_open_pull_requests(head_repository_url:, head_ref:, base_repository_url:, base_ref:)
          require_base_on_server!(base_repository_url)
          listing = fj(:pr_search, "open")
          Parsers.parse_search(listing).filter_map do |entry|
            parsed = view_pr(entry[:number])
            next unless parsed && parsed[:state] == :open
            next unless parsed[:head_ref] == head_ref && parsed[:base_ref] == base_ref
            next unless Ace::Git::Atoms::ServerUrl.match?(head_repository_url_of(parsed), head_repository_url)

            with_head_sha(parsed)
          end
        end

        # Create a PR via `fj pr create`, reconciling to an exact open match
        # first and proving the resulting head against `expected_head`.
        # `fj` cannot encode an explicit fork head; the receipt reports the
        # provider's real draft state.
        #
        # @return [ProviderMutationReceipt] idempotency :created/:existing
        def create_pull_request(head_ref:, head_repository_url:, base_ref:, expected_head:, title:, body: nil, draft: true)
          # `fj pr create -r` binds the base repository, but no observed form
          # encodes a cross-repository fork head; refusing before any command
          # (even lookups) beats creating the wrong PR.
          unless Ace::Git::Atoms::ServerUrl.match?(head_repository_url, server.url)
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Forgejo CLI (fj) pr create cannot target head repository " \
              "#{head_repository_url} (resolved server repository: #{server.url}); " \
              "run from the fork checkout or use the forge web UI"
          end

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
            return receipt(:create, verify_expected_head!(matches.first, expected_head), :existing)
          end

          send_mutation(:pr_create, title, head_ref, base_ref, body,
            ambiguous: true, identity: identity_text(head_repository_url, head_ref, base_ref))

          created = reconcile_created(
            head_repository_url: head_repository_url, head_ref: head_ref,
            base_ref: base_ref, expected_head: expected_head
          )
          receipt(:create, created, :created)
        end

        # `fj pr edit` takes one field subcommand per invocation (title|body),
        # so multi-field updates are separate commands with final evidence
        # fetched only after every field update succeeded.
        #
        # @return [ProviderMutationReceipt] operation :update
        def update_pull_request(number:, expected_head:, title: nil, body: nil)
          number = request_number!(number)
          verify_expected_head!(fetch_pr(number), expected_head)
          send_mutation(:pr_edit_title, number, title, ambiguous: false) if title
          send_mutation(:pr_edit_body, number, body, ambiguous: false) if body
          receipt(:update, fetch_pr(number), nil)
        end

        # `fj` offers no draft-to-ready command; classified as an unsupported
        # capability instead of guessing at provider behavior.
        def ready_pull_request(number:, expected_head:)
          raise Ace::Git::ProviderUnsupportedCapabilityError,
            "Forgejo CLI (fj) cannot mark a draft pull request ready; use the forge web UI"
        end

        # `fj pr merge` cannot enforce an expected-head precondition
        # atomically, so merging is refused rather than racing a stale head.
        def merge_pull_request(number:, expected_head:, method:)
          unless %i[squash merge rebase].include?(method)
            raise ArgumentError, "Invalid merge method #{method.inspect}"
          end

          raise Ace::Git::ProviderUnsupportedCapabilityError,
            "Forgejo CLI (fj) pr merge cannot enforce expected-head (#{expected_head}) " \
            "atomically; refusing unsafe merge"
        end

        private

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

        # Send one mutating repository operation. When `ambiguous` is true
        # (create), any transport-level failure becomes an unknown outcome:
        # the request may have mutated the forge, so callers must reconcile
        # by exact identity instead of retrying blindly.
        def send_mutation(operation, *arguments, ambiguous:, identity: nil)
          result = execute_repository(operation, arguments)
          return result if result[:success]

          classify_failure(result[:stderr], context: operation_context(operation, arguments))
        rescue Ace::Git::ProviderUnreachableError => e
          raise e unless ambiguous

          raise Ace::Git::ProviderUnknownOutcomeError,
            "PR create outcome unknown after transport failure (#{e.message}); " \
            "reconcile by exact identity before repeating: #{identity}"
        end

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

        # Fetch one PR as normalized evidence with exact head SHA.
        def fetch_pr(number)
          with_head_sha(view_pr(number))
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

        # Re-fetch and verify the PR created by an accepted create request.
        def reconcile_created(head_repository_url:, head_ref:, base_ref:, expected_head:)
          matches = find_open_pull_requests(
            head_repository_url: head_repository_url, head_ref: head_ref,
            base_repository_url: server.url, base_ref: base_ref
          )
          if matches.empty?
            raise Ace::Git::ProviderUnknownOutcomeError,
              "PR create accepted but no open pull request matches " \
              "#{head_repository_url}@#{head_ref} -> #{server.url}@#{base_ref}; " \
              "reconcile by exact identity before repeating"
          end
          if matches.size > 1
            raise Ace::Git::ProviderConflictingMatchesError,
              "Multiple open pull requests match #{head_repository_url}@#{head_ref} -> " \
              "#{base_ref}: #{matches.map(&:number).join(", ")}; resolve the conflict first"
          end

          verify_expected_head!(matches.first, expected_head)
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
          base = repository_target.url.to_s.chomp("/")
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
