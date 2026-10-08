# frozen_string_literal: true
require "test_helper"
require_relative "../../campaign_fixtures"

class CampaignConvergenceTest < AceReviewTest
  include CampaignFixtures

  def setup
    super
    @head = "a" * 40
    @base = "b" * 40
  end

  def completed(campaign, n, finding: nil)
    input = round_input(n)
    make_campaign_session(campaign, input, finding: finding)
    campaign_manager.record_round(campaign.fetch("campaign_id"), input)
  end

  def test_discovery_exports_known_defects_but_cannot_be_accepted_or_reset
    policy = campaign_policy.merge("minimum_rounds" => 2, "clean_rounds" => 1)
    campaign = campaign_manager.start(subject: campaign_subject, contract: "Discovery", profile: "discovery", policy: policy)
    completed(campaign, 1, finding: {})
    result = completed(campaign, 2)
    assert_equal "discovery_complete", result.fetch("outcome")
    refute result.fetch("accepted")
    assert_equal 1, result.fetch("open_findings").size
    assert_equal "discovery_complete", campaign_manager.finish(campaign.fetch("campaign_id"))["outcome"]
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign.fetch("campaign_id"), round_input(3)) }
    restarted = campaign_manager.start(subject: campaign_subject, contract: "Discovery", profile: "discovery", policy: policy)
    assert_equal campaign.fetch("campaign_id"), restarted.fetch("campaign_id")
    assert_equal 0, restarted.fetch("remaining_rounds")
    assert_raises(ArgumentError) { campaign_manager.status(campaign.fetch("campaign_id"), profile: "delivery") }
  end

  def test_medium_converges_but_blocks_acceptance_and_exhausted_phase_requires_authorized_resume
    campaign = start_campaign
    completed(campaign, 1, finding: {"priority" => "medium"})
    (2..5).each { |n| completed(campaign, n) }
    before = campaign_manager.status(campaign.fetch("campaign_id"))
    assert before.fetch("search_converged")
    refute before.fetch("accepted")
    assert_equal "needs_escalation", before.fetch("outcome")
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign.fetch("campaign_id"), round_input(6)) }
    args = {phase_id: "diagnostic", reason: "Repair needs fresh current evidence", route: "review", additional_rounds: 2}
    preview = campaign_manager.resume(campaign.fetch("campaign_id"), **args, dry_run: true)
    assert_equal 2, preview.fetch("remaining_rounds")
    assert_equal before, campaign_manager.status(campaign.fetch("campaign_id"))
    resumed = campaign_manager.resume(campaign.fetch("campaign_id"), **args)
    assert_equal 5, resumed.fetch("completed_rounds")
    assert_equal 2, resumed.fetch("phases").size
    assert_equal resumed.fetch("result_identity"), campaign_manager.resume(campaign.fetch("campaign_id"), **args).fetch("result_identity")
    assert_raises(ArgumentError) { campaign_manager.resume(campaign.fetch("campaign_id"), **args.merge(additional_rounds: 3)) }
    assert_raises(ArgumentError) { campaign_manager.resume(campaign.fetch("campaign_id"), **args.merge(phase_id: "new")) }
  end

  def test_before_call_reservations_survive_restart_and_stop_at_three_transient_failures
    campaign = start_campaign
    id = campaign.fetch("campaign_id")
    campaign_manager.record_round(id, round_input(1))
    args = {round_id: "round-1", scope: "full", provider: "fixture:model"}
    initial = campaign_manager.status(id)
    campaign_manager.reserve_execution(id, **args, dry_run: true)
    assert_equal initial, campaign_manager.status(id)
    3.times do
      execution = campaign_manager.reserve_execution(id, **args)
      assert_raises(ArgumentError) { campaign_manager.reserve_execution(id, **args) }
      assert_raises(ArgumentError) do
        campaign_manager.resume(id, phase_id: "unsafe", reason: "Cannot abandon original", route: "review", additional_rounds: 1)
      end
      campaign_manager.complete_execution(id, execution_id: execution.fetch("id"), status: "failed", failure: "timeout")
    end
    assert_raises(ArgumentError) { campaign_manager.reserve_execution(id, **args) }
    result = campaign_manager.status(id)
    assert_equal "execution_failed", result.fetch("outcome")
    assert_equal 3, result.fetch("execution_attempts").size
    assert_equal 0, result.fetch("completed_rounds")
    refute result.fetch("accepted")
  end
  def test_severity_correction_is_verified_audited_and_recomputed_without_an_extra_round
    campaign = start_campaign
    first = round_input(1)
    directory = make_campaign_session(campaign, first, finding: {})
    finding = campaign_manager.record_round(campaign.fetch("campaign_id"), first).fetch("open_findings").first
    completed(campaign, 2)
    completed(campaign, 3)
    assert_equal 2, campaign_manager.status(campaign.fetch("campaign_id")).fetch("clean_streak")
    args = {"id" => "correction", "kind" => "severity_correction", "source_id" => finding.fetch("source_id"),
      "priority" => "medium", "disposition" => "open", "reason" => "Verified scope and severity correction"}
    assert_raises(ArgumentError) { campaign_manager.assess_finding(campaign.fetch("campaign_id"), args) }
    path = File.join(@test_dir, directory, "feedback/finding.s.md")
    source = YAML.safe_load_file(path)
    source["priority"] = "medium"
    File.write(path, "---\n#{YAML.dump(source).delete_prefix("---\n")}---\n")
    corrected = campaign_manager.assess_finding(campaign.fetch("campaign_id"), args)
    assert_equal 3, corrected.fetch("completed_rounds")
    assert_equal 3, corrected.fetch("clean_streak")
    assert_equal "medium", corrected.fetch("open_findings").first.fetch("priority")
    assert_equal 2, corrected.fetch("findings").first.fetch("sources").size
    assert campaign_manager.assess_finding(campaign.fetch("campaign_id"), args).fetch("replayed")
    assert_raises(ArgumentError) { campaign_manager.assess_finding(campaign.fetch("campaign_id"), args.merge("reason" => "Different")) }
  end

  def test_evidenced_repair_and_new_verified_recurrence_pause_equivalent_review
    campaign = start_campaign
    first = completed(campaign, 1, finding: {}).fetch("open_findings").first
    File.write(File.join(@test_dir, "repair.md"), "Attempted invariant repair and regression evidence")
    repair = {"id" => "repair", "kind" => "repair_attempt", "source_id" => first.fetch("source_id"),
      "reason" => "Attempted verified repair", "artifact" => artifact_ref("repair.md")}
    campaign_manager.assess_finding(campaign.fetch("campaign_id"), repair)
    fresh = round_input(2)
    make_campaign_session(campaign, fresh, finding: {})
    fresh.fetch("dispositions").first["finding_id"] = first.fetch("id")
    recurrence = campaign_manager.record_round(campaign.fetch("campaign_id"), fresh)
    assert_equal "needs_diagnosis", recurrence.fetch("outcome")
    assert_equal 1, recurrence.fetch("recurring_blockers").size
    assert_equal 1, recurrence.fetch("open_findings").size
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign.fetch("campaign_id"), round_input(3)) }
    campaign_manager.resume(campaign.fetch("campaign_id"), phase_id: "diagnose", route: "diagnosis",
      reason: "Diagnose the retained recurring invariant", additional_rounds: 1)
    pinned = campaign_manager.record_round(campaign.fetch("campaign_id"), round_input(3))
    assert_equal 2, pinned.fetch("completed_rounds")
  end

  def test_actual_executor_entrypoint_reserves_before_call_and_never_launches_fourth_retry
    install_project_llm_provider_fixtures("claude")
    campaign = start_campaign
    id = campaign.fetch("campaign_id")
    campaign_manager.record_round(id, round_input(1))
    binding = {"campaign_id" => id, "subject" => campaign.fetch("subject"), "round_id" => "round-1", "scope" => "full"}
    calls = 0
    query = lambda do |*_args, **options|
      calls += 1
      assert_equal false, options.fetch(:fallback)
      assert_equal "running", campaign_manager.status(id).fetch("execution_attempts").last.fetch("status")
      raise Ace::LLM::ProviderError, "selected transport refused (503)"
    end
    manager = campaign_manager
    executor = Ace::Review::Molecules::LlmExecutor.new
    Ace::Review::Organisms::CampaignManager.stub(:new, manager) do
      Ace::LLM::QueryInterface.stub(:query, query) do
        4.times do
          result = executor.execute(system_prompt: "system", user_prompt: "candidate", session_dir: @test_dir,
            model: "claude:opus@ro", campaign_binding: binding)
          refute result[:success]
        end
      end
    end
    assert_equal 3, calls
    assert_equal 3, campaign_manager.status(id).fetch("execution_attempts").size
    assert_equal 0, campaign_manager.status(id).fetch("completed_rounds")
  end

  def test_compact_snapshot_retains_exact_phase_and_execution_prefix_for_existing_consumer
    campaign = start_campaign
    id = campaign.fetch("campaign_id")
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(id, input)
    end
    snapshot = campaign_manager.accepted_result_snapshot(id)
    assert_equal 1, snapshot.fetch("prefix").fetch("phases")
    assert_equal 0, snapshot.fetch("prefix").fetch("execution_attempts")
    args = {result: snapshot, subject: snapshot.fetch("subject"), contract_identity: snapshot.fetch("contract_identity"),
      policy: snapshot.fetch("effective_policy"), head: @head, base: @base, producer: "worker", reviewer: "reviewer"}
    assert campaign_manager.with_verified_result!(**args) { true }
    assert campaign_manager.verify_retained_result!(**args)
    corrupt = snapshot.merge("prefix" => snapshot.fetch("prefix").merge("phases" => 0))
    assert_raises(ArgumentError) { campaign_manager.with_verified_result!(**args.merge(result: corrupt)) { flunk } }
    assert_raises(ArgumentError) { campaign_manager.verify_retained_result!(**args.merge(result: corrupt)) }
    (3..4).each { |n| completed(campaign, n) }
    campaign_manager.resume(id, phase_id: "later", reason: "Need new current approval", route: "review", additional_rounds: 1)
    assert campaign_manager.verify_retained_result!(**args)
    assert_raises(ArgumentError) { campaign_manager.with_verified_result!(**args) { flunk } }
  end

end
