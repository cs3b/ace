# frozen_string_literal: true

require_relative "../../test_helper"

class HandoffCommandTest < AceOverseerTestCase
  class FakeHandoffOrchestrator
    attr_reader :calls

    def initialize(result: nil, error: nil)
      @result = result
      @error = error
      @calls = []
    end

    def call(task_ref:, dry_run:, on_progress: nil, runtime: nil)
      @calls << {task_ref: task_ref, dry_run: dry_run, runtime: runtime}
      raise @error if @error

      @result
    end
  end

  def ready_result
    {
      task_ref: "8xg.t.abc", worktree_path: "/wt/task-a", branch: "task-a",
      status: "ready",
      next: {"role" => "reviewer", "assignment" => "r1",
             "start_config" => ".ace-local/coworker/prepare/reviewer.yml"},
      dry_run: false
    }
  end

  def test_missing_task_raises_user_friendly_error
    orchestrator = FakeHandoffOrchestrator.new(result: ready_result)
    command = Ace::Overseer::CLI::Commands::Handoff.new(orchestrator: orchestrator)

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(task: nil)
    end

    assert_equal "--task is required. Usage: ace-overseer handoff --task <ref>", error.message
    assert_empty orchestrator.calls
  end

  def test_blank_task_refuses_after_repo_guard
    Ace::Overseer::Atoms::RepoGuard.stub(:ensure_repo!, -> {}) do
      orchestrator = FakeHandoffOrchestrator.new(result: ready_result)
      command = Ace::Overseer::CLI::Commands::Handoff.new(orchestrator: orchestrator)

      assert_raises(Ace::Support::Cli::Error) { command.call(task: "  ") }
      assert_empty orchestrator.calls
    end
  end

  def test_unsupported_runtime_refuses
    orchestrator = FakeHandoffOrchestrator.new(result: ready_result)
    command = Ace::Overseer::CLI::Commands::Handoff.new(orchestrator: orchestrator, config: {"runtime" => "auto"})

    error = assert_raises(Ace::Support::Cli::Error) { command.call(task: "8xg.t.abc", runtime: "lab") }
    assert_includes error.message, "unsupported runtime"
  end

  def test_ready_handoff_prints_the_next_leg_start_command
    Ace::Overseer::Atoms::RepoGuard.stub(:ensure_repo!, -> {}) do
      orchestrator = FakeHandoffOrchestrator.new(result: ready_result)
      command = Ace::Overseer::CLI::Commands::Handoff.new(orchestrator: orchestrator, config: {"runtime" => "auto"})

      out, = capture_io do
        command.call(task: "8xg.t.abc")
      end

      assert_includes out, "ace-coworker start --config .ace-local/coworker/prepare/reviewer.yml"
      assert_equal 1, orchestrator.calls.length
      refute orchestrator.calls.first[:dry_run]
    end
  end

  def test_sequence_complete_prints_completion_without_start_command
    Ace::Overseer::Atoms::RepoGuard.stub(:ensure_repo!, -> {}) do
      result = ready_result.merge(status: "sequence_complete", next: nil)
      orchestrator = FakeHandoffOrchestrator.new(result: result)
      command = Ace::Overseer::CLI::Commands::Handoff.new(orchestrator: orchestrator, config: {"runtime" => "auto"})

      out, = capture_io do
        command.call(task: "8xg.t.abc")
      end

      assert_includes out, "Sequence complete"
      refute_includes out, "ace-coworker start"
    end
  end

  def test_refused_handoff_surfaces_the_reason_as_cli_error
    Ace::Overseer::Atoms::RepoGuard.stub(:ensure_repo!, -> {}) do
      orchestrator = FakeHandoffOrchestrator.new(error: Ace::Overseer::Error.new("Handoff refused: assignment w1 state running"))
      command = Ace::Overseer::CLI::Commands::Handoff.new(orchestrator: orchestrator, config: {"runtime" => "auto"})

      error = assert_raises(Ace::Support::Cli::Error) do
        command.call(task: "8xg.t.abc")
      end

      assert_includes error.message, "Handoff refused"
    end
  end

  def test_quiet_suppresses_output_but_still_hands_off
    Ace::Overseer::Atoms::RepoGuard.stub(:ensure_repo!, -> {}) do
      orchestrator = FakeHandoffOrchestrator.new(result: ready_result)
      command = Ace::Overseer::CLI::Commands::Handoff.new(orchestrator: orchestrator, config: {"runtime" => "auto"})

      out, = capture_io do
        command.call(task: "8xg.t.abc", quiet: true)
      end

      assert_empty out
      assert_equal 1, orchestrator.calls.length
    end
  end

  def test_dry_run_flag_reaches_the_orchestrator
    Ace::Overseer::Atoms::RepoGuard.stub(:ensure_repo!, -> {}) do
      orchestrator = FakeHandoffOrchestrator.new(result: ready_result.merge(dry_run: true))
      command = Ace::Overseer::CLI::Commands::Handoff.new(orchestrator: orchestrator, config: {"runtime" => "auto"})

      capture_io { command.call(task: "8xg.t.abc", dry_run: true) }

      assert orchestrator.calls.first[:dry_run]
    end
  end
end
