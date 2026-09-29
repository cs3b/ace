# frozen_string_literal: true

require_relative "../../test_helper"

class OverseerWorkflowContractTest < AceOverseerTestCase
  def workflow_content
    @workflow_content ||= File.read(
      File.expand_path("../../../handbook/workflow-instructions/overseer.wf.md", __dir__)
    )
  end

  def test_encodes_work_on_status_and_prune_semantics
    assert_includes workflow_content, "ace-overseer work-on --task <task-ref>"
    assert_includes workflow_content, "ace-overseer status"
    assert_includes workflow_content, "ace-overseer prune --dry-run"
    assert_includes workflow_content, "ace-overseer prune --yes"
  end

  def test_prune_safety_contract_is_first_class_non_negotiable
    assert_includes workflow_content, "Prune safety (non-negotiable executed check)"
    assert_includes workflow_content,
      "git merge-base --is-ancestor <work-head> <base>"
    assert_includes workflow_content, "declared, verified destination"
    assert_includes workflow_content, "ace-overseer prune <target> --preservation FILE --dry-run"
    assert_includes workflow_content, "A described or remembered proof is never sufficient"
    assert_includes workflow_content, "blocks the prune"
    assert_includes workflow_content, "never silently drop"
  end

  def test_migrated_work_requires_verified_destination_and_content_equivalence
    assert_includes workflow_content, "The manifest is a claim to verify"
    assert_includes workflow_content, "full-tree equality or an"
    assert_includes workflow_content, "exact path-by-path transition"
    assert_includes workflow_content, "A matching commit subject is never sufficient"
    assert_includes workflow_content, "Never fetch proof refs into shared"
  end

  def test_patch_range_proof_requires_independently_recorded_baseline
    assert_includes workflow_content, "independently recorded\n      attempt baseline"
    assert_includes workflow_content, "must be\n      preserved on a surviving accepted ref"
    assert_includes workflow_content, "Empty or\n      caller-truncated ranges are not evidence"
  end

  def test_prune_requires_positive_no_active_writer_check
    assert_includes workflow_content, "no-active-writer check"
    assert_includes workflow_content, "ace-overseer status --format json"
    assert_includes workflow_content, "ace-assign status"
    assert_includes workflow_content, "Missing or unreadable lifecycle\n   state counts as an active writer"
    assert_includes workflow_content, "active or uncertain attempt"
    assert_includes workflow_content, "durable exclusion"
    assert_includes workflow_content, "writer cannot start into a candidate being deleted"
  end

  def test_prune_preserves_on_ambiguity_and_rejects_subject_only_proof
    assert_includes workflow_content, "Preserve on ambiguity."
    refute_includes workflow_content, "log --all --grep",
      "subject-only successor search must not return as a preservation proof"
    refute_includes workflow_content, "subject-level search",
      "subject-only successor search must not return as a preservation proof"
  end

  def test_forbidden_unsafe_prune_practices_stay_out_of_the_workflow
    refute_includes workflow_content, "fetch <source-repo>",
      "fetching proof refs into a shared repository must not be suggested"
    refute_includes workflow_content, "range-diff",
      "interpreted range-diff output must not be suggested as content proof"
    refute_includes workflow_content, "force past",
      "force must never be documented as bypassing a failed proof"
  end

  def test_status_truth_contract_is_first_class_non_negotiable
    assert_includes workflow_content, "Status truth (non-negotiable executed check)"
    assert_includes workflow_content, "claims, not state"
    assert_includes workflow_content, "executable non-secret check"
    assert_includes workflow_content, "in the same change"
    assert_includes workflow_content, "A described or remembered check is never\n   sufficient"
  end

  def test_contracts_are_listed_as_non_negotiable_summary
    assert_includes workflow_content, "Non-Negotiable Contracts Summary"
    assert_includes workflow_content, "| Prune safety |"
    assert_includes workflow_content, "| Status truth |"
  end
end
