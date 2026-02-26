# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/next_phase_simulation_runner"
require_relative "../../lib/ace/taskflow/molecules/simulation_session_store"
require "fileutils"
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

  def test_run_idea_source_enforces_draft_then_plan_and_writes_back
    with_real_tmpdir do |dir|
      ideas_dir = File.join(dir, "ideas")
      FileUtils.mkdir_p(ideas_dir)
      source_path = File.join(ideas_dir, "iterative-review.idea.s.md")
      File.write(source_path, "# Idea\n")

      stage_calls = []
      stage_executor = lambda do |resolved_source:, mode:, run_id:, previous_stage_output: nil|
        stage_calls << [mode, previous_stage_output&.dig(:mode)]
        {
          run_id: run_id,
          mode: mode,
          source: resolved_source[:input],
          questions: ["Question from #{mode}"],
          refinements: ["Refinement from #{mode}"]
        }
      end

      runner = Ace::Taskflow::Organisms::NextPhaseSimulationRunner.new(stage_executor: stage_executor)
      result = runner.run(source: source_path, modes: ["plan", "draft"], no_writeback: false)

      assert_equal "done", result.dig(:session, :status)
      assert_equal [%w[draft], %w[plan]].map(&:first), stage_calls.map(&:first)
      assert_equal [nil, "draft"], stage_calls.map(&:last)

      updated = File.read(source_path)
      assert_includes updated, "## Simulation Review (Next-Phase)"
      assert_includes updated, "Question from draft"
      assert_includes updated, "Question from plan"
      assert_equal 1, updated.scan("## Simulation Review (Next-Phase)").length
    end
  end

  def test_run_persists_failure_artifacts_when_draft_stage_fails
    with_real_tmpdir do |dir|
      ideas_dir = File.join(dir, "ideas")
      FileUtils.mkdir_p(ideas_dir)
      source_path = File.join(ideas_dir, "failing-draft.idea.s.md")
      File.write(source_path, "# Idea\n")

      store = Ace::Taskflow::Molecules::SimulationSessionStore.new(cache_root: ".cache/ace-taskflow/simulations")
      runner = Ace::Taskflow::Organisms::NextPhaseSimulationRunner.new(
        session_store: store,
        stage_executor: lambda { |mode:, **_args|
          raise "synthetic stage failure" if mode == "draft"

          { mode: mode }
        }
      )

      assert_raises(RuntimeError) { runner.run(source: source_path, modes: ["draft", "plan"], no_writeback: true) }

      run_dirs = Dir.glob(File.join(store.cache_root, "*")).sort
      refute_empty run_dirs, "at least one run directory should exist after failure"

      session_dir = run_dirs.last
      failure_data = YAML.safe_load_file(File.join(session_dir, "run-failure.yml"), permitted_classes: [Symbol], aliases: true)
      assert_equal "failed", failure_data["status"] || failure_data[:status]
      assert_equal "draft", failure_data["failed_stage"] || failure_data[:failed_stage]
      refute File.exist?(File.join(session_dir, "stage-idea-plan.yml"))
    end
  end

  def test_run_keeps_partial_synthesis_when_plan_stage_fails_for_idea_source
    with_real_tmpdir do |dir|
      ideas_dir = File.join(dir, "ideas")
      FileUtils.mkdir_p(ideas_dir)
      source_path = File.join(ideas_dir, "partial-plan.idea.s.md")
      File.write(source_path, "# Idea\n")

      runner = Ace::Taskflow::Organisms::NextPhaseSimulationRunner.new(
        stage_executor: lambda { |mode:, **_args|
          if mode == "plan"
            raise "synthetic plan failure"
          end

          { mode: mode, questions: ["draft question"], refinements: ["draft refinement"] }
        }
      )

      result = runner.run(source: source_path, modes: ["draft", "plan"], no_writeback: false)
      assert_equal "partial", result.dig(:session, :status)
      assert_equal "plan", result.dig(:session, :failed_stage)

      synthesis_path = File.join(result[:session_dir], "synthesis.yml")
      synthesis = YAML.safe_load_file(synthesis_path, permitted_classes: [Symbol], aliases: true)
      assert_equal "partial", synthesis["status"] || synthesis[:status]
      unresolved = synthesis["unresolved_gaps"] || synthesis[:unresolved_gaps]
      assert_includes unresolved.join("\n"), "synthetic plan failure"

      idea_content = File.read(source_path)
      refute_includes idea_content, "## Simulation Review (Next-Phase)"
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
