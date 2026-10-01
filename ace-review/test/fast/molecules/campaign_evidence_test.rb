# frozen_string_literal: true
require "test_helper"
require_relative "../../campaign_fixtures"

class CampaignEvidenceTest < AceReviewTest
  include CampaignFixtures

  def setup
    super
    @head = "a" * 40
    @base = "b" * 40
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

end
