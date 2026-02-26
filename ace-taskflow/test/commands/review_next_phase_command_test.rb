# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core"
require "ace/taskflow/cli/commands/review_next_phase"

class ReviewNextPhaseCommandTest < AceTaskflowTestCase
  FakeRunner = Struct.new(:result, :received) do
    def run(**kwargs)
      self.received = kwargs
      result
    end
  end

  def setup
    super
    @command = Ace::Taskflow::CLI::Commands::ReviewNextPhase.new
  end

  def test_call_invokes_runner_and_prints_summary
    runner = FakeRunner.new(
      {
        run_id: "i50jj3",
        session_dir: "/tmp/session",
        summary_path: "/tmp/session/run-summary.md",
        session: {
          artifacts: {
            request: "request.yml",
            stages: ["stage-task-plan.yml"],
            synthesis: "synthesis.yml",
            writeback_preview: "writeback-preview.md",
            summary: "run-summary.md"
          }
        }
      }
    )

    @command.stub :runner, runner do
      output, = capture_io do
        @command.call(source: "285.01", modes: "plan", no_writeback: true, quiet: false, verbose: false, debug: false)
      end

      assert_includes output, "Simulation run complete"
      assert_includes output, "Run ID: i50jj3"
      assert_includes output, "Session directory: /tmp/session"
    end

    assert_equal({ source: "285.01", modes: ["plan"], no_writeback: true }, runner.received)
  end

  def test_call_raises_error_when_source_missing
    error = assert_raises(Ace::Core::CLI::Error) do
      @command.call(source: nil, modes: "plan", no_writeback: true, quiet: false, verbose: false, debug: false)
    end

    assert_includes error.message, "Missing required option: --source"
  end

  def test_quiet_mode_outputs_only_run_id
    runner = FakeRunner.new(
      {
        run_id: "i50jj3",
        session_dir: "/tmp/session",
        summary_path: "/tmp/session/run-summary.md",
        session: { artifacts: {} }
      }
    )

    @command.stub :runner, runner do
      output, = capture_io do
        @command.call(source: "285.01", modes: "plan", no_writeback: true, quiet: true, verbose: false, debug: false)
      end

      assert_equal "i50jj3\n", output
    end
  end
end
