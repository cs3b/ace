# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/campaign_execution"

class CampaignExecutionTest < AceAssignTestCase
  Binding = Ace::Assign::Authority::CampaignExecution
  Contract = Binding::Contract

  def policy
    {"revision" => "v1", "minimum_rounds" => 3, "clean_rounds" => 2,
      "required_scopes" => ["full"], "required_checks" => ["tests", "lint"]}
  end

  def binding
    {"version" => 1, "parent_assignment_id" => "parent", "parent_attempt_id" => "attempt",
      "parent_scope" => "delivery.review", "parent_candidate_generation" => 4,
      "subject" => {"repository" => "local", "local_candidate_id" => "candidate"},
      "campaign_id" => "campaign", "contract_identity" => "a" * 64, "policy_digest" => Contract.digest(policy),
      "round_id" => "round-1", "phase" => "collection", "review_scope" => "full", "scope_identity_digest" => "b" * 64,
      "head" => "c" * 40, "base" => "d" * 40, "operation" => "review-collect", "check_name" => "review-execution"}
  end

  def test_phase_operation_matrix
    [["collection", "review-collect", "review-execution"], ["approval", "review", "review-approval"],
      ["check", "test", "tests"], ["check", "lint", "lint"]].each do |phase, operation, check|
      value = binding.merge("phase" => phase, "operation" => operation, "check_name" => check)
      assert_equal value, Binding.validate!(value, parent: "parent", policy: policy)
    end
  end

  def test_result_matches_registered_phase_candidate_and_executed_check
    receipt = {"operation" => "review-collect", "head" => binding.fetch("head"), "verdict" => "succeeded",
      "checks" => [{"name" => "review-execution", "verdict" => "passed"}]}
    assert_equal binding, Binding.validate_result!(binding, receipt: receipt, base: binding.fetch("base"))
    [receipt.merge("operation" => "test"), receipt.merge("head" => "e" * 40),
      receipt.merge("campaign" => {}), receipt.merge("checks" => []),
      receipt.merge("checks" => [{"name" => "review-execution", "verdict" => "failed"}])].each do |changed|
      assert_raises(ArgumentError) { Binding.validate_result!(binding, receipt: changed, base: binding.fetch("base")) }
    end
    assert_raises(ArgumentError) { Binding.validate_result!(binding, receipt: receipt, base: "e" * 40) }
    assert_equal binding, Binding.validate_result!(binding, receipt: receipt.merge("verdict" => "failed", "checks" => []),
      base: binding.fetch("base"))
  end

  def test_canonical_independent_review_covers_phase_artifacts_and_exact_approval_actor
    artifact = {"path" => "result-import", "sha256" => "a" * 64}
    review = {"reviewer" => {"actor" => "independent", "runtime" => "herdr"}, "head" => binding.fetch("head"), "verdict" => "approved"}
    receipt = {"artifacts" => [artifact], "review" => review}
    accepted = {"artifacts" => [artifact.merge("path" => "review-import")], "review" => review}
    value = binding.merge("phase" => "approval", "operation" => "review", "check_name" => "review-approval")
    assert Binding.validate_finished_review!(value, receipt: receipt, accepted_review: accepted)
    assert_raises(ArgumentError) { Binding.validate_finished_review!(value, receipt: receipt,
      accepted_review: accepted.merge("artifacts" => [])) }
    assert_raises(ArgumentError) { Binding.validate_finished_review!(value, receipt: receipt,
      accepted_review: accepted.merge("review" => review.merge("reviewer" => {"actor" => "other", "runtime" => "herdr"}))) }
  end

  def test_parent_registration_is_closed_and_canonical
    value = binding.slice("version", "campaign_id", "subject", "contract_identity").merge("policy" => policy)
    assert_equal value, Binding.validate_parent!(value)
    [value.merge("parent_attempt_id" => "other"), value.reject { |key, _| key == "policy" },
      value.merge("contract_identity" => "short"), value.merge("version" => 1.0)].each do |invalid|
      assert_raises(ArgumentError) { Binding.validate_parent!(invalid) }
    end
  end

  def test_matches_exact_pinned_round_not_only_policy
    scope = {"preset" => "code-valid", "subjects" => ["diff:base..head"]}
    value = binding.merge("scope_identity_digest" => Contract.digest(scope))
    round = value.slice("campaign_id", "subject", "contract_identity", "round_id").merge("policy" => policy,
      "binding" => value.slice("head", "base").merge("scope_identity" => {"full" => scope}))
    assert_equal value, Binding.validate_round!(value, parent: "parent", round: round)
    %w[campaign_id contract_identity round_id head base scope_identity_digest].each do |field|
      changed = value.merge(field => (field.end_with?("identity", "digest") ? "e" * 64 : (field == "head" || field == "base" ? "e" * 40 : "other")))
      assert_raises(ArgumentError) { Binding.validate_round!(changed, parent: "parent", round: round) }
    end
    changed = value.merge("subject" => {"repository" => "other", "local_candidate_id" => "candidate"})
    assert_raises(ArgumentError) { Binding.validate_round!(changed, parent: "parent", round: round) }
  end

  def test_pr_identity_is_canonical_and_version_is_integer
    value = binding.merge("subject" => {"repository" => "https://github.com/owner/repo", "pr" => "owner/repo#7"})
    assert_equal value, Binding.validate!(value, parent: "parent", policy: policy)
    [value.merge("version" => 1.0), value.merge("subject" => {"repository" => "https://github.com/owner/repo", "pr" => "other/repo#7"})].each do |invalid|
      assert_raises(ArgumentError) { Binding.validate!(invalid, parent: "parent", policy: policy) }
    end
  end

  def test_policy_cannot_turn_external_effect_into_check
    Ace::Assign::Molecules::ReceiptVerifier::EXTERNAL_EFFECT_OPERATIONS.each do |operation|
      selected = policy.merge("required_checks" => [operation])
      value = binding.merge("phase" => "check", "operation" => operation, "check_name" => operation,
        "policy_digest" => Contract.digest(selected))
      assert_raises(ArgumentError) { Binding.validate!(value, parent: "parent", policy: selected) }
    end
  end

  def test_rejects_incomplete_or_substituted_linkage
    mutations = [->(v) { v.delete("base") }, ->(v) { v["extra"] = true },
      ->(v) { v["parent_assignment_id"] = "sibling" }, ->(v) { v["parent_candidate_generation"] = -1 },
      ->(v) { v["policy_digest"] = "e" * 64 }, ->(v) { v["review_scope"] = "unknown" },
      ->(v) { v["head"] = "short" }, ->(v) { v["phase"] = "publish" },
      ->(v) { v["operation"] = "publish" }, ->(v) { v["check_name"] = "tests" },
      ->(v) { v["scope_identity_digest"] = "invalid" }, ->(v) { v["parent_attempt_id"] = "../other" },
      ->(v) { v.merge!("phase" => "check", "operation" => "publish", "check_name" => "publish") }]
    mutations.each do |mutate|
      value = binding
      mutate.call(value)
      assert_raises(ArgumentError) { Binding.validate!(value, parent: "parent", policy: policy) }
    end
  end
end
