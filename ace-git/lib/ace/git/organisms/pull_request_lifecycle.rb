# frozen_string_literal: true

require_relative "../atoms/pr_reference"

module Ace
  module Git
    module Organisms
      # Forge-neutral pull request lifecycle orchestration.
      #
      # Owns the shared policy for every `ace-git pr` operation: server
      # selection (exactly once per operation), identifier-to-server identity
      # validation, body-file loading, and normalized provider invocation.
      # Provider-specific command construction and parsing stay in the
      # provider packages; this class only sees normalized evidence.
      #
      # Selection rules (see the qk1 parent contract):
      # - `--server NAME` and `--default-server` are mutually exclusive.
      # - With neither, the configured repository remote is resolved through
      #   ServerRegistry; a failed remote resolution never falls back to a
      #   default.
      # - A PR URL or `owner/repo#number` is accepted only when it matches a
      #   configured server exactly; an explicit selection that contradicts
      #   the identifier fails before any mutation.
      class PullRequestLifecycle
        MERGE_METHODS = %i[squash merge rebase].freeze

        # @param server_name [String, Symbol, nil] explicit server selection
        # @param use_default [Boolean] resolve the configured default server
        # @param remote_name [String, nil] git remote used when nothing selected
        # @param timeout [Integer, nil] provider operation timeout
        # @param runner [Proc, nil] injectable provider command runner (tests)
        def initialize(server_name: nil, use_default: false, remote_name: nil, timeout: nil, runner: nil, repo_root: nil, resolved_server: nil)
          @pinned_server = resolved_server
          @selection = {server_name: server_name, use_default: use_default, remote_name: remote_name}
          @selection[:repo_root] = repo_root if repo_root
          @timeout = timeout
          @runner = runner
        end

        # Fetch normalized evidence for one pull request.
        #
        # @param identifier [String, Integer] number, `owner/repo#n`, or URL
        # @return [ProviderPullRequest]
        def show(identifier)
          reference = parse_identifier(identifier)
          server = resolve_server_for(reference)
          provider_for(server).pull_request(number: reference.number)
        end

        # Exact-head PR metadata without the diff/comment/check inventory.
        # Delta resolution needs identity and base provenance only; pulling
        # the full diff there would transfer it just to discard it.
        def review_metadata_snapshot(identifier)
          reference = parse_identifier(identifier)
          server = resolve_server_for(reference)
          provider = provider_for(server)
          before = provider.pull_request(number: reference.number)
          head = required_head!(before)
          details = provider.pull_request_review_details(number: reference.number)
          body_before = provider.pull_request_body(number: reference.number)
          # Hydration is a remote read: build the metadata from the read that
          # follows it, and re-read the body after — the task spec text lives
          # in the body, so an edit between reads invalidates the collection.
          after = provider.pull_request(number: reference.number)
          body_after = provider.pull_request_body(number: reference.number)
          if body_before != body_after
            raise ProviderExpectedHeadConflictError,
              "PR body changed while collecting review metadata; retry on the current head"
          end
          after = after.with(body: body_after) unless body_after.nil?
          # Body hydration and identity must agree with the base provenance
          # read before collection; a moved base invalidates the metadata.
          latest_details = provider.pull_request_review_details(number: reference.number)
          if after.head_sha != head || after.head_ref != before.head_ref ||
              after.base_ref != before.base_ref || latest_details.base_sha != details.base_sha
            raise ProviderExpectedHeadConflictError,
              "PR head/base changed while collecting review metadata; retry on the current head"
          end
          ProviderReviewSnapshot.new(
            provider: server.provider, pull_request: after,
            base_sha: details.base_sha, files: details.files,
            diff: nil, review_evidence: ProviderReviewEvidence.new(
              server_name: server.name, repository_url: server.url,
              pr_number: before.number, head_sha: head, comments: [], reviews: []
            ),
            checks: []
          )
        end

        # Collect one complete review packet under an exact head/base guard.
        # Provider failure is propagated; empty diff/comments remain valid
        # evidence only after the full inventory and second read agree.
        def review_snapshot(identifier, include_comments: true)
          reference = parse_identifier(identifier)
          server = resolve_server_for(reference)
          provider = provider_for(server)
          before = provider.pull_request(number: reference.number)
          head = required_head!(before)
          details = provider.pull_request_review_details(number: reference.number)
          diff = provider.pull_request_diff(number: reference.number)
          unless diff.is_a?(String)
            raise ProviderMalformedOutputError, "PR diff is not text"
          end
          comments = if include_comments
            provider.pull_request_review_evidence(number: reference.number, expected_head: head)
          else
            ProviderReviewEvidence.new(
              server_name: server.name, repository_url: server.url,
              pr_number: before.number, head_sha: head, comments: [], reviews: []
            )
          end
          checks = provider.pull_request_checks(number: reference.number, head_sha: head)
          # The CLI-parsed PR may omit the description; hydrate it from the
          # provider's body capability when available (nil stays absence).
          # Hydration is itself a remote read: the final identity comes from
          # the read that follows it, so body and identity can never come
          # from different points in time.
          body_before = provider.pull_request_body(number: reference.number)
          after = provider.pull_request(number: reference.number)
          body_after = provider.pull_request_body(number: reference.number)
          if body_before != body_after
            raise ProviderExpectedHeadConflictError,
              "PR body changed while collecting review evidence; retry on the current head"
          end
          after = after.with(body: body_after) unless body_after.nil?
          latest_details = provider.pull_request_review_details(number: reference.number)
          if after.head_sha != head || latest_details.base_sha != details.base_sha ||
              after.head_ref != before.head_ref || after.base_ref != before.base_ref ||
              after.head_repository_url != before.head_repository_url ||
              after.base_repository_url != before.base_repository_url
            raise ProviderExpectedHeadConflictError,
              "PR head/base changed while collecting review evidence; retry on the current head"
          end
          unless details.files.is_a?(Array) && checks.is_a?(Array) &&
              comments.head_sha == head && comments.pr_number == before.number
            raise ProviderMalformedOutputError, "PR review evidence is incomplete or mismatched"
          end
          ProviderReviewSnapshot.new(
            provider: server.provider, pull_request: after,
            base_sha: details.base_sha, files: details.files,
            diff: diff, review_evidence: comments, checks: checks
          )
        end

        def post_review_comment(identifier, expected_head:, body:, correlation:)
          reference = parse_identifier(identifier)
          provider = provider_for(resolve_server_for(reference))
          provider.create_pull_request_comment(
            number: reference.number, expected_head: expected_head,
            body: body, correlation: correlation
          )
        end

        def update_review_comment(identifier, expected_head:, comment_id:, body:)
          reference = parse_identifier(identifier)
          provider = provider_for(resolve_server_for(reference))
          provider.update_pull_request_comment(
            number: reference.number, expected_head: expected_head,
            comment_id: comment_id, body: body
          )
        end

        def resolve_review_thread(identifier, expected_head:, thread_id:)
          reference = parse_identifier(identifier)
          provider = provider_for(resolve_server_for(reference))
          provider.resolve_pull_request_thread(
            number: reference.number, expected_head: expected_head,
            thread_id: thread_id
          )
        end

        def file_at_ref(identifier, path:, ref:)
          reference = parse_identifier(identifier)
          provider = provider_for(resolve_server_for(reference))
          provider.repository_file(path: path, ref: ref)
        end

        # Create (or reconcile to) a pull request for an exact base/head
        # identity. There is no identifier: the selected server's repository
        # is the base, `head_repository_url` names the source (defaults to
        # the base repository; no fork inference).
        #
        # @return [ProviderMutationReceipt] idempotency :created/:existing
        def create(head_ref:, base_ref:, expected_head:, title:, head_repository_url: nil,
          body: nil, body_file: nil, draft: true)
          body_text = body_file ? load_body(body_file) : body
          server = resolve_selected_server
          provider_for(server).create_pull_request(
            head_ref: head_ref,
            head_repository_url: head_repository_url || server.url,
            base_ref: base_ref,
            expected_head: expected_head,
            title: title,
            body: body_text,
            draft: draft
          )
        end

        # Update title/body after exact-head verification.
        #
        # @return [ProviderMutationReceipt]
        def update(identifier, expected_head:, title: nil, body: nil, body_file: nil)
          body_text = body_file ? load_body(body_file) : body
          reference = parse_identifier(identifier)
          server = resolve_server_for(reference)
          provider_for(server).update_pull_request(
            number: reference.number, expected_head: expected_head,
            title: title, body: body_text
          )
        end

        # Mark a draft pull request ready after exact-head verification.
        #
        # @return [ProviderMutationReceipt]
        def ready(identifier, expected_head:)
          reference = parse_identifier(identifier)
          server = resolve_server_for(reference)
          provider_for(server).ready_pull_request(number: reference.number, expected_head: expected_head)
        end

        # Merge with provider-side expected-head enforcement; no implicit
        # merge method exists.
        #
        # @param method [Symbol, String] :squash, :merge, or :rebase
        # @return [ProviderMutationReceipt]
        def merge(identifier, expected_head:, method:)
          normalized = method.to_s.strip.downcase.to_sym
          unless MERGE_METHODS.include?(normalized)
            raise ArgumentError, "Invalid merge method '#{method}'; use one of: #{MERGE_METHODS.join(", ")}"
          end

          reference = parse_identifier(identifier)
          server = resolve_server_for(reference)
          provider_for(server).merge_pull_request(
            number: reference.number, expected_head: expected_head, method: normalized
          )
        end

        # Freeze the selected provider identity for an assignment attempt.
        def resolved_identity(identifier = nil)
          selected = identifier.nil? ? resolve_selected_server : resolve_server_for(parse_identifier(identifier))
          if @pinned_server && selected != @pinned_server
            raise ProviderIdentityMismatchError, "Configured server identity changed from the pinned delivery identity"
          end
          selected.to_h.transform_keys(&:to_s).transform_values(&:to_s)
        end

        # Read-only reconciliation of a possibly completed create. Absence
        # does not authorize another write; the assignment owns that policy.
        def reconcile_create(head_repository_url:, head_ref:, base_repository_url:, base_ref:)
          server = resolve_selected_server
          unless Atoms::ServerUrl.match?(server.url, base_repository_url)
            raise ProviderIdentityMismatchError, "Create reconciliation base does not match selected server"
          end
          provider_for(server).find_open_pull_requests(head_repository_url: head_repository_url,
            head_ref: head_ref, base_repository_url: base_repository_url, base_ref: base_ref)
        end

        def resolved_server_url(identifier)
          reference = parse_identifier(identifier)
          resolve_server_for(reference).url
        end
        private

        def required_head!(pull_request)
          head = pull_request.head_sha
          return head if head.to_s.match?(/\A[0-9a-f]{40}\z/)

          raise ProviderMalformedOutputError, "PR evidence is missing an exact head SHA"
        end

        def parse_identifier(identifier)
          reference = Atoms::PrReference.parse(identifier)
          raise ArgumentError, "Invalid PR identifier: #{identifier}" unless reference

          reference
        end

        def resolve_selected_server
          selected = ServerRegistry.resolve_for(**@selection)
          if @pinned_server && selected != @pinned_server
            raise ProviderIdentityMismatchError, "Configured server identity changed from the pinned delivery identity"
          end
          @pinned_server || selected
        end

        # Resolve exactly one server for a parsed reference, validating any
        # explicit selection against the identifier's repository identity.
        def resolve_server_for(reference)
          return resolve_selected_server unless reference.repository_explicit?

          candidates = if reference.repository_url
            ServerRegistry.matching_servers(reference.repository_url)
          else
            ServerRegistry.servers_for_owner_repo(reference.owner_repo)
          end

          if @selection[:server_name] || @selection[:use_default]
            selected = resolve_selected_server
            unless candidates.any? { |candidate| candidate.name == selected.name }
              identity = reference.repository_url || reference.owner_repo
              raise ProviderIdentityMismatchError,
                "PR identifier (#{identity}) does not match the selected server '#{selected.name}'"
            end

            selected
          elsif candidates.size == 1
            candidates.first
          elsif candidates.empty?
            identity = reference.repository_url || reference.owner_repo
            raise AmbiguousRemoteError,
              "PR repository '#{identity}' matches no configured server (configured: " \
              "#{ServerRegistry.servers.map(&:name).join(", ")})"
          else
            identity = reference.repository_url || reference.owner_repo
            raise AmbiguousRemoteError,
              "PR repository '#{identity}' matches multiple configured servers " \
              "(#{candidates.map(&:name).join(", ")}); select one explicitly"
          end
        end

        # The forge server URL for a PR identifier, resolved on demand
      # through the shared registry (pure resolution, no mutation).

        def provider_for(server)
          @resolved_server_url = server.url
          Ace::Git::Providers.for(server, timeout: @timeout, runner: @runner)
        end

        def load_body(path)
          raise ArgumentError, "--body-file is required" unless path
          raise ArgumentError, "Body file not found: #{path}" unless File.file?(path)

          File.read(path)
        rescue SystemCallError => e
          raise ArgumentError, "Cannot read body file #{path}: #{e.message}"
        end
      end
    end
  end
end
