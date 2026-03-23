# frozen_string_literal: true

require_relative "../test_helper"

class WorkOnCommandTest < AceOverseerTestCase
  class FakeWorkOnOrchestrator
    attr_reader :calls

    def initialize(result: nil, error: nil)
      @result = result
      @error = error
      @calls = []
    end

    def call(task_ref:, cli_preset:, task_refs: nil, on_progress: nil)
      @calls << {task_ref: task_ref, task_refs: task_refs, cli_preset: cli_preset}
      raise @error if @error

      @result
    end
  end

  def test_missing_task_raises_user_friendly_error
    orchestrator = FakeWorkOnOrchestrator.new(result: build_result)
    command = Ace::Overseer::CLI::Commands::WorkOn.new(orchestrator: orchestrator)

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(task: nil)
    end

    assert_equal "--task is required. Usage: ace-overseer work-on --task <ref>", error.message
    assert_empty orchestrator.calls
  end

  def test_passes_task_and_preset_to_orchestrator
    orchestrator = FakeWorkOnOrchestrator.new(result: build_result)
    command = Ace::Overseer::CLI::Commands::WorkOn.new(orchestrator: orchestrator)

    command.call(task: ["230"], preset: "fix-bug", quiet: true)

    assert_equal 1, orchestrator.calls.length
    assert_equal "230", orchestrator.calls.first[:task_ref]
    assert_equal ["230"], orchestrator.calls.first[:task_refs]
    assert_equal "fix-bug", orchestrator.calls.first[:cli_preset]
  end

  def test_parses_comma_and_repeated_task_inputs_in_order
    orchestrator = FakeWorkOnOrchestrator.new(result: build_result)
    command = Ace::Overseer::CLI::Commands::WorkOn.new(orchestrator: orchestrator)

    command.call(task: ["288,287.01", "300"], quiet: true)

    assert_equal 1, orchestrator.calls.length
    assert_equal "288", orchestrator.calls.first[:task_ref]
    assert_equal %w[288 287.01 300], orchestrator.calls.first[:task_refs]
  end

  def test_progress_output_displayed_when_not_quiet
    orchestrator = FakeWorkOnOrchestrator.new(result: build_result)
    command = Ace::Overseer::CLI::Commands::WorkOn.new(orchestrator: orchestrator)

    output, = capture_io do
      command.call(task: "230")
    end

    assert_includes output, "Done."
    assert_includes output, "Done."
  end

  def test_wraps_not_found_errors_as_cli_error
    orchestrator = FakeWorkOnOrchestrator.new(error: Ace::Overseer::Error.new("Task not found: 999"))
    command = Ace::Overseer::CLI::Commands::WorkOn.new(orchestrator: orchestrator)

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(task: "999", quiet: true)
    end

    assert_equal "Task not found: 999", error.message
  end

  private

  def build_result
    {
      task_ref: "230",
      preset: "work-on-task",
      worktree_path: "/tmp/task.230",
      branch: "230-feature",
      worktree_created: true,
      assignment_id: "abc123",
      first_step: "010-onboard",
      assignment_created: true
    }
  end
end
