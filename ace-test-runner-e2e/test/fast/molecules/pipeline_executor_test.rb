# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"
require "tmpdir"

class PipelineExecutorTest < Minitest::Test
  PipelineExecutor = Ace::Test::EndToEndRunner::Molecules::PipelineExecutor
  PipelineReportGenerator = Ace::Test::EndToEndRunner::Molecules::PipelineReportGenerator
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestCase = Ace::Test::EndToEndRunner::Models::TestCase

  class FakeSandboxBuilder
    def build(scenario:, sandbox_path:, test_cases: nil)
      FileUtils.mkdir_p(sandbox_path)
      {"PROJECT_ROOT_PATH" => File.expand_path(sandbox_path)}
    end
  end

  class FakePromptBundler
    def prepare_runner(scenario:, sandbox_path:, test_cases: nil)
      cache_dir = File.join(sandbox_path, ".ace-local", "e2e")
      FileUtils.mkdir_p(cache_dir)
      {
        system_path: File.join(cache_dir, "runner-system.md"),
        prompt_path: File.join(cache_dir, "runner-prompt.md"),
        output_path: File.join(cache_dir, "runner-output.md")
      }.tap do |paths|
        File.write(paths[:system_path], "runner-system")
        File.write(paths[:prompt_path], "run prompt")
      end
    end

    def prepare_verifier(scenario:, sandbox_path:, test_cases: nil)
      cache_dir = File.join(sandbox_path, ".ace-local", "e2e")
      FileUtils.mkdir_p(cache_dir)
      {
        system_path: File.join(cache_dir, "verifier-system.md"),
        prompt_path: File.join(cache_dir, "verifier-prompt.md"),
        output_path: File.join(cache_dir, "verifier-output.md")
      }.tap do |paths|
        File.write(paths[:system_path], "verifier-system")
        File.write(paths[:prompt_path], "verifier prompt")
      end
    end
  end

  def test_missing_required_artifacts_ignores_optional
    Dir.mktmpdir do |tmpdir|
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(sandbox_path)

      FileUtils.mkdir_p(File.join(sandbox_path, "results", "tc", "01"))
      File.write(File.join(sandbox_path, "results", "tc", "01", "optional.txt"), "optional")

      scenario = build_scenario(
        tmpdir: tmpdir,
        declared_artifacts: ["results/tc/01/required.txt"],
        optional_artifacts: ["results/tc/01/optional.txt"]
      )
      executor = PipelineExecutor.new(
        provider: "claude:haiku",
        timeout: 10,
        sandbox_builder: FakeSandboxBuilder.new,
        prompt_bundler: FakePromptBundler.new
      )

      original_query = Ace::LLM::QueryInterface.method(:query) if Ace::LLM::QueryInterface.respond_to?(:query)
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |*_args, **_kwargs|
        {text: "runner output"}
      end
      begin
        result = executor.execute(
          scenario: scenario,
          cli_args: "",
          sandbox_path: sandbox_path,
          report_dir: report_dir
        )

        assert_equal "error", result.status
        assert_includes result.error, "results/tc/01/required.txt"
      ensure
        if original_query
          Ace::LLM::QueryInterface.define_singleton_method(:query, original_query)
        else
          Ace::LLM::QueryInterface.singleton_class.send(:remove_method, :query)
        end
      end

      manifest = JSON.parse(File.read(File.join(report_dir, "tc001.manifest.json")))
      assert_includes manifest.keys, "optional_artifacts"
      assert_equal ["results/tc/01/optional.txt"], manifest["optional_artifacts"]
    end
  end

  def test_snapshot_includes_optional_artifacts
    Dir.mktmpdir do |tmpdir|
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(sandbox_path)

      FileUtils.mkdir_p(File.join(sandbox_path, "results", "tc", "01"))
      File.write(File.join(sandbox_path, "results", "tc", "01", "required.txt"), "required")
      File.write(File.join(sandbox_path, "results", "tc", "01", "optional.txt"), "optional")

      scenario = build_scenario(
        tmpdir: tmpdir,
        declared_artifacts: ["results/tc/01/required.txt"],
        optional_artifacts: ["results/tc/01/optional.txt"]
      )
      executor = PipelineExecutor.new(
        provider: "claude:haiku",
        timeout: 10,
        sandbox_builder: FakeSandboxBuilder.new,
        prompt_bundler: FakePromptBundler.new,
        report_generator: PipelineReportGenerator.new
      )

      responses = [
        {text: "runner complete"},
        {text: "### Goal 1 - Sample\n- **Verdict**: PASS\n"}
      ]

      original_query = Ace::LLM::QueryInterface.method(:query) if Ace::LLM::QueryInterface.respond_to?(:query)
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |*_args, **_kwargs|
        responses.shift
      end
      begin
        result = executor.execute(
          scenario: scenario,
          cli_args: "",
          sandbox_path: sandbox_path,
          report_dir: report_dir
        )

        assert_equal "pass", result.status
      ensure
        if original_query
          Ace::LLM::QueryInterface.define_singleton_method(:query, original_query)
        else
          Ace::LLM::QueryInterface.singleton_class.send(:remove_method, :query)
        end
      end

      snapshot = JSON.parse(File.read(File.join(report_dir, "artifact-snapshot.json")))
      assert_equal(
        ["results/tc/01/optional.txt", "results/tc/01/required.txt"],
        snapshot["TC-001"].sort
      )
    end
  end

  private

  def build_scenario(tmpdir:, declared_artifacts:, optional_artifacts:)
    TestScenario.new(
      test_id: "TS-PIPE-001",
      title: "Pipeline Artifacts",
      area: "test",
      package: "ace-test-runner-e2e",
      file_path: File.join(tmpdir, "scenario.yml"),
      content: "",
      dir_path: tmpdir,
      test_cases: [
        TestCase.new(
          tc_id: "TC-001",
          title: "One",
          content: "",
          file_path: File.join(tmpdir, "TC-001.runner.md"),
          goal_format: "standalone",
          declared_artifacts: declared_artifacts,
          optional_artifacts: optional_artifacts
        )
      ]
    )
  end
end
