# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentExecutorPhaseCatalogTest < AceAssignTestCase
  def test_reorder_catalog_by_assign_capable_skills_places_canonical_first
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    resolver = Minitest::Mock.new
    resolver.expect(:assign_capable_skill_names, ["as-task-plan"])
    executor.instance_variable_set(:@skill_source_resolver, resolver)

    input = [
      { "name" => "work-on-task", "skill" => "as-task-work" },
      { "name" => "plan-task", "skill" => "as-task-plan" },
      { "name" => "verify-test", "skill" => "as-test-verify-suite" }
    ]

    reordered = executor.send(:reorder_catalog_by_assign_capable_skills, input)

    assert_equal "plan-task", reordered[0]["name"]
    assert_equal %w[plan-task work-on-task verify-test], reordered.map { |phase| phase["name"] }
    resolver.verify
  end

  def test_reorder_catalog_by_assign_capable_skills_keeps_original_order_when_empty
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    resolver = Minitest::Mock.new
    resolver.expect(:assign_capable_skill_names, [])
    executor.instance_variable_set(:@skill_source_resolver, resolver)

    input = [
      { "name" => "work-on-task", "skill" => "as-task-work" },
      { "name" => "verify-test", "skill" => "as-test-verify-suite" }
    ]

    reordered = executor.send(:reorder_catalog_by_assign_capable_skills, input)

    assert_equal input, reordered
    resolver.verify
  end
end
