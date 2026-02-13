# frozen_string_literal: true

require_relative "../test_helper"

class QueueStateTest < AceAssignTestCase
  def setup
    @assignment = Ace::Assign::Models::Assignment.new(
      id: "abc123",
      name: "test",
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

  def test_current_finds_in_progress
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :in_progress),
      make_phase(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal "020", state.current.number
  end

  def test_current_nil_when_none_in_progress
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_nil state.current
  end

  def test_pending_filters_correctly
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :pending),
      make_phase(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal 2, state.pending.size
    assert_equal "020", state.pending.first.number
  end

  def test_done_filters_correctly
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :done),
      make_phase(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal 2, state.done.size
  end

  def test_failed_filters_correctly
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :failed)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal 1, state.failed.size
    assert_equal "020", state.failed.first.number
  end

  def test_complete_when_all_done_or_failed
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :failed),
      make_phase(number: "030", name: "third", status: :done)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert state.complete?
  end

  def test_not_complete_when_pending
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    refute state.complete?
  end

  def test_find_by_number
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "040", name: "fourth", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal "040", state.find_by_number("040").number
    assert_equal "040", state.find_by_number("40").number
    assert_equal "040", state.find_by_number(40).number
  end

  def test_summary
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :in_progress),
      make_phase(number: "030", name: "third", status: :pending),
      make_phase(number: "040", name: "fourth", status: :failed)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)
    summary = state.summary

    assert_equal 4, summary[:total]
    assert_equal 1, summary[:done]
    assert_equal 1, summary[:in_progress]
    assert_equal 1, summary[:pending]
    assert_equal 1, summary[:failed]
  end

  # === Hierarchical Tests ===

  def test_children_of_returns_direct_children
    phases = [
      make_phase(number: "010", name: "parent", status: :done),
      make_phase(number: "010.01", name: "child1", status: :done),
      make_phase(number: "010.02", name: "child2", status: :pending),
      make_phase(number: "010.01.01", name: "grandchild", status: :pending),
      make_phase(number: "020", name: "sibling", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    children = state.children_of("010")
    assert_equal 2, children.size
    numbers = children.map(&:number).sort
    assert_equal ["010.01", "010.02"], numbers
  end

  def test_children_of_returns_empty_for_leaf
    phases = [
      make_phase(number: "010", name: "parent", status: :done),
      make_phase(number: "010.01", name: "child", status: :done)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    children = state.children_of("010.01")
    assert_equal 0, children.size
  end

  def test_descendants_of_returns_all_nested
    phases = [
      make_phase(number: "010", name: "parent", status: :done),
      make_phase(number: "010.01", name: "child1", status: :done),
      make_phase(number: "010.02", name: "child2", status: :pending),
      make_phase(number: "010.01.01", name: "grandchild", status: :pending),
      make_phase(number: "020", name: "sibling", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    descendants = state.descendants_of("010")
    assert_equal 3, descendants.size
    numbers = descendants.map(&:number).sort
    assert_equal ["010.01", "010.01.01", "010.02"], numbers
  end

  def test_has_incomplete_children_true
    phases = [
      make_phase(number: "010", name: "parent", status: :done),
      make_phase(number: "010.01", name: "child1", status: :done),
      make_phase(number: "010.02", name: "child2", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert state.has_incomplete_children?("010")
  end

  def test_has_incomplete_children_false
    phases = [
      make_phase(number: "010", name: "parent", status: :pending),
      make_phase(number: "010.01", name: "child1", status: :done),
      make_phase(number: "010.02", name: "child2", status: :done)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    refute state.has_incomplete_children?("010")
  end

  def test_has_incomplete_children_false_no_children
    phases = [
      make_phase(number: "010", name: "leaf", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    refute state.has_incomplete_children?("010")
  end

  def test_top_level_returns_root_phases
    phases = [
      make_phase(number: "010", name: "parent1", status: :done),
      make_phase(number: "010.01", name: "child", status: :pending),
      make_phase(number: "020", name: "parent2", status: :pending),
      make_phase(number: "030", name: "parent3", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    top = state.top_level
    assert_equal 3, top.size
    numbers = top.map(&:number).sort
    assert_equal ["010", "020", "030"], numbers
  end

  def test_all_numbers
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "010.01", name: "nested", status: :done),
      make_phase(number: "020", name: "second", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    numbers = state.all_numbers
    assert_equal ["010", "010.01", "020"], numbers
  end

  def test_hierarchical_structure
    phases = [
      make_phase(number: "010", name: "parent", status: :done),
      make_phase(number: "010.01", name: "child1", status: :done),
      make_phase(number: "010.02", name: "child2", status: :pending),
      make_phase(number: "020", name: "leaf", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    hierarchy = state.hierarchical

    # Two top-level entries
    assert_equal 2, hierarchy.size

    # First has children
    first = hierarchy[0]
    assert_equal "010", first[:step].number
    assert_equal 2, first[:children].size

    # Second is a leaf
    second = hierarchy[1]
    assert_equal "020", second[:step].number
    assert_equal 0, second[:children].size
  end

  def test_next_workable_returns_pending_without_incomplete_children
    phases = [
      make_phase(number: "010", name: "parent", status: :pending),
      make_phase(number: "010.01", name: "child", status: :pending),
      make_phase(number: "020", name: "leaf", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    # 010 has an incomplete child (010.01), so should skip to 010.01 or 020
    # Since 010.01 is pending and has no children, it should be workable
    workable = state.next_workable
    # Could be either 010.01 or 020, depending on order
    assert_includes ["010.01", "020"], workable.number
  end

  # === Assignment State Tests ===

  def test_assignment_state_empty
    state = Ace::Assign::Models::QueueState.new(phases: [], assignment: @assignment)

    assert_equal :empty, state.assignment_state
  end

  def test_assignment_state_running
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :in_progress),
      make_phase(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal :running, state.assignment_state
  end

  def test_assignment_state_paused
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :pending),
      make_phase(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal :paused, state.assignment_state
  end

  def test_assignment_state_completed
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :done)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal :completed, state.assignment_state
  end

  def test_assignment_state_failed
    phases = [
      make_phase(number: "010", name: "first", status: :done),
      make_phase(number: "020", name: "second", status: :failed),
      make_phase(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal :failed, state.assignment_state
  end

  def test_assignment_state_failed_takes_priority_over_running
    phases = [
      make_phase(number: "010", name: "first", status: :failed),
      make_phase(number: "020", name: "second", status: :in_progress)
    ]

    state = Ace::Assign::Models::QueueState.new(phases: phases, assignment: @assignment)

    assert_equal :failed, state.assignment_state
  end
end
