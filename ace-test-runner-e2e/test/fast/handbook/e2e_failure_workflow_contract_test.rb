# frozen_string_literal: true

require_relative "../../test_helper"

class E2EFailureWorkflowContractTest < Minitest::Test
  def test_analyze_failures_requires_docs_help_drift_output
    workflow = File.read(File.expand_path("../../../handbook/workflow-instructions/e2e/analyze-failures.wf.md", __dir__))

    assert_includes workflow, "## Docs / Help Drift From E2E Failures"
    assert_includes workflow, "Public Surface Checked"
    assert_includes workflow, "Drift Found"
    assert_includes workflow, "Update Targets"
    assert_includes workflow, "This section is required even when no drift is found"
  end

  def test_fix_workflow_treats_docs_help_drift_as_readiness_requirement
    workflow = File.read(File.expand_path("../../../handbook/workflow-instructions/e2e/fix.wf.md", __dir__))

    assert_includes workflow, "## Docs / Help Drift From E2E Failures"
    assert_includes workflow, "including the docs/help drift section"
    assert_includes workflow, "## Docs / Help Updates"
    assert_includes workflow, "Any docs/help drift from analysis is fixed or explicitly carried as an unresolved blocker"
  end

  def test_create_workflow_requires_tc_style_and_declared_artifact_contract
    workflow = File.read(File.expand_path("../../../handbook/workflow-instructions/e2e/create.wf.md", __dir__))

    assert_includes workflow, "**public-surface**"
    assert_includes workflow, "**retained-contract**"
    assert_includes workflow, "Declare every verifier-dependent path in the runner or setup"
    assert_includes workflow, "Wildcard artifact paths are never valid"
  end

  def test_review_and_plan_workflows_cover_artifact_contract_and_downstream_sweeps
    review_workflow = File.read(File.expand_path("../../../handbook/workflow-instructions/e2e/review.wf.md", __dir__))
    plan_workflow = File.read(File.expand_path("../../../handbook/workflow-instructions/e2e/plan-changes.wf.md", __dir__))

    assert_includes review_workflow, "Every verifier-dependent artifact path must be declared by runner/setup"
    assert_includes review_workflow, "Artifact Contract"
    assert_includes plan_workflow, "downstream retained-E2E sweep"
    assert_includes plan_workflow, "status words"
  end
end
