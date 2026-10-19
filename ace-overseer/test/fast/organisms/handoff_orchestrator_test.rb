# frozen_string_literal: true

require "tmpdir"
require_relative "../../test_helper"

class HandoffOrchestratorTest < AceOverseerTestCase
  class FakeTaskManager
    def initialize(task)
      @task = task
    end

    def show(ref)
      @task if @task && @task.id.to_s == ref.to_s
    end
  end

  FakeTask = Struct.new(:id, :status, keyword_init: true)

  class FakeWorktreeFinder
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def switch(ref)
      @calls << ref
      @result
    end
  end

  class FakeProbe
    attr_reader :calls

    def initialize(legs:, executor_config: nil, assignments: [])
      @legs = legs
      @executor_config = executor_config
      @assignments = assignments
      @calls = []
    end

    def probe(worktree_path, task_id:)
      @calls << {worktree_path: worktree_path, task_id: task_id}
      {legs: @legs, executor: {config: @executor_config, assignments: @assignments}}
    end
  end

  class FakeWindowOpener
    attr_reader :calls

    def initialize
      @calls = []
    end

    def open(**kwargs)
      @calls << kwargs
    end
  end

  def setup
    super
    @lifecycle_root = Dir.mktmpdir("handoff-exclusion")
    @exclusion = Ace::Assign::Molecules::LifecycleExclusion.new(root: @lifecycle_root)
    @finder = FakeWorktreeFinder.new(success: true, worktree_path: "/wt/task-a", branch: "task-a", task_id: "8xg.t.abc")
  end

  def teardown
    FileUtils.rm_rf(@lifecycle_root)
    super
  end

  def orchestrator(probe:, finder: @finder)
    Ace::Overseer::Organisms::HandoffOrchestrator.new(
      task_loader: FakeTaskManager.new(FakeTask.new(id: "8xg.t.abc", status: "in-progress")),
      worktree_finder: finder,
      probe: probe,
      window_opener: @opener = FakeWindowOpener.new,
      config: {"window_presets" => {"handoff" => "work-on-task"}},
      lifecycle_exclusion: @exclusion
    )
  end

  def leg(role, assignment, state)
    {"role" => role, "assignment" => assignment, "name" => assignment, "state" => state}
  end

  def test_finished_worker_hands_worktree_to_reviewer_in_same_worktree
    probe = FakeProbe.new(
      legs: [leg("worker", "w1", "completed"), leg("reviewer", "r1", "paused"), leg("integrator", "i1", "paused")],
      assignments: [{"id" => "w1", "state" => "completed"}]
    )

    result = orchestrator(probe: probe).call(task_ref: "8xg.t.abc")

    assert_equal "ready", result[:status]
    assert_equal "/wt/task-a", result[:worktree_path]
    assert_equal "reviewer", result[:next]["role"]
    assert_equal ".ace-local/coworker/prepare/reviewer.yml", result[:next]["start_config"]
    assert_equal 1, @opener.calls.length
    assert_equal "/wt/task-a", @opener.calls.first[:worktree_path]
    assert_equal({worktree_path: "/wt/task-a", task_id: "8xg.t.abc"}, probe.calls.first)
  end

  def test_dry_run_reports_next_leg_without_effects
    probe = FakeProbe.new(legs: [leg("worker", "w1", "completed"), leg("reviewer", "r1", "paused")])

    result = orchestrator(probe: probe).call(task_ref: "8xg.t.abc", dry_run: true)

    assert_equal "ready", result[:status]
    assert result[:dry_run]
    assert_empty @opener.calls
  end

  def test_predecessor_not_terminal_refuses_and_starts_nothing
    probe = FakeProbe.new(
      legs: [leg("worker", "w1", "running"), leg("reviewer", "r1", "paused")],
      assignments: [{"id" => "w1", "state" => "running"}]
    )

    error = assert_raises(Ace::Overseer::Error) do
      orchestrator(probe: probe).call(task_ref: "8xg.t.abc")
    end

    assert_includes error.message, "Handoff refused"
    assert_includes error.message, "running"
    assert_empty @opener.calls
  end

  def test_commissioned_active_executor_never_gets_a_second_one
    probe = FakeProbe.new(
      legs: [leg("worker", "w1", "completed"), leg("reviewer", "r1", "paused")],
      executor_config: {"role" => "worker", "task" => "8xg.t.abc", "assignment" => "x9"},
      assignments: [{"id" => "x9", "state" => "running"}]
    )

    error = assert_raises(Ace::Overseer::Error) do
      orchestrator(probe: probe).call(task_ref: "8xg.t.abc")
    end

    assert_includes error.message, "an executor still holds the worktree"
    assert_empty @opener.calls
  end

  def test_unreadable_worktree_state_is_not_a_free_resource
    probe = FakeProbe.new(
      legs: [leg("worker", "w1", "completed"), leg("reviewer", "r1", "paused")],
      executor_config: Ace::Coworker::Atoms::ActiveExecutorRule::UNPARSEABLE
    )

    error = assert_raises(Ace::Overseer::Error) do
      orchestrator(probe: probe).call(task_ref: "8xg.t.abc")
    end

    assert_includes error.message, "an executor still holds the worktree"
    assert_includes error.message, "unparseable"
  end

  def test_second_task_in_its_own_worktree_hands_off_independently
    finder_b = FakeWorktreeFinder.new(success: true, worktree_path: "/wt/task-b", branch: "task-b", task_id: "8xg.t.bcd")
    probe_b = FakeProbe.new(
      legs: [leg("worker", "wb1", "completed"), leg("reviewer", "rb1", "paused")],
      assignments: [{"id" => "wb1", "state" => "completed"}]
    )
    probe_a = FakeProbe.new(
      legs: [leg("worker", "wa1", "running")],
      assignments: [{"id" => "wa1", "state" => "running"}]
    )

    result = Ace::Overseer::Organisms::HandoffOrchestrator.new(
      task_loader: FakeTaskManager.new(FakeTask.new(id: "8xg.t.bcd", status: "in-progress")),
      worktree_finder: finder_b,
      probe: probe_b,
      window_opener: opener_b = FakeWindowOpener.new,
      config: {},
      lifecycle_exclusion: @exclusion
    ).call(task_ref: "8xg.t.bcd")

    assert_raises(Ace::Overseer::Error) do
      orchestrator(probe: probe_a).call(task_ref: "8xg.t.abc")
    end

    assert_equal "ready", result[:status]
    assert_equal "/wt/task-b", result[:worktree_path]
    assert_equal "reviewer", result[:next]["role"]
    assert_equal 1, opener_b.calls.length
  end

  def test_unknown_task_refuses
    probe = FakeProbe.new(legs: [])

    error = assert_raises(Ace::Overseer::Error) do
      Ace::Overseer::Organisms::HandoffOrchestrator.new(
        task_loader: FakeTaskManager.new(nil),
        worktree_finder: @finder, probe: probe, window_opener: FakeWindowOpener.new,
        config: {}, lifecycle_exclusion: @exclusion
      ).call(task_ref: "nope")
    end

    assert_includes error.message, "Task not found"
  end

  def test_missing_worktree_refuses_without_creating_one
    probe = FakeProbe.new(legs: [])
    finder = FakeWorktreeFinder.new(success: false, error: "Worktree not found: 8xg.t.abc")

    error = assert_raises(Ace::Overseer::Error) do
      orchestrator(probe: probe, finder: finder).call(task_ref: "8xg.t.abc")
    end

    assert_includes error.message, "No usable worktree"
    assert_includes error.message, "existing worktree"
  end

  def test_completed_sequence_reports_sequence_complete
    probe = FakeProbe.new(
      legs: [leg("worker", "w1", "completed"), leg("reviewer", "r1", "completed")],
      assignments: [{"id" => "w1", "state" => "completed"}]
    )

    result = orchestrator(probe: probe).call(task_ref: "8xg.t.abc")

    assert_equal "sequence_complete", result[:status]
    assert_nil result[:next]
    assert_empty @opener.calls
  end
end
