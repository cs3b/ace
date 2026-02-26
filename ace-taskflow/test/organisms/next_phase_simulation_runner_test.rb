# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/next_phase_simulation_runner"
require_relative "../../lib/ace/taskflow/molecules/simulation_session_store"
require "yaml"

class NextPhaseSimulationRunnerTest < AceTaskflowTestCase
  def test_run_persists_framework_artifacts_for_task_source
    with_real_test_project do |dir|
      source_path = File.join(dir, "tmp-task-source.s.md")
      File.write(source_path, "# Temporary source\n")

      store = Ace::Taskflow::Molecules::SimulationSessionStore.new(cache_root: ".cache/ace-taskflow/simulations")
      runner = Ace::Taskflow::Organisms::NextPhaseSimulationRunner.new(session_store: store)
      result = runner.run(source: source_path, modes: ["plan"], no_writeback: true)

      session_dir = result[:session_dir]
      assert Dir.exist?(session_dir), "session dir should exist"
      assert File.exist?(File.join(session_dir, "request.yml"))
      assert File.exist?(File.join(session_dir, "stage-task-plan.yml"))
      assert File.exist?(File.join(session_dir, "synthesis.yml"))
      assert File.exist?(File.join(session_dir, "writeback-preview.md"))
      assert File.exist?(File.join(session_dir, "run-summary.md"))
      refute File.exist?(File.join(session_dir, "run-failure.yml"))
    end
  end

  def test_run_persists_failure_artifacts_when_stage_execution_raises
    with_real_test_project do |dir|
      source_path = File.join(dir, "tmp-task-source.s.md")
      File.write(source_path, "# Temporary source\n")

      store = Ace::Taskflow::Molecules::SimulationSessionStore.new(cache_root: ".cache/ace-taskflow/simulations")
      runner = Ace::Taskflow::Organisms::NextPhaseSimulationRunner.new(
        session_store: store,
        stage_executor: lambda { |_args|
          raise "synthetic stage failure"
        }
      )

      assert_raises(RuntimeError) { runner.run(source: source_path, modes: ["plan"], no_writeback: true) }

      run_dirs = Dir.glob(File.join(store.cache_root, "*")).sort
      refute_empty run_dirs, "at least one run directory should exist after failure"

      session_dir = run_dirs.last
      failure_path = File.join(session_dir, "run-failure.yml")
      summary_path = File.join(session_dir, "run-summary.md")

      assert File.exist?(failure_path), "run-failure.yml should exist"
      assert File.exist?(summary_path), "run-summary.md should exist"

      failure_data = YAML.safe_load_file(failure_path, permitted_classes: [Symbol], aliases: true)
      status = failure_data["status"] || failure_data[:status]
      failed_stage = failure_data["failed_stage"] || failure_data[:failed_stage]
      error_message = failure_data["error"] || failure_data[:error]
      assert_equal "failed", status
      assert_equal "plan", failed_stage
      assert_includes error_message, "synthetic stage failure"
    end
  end

  def test_missing_source_fails_fast
    with_real_test_project do
      store = Ace::Taskflow::Molecules::SimulationSessionStore.new(cache_root: ".cache/ace-taskflow/simulations")
      runner = Ace::Taskflow::Organisms::NextPhaseSimulationRunner.new(session_store: store)

      error = assert_raises(ArgumentError) do
        runner.run(source: "missing-source-ref-xyz", modes: ["plan"], no_writeback: true)
      end

      assert_includes error.message, "not found"
    end
  end
end
