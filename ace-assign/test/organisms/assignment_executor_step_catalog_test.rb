# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentExecutorStepCatalogTest < AceAssignTestCase
  def test_step_catalog_prefers_canonical_skill_step_metadata_over_yaml
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    resolver = Minitest::Mock.new
    resolver.expect(:assign_step_catalog, [
      {
        "name" => "plan-task",
        "skill" => "as-task-plan",
        "description" => "Canonical description",
        "context" => {"default" => "fork"}
      }
    ])
    executor.instance_variable_set(:@skill_source_resolver, resolver)
    executor.instance_variable_set(:@step_catalog, nil)

    executor.stub(:merge_step_catalog, [
      {
        "name" => "plan-task",
        "skill" => "as-task-plan",
        "description" => "Canonical description",
        "context" => {"default" => "fork"}
      }
    ]) do
      catalog = executor.send(:step_catalog)
      definition = catalog.first

      assert_equal "Canonical description", definition["description"]
      assert_equal({"default" => "fork"}, definition["context"])
    end

    resolver.verify
  end

  def test_merge_step_catalog_overrides_existing_entries_and_keeps_local_render_metadata
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    base_catalog = [
      {
        "name" => "plan-task",
        "skill" => "as-task-plan",
        "description" => "Legacy YAML",
        "steps" => [{"description" => "Local step"}]
      },
      {"name" => "task-load", "description" => "Internal helper"}
    ]
    canonical_catalog = [
      {
        "name" => "plan-task",
        "skill" => "as-task-plan",
        "description" => "Canonical skill",
        "context" => {"default" => "fork"}
      },
      {"name" => "verify-test-suite", "skill" => "as-test-verify-suite", "description" => "Canonical suite"}
    ]

    merged = executor.send(:merge_step_catalog, base_catalog, canonical_catalog)

    assert_equal %w[plan-task task-load verify-test-suite], merged.map { |step| step["name"] }
    plan_task = merged.find { |step| step["name"] == "plan-task" }

    assert_equal "Canonical skill", plan_task["description"]
    assert_equal({"default" => "fork"}, plan_task["context"])
    assert_equal [{"description" => "Local step"}], plan_task["steps"]
    assert_equal "Internal helper", merged.find { |step| step["name"] == "task-load" }["description"]
  end
end
