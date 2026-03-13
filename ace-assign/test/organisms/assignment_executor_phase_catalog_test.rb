# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentExecutorPhaseCatalogTest < AceAssignTestCase
  def test_phase_catalog_prefers_canonical_skill_phase_metadata_over_yaml
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    resolver = Minitest::Mock.new
    resolver.expect(:assign_phase_catalog, [
                      {
                        "name" => "plan-task",
                        "skill" => "as-task-plan",
                        "description" => "Canonical description",
                        "context" => { "default" => "fork" }
                      }
                    ])
    executor.instance_variable_set(:@skill_source_resolver, resolver)
    executor.instance_variable_set(:@phase_catalog, nil)

    executor.stub(:merge_phase_catalog, [
                    {
                      "name" => "plan-task",
                      "skill" => "as-task-plan",
                      "description" => "Canonical description",
                      "context" => { "default" => "fork" }
                    }
                  ]) do
      catalog = executor.send(:phase_catalog)
      definition = catalog.first

      assert_equal "Canonical description", definition["description"]
      assert_equal({ "default" => "fork" }, definition["context"])
    end

    resolver.verify
  end

  def test_merge_phase_catalog_overrides_existing_entries_and_keeps_internal_helpers
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    base_catalog = [
      { "name" => "plan-task", "skill" => "as-task-plan", "description" => "Legacy YAML" },
      { "name" => "task-load", "description" => "Internal helper" }
    ]
    canonical_catalog = [
      { "name" => "plan-task", "skill" => "as-task-plan", "description" => "Canonical skill" },
      { "name" => "verify-test-suite", "skill" => "as-test-verify-suite", "description" => "Canonical suite" }
    ]

    merged = executor.send(:merge_phase_catalog, base_catalog, canonical_catalog)

    assert_equal %w[plan-task task-load verify-test-suite], merged.map { |phase| phase["name"] }
    assert_equal "Canonical skill", merged.find { |phase| phase["name"] == "plan-task" }["description"]
    assert_equal "Internal helper", merged.find { |phase| phase["name"] == "task-load" }["description"]
  end
end
