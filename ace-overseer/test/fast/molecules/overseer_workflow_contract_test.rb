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
    assert_includes workflow_content,
      'git -C <successor-repo> log --all --grep "<subject>"'
    assert_includes workflow_content, "A described or remembered proof is never sufficient"
    assert_includes workflow_content, "blocks the prune"
    assert_includes workflow_content, "never silently drop"
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
