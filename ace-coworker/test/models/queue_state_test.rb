# frozen_string_literal: true

require_relative "../test_helper"

class QueueStateTest < AceCoworkerTestCase
  def setup
    @session = Ace::Coworker::Models::Session.new(
      id: "abc123",
      name: "test",
      created_at: Time.now,
      source_config: "job.yaml"
    )
  end

  def make_step(number:, name:, status:)
    Ace::Coworker::Models::Step.new(
      number: number,
      name: name,
      status: status,
      instructions: "Test"
    )
  end

  def test_current_finds_in_progress
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "020", name: "second", status: :in_progress),
      make_step(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    assert_equal "020", state.current.number
  end

  def test_current_nil_when_none_in_progress
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "020", name: "second", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    assert_nil state.current
  end

  def test_pending_filters_correctly
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "020", name: "second", status: :pending),
      make_step(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    assert_equal 2, state.pending.size
    assert_equal "020", state.pending.first.number
  end

  def test_done_filters_correctly
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "020", name: "second", status: :done),
      make_step(number: "030", name: "third", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    assert_equal 2, state.done.size
  end

  def test_failed_filters_correctly
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "020", name: "second", status: :failed)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    assert_equal 1, state.failed.size
    assert_equal "020", state.failed.first.number
  end

  def test_complete_when_all_done_or_failed
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "020", name: "second", status: :failed),
      make_step(number: "030", name: "third", status: :done)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    assert state.complete?
  end

  def test_not_complete_when_pending
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "020", name: "second", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    refute state.complete?
  end

  def test_find_by_number
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "040", name: "fourth", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    assert_equal "040", state.find_by_number("040").number
    assert_equal "040", state.find_by_number("40").number
    assert_equal "040", state.find_by_number(40).number
  end

  def test_summary
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "020", name: "second", status: :in_progress),
      make_step(number: "030", name: "third", status: :pending),
      make_step(number: "040", name: "fourth", status: :failed)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)
    summary = state.summary

    assert_equal 4, summary[:total]
    assert_equal 1, summary[:done]
    assert_equal 1, summary[:in_progress]
    assert_equal 1, summary[:pending]
    assert_equal 1, summary[:failed]
  end

  # === Hierarchical Tests ===

  def test_children_of_returns_direct_children
    steps = [
      make_step(number: "010", name: "parent", status: :done),
      make_step(number: "010.01", name: "child1", status: :done),
      make_step(number: "010.02", name: "child2", status: :pending),
      make_step(number: "010.01.01", name: "grandchild", status: :pending),
      make_step(number: "020", name: "sibling", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    children = state.children_of("010")
    assert_equal 2, children.size
    numbers = children.map(&:number).sort
    assert_equal ["010.01", "010.02"], numbers
  end

  def test_children_of_returns_empty_for_leaf
    steps = [
      make_step(number: "010", name: "parent", status: :done),
      make_step(number: "010.01", name: "child", status: :done)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    children = state.children_of("010.01")
    assert_equal 0, children.size
  end

  def test_descendants_of_returns_all_nested
    steps = [
      make_step(number: "010", name: "parent", status: :done),
      make_step(number: "010.01", name: "child1", status: :done),
      make_step(number: "010.02", name: "child2", status: :pending),
      make_step(number: "010.01.01", name: "grandchild", status: :pending),
      make_step(number: "020", name: "sibling", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    descendants = state.descendants_of("010")
    assert_equal 3, descendants.size
    numbers = descendants.map(&:number).sort
    assert_equal ["010.01", "010.01.01", "010.02"], numbers
  end

  def test_has_incomplete_children_true
    steps = [
      make_step(number: "010", name: "parent", status: :done),
      make_step(number: "010.01", name: "child1", status: :done),
      make_step(number: "010.02", name: "child2", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    assert state.has_incomplete_children?("010")
  end

  def test_has_incomplete_children_false
    steps = [
      make_step(number: "010", name: "parent", status: :pending),
      make_step(number: "010.01", name: "child1", status: :done),
      make_step(number: "010.02", name: "child2", status: :done)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    refute state.has_incomplete_children?("010")
  end

  def test_has_incomplete_children_false_no_children
    steps = [
      make_step(number: "010", name: "leaf", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    refute state.has_incomplete_children?("010")
  end

  def test_top_level_returns_root_steps
    steps = [
      make_step(number: "010", name: "parent1", status: :done),
      make_step(number: "010.01", name: "child", status: :pending),
      make_step(number: "020", name: "parent2", status: :pending),
      make_step(number: "030", name: "parent3", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    top = state.top_level
    assert_equal 3, top.size
    numbers = top.map(&:number).sort
    assert_equal ["010", "020", "030"], numbers
  end

  def test_all_numbers
    steps = [
      make_step(number: "010", name: "first", status: :done),
      make_step(number: "010.01", name: "nested", status: :done),
      make_step(number: "020", name: "second", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    numbers = state.all_numbers
    assert_equal ["010", "010.01", "020"], numbers
  end

  def test_hierarchical_structure
    steps = [
      make_step(number: "010", name: "parent", status: :done),
      make_step(number: "010.01", name: "child1", status: :done),
      make_step(number: "010.02", name: "child2", status: :pending),
      make_step(number: "020", name: "leaf", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

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
    steps = [
      make_step(number: "010", name: "parent", status: :pending),
      make_step(number: "010.01", name: "child", status: :pending),
      make_step(number: "020", name: "leaf", status: :pending)
    ]

    state = Ace::Coworker::Models::QueueState.new(steps: steps, session: @session)

    # 010 has an incomplete child (010.01), so should skip to 010.01 or 020
    # Since 010.01 is pending and has no children, it should be workable
    workable = state.next_workable
    # Could be either 010.01 or 020, depending on order
    assert_includes ["010.01", "020"], workable.number
  end
end
