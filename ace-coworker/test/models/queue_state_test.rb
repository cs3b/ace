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
end
