# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/simulation_synthesis_builder"

class SimulationSynthesisBuilderTest < AceTaskflowTestCase
  def test_build_preserves_empty_lists_for_sparse_idea_payloads
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "idea" },
      stage_outputs: [{ mode: "draft", status: "ok" }],
      stage_payloads: { "draft" => { findings: [] } }
    )

    assert_equal "ok", synthesis[:status]
    assert_empty synthesis[:questions]
    assert_empty synthesis[:refinements]
  end

  def test_build_includes_partial_failure_gap
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "idea" },
      stage_outputs: [{ mode: "draft", status: "ok" }, { mode: "plan", status: "failed" }],
      stage_payloads: { "draft" => { questions: ["Q1"] } },
      partial: true,
      failed_stage: "plan",
      error: "plan failed"
    )

    assert_equal "partial", synthesis[:status]
    assert_includes synthesis[:unresolved_gaps].join("\n"), "plan failed"
  end

  def test_build_can_reverse_question_and_refinement_aggregation_order
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "idea" },
      stage_outputs: [{ mode: "draft", status: "ok" }, { mode: "plan", status: "ok" }],
      stage_payloads: {
        "draft" => { questions: ["Q-shared", "Q-draft"], refinements: ["R-shared", "R-draft"] },
        "plan" => { questions: ["Q-shared", "Q-plan"], refinements: ["R-shared", "R-plan"] }
      },
      list_orders: { questions: :reverse, refinements: :reverse }
    )

    assert_equal ["Q-shared", "Q-plan", "Q-draft"], synthesis[:questions]
    assert_equal ["R-shared", "R-plan", "R-draft"], synthesis[:refinements]
  end

  def test_build_collects_artifacts_from_stage_payloads
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    draft_artifact = "# Task: My Draft\n\n## Description\nDo the thing.\n"
    plan_artifact = "# Plan: My Plan\n\n## Steps\n1. First step\n"
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "idea" },
      stage_outputs: [{ mode: "draft", status: "ok" }, { mode: "plan", status: "ok" }],
      stage_payloads: {
        "draft" => { status: "ok", artifact: draft_artifact, questions: [] },
        "plan" => { status: "ok", artifact: plan_artifact, questions: [] }
      }
    )

    assert_equal "ok", synthesis[:status]
    assert synthesis[:artifacts], "synthesis should have artifacts key"
    assert_equal draft_artifact, synthesis[:artifacts]["draft"]
    assert_equal plan_artifact, synthesis[:artifacts]["plan"]
  end

  def test_build_collects_review_artifact_as_draft_review
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    draft_artifact = "# Task: My Draft\n\n## Description\nDo the thing.\n"
    review_artifact = "## Readiness Review\n\n- [x] Has description\n- [ ] Missing AC\n"
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "idea" },
      stage_outputs: [{ mode: "draft", status: "ok" }],
      stage_payloads: {
        "draft" => { status: "ok", artifact: draft_artifact, review_artifact: review_artifact, questions: [] }
      }
    )

    assert_equal "ok", synthesis[:status]
    assert_equal draft_artifact, synthesis[:artifacts]["draft"]
    assert_equal review_artifact, synthesis[:artifacts]["draft_review"]
  end

  def test_build_omits_review_artifact_key_when_not_present
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "task" },
      stage_outputs: [{ mode: "plan", status: "ok" }],
      stage_payloads: {
        "plan" => { status: "ok", artifact: "# Plan\nSteps.", questions: [] }
      }
    )

    assert_equal "# Plan\nSteps.", synthesis[:artifacts]["plan"]
    refute synthesis[:artifacts].key?("plan_review"), "should not have plan_review when no review_artifact"
  end

  def test_build_artifacts_omits_empty_artifact_content
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "task" },
      stage_outputs: [{ mode: "plan", status: "ok" }],
      stage_payloads: { "plan" => { status: "ok", artifact: "", questions: ["Q1"] } }
    )

    assert_equal({}, synthesis[:artifacts])
  end

  def test_build_artifacts_is_empty_hash_when_no_artifacts_present
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "task" },
      stage_outputs: [{ mode: "plan", status: "ok" }],
      stage_payloads: { "plan" => { status: "ok", questions: ["Q1"] } }
    )

    assert_equal({}, synthesis[:artifacts])
  end
end
