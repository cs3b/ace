# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/molecules/cleanup_pr_resolver"

class CleanupPrResolverTest < Minitest::Test
  def setup
    super
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge(
      "servers" => [{"name" => "forgejo-lab", "provider" => "cleanupfake", "url" => "https://forge.example.com/o/r"}]
    ))
    @resolver = Ace::Git::Worktree::Molecules::CleanupPrResolver.new(
      target: "main", target_sha: "main123", offline: false,
      server_name: "forgejo-lab", runner: ->(**_kw) { {success: true, stdout: "", stderr: "", exit_code: 0} }
    )
  end

  def teardown
    Ace::Git.reset_config!
    Ace::Git::Providers.reset!
    super
  end

  def with_registered_provider(evidence)
    # Providers.for instantiates with kwargs, so register a class that
    # ignores them and serves the fixture evidence.
    singleton = Class.new(Ace::Git::Providers::Base) do
      define_method(:pull_request_for_branch) { |branch:| evidence }
    end
    Ace::Git::Providers.register(:cleanupfake, singleton)
    yield
  ensure
    Ace::Git::Providers.reset!
  end

  def merged_evidence(number: 101, head_sha: "feat123", merge_commit_sha: "merge456", state: :merged, url: nil)
    Ace::Git::ProviderPullRequest.new(
      server_name: "forgejo-lab", number: number, title: "t", state: state,
      head_ref: "feature", base_ref: "main", head_sha: head_sha, author: "u",
      url: url, draft: false, merged_at: nil, head_repository_url: nil,
      base_repository_url: nil, merge_commit_sha: merge_commit_sha
    )
  end

  def test_offline_mode_retains_without_provider_resolution
    resolver = Ace::Git::Worktree::Molecules::CleanupPrResolver.new(
      target: "main", target_sha: "main123", offline: true
    )
    result = resolver.classify("feature", "feat123")
    assert_equal :no_pr, result[:status]
    assert_equal "provider_disabled", result[:retention_reason]
    assert_equal "retain", result[:action]
  end

  def test_no_prs_found_returns_unproven
    with_registered_provider(nil) do
      result = @resolver.classify("feature", "feat123")
      assert_equal :no_pr, result[:status]
      assert_equal "retain", result[:action]
      assert_equal "ancestry_unproven", result[:retention_reason]
    end
  end

  def test_exact_merged_pr_head_proof
    with_registered_provider(merged_evidence) do
      @resolver.stub(:ancestor?, true) do
        result = @resolver.classify("feature", "feat123")
        assert_equal :merged, result[:status]
        assert_equal "exact_merged_pr_head", result[:proof]
        assert_equal "remove", result[:action]
        assert_equal 101, result[:pr]
      end
    end
  end

  def test_stable_patch_equivalence_proof
    with_registered_provider(merged_evidence(head_sha: "oldfeat123")) do
      @resolver.stub(:ancestor?, true) do
        @resolver.stub(:patch_equivalent?, true) do
          result = @resolver.classify("feature", "newfeat456") # Different from head_sha
          assert_equal :merged, result[:status]
          assert_equal "stable_patch_equivalence", result[:proof]
          assert_equal "remove", result[:action]
          assert_equal 101, result[:pr]
        end
      end
    end
  end

  def test_patch_mismatch_returns_unproven
    with_registered_provider(merged_evidence(head_sha: "oldfeat123")) do
      @resolver.stub(:ancestor?, true) do
        @resolver.stub(:patch_equivalent?, false) do
          result = @resolver.classify("feature", "newfeat456")
          assert_equal :merged, result[:status]
          assert_nil result[:proof]
          assert_equal "retain", result[:action]
          assert_equal "patch_mismatch", result[:retention_reason]
        end
      end
    end
  end

  def test_open_pr_never_proves_removal
    with_registered_provider(merged_evidence(state: :open)) do
      result = @resolver.classify("feature", "feat123")
      assert_equal :open, result[:status]
      assert_equal "retain", result[:action]
    end
  end

  def test_closed_unmerged_pr_retains_candidate
    with_registered_provider(merged_evidence(state: :closed)) do
      result = @resolver.classify("feature", "feat123")
      assert_equal :closed_unmerged, result[:status]
      assert_equal "retain", result[:action]
    end
  end

  def test_unreachable_merge_commit_retains_candidate
    with_registered_provider(merged_evidence) do
      @resolver.stub(:ancestor?, false) do
        result = @resolver.classify("feature", "feat123")
        assert_equal :merged, result[:status]
        assert_equal "merge_commit_unreachable", result[:retention_reason]
        assert_equal "retain", result[:action]
      end
    end
  end

  def test_provider_authentication_failure_is_distinct_from_offline
    provider_class = Class.new(Ace::Git::Providers::Base) do
      def pull_request_for_branch(branch:)
        raise Ace::Git::ProviderAuthenticationError, "no auth"
      end
    end
    Ace::Git::Providers.register(:cleanupfake, provider_class)
    result = @resolver.classify("feature", "feat123")
    assert_equal :authentication_error, result[:status]
    assert_equal "retain", result[:action]
    assert_equal "provider_evidence_unavailable", result[:retention_reason]
  ensure
    Ace::Git::Providers.reset!
  end

  def test_unresolvable_server_yields_offline_without_mutation
    Ace::Git.instance_variable_set(:@config, {"servers" => []})
    result = @resolver.classify("feature", "feat123")
    assert_equal :offline, result[:status]
    assert_equal "retain", result[:action]
  end
end
