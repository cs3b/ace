# frozen_string_literal: true
require "test_helper"
require_relative "../../campaign_fixtures"

# Pure campaign-owner tests. The callback models a separately authenticated
# evidence owner; these fixtures are not native or installed acceptance proof.
class CampaignHeadAssessmentsTest < AceReviewTest
  include CampaignFixtures

  def setup
    super
    @head, @base = "a" * 40, "b" * 40
    @head_proofs = {}
  end

  def manager
    Ace::Review::Organisms::CampaignManager.new(repo_root: @test_dir,
      revisions: ->(ref, *_args) { ref == "HEAD" ? @head : @base },
      check_evidence: fixture_check_evidence, review_evidence: fixture_review_evidence,
      approval_evidence: fixture_approval_evidence,
      head_assessment_evidence: lambda { |reference, **_expected|
        @head_proofs.fetch(reference.fetch("digest")) {
          raise Ace::Review::Atoms::CampaignContract::Invalid, "source head assessment revoked"
        }
      })
  end

  def accepted_campaign
    campaign = start_campaign
    3.times do |n|
      input = round_input(n)
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      campaign_manager.record_round(campaign.fetch("campaign_id"), input)
    end
    [campaign, campaign_manager.accepted_result_snapshot(campaign.fetch("campaign_id"))]
  end

  def assessment(campaign, predecessor, classification: "nonsemantic", text_only: true)
    check_path = ".ace-local/assessment-check-#{@head}.json"
    File.write(File.join(@test_dir, check_path), JSON.generate("head" => @head, "exit_code" => 0))
    check = accepted_check_reference(check_path)
    proof = {"schema" => "ace.review.head-assessment/v1", "campaign_id" => campaign.fetch("campaign_id"),
      "predecessor_identity" => predecessor.fetch("result_identity"),
      "from" => predecessor.slice("head", "base"), "to" => {"head" => @head, "base" => @base},
      "classification" => classification, "rationale" => "Compared complete source context and the dependency impact of this change.",
      "context" => {"sha256" => "e" * 64, "bytes" => 1234, "text_only" => text_only},
      "authority" => {"reference" => "canonical-source-assessment", "supervisor" => "pure-fixture-binding"},
      "checks" => [{"name" => "tests", "receipt" => check}]}
    digest = Ace::Review::Atoms::CampaignContract.digest(proof)
    @head_proofs[digest] = proof
    {"id" => "assessment-#{@head[0]}", "reference" => {"digest" => digest}, "predecessor" => predecessor}
  end

  def test_nonsemantic_carry_preserves_original_review_and_exact_budgets_across_restart
    campaign, original = accepted_campaign
    id = campaign.fetch("campaign_id")
    before = campaign_manager.status(id)
    @head, @base = "c" * 40, "d" * 40
    refute campaign_manager.status(id).fetch("accepted")
    input = assessment(campaign, original)
    result = manager.record_head_assessment(id, input)
    assert result.fetch("accepted"), result.fetch("reasons").inspect
    assert_equal before.fetch("counters"), result.fetch("counters")
    assert_equal before.fetch("clean_streak"), result.fetch("clean_streak")
    assert_equal before.fetch("decision").fetch("remaining_rounds"), result.fetch("decision").fetch("remaining_rounds")
    snapshot = manager.accepted_result_snapshot(id)
    assert_equal "ace.review.accepted-result/v2", snapshot.fetch("schema")
    assert_equal "a" * 40, snapshot.fetch("reviewed_head")
    assert_equal "b" * 40, snapshot.fetch("reviewed_base")
    assert_equal @head, snapshot.fetch("head")
    assert_equal @base, snapshot.fetch("base")
    refute_equal original.fetch("result_identity"), snapshot.fetch("result_identity")
    assert_equal 1, snapshot.fetch("prefix").fetch("head_assessments")
    assert manager.record_head_assessment(id, input).fetch("replayed")
    assert_equal snapshot, manager.accepted_result_snapshot(id)
    assert manager.verify_retained_result!(result: original, subject: original.fetch("subject"),
      contract_identity: original.fetch("contract_identity"), policy: original.fetch("effective_policy"),
      head: original.fetch("head"), base: original.fetch("base"), producer: "worker", reviewer: "reviewer")
    @head_proofs.clear
    refute manager.status(id).fetch("accepted")
    assert_raises(ArgumentError) { manager.accepted_result_snapshot(id) }
  end

  def test_no_default_authority_and_no_label_only_carry_for_material_or_nontext_changes
    campaign, original = accepted_campaign
    id = campaign.fetch("campaign_id")
    @head = "c" * 40
    input = assessment(campaign, original)
    assert_raises(ArgumentError) { campaign_manager.record_head_assessment(id, input) }
    %w[substantial uncertain].each do |classification|
      item = assessment(campaign, original, classification: classification)
      assert_raises(ArgumentError) { manager.record_head_assessment(id, item) }
    end
    assert_raises(ArgumentError) { manager.record_head_assessment(id, assessment(campaign, original, text_only: false)) }
    assert_empty manager.store.read(id).fetch("head_assessments")
    assert_equal 3, manager.status(id).fetch("completed_rounds")
  end

  def test_stale_prefix_missing_current_checks_conflicting_replay_and_target_mismatch_refuse
    campaign, original = accepted_campaign
    id = campaign.fetch("campaign_id")
    @head = "c" * 40
    input = assessment(campaign, original)
    proof = @head_proofs.fetch(input.dig("reference", "digest"))
    proof["to"]["head"] = "f" * 40
    assert_raises(ArgumentError) { manager.record_head_assessment(id, input) }
    proof["to"]["head"] = @head
    saved_checks = @accepted_checks.dup
    @accepted_checks.clear
    assert_raises(ArgumentError) { manager.record_head_assessment(id, input) }
    @accepted_checks = saved_checks
    assert manager.record_head_assessment(id, input).fetch("accepted")
    assert_raises(ArgumentError) { manager.record_head_assessment(id, input.merge("reference" => {"digest" => "f" * 64})) }
    @head = "d" * 40
    assert_raises(ArgumentError) { manager.record_head_assessment(id, assessment(campaign, original)) }
    assert_equal 1, manager.store.read(id).fetch("head_assessments").size
  end

  def test_two_successive_assessments_bind_the_entire_chain_and_original_review
    campaign, original = accepted_campaign
    id = campaign.fetch("campaign_id")
    @head = "c" * 40
    first = assessment(campaign, original)
    manager.record_head_assessment(id, first)
    first_result = manager.accepted_result_snapshot(id)
    @head = "d" * 40
    second = assessment(campaign, first_result)
    assert manager.record_head_assessment(id, second).fetch("accepted")
    result = manager.accepted_result_snapshot(id)
    assert_equal "a" * 40, result.fetch("reviewed_head")
    assert_equal @head, result.fetch("head")
    assert_equal 2, result.dig("prefix", "head_assessments")
    args = {subject: result.fetch("subject"), contract_identity: result.fetch("contract_identity"),
      policy: result.fetch("effective_policy"), head: @head, base: @base, producer: "worker", reviewer: "reviewer"}
    assert manager.with_verified_result!(result: result, **args) { true }
    assert manager.verify_retained_result!(result: result, **args)
    [result.merge("reviewed_head" => @head), result.merge("head_assessment_digest" => "f" * 64),
      result.merge("schema" => "ace.review.accepted-result/v1")].each do |invalid|
      assert_raises(ArgumentError) { manager.with_verified_result!(result: invalid, **args) { flunk } }
    end
    @head_proofs.delete(first.dig("reference", "digest"))
    refute manager.status(id).fetch("accepted")
    assert_raises(ArgumentError) { manager.verify_retained_result!(result: result, **args) }
  end
end
