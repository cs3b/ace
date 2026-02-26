# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/models/simulation_session"

class SimulationSessionTest < AceTaskflowTestCase
  def test_to_h_serializes_expected_fields
    session = Ace::Taskflow::Models::SimulationSession.new(
      run_id: "i50jj3",
      source: { type: "task", input: "285.01" },
      modes: %w[plan],
      status: "done",
      started_at: Time.utc(2026, 2, 26, 16, 0, 0),
      finished_at: Time.utc(2026, 2, 26, 16, 1, 0),
      artifacts: { summary: "run-summary.md" }
    )

    data = session.to_h
    assert_equal "i50jj3", data[:run_id]
    assert_equal %w[plan], data[:modes]
    assert_equal "done", data[:status]
    assert_equal "2026-02-26T16:00:00Z", data[:started_at]
    assert_equal "2026-02-26T16:01:00Z", data[:finished_at]
    assert_equal "run-summary.md", data.dig(:artifacts, :summary)
  end

  def test_invalid_run_id_raises
    error = assert_raises(ArgumentError) do
      Ace::Taskflow::Models::SimulationSession.new(
        run_id: "invalid",
        source: { type: "task", input: "285.01" },
        modes: %w[plan],
        status: "done",
        started_at: Time.now.utc
      )
    end

    assert_includes error.message, "Invalid run_id format"
  end
end
