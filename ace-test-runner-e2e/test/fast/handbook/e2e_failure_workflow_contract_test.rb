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
end
