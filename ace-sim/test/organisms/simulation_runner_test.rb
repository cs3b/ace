# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "tmpdir"

class SimulationRunnerTest < AceSimTestCase
  class SelectiveRunner
    def initialize(fail_provider: nil, fail_step: nil)
      @fail_provider = fail_provider
      @fail_step = fail_step
    end

    def call(args)
      case args[0]
      when "ace-bundle"
        output_path = args[args.index("--output") + 1]
        File.write(output_path, "Prompt")
        { success: true, stdout: "", stderr: "", exit_code: 0 }
      when "ace-llm"
        provider = args[1]
        output_path = args[args.index("--output") + 1]
        step_name = File.basename(File.dirname(output_path)).split("-", 2).last

        if provider == @fail_provider && step_name == @fail_step
          { success: false, stdout: "", stderr: "forced failure", exit_code: 1 }
        else
          File.write(output_path, "step: #{step_name}\n")
          { success: true, stdout: "", stderr: "", exit_code: 0 }
        end
      else
        { success: false, stdout: "", stderr: "unsupported", exit_code: 1 }
      end
    end
  end

  def build_session(source:, run_id: "runtest", providers: ["codex:mini"], repeat: 1)
    Ace::Sim::Models::SimulationSession.new(
      preset: "validate-idea",
      source: source,
      steps: %w[draft plan],
      providers: providers,
      repeat: repeat,
      dry_run: true,
      writeback: false,
      run_id: run_id,
      step_bundles: {
        "draft" => File.expand_path("../../.ace-defaults/sim/steps/draft.md", __dir__),
        "plan" => File.expand_path("../../.ace-defaults/sim/steps/plan.md", __dir__)
      }
    )
  end

  def test_runs_file_chained_artifacts
    Dir.mktmpdir do |dir|
      source = File.join(dir, "source.md")
      File.write(source, "initial")
      store = Ace::Sim::Molecules::SessionStore.new(cache_root: dir)
      executor = Ace::Sim::Molecules::StageExecutor.new(command_runner: SelectiveRunner.new)
      runner = Ace::Sim::Organisms::SimulationRunner.new(session_store: store, stage_executor: executor)

      result = runner.run(build_session(source: source))

      assert result[:success]
      run_dir = File.join(dir, "simulations", "runtest")
      assert File.exist?(File.join(run_dir, "session.yml"))
      assert File.exist?(File.join(run_dir, "synthesis.yml"))
      assert File.exist?(File.join(run_dir, "chains", "codex-mini-1", "01-draft", "input.md"))
      assert File.exist?(File.join(run_dir, "chains", "codex-mini-1", "01-draft", "output.md"))
      assert File.exist?(File.join(run_dir, "chains", "codex-mini-1", "02-plan", "input.md"))
      assert File.exist?(File.join(run_dir, "chains", "codex-mini-1", "02-plan", "output.md"))
    end
  end

  def test_failure_isolation_across_chains
    Dir.mktmpdir do |dir|
      source = File.join(dir, "source.md")
      File.write(source, "initial")
      store = Ace::Sim::Molecules::SessionStore.new(cache_root: dir)
      executor = Ace::Sim::Molecules::StageExecutor.new(
        command_runner: SelectiveRunner.new(fail_provider: "google:gflash", fail_step: "plan")
      )
      runner = Ace::Sim::Organisms::SimulationRunner.new(session_store: store, stage_executor: executor)

      result = runner.run(build_session(source: source, providers: ["codex:mini", "google:gflash"]))

      assert_equal "partial", result[:status]
      assert_equal 2, result[:chains].length
      ok_chain = result[:chains].find { |c| c["provider"] == "codex:mini" }
      failed_chain = result[:chains].find { |c| c["provider"] == "google:gflash" }
      assert_equal "ok", ok_chain["status"]
      assert_equal "failed", failed_chain["status"]
    end
  end

  def test_repeat_creates_independent_chains
    Dir.mktmpdir do |dir|
      source = File.join(dir, "source.md")
      File.write(source, "initial")
      store = Ace::Sim::Molecules::SessionStore.new(cache_root: dir)
      executor = Ace::Sim::Molecules::StageExecutor.new(command_runner: SelectiveRunner.new)
      runner = Ace::Sim::Organisms::SimulationRunner.new(session_store: store, stage_executor: executor)

      result = runner.run(build_session(source: source, repeat: 2))

      assert_equal 2, result[:chains].length
      run_dir = File.join(dir, "simulations", "runtest")
      assert Dir.exist?(File.join(run_dir, "chains", "codex-mini-1"))
      assert Dir.exist?(File.join(run_dir, "chains", "codex-mini-2"))
    end
  end
end
