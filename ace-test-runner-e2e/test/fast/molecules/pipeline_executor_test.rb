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
    attr_reader :build_calls, :prepare_existing_calls

    def initialize
      @build_calls = []
      @prepare_existing_calls = []
    end

    def build(scenario:, sandbox_path:, test_cases: nil)
      @build_calls << {scenario: scenario, sandbox_path: sandbox_path, test_cases: test_cases}
      FileUtils.mkdir_p(sandbox_path)
      {"PROJECT_ROOT_PATH" => File.expand_path(sandbox_path)}
    end

    def prepare_existing_sandbox(scenario:, sandbox_path:, test_cases: nil)
      @prepare_existing_calls << {scenario: scenario, sandbox_path: sandbox_path, test_cases: test_cases}
      FileUtils.mkdir_p(sandbox_path)
      {}
    end
  end

  class FakePromptBundler
    attr_reader :prepare_verifier_calls

    def initialize
      @prepare_verifier_calls = []
    end

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

    def prepare_verifier(scenario:, sandbox_path:, test_cases: nil, runner_observations: nil, artifact_contract: nil)
      @prepare_verifier_calls << {
        scenario: scenario,
        sandbox_path: sandbox_path,
        test_cases: test_cases,
        runner_observations: runner_observations,
        artifact_contract: artifact_contract
      }
      cache_dir = File.join(sandbox_path, ".ace-local", "e2e")
      FileUtils.mkdir_p(cache_dir)
      {
        system_path: File.join(cache_dir, "verifier-system.md"),
        prompt_path: File.join(cache_dir, "verifier-prompt.md"),
        output_path: File.join(cache_dir, "verifier-output.md")
      }.tap do |paths|
        File.write(paths[:system_path], "verifier-system")
        File.write(paths[:prompt_path], "verifier prompt\n#{runner_observations}")
      end
    end
  end

  class FakeSandboxBackend
    attr_reader :prepared_env_calls, :command_prefix_calls

    def initialize
      @prepared_env_calls = []
      @command_prefix_calls = []
    end

    def prepared_env(env)
      @prepared_env_calls << env
      env.merge("HOME" => "/tmp/fake-home", "TMPDIR" => "/tmp/fake-tmp", "XDG_RUNTIME_DIR" => "/tmp/fake-runtime")
    end

    def command_prefix(chdir:, env:)
      @command_prefix_calls << {chdir: chdir, env: env}
      ["bwrap", "--chdir", chdir, "--"]
    end
  end

  def test_missing_declared_artifacts_do_not_short_circuit_verifier
    Dir.mktmpdir do |tmpdir|
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(sandbox_path)
      fake_backend = FakeSandboxBackend.new

      scenario = build_scenario(
        tmpdir: tmpdir,
        declared_artifacts: ["results/tc/01/required.txt"],
        optional_artifacts: ["results/tc/01/optional.txt"]
      )
      prompt_bundler = FakePromptBundler.new
      executor = PipelineExecutor.new(
        provider: "claude:haiku",
        timeout: 10,
        sandbox_builder: FakeSandboxBuilder.new,
        prompt_bundler: prompt_bundler,
        report_generator: PipelineReportGenerator.new,
        sandbox_backend_factory: ->(_sandbox_path, source_root: nil) { fake_backend }
      )

      responses = [
        {text: "runner output"},
        {text: <<~OUT}
          ### Goal 1 - Sample
          - **Verdict**: PASS
          - **Evidence**: verifier judged final state without helper artifacts

          **Results: 1/1 passed**
        OUT
      ]
      original_query = Ace::LLM::QueryInterface.method(:query) if Ace::LLM::QueryInterface.respond_to?(:query)
      prefixes = []
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |*_args, **kwargs|
        prefixes << kwargs[:subprocess_command_prefix]
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
        assert_equal 2, fake_backend.command_prefix_calls.size
        assert_equal [["bwrap", "--chdir", sandbox_path, "--"], ["bwrap", "--chdir", sandbox_path, "--"]], prefixes
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

      snapshot = JSON.parse(File.read(File.join(report_dir, "artifact-snapshot.json")))
      assert_equal ["results/tc/01/required.txt"], snapshot["TC-001"]["missing_required_artifacts"]

      metadata = YAML.safe_load_file(File.join(report_dir, "metadata.yml"))
      assert_equal({"TC-001" => ["results/tc/01/required.txt"]}, metadata["missing_required_artifacts"])

      verifier_call = prompt_bundler.prepare_verifier_calls.last
      assert_equal ["results/tc/01/required.txt"], verifier_call[:artifact_contract]["TC-001"]["missing_required_artifacts"]
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
        report_generator: PipelineReportGenerator.new,
        sandbox_backend_factory: ->(_sandbox_path, source_root: nil) { FakeSandboxBackend.new }
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
        snapshot["TC-001"]["present_artifacts"].sort
      )
    end
  end

  def test_execute_strips_ambient_tmux_vars_from_subprocess_env
    Dir.mktmpdir do |tmpdir|
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      scenario = build_scenario(
        tmpdir: tmpdir,
        declared_artifacts: [],
        optional_artifacts: []
      )
      executor = PipelineExecutor.new(
        provider: "claude:haiku",
        timeout: 10,
        sandbox_builder: FakeSandboxBuilder.new,
        prompt_bundler: FakePromptBundler.new,
        report_generator: PipelineReportGenerator.new,
        sandbox_backend_factory: ->(_sandbox_path, source_root: nil) { FakeSandboxBackend.new }
      )

      original_query = Ace::LLM::QueryInterface.method(:query) if Ace::LLM::QueryInterface.respond_to?(:query)
      calls = []
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |_provider, _prompt, **kwargs|
        calls << kwargs[:subprocess_env]
        {text: (calls.length == 1) ? "runner complete" : "### Goal 1 - Sample\n- **Verdict**: PASS\n"}
      end

      result = executor.execute(
        scenario: scenario,
        cli_args: "",
        sandbox_path: sandbox_path,
        report_dir: report_dir,
        env_vars: {"TMUX" => "/tmp/tmux", "TMUX_PANE" => "%1", "ACE_TMUX_SESSION" => "safe-session"}
      )

      assert_equal "pass", result.status
      assert_equal 2, calls.length
      calls.each do |env|
        assert_nil env["TMUX"]
        assert_nil env["TMUX_PANE"]
        assert_equal "safe-session", env["ACE_TMUX_SESSION"]
      end
    ensure
      if original_query
        Ace::LLM::QueryInterface.define_singleton_method(:query, original_query)
      else
        Ace::LLM::QueryInterface.singleton_class.send(:remove_method, :query)
      end
    end
  end

  def test_execute_reuses_prepared_sandbox_without_rebuilding_it
    Dir.mktmpdir do |tmpdir|
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(sandbox_path)
      FileUtils.mkdir_p(File.join(sandbox_path, ".ace", "llm", "providers"))
      File.write(File.join(sandbox_path, ".ace", "llm", "providers", "anthropic.yml"), "provider: anthropic\n")

      scenario = build_scenario(
        tmpdir: tmpdir,
        declared_artifacts: [],
        optional_artifacts: []
      )
      sandbox_builder = FakeSandboxBuilder.new
      executor = PipelineExecutor.new(
        provider: "claude:haiku",
        timeout: 10,
        sandbox_builder: sandbox_builder,
        prompt_bundler: FakePromptBundler.new,
        report_generator: PipelineReportGenerator.new,
        sandbox_backend_factory: ->(_sandbox_path, source_root: nil) { FakeSandboxBackend.new }
      )

      responses = [
        {text: "runner complete"},
        {text: "### Goal 1 - Sample\n- **Verdict**: PASS\n"}
      ]

      original_query = Ace::LLM::QueryInterface.method(:query) if Ace::LLM::QueryInterface.respond_to?(:query)
      calls = []
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |*_args, **kwargs|
        calls << kwargs[:subprocess_env]
        responses.shift
      end
      begin
        result = executor.execute(
          scenario: scenario,
          cli_args: "",
          sandbox_path: sandbox_path,
          report_dir: report_dir,
          env_vars: {
            "PROJECT_ROOT_PATH" => File.expand_path(sandbox_path),
            "ACE_E2E_SOURCE_ROOT" => File.expand_path(tmpdir),
            "CUSTOM" => "preserved"
          }
        )

        assert_equal "pass", result.status
      ensure
        if original_query
          Ace::LLM::QueryInterface.define_singleton_method(:query, original_query)
        else
          Ace::LLM::QueryInterface.singleton_class.send(:remove_method, :query)
        end
      end

      assert_equal 0, sandbox_builder.build_calls.length
      assert_equal 1, sandbox_builder.prepare_existing_calls.length
      assert_equal "provider: anthropic\n", File.read(File.join(sandbox_path, ".ace", "llm", "providers", "anthropic.yml"))
      assert_equal "preserved", calls.first["CUSTOM"]
    end
  end

  def test_execute_passes_runner_observations_to_verifier_and_report_metadata
    Dir.mktmpdir do |tmpdir|
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      FileUtils.mkdir_p(File.join(sandbox_path, "results", "tc", "01"))
      scenario = build_scenario(
        tmpdir: tmpdir,
        declared_artifacts: [],
        optional_artifacts: []
      )
      executor = PipelineExecutor.new(
        provider: "claude:haiku",
        timeout: 10,
        sandbox_builder: FakeSandboxBuilder.new,
        prompt_bundler: FakePromptBundler.new,
        report_generator: PipelineReportGenerator.new,
        sandbox_backend_factory: ->(_sandbox_path, source_root: nil) { FakeSandboxBackend.new }
      )

      responses = [
        {text: <<~OUT},
          - **Test ID**: TS-PIPE-001
          - **Status**: pass
          - **Passed**: 1
          - **Failed**: 0
          - **Total**: 1
          - **Report Paths**: ts-pipe-reports/*
          - **Observations**: Created the declared sandbox outputs and confirmed final state.
        OUT
        {text: "### Goal 1 - Sample\n- **Verdict**: PASS\n- **Evidence**: sandbox state matched\n"}
      ]

      original_query = Ace::LLM::QueryInterface.method(:query) if Ace::LLM::QueryInterface.respond_to?(:query)
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |_provider, _prompt, **_kwargs|
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
        metadata = YAML.safe_load_file(File.join(report_dir, "metadata.yml"))
        assert_equal "Created the declared sandbox outputs and confirmed final state.", metadata["runner_observations"]

        verifier_prompt = File.read(File.join(sandbox_path, ".ace-local", "e2e", "verifier-prompt.md"))
        assert_includes verifier_prompt, "Created the declared sandbox outputs and confirmed final state."
      ensure
        if original_query
          Ace::LLM::QueryInterface.define_singleton_method(:query, original_query)
        else
          Ace::LLM::QueryInterface.singleton_class.send(:remove_method, :query)
        end
      end
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
