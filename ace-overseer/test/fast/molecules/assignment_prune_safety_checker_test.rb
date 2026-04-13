# frozen_string_literal: true

require_relative "../../test_helper"

class AssignmentPruneSafetyCheckerTest < AceOverseerTestCase
  FakeAssignment = Struct.new(:id, :name, :cache_dir)
  FakeQueueState = Struct.new(:assignment_state) do
    def summary
      {total: 3, done: 3, failed: 0, in_progress: 0, pending: 0}
    end
  end
  FakeAssignmentInfo = Struct.new(:assignment, :queue_state) do
    def completed?
      queue_state.assignment_state == :completed
    end
  end

  class FakeDiscoverer
    def initialize(infos)
      @infos = infos
    end

    def find_all(include_completed: false)
      @infos
    end
  end

  def test_completed_assignment_is_safe_to_prune
    info = FakeAssignmentInfo.new(
      FakeAssignment.new("abc12", "work-on-task-230", "/cache/abc12"),
      FakeQueueState.new(:completed)
    )

    checker = Ace::Overseer::Molecules::AssignmentPruneSafetyChecker.new(
      assignment_discoverer_factory: -> { FakeDiscoverer.new([info]) }
    )

    candidate = checker.check(assignment_id: "abc12")

    assert candidate.safe_to_prune?
    assert_equal "abc12", candidate.assignment_id
    assert_equal "work-on-task-230", candidate.assignment_name
    assert_equal "completed", candidate.assignment_state
    assert_empty candidate.reasons
  end

  def test_running_assignment_is_not_safe_to_prune
    info = FakeAssignmentInfo.new(
      FakeAssignment.new("abc12", "work-on-task-230", "/cache/abc12"),
      FakeQueueState.new(:running)
    )

    checker = Ace::Overseer::Molecules::AssignmentPruneSafetyChecker.new(
      assignment_discoverer_factory: -> { FakeDiscoverer.new([info]) }
    )

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons, "assignment still running"
  end

  def test_missing_assignment_returns_not_found
    checker = Ace::Overseer::Molecules::AssignmentPruneSafetyChecker.new(
      assignment_discoverer_factory: -> { FakeDiscoverer.new([]) }
    )

    candidate = checker.check(assignment_id: "missing")

    refute candidate.safe_to_prune?
    assert_equal "not_found", candidate.assignment_state
    assert_includes candidate.reasons, "assignment not found"
  end
end
