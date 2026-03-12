# frozen_string_literal: true

require_relative "../test_helper"

class TestExecutorTest < Minitest::Test
  TestExecutor = Ace::Test::EndToEndRunner::Molecules::TestExecutor
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario

  def test_execute_pipeline_requires_deterministic_paths
    executor = TestExecutor.new(provider: "opencode:glm", timeout: 10)
    scenario = create_scenario

    result = executor.execute(scenario)

    assert_equal "TS-LINT-001", result.test_id
    assert_equal "error", result.status
    assert_equal "Execution pipeline requires run_id/report_dir", result.summary
  end

  def test_execute_pipeline_uses_runner_and_verifier_passes_env
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_pipeline_files(tmpdir)
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      scenario = create_pipeline_scenario(scenario_dir)
      executor = TestExecutor.new(provider: "claude:sonnet", timeout: 10)

      calls = []
      responses = [
        { text: "Runner completed." },
        { text: <<~OUT }
          ### Goal 1 - First
          - **Verdict**: PASS
          - **Evidence**: ok

          ### Goal 2 - Second
          - **Verdict**: FAIL
          - **Category**: tool-bug
          - **Evidence**: mismatch

          **Results: 1/2 passed**
        OUT
      ]

      Ace::LLM::QueryInterface.stub(:query, lambda { |*args, **kwargs|
        calls << { prompt: args[1], kwargs: kwargs }
        responses.shift
      }) do
        result = executor.execute(
          scenario,
          sandbox_path: sandbox_path,
          report_dir: report_dir,
          env_vars: { "CUSTOM" => "value" }
        )

        assert_equal "partial", result.status
        assert_equal 2, result.total_count
        assert_equal 1, result.failed_count
        assert_equal report_dir, result.report_dir
      end

      assert_equal 2, calls.size, "runner and verifier should both execute"
      assert File.exist?(File.join(report_dir, "metadata.yml")), "pipeline should write metadata"
      assert_equal "value", calls.first[:kwargs][:subprocess_env]["CUSTOM"]
      assert_equal File.expand_path(sandbox_path), calls.first[:kwargs][:subprocess_env]["PROJECT_ROOT_PATH"]
      assert_equal File.expand_path(sandbox_path), calls.first[:kwargs][:working_dir]
      assert_equal File.expand_path(sandbox_path), calls.last[:kwargs][:working_dir]
    end
  end

  def test_execute_pipeline_writes_error_report_when_verifier_output_is_unparseable
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_pipeline_files(tmpdir)
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      scenario = create_pipeline_scenario(scenario_dir)
      executor = TestExecutor.new(provider: "claude:sonnet", timeout: 10)

      responses = [
        { text: "Runner completed." },
        { text: "Verifier output was malformed and had no contract fields." }
      ]

      Ace::LLM::QueryInterface.stub(:query, lambda { |_provider, _prompt, **_kwargs|
        responses.shift
      }) do
        result = executor.execute(
          scenario,
          sandbox_path: sandbox_path,
          report_dir: report_dir
        )

        assert_equal "error", result.status
        assert_equal report_dir, result.report_dir
      end

      metadata = YAML.safe_load_file(File.join(report_dir, "metadata.yml"))
      assert_equal "error", metadata["status"]
    end
  end

  def test_execute_via_prompt_catches_unexpected_error
    executor = TestExecutor.new(provider: "google:gemini-pro", timeout: 10)
    scenario = create_scenario

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { raise Errno::EPIPE, "Broken pipe" }) do
      result = executor.execute(scenario)

      assert_equal "TS-LINT-001", result.test_id
      assert_equal "error", result.status
      assert_equal "Unexpected execution error", result.summary
      assert_includes result.error, "Errno::EPIPE"
      assert_includes result.error, "Broken pipe"
    end
  end

  # --- TC-Level Execution ---

  def test_execute_tc_via_prompt_happy_path
    executor = TestExecutor.new(provider: "google:gemini-pro", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case

    valid_response = {
      text: '{"test_id":"TS-LINT-001","tc_id":"TC-001","status":"pass","test_cases":[{"id":"TC-001","description":"Test","status":"pass"}],"summary":"TC-001 passed"}'
    }

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { valid_response }) do
      result = executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario)

      assert_equal "TS-LINT-001", result.test_id
      assert_equal "pass", result.status
      assert_equal 1, result.test_cases.size
      assert_equal "TC-001", result.test_cases.first[:id]
    end
  end

  def test_execute_tc_via_skill_happy_path
    executor = TestExecutor.new(provider: "opencode:glm", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case

    valid_response = {
      text: "- **Test ID**: TS-LINT-001\n- **TC ID**: TC-001\n- **Status**: pass\n- **Issues**: None"
    }

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { valid_response }) do
      result = executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario)

      assert_equal "TS-LINT-001", result.test_id
      assert_equal "pass", result.status
      assert_equal 1, result.test_cases.size
      assert_equal "TC-001", result.test_cases.first[:id]
    end
  end

  def test_execute_tc_via_skill_detects_no_tests_found_error
    executor = TestExecutor.new(provider: "opencode:glm", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case

    bad_response = {
      text: "No tests found for package 'ace-overseer' with ID 'TS-OVERSEER-002'"
    }

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { bad_response }) do
      result = executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario)

      assert_equal "TS-LINT-001", result.test_id
      assert_equal "error", result.status
      assert_equal "TC skill invocation failed before test execution", result.summary
      assert_includes result.error, "No tests found for package"
    end
  end

  def test_execute_tc_via_skill_passes_env_vars_as_subprocess_env
    executor = TestExecutor.new(provider: "claude:sonnet", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case
    env_vars = { "ACE_TMUX_SESSION" => "TS-TEST-001-e2e" }

    captured_kwargs = nil
    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **kw) { captured_kwargs = kw; { text: "- **Test ID**: TS-LINT-001\n- **TC ID**: TC-001\n- **Status**: pass\n- **Issues**: None" } }) do
      executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario, env_vars: env_vars)
    end

    assert_equal env_vars, captured_kwargs[:subprocess_env], "env_vars should be passed as subprocess_env to QueryInterface.query for TC execution"
    assert_equal "/tmp/sb", captured_kwargs[:working_dir], "sandbox_path should be threaded as working_dir for TC execution"
  end

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "TS-LINT-001",
      title: "Test Title",
      area: "lint",
      package: "ace-lint",
      priority: "high",
      duration: "~15min",
      file_path: "/tmp/test/scenario.yml",
      content: "# Test content"
    }
    TestScenario.new(**defaults.merge(overrides))
  end

  def create_pipeline_scenario(dir_path)
    TestScenario.new(
      test_id: "TS-B36TS-001",
      title: "Pipeline Scenario",
      area: "timestamp",
      package: "ace-b36ts",
      priority: "high",
      duration: "~5min",
      file_path: File.join(dir_path, "scenario.yml"),
      content: "",
      dir_path: dir_path,
      test_cases: [
        Ace::Test::EndToEndRunner::Models::TestCase.new(
          tc_id: "TC-001",
          title: "First",
          content: "",
          file_path: File.join(dir_path, "TC-001-first.runner.md"),
          goal_format: "standalone"
        ),
        Ace::Test::EndToEndRunner::Models::TestCase.new(
          tc_id: "TC-002",
          title: "Second",
          content: "",
          file_path: File.join(dir_path, "TC-002-second.runner.md"),
          goal_format: "standalone"
        )
      ],
      sandbox_layout: {
        "results/tc/01/" => "one",
        "results/tc/02/" => "two"
      }
    )
  end

  def create_pipeline_files(tmpdir)
    dir_path = File.join(tmpdir, "TS-B36TS-001")
    FileUtils.mkdir_p(dir_path)
    File.write(File.join(dir_path, "runner.yml.md"), <<~MD)
      ---
      bundle:
        files:
          - ./TC-001-first.runner.md
          - ./TC-002-second.runner.md
      ---

      # Runner
      Workspace root: (current directory)
    MD
    File.write(File.join(dir_path, "verifier.yml.md"), <<~MD)
      ---
      bundle:
        files:
          - ./TC-001-first.verify.md
          - ./TC-002-second.verify.md
      ---

      # Verifier
    MD
    File.write(File.join(dir_path, "TC-001-first.runner.md"), "# Goal 1")
    File.write(File.join(dir_path, "TC-002-second.runner.md"), "# Goal 2")
    File.write(File.join(dir_path, "TC-001-first.verify.md"), "# Verify 1")
    File.write(File.join(dir_path, "TC-002-second.verify.md"), "# Verify 2")
    dir_path
  end

  def create_test_case(overrides = {})
    defaults = {
      tc_id: "TC-001",
      title: "Test Case Title",
      content: "## Objective\n\nVerify something.",
      file_path: "/tmp/test/TC-001-test-case.tc.md"
    }
    Ace::Test::EndToEndRunner::Models::TestCase.new(**defaults.merge(overrides))
  end
end
