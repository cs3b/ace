# frozen_string_literal: true

require "test_helper"

class WorkflowLayerOwnershipContractTest < AceTaskTestCase
  def test_bug_analyze_requires_layer_ownership_triage
    content = File.read(workflow_path("bug/analyze.wf.md"))

    assert_includes content, "### 5. Layer Ownership Triage"
    assert_includes content, "Owner/creator"
    assert_includes content, "Consumer/symptom"
    assert_includes content, "Do not propose a consumer-only fix"
    assert_includes content, "ace-tmux"
  end

  def test_bug_fix_blocks_consumer_only_workarounds
    content = File.read(workflow_path("bug/fix.wf.md"))

    assert_includes content, "Layer ownership guard"
    assert_includes content, "stop and return to analysis"
    assert_includes content, "Put shared policy in the owner layer"
  end

  def test_task_plan_requires_owner_layer_before_file_planning
    content = File.read(workflow_path("task/plan.wf.md"))

    assert_includes content, "Layer Ownership Triage"
    assert_includes content, "identify the owner layer before choosing files to edit"
    assert_includes content, "Do not plan a consumer-only fix"
  end

  def test_task_work_stops_when_plan_targets_symptom_package
    content = File.read(workflow_path("task/work.wf.md"))

    assert_includes content, "symptom/consumer package"
    assert_includes content, "stop and re-plan at the owner layer"
    assert_includes content, "adapters and consumers should reuse owner APIs"
  end

  private

  def workflow_path(relative_path)
    File.expand_path("../../../handbook/workflow-instructions/#{relative_path}", __dir__)
  end
end
