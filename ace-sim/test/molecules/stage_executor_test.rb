# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "tmpdir"

class StageExecutorTest < AceSimTestCase
  class HappyRunner
    def call(args)
      case args[0]
      when "ace-bundle"
        output_path = args[args.index("--output") + 1]
        File.write(output_path, "Prompt")
      when "ace-llm"
        output_path = args[args.index("--output") + 1]
        File.write(output_path, "result: ok\n")
      end
      {success: true, stdout: "", stderr: "", exit_code: 0}
    end
  end

  class EmptyOutputRunner
    def call(args)
      case args[0]
      when "ace-bundle"
        output_path = args[args.index("--output") + 1]
        File.write(output_path, "Prompt")
      when "ace-llm"
        output_path = args[args.index("--output") + 1]
        File.write(output_path, "")
      end
      {success: true, stdout: "", stderr: "", exit_code: 0}
    end
  end

  class FailingBundleRunner
    def call(_args)
      {success: false, stdout: "", stderr: "bundle failed", exit_code: 1}
    end
  end

  def test_executes_step_and_writes_required_files
    Dir.mktmpdir do |dir|
      step_dir = File.join(dir, "01-draft")
      FileUtils.mkdir_p(step_dir)
      bundle = File.join(dir, "draft.md")
      input = File.join(dir, "input.md")
      File.write(bundle, "---\nbundle:\n  embed_document_source: true\n---\n")
      File.write(input, "source text")

      result = Ace::Sim::Molecules::StageExecutor.new(command_runner: HappyRunner.new).execute(
        step: "draft",
        provider: "codex:mini",
        iteration: 1,
        step_dir: step_dir,
        step_bundle_path: bundle,
        input_source_path: input
      )

      assert_equal "ok", result["status"]
      assert File.exist?(File.join(step_dir, "input.md"))
      assert File.exist?(File.join(step_dir, "user.bundle.md"))
      assert File.exist?(File.join(step_dir, "user.prompt.md"))
      assert File.exist?(File.join(step_dir, "output.md"))
      assert_equal "source text", File.read(File.join(step_dir, "input.md"))
    end
  end

  def test_fails_for_empty_output
    Dir.mktmpdir do |dir|
      step_dir = File.join(dir, "02-plan")
      FileUtils.mkdir_p(step_dir)
      bundle = File.join(dir, "plan.md")
      input = File.join(dir, "input.md")
      File.write(bundle, "---\nbundle:\n  embed_document_source: true\n---\n")
      File.write(input, "source text")

      result = Ace::Sim::Molecules::StageExecutor.new(command_runner: EmptyOutputRunner.new).execute(
        step: "plan",
        provider: "codex:mini",
        iteration: 1,
        step_dir: step_dir,
        step_bundle_path: bundle,
        input_source_path: input
      )

      assert_equal "failed", result["status"]
      assert_match(/missing or empty/, result["error"])
    end
  end

  def test_fails_when_bundle_command_fails
    Dir.mktmpdir do |dir|
      step_dir = File.join(dir, "01-draft")
      FileUtils.mkdir_p(step_dir)
      bundle = File.join(dir, "draft.md")
      input = File.join(dir, "input.md")
      File.write(bundle, "---\nbundle:\n  embed_document_source: true\n---\n")
      File.write(input, "source text")

      result = Ace::Sim::Molecules::StageExecutor.new(command_runner: FailingBundleRunner.new).execute(
        step: "draft",
        provider: "codex:mini",
        iteration: 1,
        step_dir: step_dir,
        step_bundle_path: bundle,
        input_source_path: input
      )

      assert_equal "failed", result["status"]
      assert_match(/ace-bundle failed/, result["error"])
    end
  end
end
