# frozen_string_literal: true

require_relative "../test_helper"

class SimulationSessionTest < AceSimTestCase
  def base_args
    {
      preset: "validate-idea",
      source: "296.02",
      steps: %w[draft plan work],
      providers: ["codex:mini"],
      repeat: 2,
      dry_run: true,
      writeback: false,
      synthesis_workflow: "",
      synthesis_provider: "",
      step_bundles: {
        "draft" => "draft.md",
        "plan" => "plan.md",
        "work" => "work.md"
      }
    }
  end

  def test_builds_valid_session
    session = Ace::Sim::Models::SimulationSession.new(**base_args)

    assert_equal "validate-idea", session.preset
    assert_equal ["296.02"], session.source
    assert_equal %w[draft plan work], session.steps
    assert_equal ["codex:mini"], session.providers
    assert_equal 2, session.repeat
    assert session.dry_run?
    refute session.writeback
    refute_empty session.run_id
    refute session.synthesis_enabled?
  end

  def test_rejects_invalid_repeat
    assert_raises(Ace::Sim::ValidationError) do
      Ace::Sim::Models::SimulationSession.new(**base_args.merge(repeat: 0))
    end
  end

  def test_rejects_missing_step_bundle
    err = assert_raises(Ace::Sim::ValidationError) do
      Ace::Sim::Models::SimulationSession.new(**base_args.merge(step_bundles: {"draft" => "draft.md"}))
    end

    assert_match(/Missing step configs/, err.message)
  end

  def test_requires_workflow_when_synthesis_provider_is_set
    err = assert_raises(Ace::Sim::ValidationError) do
      Ace::Sim::Models::SimulationSession.new(**base_args.merge(synthesis_provider: "glite"))
    end

    assert_match(/synthesis_provider requires synthesis_workflow/, err.message)
  end
end
