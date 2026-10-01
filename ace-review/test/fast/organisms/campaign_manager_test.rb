# frozen_string_literal: true
require "test_helper"
require_relative "../../campaign_fixtures"

class CampaignManagerTest < AceReviewTest
  include CampaignFixtures

  def setup
    super
    @head = "a" * 40
    @base = "b" * 40
  end

  def test_history_survives_heads_restart_and_unresolved_high_absent_from_later_reviews
    campaign = start_campaign
    first = round_input(1)
    make_campaign_session(campaign, first, finding: {})
    result = campaign_manager.record_round(campaign["campaign_id"], first)
    assert_equal 1, result["completed_rounds"]
    assert_equal 0, result["clean_streak"]
    @head = "c" * 40
    result = campaign_manager.status(campaign["campaign_id"])
    refute result["evidence"]["valid"]
    assert_equal "a" * 40, result["evidence"]["source_head"]
    [2, 3].each do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 3
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    result = campaign_manager.finish(campaign["campaign_id"])
    assert_equal 3, result["completed_rounds"]
    assert_equal 2, result["clean_streak"]
    assert result["search_converged"]
    assert result["evidence"]["valid"]
    refute result["accepted"]
    assert_equal 1, result["open_findings"].size
  end

  def test_resolved_high_is_not_clean_and_reopening_uses_new_occurrence
    campaign = start_campaign
    input = round_input(1)
    dir = make_campaign_session(campaign, input, finding: {"status" => "done", "resolution" => "Repaired invariant"})
    result = campaign_manager.record_round(campaign["campaign_id"], input)
    assert_equal 0, result["clean_streak"]
    assert_empty result["open_findings"]
    reopened = round_input(2)
    make_campaign_session(campaign, reopened, finding: {})
    reopened["dispositions"][0].merge!("finding_id" => "#{dir}#finding", "disposition" => "reopened")
    result = campaign_manager.record_round(campaign["campaign_id"], reopened)
    assert_equal "reopened", result["open_findings"][0]["disposition"]
  end

  def test_three_clean_rounds_need_actual_current_approval_checks_and_report_integrity
    campaign = start_campaign
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    result = campaign_manager.finish(campaign["campaign_id"])
    assert result["accepted"], result["reasons"].inspect
    File.delete(File.join(@test_dir, result["rounds"].last["sessions"].first["reports"].first["artifact"]["path"]))
    result = campaign_manager.status(campaign["campaign_id"])
    refute result["accepted"]
    refute result["evidence"]["available"]
    assert_equal 3, result["completed_rounds"]
  end

  def test_partial_scope_restart_idempotence_conflict_and_missing_report
    campaign = start_campaign(scopes: %w[one two])
    input = round_input(1, scopes: %w[one two])
    make_campaign_session(campaign, input, scope: "one")
    result = campaign_manager.record_round(campaign["campaign_id"], input)
    assert_equal 0, result["completed_rounds"]
    assert_equal 2, campaign_manager.status(campaign["campaign_id"])["counters"]["recording_attempts"]
    assert campaign_manager.record_round(campaign["campaign_id"], input)["replayed"]
    assert_raises(ArgumentError) do
      campaign_manager.record_round(campaign["campaign_id"], input.merge("head" => "c" * 40))
    end
    complete = Marshal.load(Marshal.dump(input))
    complete["attempt_id"] = "completion"
    make_campaign_session(campaign, complete, scope: "two")
    result = campaign_manager.record_round(campaign["campaign_id"], complete)
    assert_equal 1, result["completed_rounds"]
    assert_equal 2, result["counters"]["provider_calls"]
    missing = round_input(2, scopes: %w[one two])
    dir = make_campaign_session(campaign, missing, scope: "one")
    File.delete(File.join(@test_dir, dir, "review-report-reviewer.md"))
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], missing) }
    assert_equal 1, campaign_manager.status(campaign["campaign_id"])["completed_rounds"]
  end

  def test_partial_high_keeps_completed_round_nonclean_even_when_repaired_before_coverage_finishes
    campaign = start_campaign(scopes: %w[one two])
    input = round_input(1, scopes: %w[one two])
    make_campaign_session(campaign, input, scope: "one", finding: {"status" => "done", "resolution" => "Repaired"})
    result = campaign_manager.record_round(campaign["campaign_id"], input)
    assert_equal 0, result["completed_rounds"]
    input["attempt_id"] = "complete"
    make_campaign_session(campaign, input, scope: "two")
    result = campaign_manager.record_round(campaign["campaign_id"], input)
    assert_equal 1, result["completed_rounds"]
    assert_equal 0, result["clean_streak"]
  end

  def test_noop_failed_and_empty_attempts_never_count
    campaign = start_campaign
    [{noop: true}, {failed: true}, nil].each_with_index do |mode, n|
      input = round_input(n)
      make_campaign_session(campaign, input, **mode) if mode
      result = campaign_manager.record_round(campaign["campaign_id"], input)
      assert_equal 0, result["completed_rounds"]
      assert_equal 0, result["clean_streak"]
    end
  end

  def test_missing_earlier_counted_report_blocks_acceptance_without_erasing_rounds
    campaign = start_campaign
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    result = campaign_manager.finish(campaign["campaign_id"])
    assert result["accepted"]
    File.delete(File.join(@test_dir, result["rounds"].first["sessions"].first["reports"].first["artifact"]["path"]))
    result = campaign_manager.status(campaign["campaign_id"])
    refute result["accepted"]
    assert_equal 3, result["completed_rounds"]
    assert_equal 3, result["clean_streak"]
  end

  def test_partial_attempt_and_earlier_approval_sources_remain_required_after_convergence
    campaign = start_campaign(scopes: %w[one two])
    3.times do |n|
      input = round_input(n, scopes: %w[one two])
      %w[one two].each { |scope| make_campaign_session(campaign, input, scope: scope) }
      add_campaign_approval(campaign, input) if n == 0 || n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    partial = round_input(3, scopes: %w[one two])
    make_campaign_session(campaign, partial, scope: "one")
    campaign_manager.record_round(campaign["campaign_id"], partial)
    result = campaign_manager.finish(campaign["campaign_id"])
    assert result["accepted"], result["reasons"].inspect
    partial_report = result["attempts"].last["sessions"].first["reports"].first["artifact"]["path"]
    earlier_approval = result["rounds"].first["approval"]["artifact"]["path"]
    [partial_report, earlier_approval].each do |relative|
      path = File.join(@test_dir, relative)
      bytes = File.binread(path)
      File.delete(path)
      blocked = campaign_manager.finish(campaign["campaign_id"])
      refute blocked["accepted"]
      refute blocked["evidence"]["available"]
      assert_equal 3, blocked["completed_rounds"]
      assert_equal 3, blocked["clean_streak"]
      assert_equal result["counters"], blocked["counters"]
      File.binwrite(path, bytes)
      assert campaign_manager.status(campaign["campaign_id"])["accepted"]
    end
  end

  def test_contract_successor_retains_findings_and_same_contract_reuses_identity
    campaign = start_campaign
    input = round_input(1)
    make_campaign_session(campaign, input, finding: {})
    campaign_manager.record_round(campaign["campaign_id"], input)
    @head = "c" * 40
    assert_equal campaign["campaign_id"], start_campaign["campaign_id"]
    assert_raises(ArgumentError) do
      campaign_manager.start(subject: campaign_subject, contract: "New requirements", policy: campaign_policy)
    end
    successor = campaign_manager.start(subject: campaign_subject, contract: "New requirements", policy: campaign_policy,
      reason: "Requirement invariant changed")
    assert_equal campaign["campaign_id"], successor["predecessor"]
    assert_equal 1, successor["open_findings"].size
    assert_raises(ArgumentError) do
      campaign_manager.start(subject: campaign_subject, contract: "Frozen requirements",
        policy: campaign_policy.merge("minimum_rounds" => 4))
    end
  end

  def test_self_approval_fabricated_counts_mixed_head_and_unverified_feedback_fail_closed
    campaign = start_campaign
    input = round_input(1)
    make_campaign_session(campaign, input)
    add_campaign_approval(campaign, input, producer: "reviewer")
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], input) }
    input.delete("approval")
    assert_raises(ArgumentError) do
      campaign_manager.record_round(campaign["campaign_id"], input.merge("search_converged" => true))
    end
    assert_raises(ArgumentError) do
      campaign_manager.record_round(campaign["campaign_id"], input.merge("head" => "c" * 40))
    end
    bad = round_input(2)
    make_campaign_session(campaign, bad, finding: {"status" => "draft"})
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], bad) }
    assert_equal 0, campaign_manager.status(campaign["campaign_id"])["completed_rounds"]
  end

  def test_pr_status_uses_live_provider_head_and_unavailable_source_stays_blocked
    manager = Ace::Review::Organisms::CampaignManager.new(repo_root: @test_dir)
    subject = {"repository" => "https://github.com/owner/repo", "pr" => "owner/repo#42"}
    metadata = {success: true, metadata: {"url" => "https://github.com/owner/repo/pull/42",
      "headRefOid" => "c" * 40, "baseRefOid" => @base}}
    campaign = Ace::Review::Molecules::GhPrFetcher.stub(:fetch_metadata, metadata) do
      manager.start(subject: subject, contract: "requirements", policy: campaign_policy)
    end
    assert_equal "c" * 40, campaign["evidence"]["current_head"]
    status = Ace::Review::Molecules::GhPrFetcher.stub(:fetch_metadata, {success: false, error: "source unavailable"}) do
      manager.status(campaign["campaign_id"])
    end
    refute status["accepted"]
    assert_includes status["reasons"], "source unavailable"
    assert_raises(ArgumentError) do
      manager.start(subject: subject.merge("repository" => "https://forge.invalid/owner/repo"),
        contract: "requirements", policy: campaign_policy)
    end
  end

  def test_concurrent_start_record_and_dry_run_preserve_single_history
    before = Dir.glob(File.join(@test_dir, "**/*"), File::FNM_DOTMATCH)
    preview = campaign_manager.start(subject: campaign_subject, contract: "Frozen requirements", policy: campaign_policy,
      dry_run: true)
    assert_equal before, Dir.glob(File.join(@test_dir, "**/*"), File::FNM_DOTMATCH)
    campaigns = 4.times.map { Thread.new { start_campaign } }.map(&:value)
    assert_equal 1, campaigns.map { |c| c["campaign_id"] }.uniq.size
    campaign = campaigns.first
    input = round_input(1)
    make_campaign_session(campaign, input)
    results = 4.times.map { Thread.new { campaign_manager.record_round(campaign["campaign_id"], input) } }.map(&:value)
    assert results.all? { |r| r["completed_rounds"] == 1 }
    record = File.read(campaign_manager.store.path(campaign["campaign_id"]))
    campaign_manager.finish(campaign["campaign_id"], dry_run: true)
    assert_equal record, File.read(campaign_manager.store.path(campaign["campaign_id"]))
    assert preview["dry_run"]
  end
end
