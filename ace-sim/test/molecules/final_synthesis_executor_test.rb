# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class FinalSynthesisExecutorTest < AceSimTestCase
  class HappyRunner
    def call(args)
      case args[0]
      when "ace-bundle"
        output_path = args[args.index("--output") + 1]
        File.write(output_path, "Prompt")
      when "ace-llm"
        output_path = args[args.index("--output") + 1]
        File.write(
          output_path,
          <<~MD
            <suggestions-report>
            # Suggestions

            - Update this
            </suggestions-report>

            <source-revised>
            # Revised Source

            Updated source content.
            </source-revised>
          MD
        )
      end
      {success: true, stdout: "", stderr: "", exit_code: 0}
    end
  end

  class InvalidSequenceRunner
    def call(args)
      if args[0] == "ace-bundle"
        output_path = args[args.index("--output") + 1]
        File.write(output_path, "Prompt")
        return {success: true, stdout: "", stderr: "", exit_code: 0}
      end

      output_path = args[args.index("--output") + 1]
      File.write(output_path, "# Missing required tags")
      {success: true, stdout: "", stderr: "", exit_code: 0}
    end
  end

  class FailingLlmRunner
    def call(args)
      if args[0] == "ace-bundle"
        output_path = args[args.index("--output") + 1]
        File.write(output_path, "Prompt")
        return {success: true, stdout: "", stderr: "", exit_code: 0}
      end

      {success: false, stdout: "", stderr: "llm failed", exit_code: 1}
    end
  end

  def build_session(source)
    Ace::Sim::Models::SimulationSession.new(
      preset: "validate-idea",
      source: source,
      steps: %w[draft plan],
      providers: ["codex:mini"],
      repeat: 1,
      dry_run: false,
      writeback: false,
      synthesis_workflow: "wfi://task/review",
      synthesis_provider: "glite",
      step_bundles: {
        "draft" => File.expand_path("../../.ace-defaults/sim/steps/draft.md", __dir__),
        "plan" => File.expand_path("../../.ace-defaults/sim/steps/plan.md", __dir__)
      }
    )
  end

  def test_generates_report_and_revised_source
    Dir.mktmpdir do |dir|
      source = File.join(dir, "source.md")
      File.write(source, "# Original source\n")
      bundled_input = File.join(dir, "input.bundle.md")
      File.write(bundled_input, "# Bundled source\n")
      run_dir = File.join(dir, "simulations", "run1")
      FileUtils.mkdir_p(run_dir)
      chain_output = File.join(run_dir, "chains", "codex-mini-1", "01-draft", "output.md")
      FileUtils.mkdir_p(File.dirname(chain_output))
      File.write(chain_output, "step output")

      session = build_session(source)
      chains = [{
        "provider" => "codex:mini",
        "iteration" => 1,
        "status" => "ok",
        "steps" => [{"step" => "draft", "status" => "ok", "output_path" => chain_output}]
      }]

      result = Ace::Sim::Molecules::FinalSynthesisExecutor.new(command_runner: HappyRunner.new).execute(
        run_dir: run_dir,
        session: session,
        chains: chains,
        source_original_input_path: bundled_input
      )

      assert_equal "ok", result["status"]
      assert_equal "glite", result["provider"]
      assert File.exist?(File.join(run_dir, "final", "source.original.md"))
      assert File.exist?(File.join(run_dir, "final", "input.md"))
      assert File.exist?(File.join(run_dir, "final", "user.bundle.md"))
      assert File.exist?(File.join(run_dir, "final", "user.prompt.md"))
      assert File.exist?(File.join(run_dir, "final", "output.sequence.md"))
      assert File.exist?(File.join(run_dir, "final", "suggestions.report.md"))
      assert File.exist?(File.join(run_dir, "final", "source.revised.md"))

      report = File.read(File.join(run_dir, "final", "suggestions.report.md"))
      revised = File.read(File.join(run_dir, "final", "source.revised.md"))
      original = File.read(File.join(run_dir, "final", "source.original.md"))
      assert_includes report, "# Suggestions"
      assert_includes revised, "# Revised Source"
      assert_equal "# Bundled source\n", original
    end
  end

  def test_returns_failed_when_sequence_missing_required_tags
    Dir.mktmpdir do |dir|
      source = File.join(dir, "source.md")
      File.write(source, "source")
      run_dir = File.join(dir, "simulations", "run1")
      FileUtils.mkdir_p(run_dir)

      session = build_session(source)
      result = Ace::Sim::Molecules::FinalSynthesisExecutor.new(command_runner: InvalidSequenceRunner.new).execute(
        run_dir: run_dir,
        session: session,
        chains: []
      )

      assert_equal "failed", result["status"]
      assert_match(/missing required tags/, result["error"])
      assert File.exist?(File.join(run_dir, "final", "output.sequence.md"))
      refute File.exist?(File.join(run_dir, "final", "source.revised.md"))
    end
  end

  def test_returns_failed_when_llm_fails
    Dir.mktmpdir do |dir|
      source = File.join(dir, "source.md")
      File.write(source, "source")
      run_dir = File.join(dir, "simulations", "run1")
      FileUtils.mkdir_p(run_dir)

      session = build_session(source)

      result = Ace::Sim::Molecules::FinalSynthesisExecutor.new(command_runner: FailingLlmRunner.new).execute(
        run_dir: run_dir,
        session: session,
        chains: []
      )

      assert_equal "failed", result["status"]
      assert_match(/ace-llm failed/, result["error"])
    end
  end
end
