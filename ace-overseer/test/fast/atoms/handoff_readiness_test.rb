# frozen_string_literal: true

require_relative "../../test_helper"

class HandoffReadinessTest < AceOverseerTestCase
  def leg(role, assignment, state)
    {"role" => role, "assignment" => assignment, "name" => "#{assignment}", "state" => state}
  end

  def test_finished_predecessor_unlocks_next_leg
    legs = [
      leg("worker", "w1", "completed"),
      leg("reviewer", "r1", "paused"),
      leg("integrator", "i1", "paused")
    ]

    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: legs)

    assert_equal :ready, result[:status]
    assert_equal "reviewer", result[:next]["role"]
    assert_equal "r1", result[:next]["assignment"]
  end

  def test_all_legs_completed_means_sequence_complete
    legs = [leg("worker", "w1", "completed"), leg("reviewer", "r1", "completed")]

    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: legs)

    assert_equal :sequence_complete, result[:status]
  end

  def test_active_executor_refuses_regardless_of_states
    legs = [leg("worker", "w1", "completed"), leg("reviewer", "r1", "paused")]
    active = {active: true, evidence: {"assignment" => "w1", "state" => "running", "source" => "config"}}

    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: legs, active_executor: active)

    assert_equal :refused, result[:status]
    assert_includes result[:reasons].join("; "), "an executor still holds the worktree"
    assert_includes result[:reasons].join("; "), "w1"
  end

  def test_predecessor_not_terminal_refuses_instead_of_handing_off
    legs = [
      leg("worker", "w1", "running"),
      leg("reviewer", "r1", "paused")
    ]

    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: legs)

    assert_equal :refused, result[:status]
    assert_includes result[:reasons].join("; "), "assignment w1"
    assert_includes result[:reasons].join("; "), "state running"
  end

  def test_failed_predecessor_is_not_a_finished_leg
    legs = [
      leg("worker", "w1", "failed"),
      leg("reviewer", "r1", "paused")
    ]

    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: legs)

    assert_equal :refused, result[:status]
    assert_includes result[:reasons].join("; "), "failed"
  end

  def test_unknown_state_is_not_a_free_resource
    legs = [
      leg("worker", "w1", ""),
      leg("reviewer", "r1", "paused")
    ]

    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: legs)

    assert_equal :refused, result[:status]
    assert_includes result[:reasons].join("; "), "unknown"
  end

  def test_stalled_next_leg_refuses_too
    legs = [leg("worker", "w1", "completed"), leg("reviewer", "r1", "stalled")]

    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: legs)

    assert_equal :refused, result[:status]
    assert_includes result[:reasons].join("; "), "stalled"
    assert_includes result[:reasons].join("; "), "never start a second executor"
  end

  def test_next_leg_without_start_config_refuses
    legs = [leg("worker", "w1", "completed"), leg(nil, "r1", "paused")]

    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: legs)

    assert_equal :refused, result[:status]
    assert_includes result[:reasons].join("; "), "no start config"
  end

  def test_empty_sequence_refuses
    result = Ace::Overseer::Atoms::HandoffReadiness.evaluate(legs: [])

    assert_equal :refused, result[:status]
    assert_includes result[:reasons].join("; "), "no role-sequence assignments"
  end
end
