# frozen_string_literal: true

require_relative "../../test_helper"

class AssignmentPruneSafetyCheckerTest < AceOverseerTestCase
  FakeAssignment = Struct.new(:id, :name, :cache_dir, :task_id) do
    def managed?
      !task_id.nil? && !task_id.to_s.strip.empty?
    end
  end

  FakeQueueState = Struct.new(:assignment_state, :summary_data) do
    def summary
      summary_data
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
    checker = build_checker(completed_info)

    candidate = checker.check(assignment_id: "abc12")

    assert candidate.safe_to_prune?
    assert_equal "abc12", candidate.assignment_id
    assert_equal "work-on-task-230", candidate.assignment_name
    assert_equal "completed", candidate.assignment_state
    assert_empty candidate.reasons
  end

  def test_running_assignment_is_not_safe_to_prune
    checker = build_checker(info(:running))

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

  def test_active_local_step_blocks_completed_assignment
    checker = build_checker(completed_info(summary: {total: 3, done: 2, failed: 0, active: 1, pending: 0}))

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    refute candidate.work_terminal
    assert_includes candidate.reasons.join(" "), "1 active and 0 pending"
  end

  def test_pending_local_step_blocks_completed_assignment
    checker = build_checker(completed_info(summary: {total: 3, done: 2, failed: 0, active: 0, pending: 1}))

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "pending step"
  end

  def test_unreadable_local_step_state_blocks
    checker = build_checker(completed_info(summary: nil))

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "step state unreadable"
  end

  def test_unreadable_summary_object_blocks
    checker = build_checker(completed_info(summary: "not-a-summary"))

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "step state unreadable"
  end

  private

  def completed_info(summary: {total: 3, done: 3, failed: 0, active: 0, pending: 0})
    FakeAssignmentInfo.new(
      FakeAssignment.new("abc12", "work-on-task-230", "/cache/abc12"),
      FakeQueueState.new(:completed, summary)
    )
  end

  def info(state, summary: {total: 3, done: 1, failed: 0, active: 1, pending: 1})
    FakeAssignmentInfo.new(
      FakeAssignment.new("abc12", "work-on-task-230", "/cache/abc12"),
      FakeQueueState.new(state, summary)
    )
  end

  def build_checker(assignment_info)
    Ace::Overseer::Molecules::AssignmentPruneSafetyChecker.new(
      assignment_discoverer_factory: -> { FakeDiscoverer.new([assignment_info]) }
    )
  end
end
