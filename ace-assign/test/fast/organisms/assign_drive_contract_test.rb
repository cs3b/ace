# frozen_string_literal: true

require_relative "../../test_helper"

class AssignDriveContractTest < AceAssignTestCase
  def test_drive_workflow_enforces_no_skip_and_attempt_first_policy
    content = drive_workflow

    assert_includes content, "Planned steps are mandatory work items. Do not skip them by judgment."
    assert_includes content, 'Never use report text to "skip" or synthesize completion for planned steps.'
    assert_includes content, "### 4. External Action Rule (Attempt-First)"
    assert_includes content, "exact error output"
    refute_includes content, "Skip Assessment"
  end

  def test_drive_workflow_requires_status_driven_fork_resume
    content = drive_workflow

    assert_includes content, "Delegate fork waiting and resume logic to `ace-assign watch`."
    assert_includes content, "ace-assign watch --assignment \"$ASSIGNMENT_TARGET\""
    assert_includes content, "Treat `ace-assign status` as the source of truth."
    assert_includes content, "If the watcher returns because only inline/manual work remains"
    assert_includes content, "If a prior drive session or terminal ended, a new `/as-assign-drive` invocation MUST recover from assignment state"
    assert_includes content, "Correct after interruption: re-run `/as-assign-drive <assignment-id>`"
    refute_includes content, "sleep 360"
  end

  def test_drive_skill_remains_a_thin_workflow_wrapper
    content = drive_skill

    assert_includes content, "workflow: wfi://assign/drive"
    assert_includes content, "Load and run `ace-bundle wfi://assign/drive`"
    assert_includes content, "`ace-assign watch` owns fork waiting and queue continuation"
    assert_includes content, "re-enter from assignment state"
    refute_includes content, "Planned steps are mandatory work items."
    refute_includes content, "External Action Rule (Attempt-First)"
  end

  private

  def drive_workflow
    @drive_workflow ||= File.read(File.expand_path("../../../handbook/workflow-instructions/assign/drive.wf.md", __dir__))
  end

  def drive_skill
    @drive_skill ||= File.read(File.expand_path("../../../handbook/skills/as-assign-drive/SKILL.md", __dir__))
  end
end
