# frozen_string_literal: true

require_relative "../../test_helper"
require "yaml"

class ConfigureProjectWorkflowContractTest < AceOverseerTestCase
  def test_thin_skill_invokes_configure_project_workflow
    skill = YAML.safe_load_file(skill_path)

    assert_equal "as-overseer-configure-project", skill.fetch("name")
    assert_equal "wfi://overseer/configure-project", skill.dig("skill", "execution", "workflow")
    assert_includes File.read(skill_path), "ace-bundle wfi://overseer/configure-project"
  end

  def test_workflow_reviews_presets_workflows_and_decision_guides
    content = workflow_content

    %w[supervise-delivery integrate-batch deliver-release close-delivery].each do |preset|
      assert_includes content, preset
    end
    assert_includes content, "project-local preset overrides"
    assert_includes content, "wfi://"
    assert_includes content, "guide://delivery-supervision"
    assert_includes content, "ace-nav resolve <URI> --why"
    assert_includes content, "ace-nav resolve"
  end

  def test_workflow_is_idempotent_and_preserves_customization
    content = workflow_content

    assert_includes content, "Never overwrite an existing project customization"
    assert_includes content, "byte-identical"
    assert_includes content, "no-op"
    assert_includes content, "Do not create or duplicate tasks"
    assert_includes content, "one target path per logical override"
    assert_includes content, "unknown keys, comments"
  end

  def test_workflow_reports_concrete_outcomes_and_authority_blockers
    content = workflow_content

    assert_includes content, "CREATED"
    assert_includes content, "UPDATED"
    assert_includes content, "KEPT"
    assert_includes content, "BLOCKED"
    assert_includes content, "before digest"
    assert_includes content, "after digest"
    assert_includes content, "does not grant permissions"
    assert_includes content, "does not publish"
  end

  private

  def skill_path
    File.expand_path("../../../handbook/skills/as-overseer-configure-project/SKILL.md", __dir__)
  end

  def workflow_path
    File.expand_path("../../../handbook/workflow-instructions/overseer/configure-project.wf.md", __dir__)
  end

  def workflow_content
    @workflow_content ||= File.read(workflow_path)
  end
end
