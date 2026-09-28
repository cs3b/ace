# frozen_string_literal: true

require "json"
require "uri"
require_relative "cli_executor"
require_relative "parsers"

module Ace
  module Git
    module Forgejo
      # Forgejo provider implementation of the shared provider contract.
      #
      # Owns Forgejo terminology and translates `fj` responses into the
      # normalized evidence types defined by the ace-git core. Every failure is
      # classified with the shared taxonomy; `fj` failures are never hidden
      # behind ad-hoc curl calls or silent fallbacks.
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

        # @return [Boolean] true when the server host has a configured `fj` login
        def authenticated?
          CliExecutor.authenticated?(server_host, runner: runner)
        end

        # @raise [Ace::Git::ProviderAuthenticationError] when unauthenticated
        def check_authenticated!
          CliExecutor.check_authenticated!(host: server_host, runner: runner)
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
          # `fj pr search` has no --limit flag; fetch all and order newest-first.
          listing = fj(["--style", "minimal", "pr", "search", "--state", "all"])
          entries = Parsers.parse_search(listing).sort_by { |entry| -entry[:number] }

          entries.each do |entry|
            view = fj(["--style", "minimal", "pr", "view", entry[:number].to_s])
            parsed = Parsers.parse_pr_view(view)
            next unless parsed && parsed[:head_ref] == branch

            parsed[:head_sha] = head_sha_of(entry[:number])
            return normalize_pr(parsed)
          end

          nil
        end

        # @return [String] unified diff text for the pull request
        def pull_request_diff(number:)
          fj(["pr", "view", number.to_s, "diff"])
        end

        # `fj pr search` has no --limit flag; cap client-side after sorting
        # newest-first so the returned window is deterministic.
        #
        # @return [Array<ProviderPullRequest>] recent PRs, newest first
        def recent_pull_requests(limit:)
          listing = fj(["--style", "minimal", "pr", "search", "--state", "all"])
          Parsers.parse_search(listing)
            .map { |entry| normalize_search_entry(entry) }
            .sort_by { |pr| -pr.number }
            .first(limit)
        end

        # @return [ProviderIssue] normalized issue evidence
        def issue(number:)
          view = fj(["--style", "minimal", "issue", "view", number.to_s])
          parsed = Parsers.parse_issue_view(view) ||
            raise(Ace::Git::ProviderMalformedOutputError,
              "Unrecognized `fj issue view #{number}` output; update the Forgejo provider parser")

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

        # @return [Array<ProviderCheck>] normalized check evidence for a ref
        def checks(ref:)
          tasks = fj(["--style", "minimal", "actions", "tasks"])
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
        def repository
          view = fj(["--style", "minimal", "repo", "view"])
          parsed = Parsers.parse_repo_view(view)

          Ace::Git::ProviderRepository.new(
            server_name: server.name,
            full_name: parsed[:full_name],
            default_branch: nil,
            url: parsed[:url]
          )
        end

        # ---- PR lifecycle mutations ----

        # @return [Array<ProviderPullRequest>] open PRs matching the exact
        #   base/head identity, with head SHA provenance
        def find_open_pull_requests(head_repository_url:, head_ref:, base_repository_url:, base_ref:)
          require_base_on_server!(base_repository_url)
          listing = fj(["--style", "minimal", "pr", "search", "--state", "open"])
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
        # `fj` cannot create draft PRs; the receipt reports the provider's
        # real draft state.
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
            return receipt(:create, verify_expected_head!(matches.first, expected_head), :existing)
          end

          args = ["pr", "create", title, "--head", head_ref, "--base", base_ref]
          args += ["--body", body] if body
          send_mutation(args, ambiguous: true, identity: identity_text(head_repository_url, head_ref, base_ref))

          created = reconcile_created(
            head_repository_url: head_repository_url, head_ref: head_ref,
            base_ref: base_ref, expected_head: expected_head
          )
          receipt(:create, created, :created)
        end

        # @return [ProviderMutationReceipt] operation :update
        def update_pull_request(number:, expected_head:, title: nil, body: nil)
          verify_expected_head!(fetch_pr(number), expected_head)
          args = ["pr", "edit", number.to_s]
          args += ["title", title] if title
          args += ["body", body] if body
          send_mutation(args, ambiguous: false)
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

        # Run one `fj` command, classifying every failure with the taxonomy.
        def fj(args)
          result = CliExecutor.execute(args, timeout: timeout, runner: runner)
          return result[:stdout] if result[:success]

          classify_failure(result[:stderr], context: args.join(" "))
        end

        # Send one mutating `fj` command. When `ambiguous` is true (create),
        # any transport-level failure becomes an unknown outcome: the request
        # may have mutated the forge, so callers must reconcile by exact
        # identity instead of retrying blindly.
        def send_mutation(args, ambiguous:, identity: nil)
          result = CliExecutor.execute(args, timeout: timeout, runner: runner)
          return result if result[:success]

          classify_failure(result[:stderr], context: args.join(" "))
        rescue Ace::Git::ProviderUnreachableError => e
          raise e unless ambiguous

          raise Ace::Git::ProviderUnknownOutcomeError,
            "PR create outcome unknown after transport failure (#{e.message}); " \
            "reconcile by exact identity before repeating: #{identity}"
        end

        def classify_failure(message, context:)
          message = message.to_s
          case message
          when /not found|does not exist|no pull request|no issue/i
            raise Ace::Git::ProviderObjectNotFoundError, "Object not found (#{context}): #{message}"
          when /access denied|unauthorized|token/i
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

        # View one PR and parse its stable minimal-style output.
        def view_pr(number)
          view = fj(["--style", "minimal", "pr", "view", number.to_s])
          Parsers.parse_pr_view(view) ||
            raise(Ace::Git::ProviderMalformedOutputError,
              "Unrecognized `fj pr view #{number}` output; update the Forgejo provider parser")
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
          commits = fj(["--style", "minimal", "pr", "view", number.to_s, "commits"])
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
            base_repository_url: server.url,
            merge_commit_sha: nil
          )
        end

        # Source repository URL for the PR head: forks are reported by the
        # `From `owner/repo:branch`` segment and live on the same host as the
        # base repository; canonical PRs use the configured repository.
        def head_repository_url_of(parsed)
          repo = parsed[:head_repository]
          return server.url if repo.nil? || repo.empty?

          "#{server_host_root}/#{repo}"
        end

        def server_host_root
          @server_host_root ||= begin
            uri = URI.parse(server.url.to_s)
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
            base_repository_url: nil,
            merge_commit_sha: nil
          )
        end

        def server_host
          @server_host ||= begin
            uri = URI.parse(server.url.to_s)
            uri.host
          rescue URI::Error
            nil
          end
        end

        def pr_url(number)
          base = server.url.to_s.chomp("/")
          "#{base}/pulls/#{number}"
        end

        def issue_url(number)
          base = server.url.to_s.chomp("/")
          "#{base}/issues/#{number}"
        end
      end
    end
  end
end
