# frozen_string_literal: true

require_relative "../test_helper"

class PhaseTest < AceAssignTestCase
  def test_initialization
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Do the thing"
    )

    assert_equal "010", phase.number
    assert_equal "init", phase.name
    assert_equal :pending, phase.status
    assert_equal "Do the thing", phase.instructions
  end

  def test_invalid_status_raises
    assert_raises(ArgumentError) do
      Ace::Assign::Models::Phase.new(
        number: "010",
        name: "init",
        status: :invalid,
        instructions: "Test"
      )
    end
  end

  def test_complete_for_done
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :done,
      instructions: "Test"
    )

    assert phase.complete?
  end

  def test_complete_for_failed
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :failed,
      instructions: "Test"
    )

    assert phase.complete?
  end

  def test_not_complete_for_pending
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    refute phase.complete?
  end

  def test_workable_for_pending
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    assert phase.workable?
  end

  def test_not_workable_for_done
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :done,
      instructions: "Test"
    )

    refute phase.workable?
  end

  def test_retry_detection
    phase = Ace::Assign::Models::Phase.new(
      number: "042",
      name: "run-tests",
      status: :pending,
      instructions: "Test",
      added_by: "retry_of:040"
    )

    assert phase.retry?
    assert_equal "040", phase.retry_of
  end

  def test_not_retry
    phase = Ace::Assign::Models::Phase.new(
      number: "041",
      name: "fix",
      status: :pending,
      instructions: "Test",
      added_by: "dynamic"
    )

    refute phase.retry?
    assert_nil phase.retry_of
  end

  def test_to_frontmatter
    now = Time.utc(2026, 1, 28, 12, 0, 0)
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :in_progress,
      instructions: "Test",
      started_at: now
    )

    fm = phase.to_frontmatter

    assert_equal "init", fm["name"]
    assert_equal "in_progress", fm["status"]
    assert_equal "2026-01-28T12:00:00Z", fm["started_at"]
  end

  def test_fork_detection
    phase = Ace::Assign::Models::Phase.new(
      number: "020",
      name: "implement",
      status: :pending,
      instructions: "Implement the feature",
      context: "fork"
    )

    assert phase.fork?
    assert_equal "fork", phase.context
  end

  def test_not_fork_when_context_nil
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    refute phase.fork?
    assert_nil phase.context
  end

  def test_rejects_invalid_context
    error = assert_raises(ArgumentError) do
      Ace::Assign::Models::Phase.new(
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
    phase = Ace::Assign::Models::Phase.new(
      number: "020",
      name: "implement",
      status: :pending,
      instructions: "Test",
      context: "fork"
    )

    fm = phase.to_frontmatter

    assert_equal "fork", fm["context"]
  end

  def test_to_frontmatter_excludes_nil_context
    phase = Ace::Assign::Models::Phase.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    fm = phase.to_frontmatter

    refute fm.key?("context")
  end
end
