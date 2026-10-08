# frozen_string_literal: true
require "test_helper"
require_relative "../../campaign_fixtures"

class CampaignManagerTest < AceReviewTest
  include CampaignFixtures

  def setup
    super
    @head = "a" * 40
    @base = "b" * 40
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge(
      "servers" => [{"name" => "public", "provider" => "github", "url" => "https://github.com/owner/repo"}]
    ))
  end

  def teardown
    Ace::Git.reset_config!
    super
  end

  def test_parent_registration_requires_exact_active_contract
    campaign = start_campaign
    manager = campaign_manager
    args = {subject: campaign["subject"], contract_identity: campaign["contract_identity"], policy: campaign["effective_policy"]}
    id = campaign.fetch("campaign_id")
    assert_raises(ArgumentError) { manager.with_campaign_registration!(id, **args) }
    assert_equal id, manager.with_campaign_registration!(id, **args) { |value| assert value.frozen?; value.fetch("campaign_id") }
    assert_raises(ArgumentError) { manager.with_campaign_registration!(id, **args.merge(contract_identity: "e" * 64)) { flunk } }
    manager.start(subject: campaign_subject, contract: "New requirements", policy: campaign_policy, reason: "Changed requirement")
    assert_raises(ArgumentError) { manager.with_campaign_registration!(id, **args) { flunk } }
  end

  def test_execution_round_guard_requires_current_pinned_incomplete_round
    campaign = start_campaign
    id = campaign.fetch("campaign_id")
    manager = campaign_manager
    assert_raises(ArgumentError) { manager.with_execution_round!(id, round_id: "round-1") { flunk } }
    input = round_input(1)
    manager.record_round(id, input.merge("attempt_id" => "pin-1"))
    assert_raises(ArgumentError) { manager.with_execution_round!(id, round_id: "round-1") }
    result = manager.with_execution_round!(id, round_id: "round-1") do |value|
      assert_equal input.fetch("scope_identity"), value.fetch("binding").fetch("scope_identity")
      assert value.fetch("binding").frozen?
      File.open(File.join(manager.store.root, ".lock"), File::RDWR) do |lock|
        refute lock.flock(File::LOCK_EX | File::LOCK_NB)
      end
      :registered
    end
    assert_equal :registered, result
    @head = "e" * 40
    assert_raises(ArgumentError) { manager.with_execution_round!(id, round_id: "round-1") { flunk } }
    @head = input.fetch("head")
    make_campaign_session(campaign, input)
    manager.record_round(id, input)
    assert_raises(ArgumentError) { manager.with_execution_round!(id, round_id: "round-1") { flunk } }
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

  def test_verified_result_guard_holds_lock_and_releases_after_exception
    campaign = start_campaign
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    result = campaign_manager.finish(campaign["campaign_id"])
    args = {result: result, subject: result["subject"], contract_identity: result["contract_identity"],
      policy: result["effective_policy"], head: @head, base: @base, producer: "worker", reviewer: "reviewer"}
    manager = campaign_manager
    assert_raises(ArgumentError) { manager.with_verified_result!(**args) }
    lock_path = File.join(manager.store.root, ".lock")
    assert_raises(RuntimeError) do
      manager.with_verified_result!(**args) do |current|
        assert current.frozen?
        assert current["rounds"].last["approval"]["report_models"].first.frozen?
        File.open(lock_path, File::RDWR) { |lock| refute lock.flock(File::LOCK_EX | File::LOCK_NB) }
        raise "consumer failed"
      end
    end
    File.open(lock_path, File::RDWR) { |lock| assert lock.flock(File::LOCK_EX | File::LOCK_NB) }
    assert_equal :consumed, manager.with_verified_result!(**args) { :consumed }
    {head: "c" * 40, base: "c" * 40, producer: "other", reviewer: "other", contract_identity: "f" * 64,
      policy: result["effective_policy"].merge("minimum_rounds" => 4)}.each do |key, value|
      assert_raises(ArgumentError) { manager.with_verified_result!(**args.merge(key => value)) { flunk "invalid binding yielded" } }
    end
    [result.merge("dry_run" => true), result.merge("result_identity" => "f" * 64)].each do |invalid|
      assert_raises(ArgumentError) { manager.with_verified_result!(**args.merge(result: invalid)) { flunk "invalid result yielded" } }
    end
    File.unlink(lock_path)
    assert_raises(ArgumentError) { manager.with_verified_result!(**args) { flunk "missing lock yielded" } }

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
    original_head = @head
    @head = nil
    assert_equal false, campaign_manager.status(campaign["campaign_id"])["evidence"]["valid"]
    @head = original_head
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

  def test_missing_current_counted_report_blocks_acceptance_without_erasing_rounds
    campaign = start_campaign
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    result = campaign_manager.finish(campaign["campaign_id"])
    assert result["accepted"]
    # Earlier rounds' session files age legitimately (historical authority is
    # journal-backed); the current round's report must stay verifiable.
    File.delete(File.join(@test_dir, result["rounds"].first["sessions"].first["reports"].first["artifact"]["path"]))
    result = campaign_manager.status(campaign["campaign_id"])
    assert result["accepted"]
    File.delete(File.join(@test_dir, result["rounds"].last["sessions"].first["reports"].first["artifact"]["path"]))
    result = campaign_manager.status(campaign["campaign_id"])
    refute result["accepted"]
    assert_equal 3, result["completed_rounds"]
    assert_equal 3, result["clean_streak"]
  end

  def test_current_sources_stay_strict_while_partial_and_earlier_authority_is_journal_backed
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
    # Partial and earlier authority is validated by journal-backed historical
    # reads, so their working files may age without blocking acceptance.
    [partial_report, earlier_approval].each do |relative|
      path = File.join(@test_dir, relative)
      bytes = File.binread(path)
      File.delete(path)
      still_accepted = campaign_manager.finish(campaign["campaign_id"])
      assert still_accepted["accepted"], still_accepted["reasons"].inspect
      File.binwrite(path, bytes)
    end
    # The current round's own evidence stays strictly verified.
    current_report = result["rounds"].last["sessions"].first["reports"].first["artifact"]["path"]
    path = File.join(@test_dir, current_report)
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
    metadata = {success: true, metadata: {"url" => "https://github.com/Owner/Repo/pull/42",
      "headRefOid" => "c" * 40, "baseRefOid" => @base}}
    campaign = with_pr_result(metadata) do
      manager.start(subject: subject, contract: "requirements", policy: campaign_policy)
    end
    assert_equal "c" * 40, campaign["evidence"]["current_head"]
    status = with_pr_result(success: false, error: "source unavailable") do
      manager.status(campaign["campaign_id"])
    end
    refute status["accepted"]
    assert status["reasons"].any? { |reason| reason.include?("source unavailable") }
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
    bytes = File.binread(campaign_manager.store.path(campaign["campaign_id"]))
    reused_preview = campaign_manager.start(subject: campaign_subject, contract: "Frozen requirements",
      policy: campaign_policy, dry_run: true)
    assert reused_preview["dry_run"]
    assert_equal campaign["campaign_id"], reused_preview["campaign_id"]
    assert_equal bytes, File.binread(campaign_manager.store.path(campaign["campaign_id"]))
    input = round_input(1)
    make_campaign_session(campaign, input)
    results = 4.times.map { Thread.new { campaign_manager.record_round(campaign["campaign_id"], input) } }.map(&:value)
    assert results.all? { |r| r["completed_rounds"] == 1 }
    record = File.read(campaign_manager.store.path(campaign["campaign_id"]))
    campaign_manager.finish(campaign["campaign_id"], dry_run: true)
    assert_equal record, File.read(campaign_manager.store.path(campaign["campaign_id"]))
    assert preview["dry_run"]
  end
  def test_later_partial_resolved_high_invalidates_earlier_approval_until_completed_reviews
    campaign = start_campaign(scopes: %w[one two])
    3.times do |n|
      input = round_input(n, scopes: %w[one two])
      %w[one two].each { |scope| make_campaign_session(campaign, input, scope: scope) }
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    assert campaign_manager.finish(campaign["campaign_id"])["accepted"]
    partial = round_input(3, scopes: %w[one two])
    make_campaign_session(campaign, partial, scope: "one", finding: {"status" => "done", "resolution" => "Fixed"})
    blocked = campaign_manager.record_round(campaign["campaign_id"], partial)
    refute blocked["accepted"]
    refute blocked["evidence"]["valid"]
    assert_equal 3, blocked["completed_rounds"]
    assert_equal 0, blocked["clean_streak"]
    assert_empty blocked["open_findings"]
    partial["attempt_id"] = "complete-later"
    make_campaign_session(campaign, partial, scope: "two")
    complete = campaign_manager.record_round(campaign["campaign_id"], partial)
    assert_equal 0, complete["clean_streak"]
    [4, 5].each do |n|
      input = round_input(n, scopes: %w[one two])
      %w[one two].each { |scope| make_campaign_session(campaign, input, scope: scope) }
      add_campaign_approval(campaign, input) if n == 5
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    assert campaign_manager.finish(campaign["campaign_id"])["accepted"]
  end

  def test_superseded_contract_preserves_history_but_cannot_regain_acceptance
    campaign = start_campaign
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    assert campaign_manager.finish(campaign["campaign_id"])["accepted"]
    successor = campaign_manager.start(subject: campaign_subject, contract: "Changed requirement",
      policy: campaign_policy, reason: "Requirement changed")
    old = campaign_manager.finish(campaign["campaign_id"])
    refute old["accepted"]
    refute old["active_contract"]
    assert_equal successor["campaign_id"], old["superseded_by"]
    assert_equal 3, old["completed_rounds"]
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], round_input(4)) }
    File.delete(campaign_manager.store.path(successor["campaign_id"]))
    refute campaign_manager.status(campaign["campaign_id"])["accepted"]
  end

  def test_conflicting_occurrences_cannot_share_one_canonical_finding_in_a_submission
    campaign = start_campaign(scopes: %w[one two])
    initial = round_input(1, scopes: %w[one two])
    make_campaign_session(campaign, initial, scope: "one", finding: {})
    make_campaign_session(campaign, initial, scope: "two")
    known = campaign_manager.record_round(campaign["campaign_id"], initial)["open_findings"].first["id"]
    later = round_input(2, scopes: %w[one two])
    make_campaign_session(campaign, later, scope: "one", finding: {})
    make_campaign_session(campaign, later, scope: "two", finding: {"status" => "done", "resolution" => "Fixed"})
    later["dispositions"].each { |assessment| assessment["finding_id"] = known }
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], later) }
    state = campaign_manager.status(campaign["campaign_id"])
    assert_equal 1, state["completed_rounds"]
    assert_equal known, state["open_findings"].first["id"]
  end

  def test_existing_feedback_resolution_is_append_only_and_does_not_reuse_old_scope_coverage
    campaign = start_campaign
    first = round_input(1)
    dir = make_campaign_session(campaign, first, finding: {})
    initial = campaign_manager.record_round(campaign["campaign_id"], first)
    finding = initial["open_findings"].first
    snapshot = File.join(@test_dir, finding["artifact"]["path"])
    old_bytes = File.binread(snapshot)
    source_path = File.join(@test_dir, dir, "feedback/finding.s.md")
    item = YAML.safe_load_file(source_path)
    item["status"] = "done"
    item["resolution"] = "Regression verifies the repaired invariant."
    File.write(source_path, "---\n#{YAML.dump(item).delete_prefix("---\n")}---\n")
    assert_equal old_bytes, File.binread(snapshot)
    assert campaign_manager.status(campaign["campaign_id"])["evidence"]["available"]
    second = round_input(2)
    make_campaign_session(campaign, second)
    second["dispositions"] << {"source_id" => finding["source_id"], "reason" => "Verified earlier repair."}
    corrected = campaign_manager.record_round(campaign["campaign_id"], second)
    assert_empty corrected["open_findings"]
    assert_equal 2, corrected["completed_rounds"]
    assert_equal 1, corrected["clean_streak"]
    assert_equal 2, corrected["counters"]["provider_calls"]
    assert_equal old_bytes, File.binread(snapshot)
    assert_equal 2, campaign_manager.store.read(campaign["campaign_id"])["assessments"].size
    third = round_input(3)
    make_campaign_session(campaign, third)
    add_campaign_approval(campaign, third)
    assert campaign_manager.record_round(campaign["campaign_id"], third)["accepted"]
    File.delete(snapshot)
    refute campaign_manager.status(campaign["campaign_id"])["accepted"]
  end

  def test_empty_later_resolution_cannot_reuse_approval_without_completed_current_coverage
    campaign = start_campaign
    first = round_input(1)
    dir = make_campaign_session(campaign, first, finding: {})
    finding = campaign_manager.record_round(campaign["campaign_id"], first)["open_findings"].first
    [2, 3].each do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 3
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    converged = campaign_manager.status(campaign["campaign_id"])
    assert converged["search_converged"]
    assert_equal 2, converged["clean_streak"]
    refute converged["accepted"]
    source_path = File.join(@test_dir, dir, "feedback/finding.s.md")
    item = YAML.safe_load_file(source_path)
    item["status"] = "done"
    item["priority"] = "medium"
    item["resolution"] = "Regression verifies the repaired invariant."
    File.write(source_path, "---\n#{YAML.dump(item).delete_prefix("---\n")}---\n")
    resolution = round_input(4)
    resolution["dispositions"] << {"source_id" => finding["source_id"], "reason" => "Verified earlier repair."}
    blocked = campaign_manager.record_round(campaign["campaign_id"], resolution)
    assert_empty blocked["open_findings"]
    assert_equal "medium", blocked["findings"].find { |f| f["id"] == finding["id"] }["priority"]
    assert_equal 3, blocked["completed_rounds"]
    assert_equal 2, blocked["clean_streak"]
    refute blocked["accepted"]
    refute blocked["evidence"]["valid"]
    assert_includes blocked["reasons"], "later High/Critical assessment requires a completed current review"
    complete = round_input(4, attempt: "complete-after-resolution")
    make_campaign_session(campaign, complete)
    add_campaign_approval(campaign, complete)
    accepted = campaign_manager.record_round(campaign["campaign_id"], complete)
    assert accepted["accepted"], accepted["reasons"].inspect
    assert_equal 4, accepted["completed_rounds"]
    assert_equal 3, accepted["clean_streak"]
  end

  def test_return_to_earlier_requirements_creates_a_new_active_successor
    a = start_campaign
    first = round_input(1)
    make_campaign_session(a, first, finding: {})
    campaign_manager.record_round(a["campaign_id"], first)
    b = campaign_manager.start(subject: campaign_subject, contract: "Changed requirements",
      policy: campaign_policy, reason: "New behavior")
    returned = campaign_manager.start(subject: campaign_subject, contract: "Frozen requirements",
      policy: campaign_policy, reason: "Restore earlier behavior")
    refute_equal a["campaign_id"], returned["campaign_id"]
    assert_equal a["contract_identity"], returned["contract_identity"]
    assert_equal b["campaign_id"], returned["predecessor"]
    assert returned["active_contract"]
    assert_equal 1, returned["open_findings"].size
    assert_equal 0, returned["completed_rounds"]
    assert_equal returned["campaign_id"], start_campaign["campaign_id"]
    refute campaign_manager.status(a["campaign_id"])["active_contract"]
    refute campaign_manager.status(b["campaign_id"])["active_contract"]
    File.delete(campaign_manager.store.path(returned["campaign_id"]))
    assert_raises(ArgumentError) { start_campaign }
  end

  def test_unrelated_corruption_does_not_block_existing_campaign_status_or_finish
    damaged = start_campaign
    subject = campaign_subject.merge("local_candidate_id" => "other-candidate")
    intact = campaign_manager.start(subject: subject, contract: "Frozen requirements", policy: campaign_policy)
    3.times do |n|
      input = round_input(n)
      make_campaign_session(intact, input)
      add_campaign_approval(intact, input) if n == 2
      campaign_manager.record_round(intact["campaign_id"], input)
    end
    assert campaign_manager.finish(intact["campaign_id"])["accepted"]
    File.write(campaign_manager.store.path(damaged["campaign_id"]), "corrupt")

    assert_raises(ArgumentError) { campaign_manager.status(damaged["campaign_id"]) }
    status = campaign_manager.status(intact["campaign_id"])
    assert status["active_contract"]
    assert_equal intact["campaign_id"], status["campaign_id"]
    assert campaign_manager.finish(intact["campaign_id"])["accepted"]
    reused = campaign_manager.start(subject: subject, contract: "Frozen requirements", policy: campaign_policy)
    assert_equal intact["campaign_id"], reused["campaign_id"]
  end

  def test_interrupted_successor_publication_keeps_predecessor_superseded
    manager = campaign_manager
    predecessor = start_campaign
    original_write = manager.store.method(:write)
    manager.store.define_singleton_method(:write) do |record|
      raise IOError, "interrupted successor publication" if record["predecessor"]
      original_write.call(record)
    end

    assert_raises(IOError) do
      manager.start(subject: campaign_subject, contract: "Changed requirements", policy: campaign_policy,
        reason: "New behavior")
    end
    status = campaign_manager.status(predecessor["campaign_id"])
    refute status["active_contract"]
    refute status["accepted"]
    refute campaign_manager.finish(predecessor["campaign_id"])["accepted"]
    assert_raises(ArgumentError) { start_campaign }
  end

  def test_retained_earlier_and_partial_review_authority_remains_required_across_head_drift
    campaign = start_campaign(scopes: %w[one two])
    3.times do |n|
      input = round_input(n, scopes: %w[one two])
      %w[one two].each { |scope| make_campaign_session(campaign, input, scope: scope) }
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    partial = round_input(3, scopes: %w[one two])
    make_campaign_session(campaign, partial, scope: "one")
    initial = campaign_manager.record_round(campaign["campaign_id"], partial)
    assert initial["accepted"]
    historical_refs = [initial["attempts"].find { |a| a["completed"] }["sessions"].first["receipt"],
      initial["attempts"].last["sessions"].first["receipt"]]
    @head = "c" * 40
    current = round_input(4, scopes: %w[one two])
    %w[one two].each { |scope| make_campaign_session(campaign, current, scope: scope) }
    add_campaign_approval(campaign, current)
    accepted = campaign_manager.record_round(campaign["campaign_id"], current)
    assert accepted["accepted"], accepted["reasons"].inspect
    historical_refs.each do |ref|
      proof = @accepted_reviews.delete(ref["digest"])
      blocked = campaign_manager.status(campaign["campaign_id"])
      refute blocked["accepted"]
      refute blocked["evidence"]["available"]
      assert_equal accepted["counters"], blocked["counters"]
      assert_equal 4, blocked["completed_rounds"]
      @accepted_reviews[ref["digest"]] = proof
      assert campaign_manager.status(campaign["campaign_id"])["accepted"]
    end
  end

  def test_incomplete_unaccepted_assessment_cannot_invalidate_prior_high_or_reuse_approval
    scopes = %w[one two]
    campaign = start_campaign(scopes: scopes)
    known = nil
    3.times do |n|
      input = round_input(n, scopes: scopes)
      make_campaign_session(campaign, input, scope: "one", finding: n.zero? ? {} : nil)
      make_campaign_session(campaign, input, scope: "two")
      add_campaign_approval(campaign, input) if n == 2
      result = campaign_manager.record_round(campaign["campaign_id"], input)
      known ||= result["open_findings"].first["id"]
    end
    attack = round_input(3, scopes: scopes)
    campaign_manager.record_round(campaign["campaign_id"], attack)
    before = campaign_manager.status(campaign["campaign_id"])
    assert before["search_converged"]
    refute before["accepted"]
    dir = make_campaign_session(campaign, attack, scope: "one", finding: {"status" => "invalid"})
    attack["dispositions"].first["finding_id"] = known
    path = File.join(@test_dir, dir, "metadata.yml")
    metadata = YAML.safe_load_file(path)
    metadata["feedback_extraction"]["status"] = "failed"
    File.write(path, YAML.dump(metadata))
    attack["sessions"].first["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
    attack["sessions"].first.delete("receipt")
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], attack) }
    protected_state = campaign_manager.status(campaign["campaign_id"])
    assert_equal before["counters"], protected_state["counters"]
    assert_equal known, protected_state["open_findings"].first["id"]
    refute protected_state["accepted"]
    metadata["feedback_extraction"]["status"] = "succeeded"
    File.write(path, YAML.dump(metadata))
    attack["sessions"].first["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
    accept_review_session(attack, dir)
    attack["attempt_id"] = "accepted-partial-invalidation"
    partial = campaign_manager.record_round(campaign["campaign_id"], attack)
    assert_empty partial["open_findings"]
    assert_equal 3, partial["completed_rounds"]
    assert_equal 2, partial["clean_streak"]
    refute partial["accepted"]
    refute partial["evidence"]["valid"]
    attack["attempt_id"] = "complete-current-invalidation"
    make_campaign_session(campaign, attack, scope: "two")
    add_campaign_approval(campaign, attack)
    complete = campaign_manager.record_round(campaign["campaign_id"], attack)
    assert complete["accepted"], complete["reasons"].inspect
    assert_equal 4, complete["completed_rounds"]
    assert_equal 3, complete["clean_streak"]
  end

  def test_partial_resolved_high_resets_convergence_even_when_a_different_round_completes
    scopes = %w[one two]
    campaign = start_campaign(scopes: scopes)
    3.times do |n|
      input = round_input(n, scopes: scopes)
      scopes.each { |scope| make_campaign_session(campaign, input, scope: scope) }
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    assert campaign_manager.finish(campaign["campaign_id"])["accepted"]
    input = round_input("unfinished", scopes: scopes)
    make_campaign_session(campaign, input, scope: "one", finding: {"status" => "done", "resolution" => "Repaired"})
    partial = campaign_manager.record_round(campaign["campaign_id"], input)
    assert_equal 3, partial["completed_rounds"]
    assert_equal 0, partial["clean_streak"]
    refute partial["search_converged"]
    refute partial["accepted"]
    2.times do |n|
      input = round_input("different-#{n}", scopes: scopes)
      scopes.each { |scope| make_campaign_session(campaign, input, scope: scope) }
      add_campaign_approval(campaign, input)
      result = campaign_manager.record_round(campaign["campaign_id"], input)
      assert_equal n + 1, result["clean_streak"]
      assert_equal n == 1, result["accepted"]
      assert_equal result["clean_streak"], campaign_manager.status(campaign["campaign_id"])["clean_streak"]
    end
    assert_equal 5, campaign_manager.finish(campaign["campaign_id"])["completed_rounds"]
  end

  def test_pr_source_exceptions_produce_blocked_start_status_and_finish
    manager = Ace::Review::Organisms::CampaignManager.new(repo_root: @test_dir)
    subject = {"repository" => "https://github.com/owner/repo", "pr" => "owner/repo#42"}
    [Ace::Git::ProviderCliMissingError.new("forge CLI"),
      Ace::Git::ProviderAuthenticationError.new("forge login")].each do |failure|
      with_pr_result(->(*) { raise failure }) do
        campaign = manager.start(subject: subject, contract: "requirements", policy: campaign_policy)
        [campaign, manager.status(campaign["campaign_id"]), manager.finish(campaign["campaign_id"])].each do |result|
          refute JSON.parse(JSON.generate(result))["accepted"]
          assert result["reasons"].any? { |reason| reason.include?("PR source unavailable") }
          assert_equal false, result["evidence"]["valid"]
          assert_equal 0, result["completed_rounds"]
        end
      end
    end
  end

  def test_equivalent_github_repository_spellings_reuse_history_and_unresolved_findings
    subject = {"repository" => "https://github.com/owner/repo", "pr" => "owner/repo#42"}
    campaign = campaign_manager.start(subject: subject, contract: "requirements", policy: campaign_policy)
    input = round_input(1)
    input["scope_identity"]["full"]["subjects"] = ["pr:owner/repo#42"]
    make_campaign_session(campaign, input, finding: {})
    campaign_manager.record_round(campaign["campaign_id"], input)
    [subject.merge("repository" => "https://github.com/owner/repo/"),
      {"repository" => "https://github.com/Owner/Repo/", "pr" => "Owner/Repo#42"}].each do |equivalent|
      resumed = campaign_manager.start(subject: equivalent, contract: "requirements", policy: campaign_policy)
      assert_equal campaign["campaign_id"], resumed["campaign_id"]
      assert_equal 1, resumed["completed_rounds"]
      assert_equal "high", resumed["open_findings"].first["priority"]
      refute resumed["accepted"]
    end
  end

  def test_first_record_deletion_cannot_reset_findings
    manager = campaign_manager
    campaign = start_campaign
    input = round_input(1)
    make_campaign_session(campaign, input, finding: {})
    manager.record_round(campaign["campaign_id"], input)
    path = manager.store.path(campaign["campaign_id"])
    trusted = File.binread(path)
    File.delete(path)
    assert_raises(ArgumentError) { start_campaign }
    assert_empty Dir.glob(File.join(manager.store.root, "*.json"))
    File.binwrite(path, trusted)
    restored = start_campaign
    assert_equal campaign["campaign_id"], restored["campaign_id"]
    assert_equal 1, restored["open_findings"].size
  end

  def with_pr_result(result)
    provider = Object.new
    provider.define_singleton_method(:fetch) do |_identifier|
      result.respond_to?(:call) ? result.call : result
    end
    provider.define_singleton_method(:fetch_metadata) do |_identifier|
      if result.respond_to?(:call)
        result.call
      elsif result[:success] == false
        result
      else
        {success: true, metadata: result[:metadata]}
      end
    end
    Ace::Review::Molecules::PrProvider.stub(:new, provider) { yield }
  end

end
