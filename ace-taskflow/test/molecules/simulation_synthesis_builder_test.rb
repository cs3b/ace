# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/simulation_synthesis_builder"

class SimulationSynthesisBuilderTest < AceTaskflowTestCase
  def test_build_adds_defaults_for_sparse_idea_payloads
    builder = Ace::Taskflow::Molecules::SimulationSynthesisBuilder.new
    synthesis = builder.build(
      run_id: "i50jj3",
      source: { type: "idea" },
      stage_outputs: [{ mode: "draft", status: "ok" }],
      stage_payloads: { "draft" => { findings: [] } }
    )

    assert_equal "ok", synthesis[:status]
    refute_empty synthesis[:questions]
    refute_empty synthesis[:refinements]
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
end
