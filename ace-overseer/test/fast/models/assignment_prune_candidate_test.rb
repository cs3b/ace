# frozen_string_literal: true

require_relative "../../test_helper"

class AssignmentPruneCandidateTest < AceOverseerTestCase
  def test_safe_to_prune_when_completed
    candidate = Ace::Overseer::Models::AssignmentPruneCandidate.new(
      assignment_id: "abc12",
      assignment_name: "work-on-task-230",
      assignment_state: "completed",
      location_path: "/tmp/task.230"
    )

    assert candidate.safe_to_prune?
  end

  def test_not_safe_to_prune_when_running
    candidate = Ace::Overseer::Models::AssignmentPruneCandidate.new(
      assignment_id: "abc12",
      assignment_name: "work-on-task-230",
      assignment_state: "running",
      location_path: "/tmp/task.230",
      reasons: ["assignment still running"]
    )

    refute candidate.safe_to_prune?
  end

  def test_to_h_returns_expected_fields
    candidate = Ace::Overseer::Models::AssignmentPruneCandidate.new(
      assignment_id: "abc12",
      assignment_name: "work-on-task-230",
      assignment_state: "completed",
      location_path: "/tmp/task.230",
      reasons: []
    )

    h = candidate.to_h
    assert_equal "abc12", h[:assignment_id]
    assert_equal "work-on-task-230", h[:assignment_name]
    assert_equal "completed", h[:assignment_state]
    assert_equal true, h[:safe_to_prune]
  end
end
