# frozen_string_literal: true

require_relative "../test_helper"

class StepTest < AceCoworkerTestCase
  def test_initialization
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Do the thing"
    )

    assert_equal "010", step.number
    assert_equal "init", step.name
    assert_equal :pending, step.status
    assert_equal "Do the thing", step.instructions
  end

  def test_invalid_status_raises
    assert_raises(ArgumentError) do
      Ace::Coworker::Models::Step.new(
        number: "010",
        name: "init",
        status: :invalid,
        instructions: "Test"
      )
    end
  end

  def test_complete_for_done
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :done,
      instructions: "Test"
    )

    assert step.complete?
  end

  def test_complete_for_failed
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :failed,
      instructions: "Test"
    )

    assert step.complete?
  end

  def test_not_complete_for_pending
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    refute step.complete?
  end

  def test_workable_for_pending
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    assert step.workable?
  end

  def test_not_workable_for_done
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :done,
      instructions: "Test"
    )

    refute step.workable?
  end

  def test_retry_detection
    step = Ace::Coworker::Models::Step.new(
      number: "042",
      name: "run-tests",
      status: :pending,
      instructions: "Test",
      added_by: "retry_of:040"
    )

    assert step.retry?
    assert_equal "040", step.retry_of
  end

  def test_not_retry
    step = Ace::Coworker::Models::Step.new(
      number: "041",
      name: "fix",
      status: :pending,
      instructions: "Test",
      added_by: "dynamic"
    )

    refute step.retry?
    assert_nil step.retry_of
  end

  def test_to_frontmatter
    now = Time.utc(2026, 1, 28, 12, 0, 0)
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :in_progress,
      instructions: "Test",
      started_at: now
    )

    fm = step.to_frontmatter

    assert_equal "init", fm["name"]
    assert_equal "in_progress", fm["status"]
    assert_equal "2026-01-28T12:00:00Z", fm["started_at"]
  end

  def test_fork_detection
    step = Ace::Coworker::Models::Step.new(
      number: "020",
      name: "implement",
      status: :pending,
      instructions: "Implement the feature",
      context: "fork"
    )

    assert step.fork?
    assert_equal "fork", step.context
  end

  def test_not_fork_when_context_nil
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    refute step.fork?
    assert_nil step.context
  end

  def test_rejects_invalid_context
    error = assert_raises(ArgumentError) do
      Ace::Coworker::Models::Step.new(
        number: "010",
        name: "init",
        status: :pending,
        instructions: "Test",
        context: "inline"
      )
    end

    assert_match(/Invalid context 'inline'/, error.message)
    assert_match(/fork/, error.message)
  end

  def test_to_frontmatter_includes_context
    step = Ace::Coworker::Models::Step.new(
      number: "020",
      name: "implement",
      status: :pending,
      instructions: "Test",
      context: "fork"
    )

    fm = step.to_frontmatter

    assert_equal "fork", fm["context"]
  end

  def test_to_frontmatter_excludes_nil_context
    step = Ace::Coworker::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    fm = step.to_frontmatter

    refute fm.key?("context")
  end
end
