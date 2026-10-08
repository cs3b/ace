# frozen_string_literal: true

require "test_helper"
require_relative "../../campaign_fixtures"

class CampaignEvidenceTest < AceReviewTest
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

  def test_review_actor_can_differ_from_verified_report_model
    campaign = start_campaign
    input = round_input(1)
    make_campaign_session(campaign, input)
    add_campaign_approval(campaign, input, reviewer: "uid-13002")
    result = campaign_manager.record_round(campaign["campaign_id"], input)
    assert_equal 1, result["completed_rounds"]
  end

  def test_round_retains_and_rechecks_source_child_linkage_for_approval_and_checks
    campaign = start_campaign
    input = round_input(1)
    make_campaign_session(campaign, input)
    add_campaign_approval(campaign, input, reviewer: "uid-13002")
    linkage = {"assignment_id" => "child", "attempt_id" => "child-attempt",
      "definition_digest" => "a" * 64, "binding_digest" => "b" * 64}
    @accepted_approvals.each_value { |proof| proof["execution_binding"] = linkage.dup }
    @accepted_checks.each_value { |proof| proof["execution_binding"] = linkage.dup }
    manager = campaign_manager
    manager.record_round(campaign.fetch("campaign_id"), input)
    stored = manager.store.transaction(dry_run: true) { manager.store.read(campaign.fetch("campaign_id")) }
    approval = stored.fetch("rounds").first.fetch("approval")
    assert_equal linkage, approval.fetch("execution_proof").fetch("execution_binding")
    assert_equal linkage, approval.fetch("checks").first.fetch("execution_proof").fetch("execution_binding")
    evidence = manager.instance_variable_get(:@evidence)
    evidence.verify_approval_authority(approval, historical: true)
    @accepted_checks.each_value { |proof| proof["execution_binding"]["binding_digest"] = "c" * 64 }
    assert_raises(Ace::Review::Atoms::CampaignContract::Invalid) { evidence.verify_approval_authority(approval, historical: true) }
  end

  def test_approval_requires_complete_unambiguous_verified_report_models
    campaign = start_campaign
    mutations = [
      ->(approval) { approval.delete("report_models") },
      ->(approval) { approval["report_models"] = [] },
      ->(approval) { approval["report_models"] *= 2 },
      ->(approval) { approval["report_models"][0]["report_model"] = "uid-13002" },
      ->(approval) { approval["report_models"][0]["extra"] = true },
      ->(approval) { approval["reports"] *= 2 }
    ]
    mutations.each_with_index do |mutate, index|
      input = round_input(index + 1)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input, reviewer: "uid-13002")
      path = File.join(@test_dir, input["approval"]["path"])
      approval = JSON.parse(File.read(path))
      mutate.call(approval)
      File.write(path, JSON.generate(approval))
      input["approval"] = artifact_ref(input["approval"]["path"])
      assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], input) }
      assert_equal 0, campaign_manager.status(campaign["campaign_id"])["completed_rounds"]
    end
  end

  def test_real_single_runner_metadata_with_relative_session_path_is_consumable
    campaign = start_campaign
    input = round_input(1)
    dir = make_campaign_session(campaign, input)
    metadata_path = File.join(@test_dir, dir, "metadata.yml")
    metadata = YAML.safe_load_file(metadata_path)
    metadata.delete("models")
    File.write(metadata_path, YAML.dump(metadata))
    result = {success: true, output_file: File.join(dir, "review-report-reviewer.md"),
              execution: {status: "succeeded", provider: "fixture", model: "reviewer"}}
    manager = Ace::Review::Organisms::ReviewManager.new(project_root: @test_dir)
    manager.send(:save_ruby_api_metadata, dir, result)
    input["sessions"][0]["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
    accept_review_session(input, dir)
    result = campaign_manager.record_round(campaign["campaign_id"], input)
    assert_equal 1, result["completed_rounds"]
    assert_equal 1, result["counters"]["provider_calls"]
  end

  def test_failed_provider_entry_does_not_invalidate_completed_reviewer
    campaign = start_campaign
    input = round_input(1)
    dir = make_campaign_session(campaign, input)
    path = File.join(@test_dir, dir, "metadata.yml")
    metadata = YAML.safe_load_file(path)
    # A provider failed before producing a report alongside the model that
    # completed; the failed entry is not a reviewer and must not invalidate
    # the execution that did complete.
    failed = Marshal.load(Marshal.dump(metadata["models"].first))
    failed.merge!("status" => "failed", "output_file" => nil, "report_sha256" => nil,
      "execution" => {"status" => "failed", "provider" => "fixture", "model" => "broken"})
    metadata["models"] << failed
    File.write(path, YAML.dump(metadata))
    input["sessions"][0]["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
    accept_review_session(input, dir)
    result = campaign_manager.record_round(campaign["campaign_id"], input)
    assert_equal 1, result["completed_rounds"]
    assert_equal 2, result["counters"]["provider_calls"]
  end

  def test_missing_execution_and_fabricated_approval_cannot_count_or_accept
    campaign = start_campaign
    input = round_input(1)
    dir = make_campaign_session(campaign, input)
    path = File.join(@test_dir, dir, "metadata.yml")
    value = YAML.safe_load_file(path)
    value["models"][0].delete("execution")
    File.write(path, YAML.dump(value))
    input["sessions"][0]["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], input) }
    result = campaign_manager.status(campaign["campaign_id"])
    assert_equal 0, result["completed_rounds"]
    assert_equal 0, result["clean_streak"]
    forged = round_input(2)
    make_campaign_session(campaign, forged)
    add_campaign_approval(campaign, forged)
    check = File.join(@test_dir, ".ace-local/check-round-2.json")
    File.write(check, JSON.generate("name" => "tests", "head" => @head, "exit_code" => 0))
    approval_path = File.join(@test_dir, forged["approval"]["path"])
    approval = JSON.parse(File.read(approval_path))
    approval["checks"][0]["receipt"] = {"attempt_id" => "forged", "digest" => "f" * 64}
    File.write(approval_path, JSON.generate(approval))
    forged["approval"] = artifact_ref(forged["approval"]["path"])
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], forged) }
  end

  def test_only_explicit_successful_model_status_can_complete_a_round
    campaign = start_campaign
    [nil, "pending", "running"].each_with_index do |status, n|
      input = round_input(n)
      dir = make_campaign_session(campaign, input)
      path = File.join(@test_dir, dir, "metadata.yml")
      metadata = YAML.safe_load_file(path)
      metadata["head"] = @head
      metadata["models"].first["status"] = status
      # Keep successful execution, report and extraction intact; reaccept the
      # changed artifact so rejection cannot come from a stale checksum.
      File.write(path, YAML.dump(metadata))
      input["sessions"].first["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
      accept_review_session(input, dir)
      assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], input) }
      result = campaign_manager.status(campaign["campaign_id"])
      assert_equal 0, result["completed_rounds"]
      assert_equal 0, result["clean_streak"]
    end
  end

  def test_missing_or_conflicting_recorded_head_cannot_count_valid_collection
    campaign = start_campaign
    [nil, "c" * 40].each_with_index do |head, n|
      input = round_input(n)
      dir = make_campaign_session(campaign, input)
      path = File.join(@test_dir, dir, "metadata.yml")
      metadata = YAML.safe_load_file(path)
      metadata["head"] = head
      File.write(path, YAML.dump(metadata))
      input["sessions"].first["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
      accept_review_session(input, dir)
      error = assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], input) }
      assert_match(/recorded head/, error.message)
      assert_equal 0, campaign_manager.status(campaign["campaign_id"])["completed_rounds"]
    end
  end

  def test_symlink_escape_is_rejected_even_with_matching_bytes
    File.write(File.join(@test_dir, "inside"), "artifact")
    Dir.mktmpdir do |outside|
      external = File.join(outside, "report")
      File.write(external, "artifact")
      File.symlink(external, File.join(@test_dir, "escape"))
      reader = Ace::Review::Molecules::CampaignEvidence.new(repo_root: @test_dir)
      assert_raises(ArgumentError) { reader.artifact(artifact_ref("escape")) }
    end
  end

  def test_skipped_failed_or_unrecorded_feedback_extraction_never_completes_a_round
    campaign = start_campaign
    [nil, {"status" => "skipped"}, {"status" => "failed"}].each_with_index do |extraction, n|
      input = round_input(n)
      dir = make_campaign_session(campaign, input)
      path = File.join(@test_dir, dir, "metadata.yml")
      metadata = YAML.safe_load_file(path)
      metadata["feedback_extraction"] = extraction
      File.write(path, YAML.dump(metadata))
      input["sessions"].first["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
      result = campaign_manager.record_round(campaign["campaign_id"], input)
      assert_equal 0, result["completed_rounds"]
      assert_equal 0, result["clean_streak"]
    end
  end

  def test_extractor_manifest_accounts_for_every_finding_and_report
    campaign = start_campaign
    input = round_input(1)
    dir = make_campaign_session(campaign, input, finding: {})
    manager = Ace::Review::Organisms::ReviewManager.new(project_root: @test_dir)
    finding = File.join(@test_dir, dir, "feedback/finding.s.md")
    manager.send(:save_campaign_feedback_metadata, File.join(@test_dir, dir),
      {success: true, items_count: 1, paths: [finding]})
    File.delete(finding)
    input["dispositions"] = []
    input["sessions"].first["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], input) }
    assert_equal 0, campaign_manager.status(campaign["campaign_id"])["completed_rounds"]
  end

  def test_full_pr_recording_rechecks_collected_manifest
    campaign = campaign_manager.start(subject: {"repository" => "https://github.com/owner/repo", "pr" => "owner/repo#42"},
      contract: "requirements", policy: campaign_policy)
    input = round_input(1)
    input["scope_identity"]["full"]["subjects"] = ["pr:owner/repo#42"]
    dir = make_campaign_session(campaign, input)
    path = File.join(@test_dir, dir, "metadata.yml")
    original = File.read(path)
    metadata = YAML.safe_load(original)
    metadata["diff_manifest"]["excluded_files"] = ["two.rb"]
    File.write(path, YAML.dump(metadata))
    input["sessions"].first["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], input) }
    assert_equal 0, campaign_manager.status(campaign["campaign_id"])["completed_rounds"]
    File.write(path, original)
    input["sessions"].first["metadata"] = artifact_ref(File.join(dir, "metadata.yml"))
    assert_equal 1, campaign_manager.record_round(campaign["campaign_id"], input)["completed_rounds"]
  end

  def test_rejecting_report_and_collection_proof_cannot_supply_independent_approval
    campaign = start_campaign
    input = round_input(1)
    dir = make_campaign_session(campaign, input)
    report = File.join(dir, "review-report-reviewer.md")
    File.write(File.join(@test_dir, report), "Verdict: rejected. Candidate must not be accepted.\n")
    metadata_path = File.join(dir, "metadata.yml")
    metadata = YAML.safe_load_file(File.join(@test_dir, metadata_path))
    report_sha = artifact_ref(report)["sha256"]
    metadata["models"].first["report_sha256"] = report_sha
    metadata["feedback_extraction"]["report_sha256"] = [report_sha]
    File.write(File.join(@test_dir, metadata_path), YAML.dump(metadata))
    input["sessions"].first["metadata"] = artifact_ref(metadata_path)
    accept_review_session(input, dir)
    evidence = Ace::Review::Molecules::CampaignEvidence.new(repo_root: @test_dir,
      review_evidence: fixture_review_evidence, approval_evidence: fixture_approval_evidence)
    record = campaign_manager.store.read(campaign["campaign_id"])
    add_campaign_approval(campaign, input)
    path = File.join(@test_dir, input["approval"]["path"])
    original = JSON.parse(File.read(path))
    [nil, input["sessions"].first["receipt"], {"attempt_id" => "invented", "digest" => "f" * 64}].each do |receipt|
      forged = original.merge("receipt" => receipt)
      File.write(path, JSON.generate(forged))
      input["approval"] = artifact_ref(input["approval"]["path"])
      assert evidence.session(input["sessions"].first, record: record, binding: input)["completed"]
      error = assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], input) }
      assert_match(/accepted approval receipt|did not accept independent approval/, error.message)
      result = campaign_manager.status(campaign["campaign_id"])
      refute result["accepted"]
      assert_equal 0, result["completed_rounds"]
    end
  end

  def test_retained_approval_authority_is_required_after_new_head_and_approval
    campaign = start_campaign
    old_receipt = nil
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n > 0
      old_receipt = JSON.parse(File.read(File.join(@test_dir, input["approval"]["path"]))).fetch("receipt") if n == 1
      campaign_manager.record_round(campaign["campaign_id"], input)
    end
    assert campaign_manager.finish(campaign["campaign_id"])["accepted"]
    @head = "c" * 40
    input = round_input(3)
    make_campaign_session(campaign, input)
    add_campaign_approval(campaign, input)
    assert campaign_manager.record_round(campaign["campaign_id"], input)["accepted"]
    @accepted_approvals.delete(old_receipt["digest"])
    result = campaign_manager.finish(campaign["campaign_id"])
    refute result["accepted"]
    assert_equal 4, result["completed_rounds"]
    assert_equal 4, result["clean_streak"]
  end
end
