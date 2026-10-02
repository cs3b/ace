# frozen_string_literal: true

module Ace
  module Git
    # Normalized evidence types produced by every provider implementation.
    #
    # Provider packages translate their CLI responses into exactly these
    # shapes, so consumers can stay forge-neutral. All fields except the
    # identifying ones may be nil when a provider cannot supply them.
    #
    # Pull request state values: :open, :merged, :closed. Issue state values:
    # :open, :closed.
    ProviderPullRequest = Data.define(
      :server_name, :number, :title, :body, :state, :head_ref, :base_ref,
      :head_sha, :author, :url, :draft, :merged_at,
      :head_repository_url, :base_repository_url, :merge_commit_sha
    )

    ProviderIssue = Data.define(:server_name, :number, :title, :state, :author, :url, :labels)

    # Normalized check/CI evidence for one check run.
    ProviderCheck = Data.define(:server_name, :name, :state, :conclusion, :url)

    # Comments keep the exact repository and PR identity supplied by the
    # selected provider. A nil path/line denotes a conversation comment.
    ProviderReviewComment = Data.define(
      :server_name, :repository_url, :pr_number, :id, :author, :body,
      :url, :path, :line, :head_sha, :resolved, :thread_id
    )

    ProviderReview = Data.define(
      :server_name, :repository_url, :pr_number, :id, :author, :body,
      :state, :url, :head_sha
    )

    ProviderReviewEvidence = Data.define(
      :server_name, :repository_url, :pr_number, :head_sha, :comments, :reviews
    )

    ProviderReviewDetails = Data.define(:server_name, :repository_url, :pr_number, :base_sha, :files)

    ProviderReviewSnapshot = Data.define(
      :provider, :pull_request, :base_sha, :files, :diff, :review_evidence, :checks
    )

    ProviderReviewMutation = Data.define(
      :server_name, :repository_url, :pr_number, :head_sha, :comment,
      :idempotency
    )

    # Normalized repository evidence.
    ProviderRepository = Data.define(:server_name, :full_name, :default_branch, :url)

    # Exact pull request source/base identity used for idempotent create
    # reconciliation, expected-head proof, and cleanup consent binding.
    #
    # `head_sha` is the exact head commit the identity was captured at; every
    # mutation decision that depends on head state must compare against it.
    ProviderPullRequestIdentity = Data.define(
      :head_repository_url, :head_ref, :base_repository_url, :base_ref, :head_sha
    ) do
      # @return [Hash] plain, JSON-serializable representation
      def to_h
        {
          head_repository_url: head_repository_url,
          head_ref: head_ref,
          base_repository_url: base_repository_url,
          base_ref: base_ref,
          head_sha: head_sha
        }
      end
    end

    # Normalized result of one provider lifecycle mutation (create, update,
    # ready, merge). Receipts are immutable evidence: the operation performed,
    # the pull request state observed afterwards, and — for creates only —
    # whether the request created a new PR or reconciled to an existing one
    # (`:created` / `:existing`; nil for non-create operations).
    ProviderMutationReceipt = Data.define(:server_name, :operation, :pull_request, :idempotency) do
      # @return [Hash] plain, JSON-serializable representation
      def to_h
        {
          server_name: server_name,
          operation: operation,
          idempotency: idempotency,
          pull_request: pull_request&.to_h
        }
      end
    end

    # Cleanup proof status vocabulary. Only :merged is confirmed remote merge
    # proof; every other status retains the candidate. Provider transport
    # failures (:offline, :authentication_error, :malformed) are distinct from
    # object states and never relabel a failed lookup as merged.
    CLEANUP_PROOF_STATUSES = %i[
      no_pr open closed_unmerged merged offline authentication_error malformed
    ].freeze

    # Normalized provider proof about the pull request behind a cleanup
    # candidate (worktree, local ref, or remote ref). `status` is one of
    # {CLEANUP_PROOF_STATUSES}; pr/head fields are nil unless a PR was found.
    ProviderCleanupProof = Data.define(
      :server_name, :status, :pr_number, :pr_url, :head_sha, :merge_commit_sha
    ) do
      # @return [Boolean] true only for confirmed remote merge proof
      def merged?
        status == :merged
      end

      # @return [Hash] plain, JSON-serializable representation
      def to_h
        {
          server_name: server_name,
          status: status,
          pr_number: pr_number,
          pr_url: pr_url,
          head_sha: head_sha,
          merge_commit_sha: merge_commit_sha
        }
      end
    end
  end
end
