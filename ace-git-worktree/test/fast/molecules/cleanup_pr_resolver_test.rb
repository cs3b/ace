# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/molecules/cleanup_pr_resolver"

class CleanupPrResolverTest < Minitest::Test
  def setup
    super
    
    # Ensure gh is considered available for most tests
    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :gh_authenticated?, true do
        @resolver = Ace::Git::Worktree::Molecules::CleanupPrResolver.new(
          target: "main", target_sha: "main123", offline: false
        )
      end
    end
  end

  def test_offline_mode_returns_offline_result
    resolver = Ace::Git::Worktree::Molecules::CleanupPrResolver.new(
      target: "main", target_sha: "main123", offline: true
    )
    result = resolver.classify("feature", "feat123")
    assert_equal "none", result[:proof]
    assert_equal "offline", result[:provider_status]
  end

  def test_no_prs_found_returns_unproven
    @resolver.stub(:fetch_merged_prs_for_branch, []) do
      result = @resolver.classify("feature", "feat123")
      assert_equal "none", result[:proof]
      assert_equal "available", result[:provider_status]
      assert_equal "ancestry_unproven", result[:retention_reason]
    end
  end

  def test_exact_merged_pr_head_proof
    pr_data = [{
      "baseRefName" => "main",
      "state" => "MERGED",
      "number" => 101,
      "headRefOid" => "feat123",
      "mergeCommit" => {"oid" => "merge456"}
    }]

    @resolver.stub(:fetch_merged_prs_for_branch, pr_data) do
      @resolver.stub(:ancestor?, true) do
        result = @resolver.classify("feature", "feat123")
        assert_equal "exact_merged_pr_head", result[:proof]
        assert_equal "remove", result[:action]
        assert_equal 101, result[:pr]
      end
    end
  end

  def test_stable_patch_equivalence_proof
    pr_data = [{
      "baseRefName" => "main",
      "state" => "MERGED",
      "number" => 101,
      "headRefOid" => "oldfeat123",
      "mergeCommit" => {"oid" => "merge456"}
    }]

    @resolver.stub(:fetch_merged_prs_for_branch, pr_data) do
      @resolver.stub(:ancestor?, true) do
        @resolver.stub(:patch_equivalent?, true) do
          result = @resolver.classify("feature", "newfeat456") # Different from headRefOid
          assert_equal "stable_patch_equivalence", result[:proof]
          assert_equal "remove", result[:action]
          assert_equal 101, result[:pr]
        end
      end
    end
  end

  def test_patch_mismatch_returns_unproven
    pr_data = [{
      "baseRefName" => "main",
      "state" => "MERGED",
      "number" => 101,
      "headRefOid" => "oldfeat123",
      "mergeCommit" => {"oid" => "merge456"}
    }]

    @resolver.stub(:fetch_merged_prs_for_branch, pr_data) do
      @resolver.stub(:ancestor?, true) do
        @resolver.stub(:patch_equivalent?, false) do
          result = @resolver.classify("feature", "newfeat456")
          assert_equal "none", result[:proof]
          assert_equal "retain", result[:action]
          assert_equal "patch_mismatch", result[:retention_reason]
        end
      end
    end
  end

  def test_wrong_target_returns_unproven
    pr_data = [{
      "baseRefName" => "develop", # Wrong base
      "state" => "MERGED",
      "number" => 101,
      "headRefOid" => "feat123",
      "mergeCommit" => {"oid" => "merge456"}
    }]

    @resolver.stub(:fetch_merged_prs_for_branch, pr_data) do
      result = @resolver.classify("feature", "feat123")
      assert_equal "none", result[:proof]
      assert_equal "ancestry_unproven", result[:retention_reason]
    end
  end

  def test_ambiguous_prs_returns_unproven
    pr_data = [
      {
        "baseRefName" => "develop", # Not valid
        "state" => "MERGED",
        "number" => 101,
        "headRefOid" => "feat123",
        "mergeCommit" => {"oid" => "merge456"}
      },
      {
        "baseRefName" => "staging", # Not valid
        "state" => "MERGED",
        "number" => 102,
        "headRefOid" => "feat123",
        "mergeCommit" => {"oid" => "merge789"}
      }
    ]

    @resolver.stub(:fetch_merged_prs_for_branch, pr_data) do
      result = @resolver.classify("feature", "feat123")
      assert_equal "none", result[:proof]
      assert_equal "ambiguous", result[:provider_status]
      assert_equal "ambiguous_prs", result[:retention_reason]
    end
  end
end
