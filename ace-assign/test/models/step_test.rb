# frozen_string_literal: true

require_relative "../test_helper"

class StepTest < AceAssignTestCase
  def test_initialization
    step = Ace::Assign::Models::Step.new(
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
      Ace::Assign::Models::Step.new(
        number: "010",
        name: "init",
        status: :invalid,
        instructions: "Test"
      )
    end
  end

  def test_complete_for_done
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :done,
      instructions: "Test"
    )

    assert step.complete?
  end

  def test_complete_for_failed
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :failed,
      instructions: "Test"
    )

    assert step.complete?
  end

  def test_not_complete_for_pending
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    refute step.complete?
  end

  def test_workable_for_pending
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    assert step.workable?
  end

  def test_not_workable_for_done
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :done,
      instructions: "Test"
    )

    refute step.workable?
  end

  def test_retry_detection
    step = Ace::Assign::Models::Step.new(
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
    step = Ace::Assign::Models::Step.new(
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
    step = Ace::Assign::Models::Step.new(
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
    step = Ace::Assign::Models::Step.new(
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
    step = Ace::Assign::Models::Step.new(
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
      Ace::Assign::Models::Step.new(
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
    step = Ace::Assign::Models::Step.new(
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
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    fm = step.to_frontmatter

    refute fm.key?("context")
  end

  def test_to_frontmatter_includes_fork_pid_metadata
    now = Time.utc(2026, 2, 25, 19, 0, 0)
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "work-on-task",
      status: :in_progress,
      instructions: "Run fork execution",
      fork_launch_pid: 35_5349,
      fork_tracked_pids: [3_553_666, 3_553_667],
      fork_pid_updated_at: now,
      fork_pid_file: "/tmp/010.pid.yml"
    )

    fm = step.to_frontmatter

    assert_equal 355_349, fm["fork_launch_pid"]
    assert_equal [3_553_666, 3_553_667], fm["fork_tracked_pids"]
    assert_equal "2026-02-25T19:00:00Z", fm["fork_pid_updated_at"]
    assert_equal "/tmp/010.pid.yml", fm["fork_pid_file"]
  end

  def test_stall_reason_defaults_to_nil
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    assert_nil step.stall_reason
  end

  def test_stall_reason_stored_when_provided
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :in_progress,
      instructions: "Test",
      stall_reason: "I need direction before continuing."
    )

    assert_equal "I need direction before continuing.", step.stall_reason
  end

  def test_to_frontmatter_includes_stall_reason_when_set
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :in_progress,
      instructions: "Test",
      stall_reason: "Unexpected state encountered."
    )

    fm = step.to_frontmatter
    assert_equal "Unexpected state encountered.", fm["stall_reason"]
  end

  def test_to_frontmatter_excludes_stall_reason_when_nil
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "init",
      status: :pending,
      instructions: "Test"
    )

    fm = step.to_frontmatter
    refute fm.key?("stall_reason")
  end

  def test_batch_scheduler_metadata_round_trips_to_frontmatter
    step = Ace::Assign::Models::Step.new(
      number: "010",
      name: "batch-items",
      status: :pending,
      instructions: "Batch instructions",
      batch_parent: true,
      parallel: true,
      max_parallel: 3,
      fork_retry_limit: 1
    )

    fm = step.to_frontmatter
    assert_equal true, fm["batch_parent"]
    assert_equal true, fm["parallel"]
    assert_equal 3, fm["max_parallel"]
    assert_equal 1, fm["fork_retry_limit"]
  end

  def test_rejects_invalid_max_parallel
    error = assert_raises(ArgumentError) do
      Ace::Assign::Models::Step.new(
        number: "010",
        name: "batch-items",
        status: :pending,
        instructions: "Test",
        max_parallel: 0
      )
    end

    assert_match(/max_parallel/, error.message)
  end

  def test_fork_provider_from_fork_options
    step = Ace::Assign::Models::Step.new(
      number: "020",
      name: "research",
      status: :pending,
      instructions: "Run research",
      context: "fork",
      fork_options: {"provider" => "claude:sonnet@yolo"}
    )

    assert_equal "claude:sonnet@yolo", step.fork_provider
  end

  def test_to_frontmatter_includes_fork_options
    step = Ace::Assign::Models::Step.new(
      number: "020",
      name: "research",
      status: :pending,
      instructions: "Run research",
      context: "fork",
      fork_options: {"provider" => "claude:sonnet@yolo"}
    )

    fm = step.to_frontmatter
    assert_equal({"provider" => "claude:sonnet@yolo"}, fm["fork"])
  end

  def test_to_frontmatter_excludes_empty_fork_options
    step = Ace::Assign::Models::Step.new(
      number: "020",
      name: "research",
      status: :pending,
      instructions: "Run research",
      context: "fork",
      fork_options: {}
    )

    fm = step.to_frontmatter
    refute fm.key?("fork")
  end
end
