# frozen_string_literal: true

require "test_helper"

module Providers
  # The Base contract is the core boundary: it must never execute provider
  # commands itself, and every contract method demands a real implementation.
  class BaseTest < AceGitTestCase
    def setup
      super
      @server = Ace::Git::ResolvedServer.new(name: "s", provider: :fakeforge, url: "https://s.example.com")
      @base = Ace::Git::Providers::Base.new(server: @server)
    end

    def test_holds_server_identity_and_default_timeout
      assert_equal @server, @base.server
      assert_equal Ace::Git.network_timeout, @base.timeout
    end

    def test_timeout_override
      base = Ace::Git::Providers::Base.new(server: @server, timeout: 5)
      assert_equal 5, base.timeout
    end

    def test_contract_methods_are_abstract
      methods = {
        available?: {},
        check_available!: {},
        authenticated?: {},
        check_authenticated!: {},
        pull_request: {number: 1},
        pull_request_for_branch: {branch: "main"},
        pull_request_diff: {number: 1},
        recent_pull_requests: {limit: 5},
        issue: {number: 1},
        checks: {ref: "main"},
        repository: {},
        find_open_pull_requests: {
          head_repository_url: "https://s.example.com/o/r", head_ref: "feature",
          base_repository_url: "https://s.example.com/o/r", base_ref: "main"
        },
        create_pull_request: {
          head_ref: "feature", head_repository_url: "https://s.example.com/o/r",
          base_ref: "main", expected_head: "a" * 40, title: "t"
        },
        update_pull_request: {number: 1, expected_head: "a" * 40},
        ready_pull_request: {number: 1, expected_head: "a" * 40},
        merge_pull_request: {number: 1, expected_head: "a" * 40, method: :squash}
      }

      methods.each do |method_name, kwargs|
        error = assert_raises(NotImplementedError, "#{method_name} must be abstract") do
          if kwargs.empty?
            @base.public_send(method_name)
          else
            @base.public_send(method_name, **kwargs)
          end
        end
        assert_match(/must implement/, error.message)
      end
    end

    def test_lifecycle_receipt_serializes_evidence_without_idempotency_for_non_create
      pr = Ace::Git::ProviderPullRequest.new(
        server_name: "s", number: 7, title: "t", state: :open, head_ref: "f", body: nil,
        base_ref: "main", head_sha: "a" * 40, author: "u", url: nil, draft: true,
        merged_at: nil, head_repository_url: "https://s.example.com/o/r",
        base_repository_url: "https://s.example.com/o/r", merge_commit_sha: nil
      )
      receipt = Ace::Git::ProviderMutationReceipt.new(
        server_name: "s", operation: :merge, pull_request: pr, idempotency: nil
      )
      assert_equal :merge, receipt.to_h[:operation]
      assert_nil receipt.to_h[:idempotency]
      assert_equal 7, receipt.to_h[:pull_request][:number]
      assert_equal "https://s.example.com/o/r", receipt.to_h[:pull_request][:head_repository_url]
    end

    def test_cleanup_proof_only_merged_status_confirms_remote_merge
      proof = Ace::Git::ProviderCleanupProof.new(
        server_name: "s", status: :merged, pr_number: 7, pr_url: nil,
        head_sha: "a" * 40, merge_commit_sha: "b" * 40
      )
      offline = Ace::Git::ProviderCleanupProof.new(
        server_name: "s", status: :offline, pr_number: nil, pr_url: nil,
        head_sha: nil, merge_commit_sha: nil
      )
      assert proof.merged?
      refute offline.merged?
      assert Ace::Git::CLEANUP_PROOF_STATUSES.include?(offline.status)
    end
  end
end
