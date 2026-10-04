# frozen_string_literal: true

module Ace
  module TestSupport
    # Shared PR-lifecycle contract parity suite.
    #
    # Provider packages include this module and supply scripted runners per
    # symbolic scenario, proving identical normalized receipts, exact-identity
    # matching, expected-head enforcement, idempotent create, unknown-outcome
    # classification, and capability classification across every provider —
    # with no network and no provider CLI.
    #
    # Host test class contract:
    # - #build_provider(runner) -> Ace::Git::Providers::Base on the runner
    # - #lifecycle_runner(scenario) -> scripted runner for the scenario
    # - #ready_supported? [Boolean] provider can mark drafts ready
    # - #merge_supported? [Boolean] provider enforces head atomically
    module PullRequestLifecycleContract
      SERVER_URL = "https://forge.example.com/owner/repo"
      HEAD_SHA = "fc14c43d3660ac6c133959a6dec29603413f0e8a"
      OTHER_SHA = "0123456789abcdef0123456789abcdef01234567"

      IDENTITY = {
        head_repository_url: SERVER_URL,
        head_ref: "feature/x",
        base_repository_url: SERVER_URL,
        base_ref: "main"
      }.freeze

      # Create kwargs: the base repository is always the resolved server.
      CREATE_IDENTITY = IDENTITY.except(:base_repository_url).freeze

      def test_lifecycle_find_matches_exact_identity_with_provenance
        prs = build_provider(lifecycle_runner(:find_single)).find_open_pull_requests(**IDENTITY)
        assert_equal [25], prs.map(&:number)
        pr = prs.first
        assert_equal HEAD_SHA, pr.head_sha
        assert_equal "feature/x", pr.head_ref
        assert_equal "main", pr.base_ref
        assert_equal SERVER_URL, pr.head_repository_url
        assert_equal SERVER_URL, pr.base_repository_url
      end

      def test_lifecycle_create_proves_head_and_reports_created
        provider = build_provider(lifecycle_runner(:create_new))
        receipt = provider.create_pull_request(
          **CREATE_IDENTITY, expected_head: HEAD_SHA, title: "Ship it"
        )
        assert_instance_of Ace::Git::ProviderMutationReceipt, receipt
        assert_equal :create, receipt.operation
        assert_equal :created, receipt.idempotency
        assert_equal 25, receipt.pull_request.number
        assert_equal "feature/x", receipt.pull_request.head_ref
        assert_equal "main", receipt.pull_request.base_ref
        assert_equal SERVER_URL, receipt.pull_request.head_repository_url
        assert_equal true, receipt.pull_request.draft
        assert_equal HEAD_SHA, receipt.pull_request.head_sha
        assert_equal SERVER_URL, receipt.pull_request.base_repository_url
        assert_equal HEAD_SHA, receipt.to_h.dig(:pull_request, :head_sha)
      end

      def test_lifecycle_create_reconciles_to_exact_open_match
        receipt = build_provider(lifecycle_runner(:create_existing)).create_pull_request(
          **CREATE_IDENTITY, expected_head: HEAD_SHA, title: "Ship it"
        )
        assert_equal :existing, receipt.idempotency
        assert_equal 25, receipt.pull_request.number
      end

      def test_lifecycle_create_rejects_stale_expected_head_without_mutation
        provider = build_provider(lifecycle_runner(:create_existing))
        error = assert_raises(Ace::Git::ProviderExpectedHeadConflictError) do
          provider.create_pull_request(
            **CREATE_IDENTITY, expected_head: OTHER_SHA, title: "Ship it"
          )
        end
        assert_match(/head changed|does not match/i, error.message)
      end

      def test_lifecycle_create_conflicts_on_multiple_exact_matches
        provider = build_provider(lifecycle_runner(:find_multi))
        error = assert_raises(Ace::Git::ProviderConflictingMatchesError) do
          provider.create_pull_request(
            **CREATE_IDENTITY, expected_head: HEAD_SHA, title: "Ship it"
          )
        end
        assert_match(/match/i, error.message)
      end

      def test_lifecycle_create_reports_unknown_outcome_with_reconciliation_identity
        provider = build_provider(lifecycle_runner(:create_unknown))
        error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
          provider.create_pull_request(
            **CREATE_IDENTITY, expected_head: HEAD_SHA, title: "Ship it"
          )
        end
        assert_match(/reconcile by exact identity/i, error.message)
        assert_match(%r{owner/repo}, error.message)
      end

      def test_lifecycle_update_enforces_expected_head
        provider = build_provider(lifecycle_runner(:update_stale))
        error = assert_raises(Ace::Git::ProviderExpectedHeadConflictError) do
          provider.update_pull_request(number: 25, expected_head: OTHER_SHA, title: "New title")
        end
        assert_match(/head changed/i, error.message)

        receipt = build_provider(lifecycle_runner(:update_ok))
          .update_pull_request(number: 25, expected_head: HEAD_SHA, title: "New title")
        assert_equal :update, receipt.operation
        assert_equal HEAD_SHA, receipt.pull_request.head_sha
      end

      def test_lifecycle_ready_classifies_capability
        provider = build_provider(lifecycle_runner(ready_supported? ? :ready_ok : :ready_unsupported))
        if ready_supported?
          receipt = provider.ready_pull_request(number: 25, expected_head: HEAD_SHA)
          assert_equal :ready, receipt.operation
        else
          error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
            provider.ready_pull_request(number: 25, expected_head: HEAD_SHA)
          end
          assert_match(/ready|capab|support/i, error.message)
        end
      end

      def test_lifecycle_merge_enforces_expected_head_atomically
        provider = build_provider(lifecycle_runner(merge_supported? ? :merge_ok : :merge_unsupported))
        if merge_supported?
          receipt = provider.merge_pull_request(number: 25, expected_head: HEAD_SHA, method: :squash)
          assert_equal :merge, receipt.operation
          assert_equal HEAD_SHA, receipt.pull_request.head_sha

          error = assert_raises(Ace::Git::ProviderExpectedHeadConflictError) do
            build_provider(lifecycle_runner(:merge_stale))
              .merge_pull_request(number: 25, expected_head: OTHER_SHA, method: :squash)
          end
          assert_match(/head|match/i, error.message)
        else
          error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
            provider.merge_pull_request(number: 25, expected_head: HEAD_SHA, method: :squash)
          end
          assert_match(/atomic|expected[- ]head|capab|support/i, error.message)
        end
      end

      def test_lifecycle_merge_rejects_unknown_methods
        provider = build_provider(lifecycle_runner(:find_single))
        assert_raises(ArgumentError) do
          provider.merge_pull_request(number: 25, expected_head: HEAD_SHA, method: :fast_forward)
        end
      end
    end
  end
end
