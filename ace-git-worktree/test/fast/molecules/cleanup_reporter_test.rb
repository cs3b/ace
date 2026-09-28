# frozen_string_literal: true

require "test_helper"
require "json"
require "ace/git/worktree/molecules/cleanup_reporter"

class CleanupReporterTest < Minitest::Test
  def setup
    super
    @reporter = Ace::Git::Worktree::Molecules::CleanupReporter.new(
      target: "main", remote: "origin", offline: true
    )
  end

  # --- Common dir resolution ---

  def test_report_fails_without_common_dir
    @reporter.stub(:resolve_common_dir, nil) do
      result = @reporter.report
      assert_equal false, result[:success]
      assert_includes result[:error], "common git directory"
    end
  end

  def test_report_fails_without_target_ref
    @reporter.stub(:resolve_common_dir, "/repo/.git") do
      @reporter.stub(:resolve_ref, nil) do
        result = @reporter.report
        assert_equal false, result[:success]
        assert_includes result[:error], "Cannot resolve target ref"
      end
    end
  end

  # --- Successful report ---

  def test_successful_report_has_expected_schema
    stub_successful_report do
      result = @reporter.report
      assert_equal true, result[:success]
      assert_equal "1.0", result[:schema_version]
      assert_equal "main", result[:target][:ref]
      assert_equal "abc123", result[:target][:sha]
      assert_equal "origin", result[:remote][:name]
      assert_equal "offline", result[:refresh][:status]
      assert result.key?(:worktrees)
      assert result.key?(:local_refs)
      assert result.key?(:remote_refs)
      assert result.key?(:actions)
      assert result.key?(:plan_digest)
    end
  end

  # --- Worktree classification ---

  def test_primary_worktree_retained
    stub_successful_report(
      worktrees: [worktree_entry("/repo", "main", "abc123", primary: true)]
    ) do
      result = @reporter.report
      wt = result[:worktrees].first
      assert_equal "retain", wt[:action]
      assert_equal "primary_checkout", wt[:retention_reason]
    end
  end

  def test_locked_worktree_retained
    stub_successful_report(
      worktrees: [worktree_entry("/repo/feature", "feature", "def456", locked: true)]
    ) do
      result = @reporter.report
      wt = result[:worktrees].first
      assert_equal "retain", wt[:action]
      assert_equal "locked", wt[:retention_reason]
    end
  end

  def test_dirty_worktree_retained
    stub_successful_report(
      worktrees: [worktree_entry("/repo/feature", "feature", "def456",
        dirty: {staged: ["file.rb"], unstaged: [], untracked: []})]
    ) do
      result = @reporter.report
      wt = result[:worktrees].first
      assert_equal "retain", wt[:action]
      assert_equal "dirty", wt[:retention_reason]
    end
  end

  def test_ancestor_worktree_removed
    stub_successful_report(
      worktrees: [worktree_entry("/repo/merged", "merged", "aaa111")],
      ancestry_map: {"aaa111" => true}
    ) do
      result = @reporter.report
      wt = result[:worktrees].first
      assert_equal "remove", wt[:action]
      assert_equal "ancestor", wt[:ancestry]
    end
  end

  def test_unproven_worktree_retained
    stub_successful_report(
      worktrees: [worktree_entry("/repo/feature", "feature", "bbb222")],
      ancestry_map: {"bbb222" => false}
    ) do
      result = @reporter.report
      wt = result[:worktrees].first
      assert_equal "retain", wt[:action]
      assert_equal "ancestry_unproven", wt[:retention_reason]
    end
  end

  # --- Ref classification ---

  def test_protected_local_ref_retained
    stub_successful_report(
      local_refs: [{name: "main", sha: "abc123", upstream: nil, protected: true,
                    ancestry: nil, action: nil, retention_reason: nil}]
    ) do
      result = @reporter.report
      ref = result[:local_refs].first
      assert_equal "retain", ref[:action]
      assert_equal "protected", ref[:retention_reason]
    end
  end

  def test_ancestor_local_ref_removed
    stub_successful_report(
      local_refs: [{name: "merged-branch", sha: "ccc333", upstream: nil, protected: false,
                    ancestry: nil, action: nil, retention_reason: nil}],
      ancestry_map: {"ccc333" => true}
    ) do
      result = @reporter.report
      ref = result[:local_refs].first
      assert_equal "remove", ref[:action]
      assert_equal "ancestor", ref[:ancestry]
    end
  end

  def test_unproven_local_ref_retained
    stub_successful_report(
      local_refs: [{name: "feature", sha: "ddd444", upstream: nil, protected: false,
                    ancestry: nil, action: nil, retention_reason: nil}],
      ancestry_map: {"ddd444" => false}
    ) do
      result = @reporter.report
      ref = result[:local_refs].first
      assert_equal "retain", ref[:action]
      assert_equal "ancestry_unproven", ref[:retention_reason]
    end
  end

  # --- Action plan ordering ---

  def test_action_plan_orders_worktrees_then_local_then_remote
    stub_successful_report(
      worktrees: [worktree_entry("/repo/wt1", "wt1", "aaa111")],
      local_refs: [{name: "local1", sha: "bbb222", upstream: nil, protected: false,
                    ancestry: nil, action: nil, retention_reason: nil}],
      remote_refs: [{name: "origin/remote1", short_name: "remote1", sha: "ccc333",
                     protected: false, ancestry: nil, action: nil, retention_reason: nil}],
      ancestry_map: {"aaa111" => true, "bbb222" => true, "ccc333" => true}
    ) do
      result = @reporter.report
      actions = result[:actions]
      assert_equal 3, actions.length
      assert_equal "remove_worktree", actions[0][:type]
      assert_equal "delete_local_ref", actions[1][:type]
      assert_equal "delete_remote_ref", actions[2][:type]
    end
  end

  # --- Digest stability ---

  def test_repeated_report_produces_same_digest
    stub_successful_report(
      worktrees: [worktree_entry("/repo/wt1", "wt1", "aaa111")],
      ancestry_map: {"aaa111" => true}
    ) do
      result1 = @reporter.report
      result2 = @reporter.report
      assert_equal result1[:plan_digest], result2[:plan_digest]
    end
  end

  def test_changed_provider_proof_invalidates_digest
    # Same inventory, different provider proof (no_pr vs confirmed merged):
    # the approved digest must change because the proof is part of consent.
    def report_with_proof(status, pr, merged_head)
      @reporter.stub(:resolve_common_dir, "/repo/.git") do
        @reporter.stub(:resolve_ref, ->(ref) { ref == "main" ? "abc123" : nil }) do
          @reporter.stub(:inventory_worktrees, [worktree_entry("/repo/wt1", "wt1", "aaa111")]) do
            @reporter.stub(:inventory_local_refs, []) do
              @reporter.stub(:inventory_remote_refs, []) do
                @reporter.stub(:ancestor?, ->(_candidate, _target) { false }) do
                  mock_resolver = Object.new
                  mock_resolver.define_singleton_method(:classify) do |_branch, _sha|
                    {status: status, proof: status == :merged ? "exact_merged_pr_head" : nil,
                     pr: pr, pr_url: nil, candidate_head: nil, merged_head: merged_head,
                     merge_commit: status == :merged ? "m1" : nil, target_reachable: status == :merged,
                     provider_status: "available",
                     action: status == :merged ? "remove" : "retain",
                     retention_reason: status == :merged ? nil : "ancestry_unproven"}
                  end
                  mock_resolver.define_singleton_method(:resolved_server) { nil }
                  Ace::Git::Worktree::Molecules::CleanupPrResolver.stub :new, mock_resolver do
                    @reporter.report[:plan_digest]
                  end
                end
              end
            end
          end
        end
      end
    end

    digest_no_pr = report_with_proof(:no_pr, nil, nil)
    digest_merged = report_with_proof(:merged, 25, "head1")
    refute_equal digest_no_pr, digest_merged, "changed provider proof must invalidate the approved digest"
  end

  def test_different_state_produces_different_digest
    digest1 = nil
    stub_successful_report(
      worktrees: [worktree_entry("/repo/wt1", "wt1", "aaa111")],
      ancestry_map: {"aaa111" => true}
    ) do
      digest1 = @reporter.report[:plan_digest]
    end

    digest2 = nil
    stub_successful_report(
      worktrees: [worktree_entry("/repo/wt1", "wt1", "aaa111"),
                  worktree_entry("/repo/wt2", "wt2", "bbb222")],
      ancestry_map: {"aaa111" => true, "bbb222" => false}
    ) do
      digest2 = @reporter.report[:plan_digest]
    end

    refute_equal digest1, digest2
  end

  # --- Offline mode ---

  def test_offline_mode_skips_remote_refresh
    stub_successful_report do
      result = @reporter.report
      assert_equal "offline", result[:refresh][:status]
    end
  end

  private

  def worktree_entry(path, branch, sha, primary: false, locked: false, dirty: nil)
    {
      path: path,
      sha: sha,
      branch: branch,
      primary: primary,
      bare: false,
      detached: false,
      locked: locked,
      lock_reason: nil,
      prunable: false,
      dirty: dirty,
      protected: primary || locked,
      ancestry: nil,
      action: nil,
      retention_reason: nil
    }
  end

  def stub_successful_report(worktrees: [], local_refs: [], remote_refs: [], ancestry_map: {})
    @reporter.stub(:resolve_common_dir, "/repo/.git") do
      # resolve_ref returns target sha for "main", remote sha for "origin/main"
      resolve_ref_impl = ->(ref) {
        case ref
        when "main" then "abc123"
        when "origin/main" then "abc123"
        else nil
        end
      }
      @reporter.stub(:resolve_ref, resolve_ref_impl) do
        @reporter.stub(:inventory_worktrees, worktrees) do
          @reporter.stub(:inventory_local_refs, local_refs) do
            @reporter.stub(:inventory_remote_refs, remote_refs) do
              ancestor_impl = ->(candidate, _target) { ancestry_map.fetch(candidate, false) }
              @reporter.stub(:ancestor?, ancestor_impl) do
                # Stub PR Resolver
                mock_resolver = Object.new
                def mock_resolver.classify(branch, sha)
                  {
                    status: :offline,
                    proof: nil,
                    pr: nil,
                    pr_url: nil,
                    candidate_head: nil,
                    merged_head: nil,
                    merge_commit: nil,
                    target_reachable: "unknown",
                    provider_status: "offline",
                    action: "retain",
                    retention_reason: "ancestry_unproven"
                  }
                end

                def mock_resolver.resolved_server
                  nil
                end
                
                Ace::Git::Worktree::Molecules::CleanupPrResolver.stub :new, mock_resolver do
                  yield
                end
              end
            end
          end
        end
      end
    end
  end
end
