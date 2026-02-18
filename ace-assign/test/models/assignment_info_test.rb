# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentInfoTest < AceAssignTestCase
  def setup
    @assignment = Ace::Assign::Models::Assignment.new(
      id: "abc123",
      name: "test-task",
      created_at: Time.now,
      source_config: "job.yaml"
    )
  end

  def make_phase(number:, name:, status:)
    Ace::Assign::Models::Phase.new(
      number: number,
      name: name,
      status: status,
      instructions: "Test"
    )
  end

  def test_state_running
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      Ace::Assign::Models::Phase.new(number: "020", name: "second", status: :in_progress, instructions: "Test", started_at: Time.now - 60),
      make_phase(number: "030", name: "third", status: :pending)
    ]
    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal :running, info.state
    refute info.completed?
  end

  def test_state_paused
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :pending)
    ]
    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal :paused, info.state
    refute info.completed?
  end

  def test_state_completed
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :done)
    ]
    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal :completed, info.state
    assert info.completed?
  end

  def test_state_failed
    # Failed but NOT all complete (has pending) → :failed
    phases = [
      make_phase(number: "010", name: "first", status: :failed),
      make_phase(number: "020", name: "second", status: :pending)
    ]
    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal :failed, info.state
  end

  def test_state_completed_with_failures
    # All phases complete (done or failed) → :completed
    phases = [
      make_phase(number: "010", name: "first", status: :failed)
    ]
    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal :completed, info.state
    assert info.completed?
  end

  def test_state_empty
    state = Ace::Assign::Models::QueueState.new(phases: [], assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal :empty, info.state
  end

  def test_progress
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :done),
      make_phase(number: "030", name: "third", status: :in_progress),
      make_phase(number: "040", name: "fourth", status: :pending),
      make_phase(number: "050", name: "fifth", status: :pending)
    ]
    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal "2/5", info.progress
  end

  def test_current_phase
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "implement", status: :in_progress)
    ]
    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal "implement", info.current_phase
  end

  def test_current_phase_none
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :pending)
    ]
    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: state)

    assert_equal "-", info.current_phase
  end

  def test_delegation
    info_state = Ace::Assign::Models::QueueState.new(phases: [], assignment: @assignment)
    info = Ace::Assign::Models::AssignmentInfo.new(assignment: @assignment, queue_state: info_state)

    assert_equal "abc123", info.id
    assert_equal "test-task", info.name
    assert_equal "test-task", info.task_ref
    assert_equal @assignment.updated_at, info.updated_at
    assert_equal @assignment.created_at, info.created_at
  end
end
