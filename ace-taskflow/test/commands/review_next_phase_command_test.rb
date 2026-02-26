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
        @command.call(source: "285.01", modes: "plan", dry_run: true, quiet: false, verbose: false, debug: false)
      end

      assert_includes output, "Simulation run complete"
      assert_includes output, "Run ID: i50jj3"
      assert_includes output, "Session directory: /tmp/session"
    end

    assert_equal "285.01", runner.received[:source]
    assert_equal "plan", runner.received[:modes]
    assert_equal true, runner.received[:no_writeback]
    assert_equal true, runner.received[:manual]
    assert_equal false, runner.received[:cli_enable]
    assert_equal false, runner.received[:cli_disable]
  end

  def test_call_raises_error_when_source_missing
    error = assert_raises(Ace::Core::CLI::Error) do
      @command.call(source: nil, modes: "plan", dry_run: true, quiet: false, verbose: false, debug: false)
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
        @command.call(source: "285.01", modes: "plan", dry_run: true, quiet: true, verbose: false, debug: false)
      end

      assert_equal "i50jj3\n", output
    end
  end

  def test_call_supports_next_phase_override_flags
    runner = FakeRunner.new(
      {
        run_id: "i50jj3",
        session_dir: "/tmp/session",
        summary_path: "/tmp/session/run-summary.md",
        session: { artifacts: {} }
      }
    )

    @command.stub :runner, runner do
      capture_io do
        @command.call(
          source: "285.01",
          modes: nil,
          next_phase_modes: "plan,work",
          next_phase_review: true,
          no_next_phase_review: false,
          auto_trigger: true,
          dry_run: true,
          quiet: false,
          verbose: false,
          debug: false
        )
      end
    end

    assert_equal false, runner.received[:manual]
    assert_equal true, runner.received[:cli_enable]
    assert_equal false, runner.received[:cli_disable]
    assert_equal "plan,work", runner.received[:modes]
  end

  def test_verbose_mode_prints_artifact_details
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
        @command.call(source: "285.01", modes: "plan", dry_run: true, quiet: false, verbose: true, debug: false)
      end

      assert_includes output, "Artifacts:"
      assert_includes output, "stage-task-plan.yml"
      assert_includes output, "synthesis.yml"
      assert_includes output, "writeback-preview.md"
      assert_includes output, "run-summary.md"
    end
  end

  def test_skipped_result_prints_skip_summary
    runner = FakeRunner.new(
      {
        skipped: true,
        reason: "Next-phase simulation disabled by trigger policy"
      }
    )

    @command.stub :runner, runner do
      output, = capture_io do
        @command.call(
          source: "285.01",
          modes: "plan",
          next_phase_modes: nil,
          next_phase_review: false,
          no_next_phase_review: true,
          auto_trigger: true,
          dry_run: true,
          quiet: false,
          verbose: false,
          debug: false
        )
      end

      assert_includes output, "Simulation skipped"
      assert_includes output, "disabled by trigger policy"
    end
  end
end
