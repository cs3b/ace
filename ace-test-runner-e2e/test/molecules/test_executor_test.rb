# frozen_string_literal: true

require_relative "../test_helper"

class TestExecutorTest < Minitest::Test
  TestExecutor = Ace::Test::EndToEndRunner::Molecules::TestExecutor
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario

  def test_execute_via_skill_catches_unexpected_error
    executor = TestExecutor.new(provider: "opencode:glm", timeout: 10)
    scenario = create_scenario

    # Stub QueryInterface.query to raise an IOError (simulating stream closed)
    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { raise IOError, "stream closed in another thread" }) do
      result = executor.execute(scenario)

      assert_equal "TS-LINT-001", result.test_id
      assert_equal "error", result.status
      assert_equal "Unexpected execution error", result.summary
      assert_includes result.error, "IOError"
      assert_includes result.error, "stream closed in another thread"
    end
  end

  def test_execute_via_skill_detects_shell_misinvocation
    executor = TestExecutor.new(provider: "opencode:glm", timeout: 10)
    scenario = create_scenario

    bad_response = {
      text: "bash: line 1: /ace-e2e-run: command not found"
    }

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { bad_response }) do
      result = executor.execute(scenario)

      assert_equal "TS-LINT-001", result.test_id
      assert_equal "error", result.status
      assert_equal "Skill invocation failed before test execution", result.summary
      assert_includes result.error, "slash command was executed in a shell"
      assert_includes result.error, "/ace-e2e-run"
    end
  end

  def test_execute_via_prompt_catches_unexpected_error
    executor = TestExecutor.new(provider: "google:gemini-pro", timeout: 10)
    scenario = create_scenario

    # Stub QueryInterface.query to raise an Errno::EPIPE
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

  def test_execute_tc_via_skill_catches_unexpected_error
    executor = TestExecutor.new(provider: "opencode:glm", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { raise IOError, "stream closed" }) do
      result = executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario)

      assert_equal "TS-LINT-001", result.test_id
      assert_equal "error", result.status
      assert_includes result.error, "IOError"
      assert_includes result.error, "stream closed"
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

  def test_execute_tc_via_prompt_catches_unexpected_error
    executor = TestExecutor.new(provider: "google:gemini-pro", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { raise Errno::EPIPE, "Broken pipe" }) do
      result = executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario)

      assert_equal "TS-LINT-001", result.test_id
      assert_equal "error", result.status
      assert_includes result.error, "Errno::EPIPE"
    end
  end

  def test_execute_tc_returns_test_result
    executor = TestExecutor.new(provider: "opencode:glm", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { raise IOError, "error" }) do
      result = executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario)
      assert_instance_of Ace::Test::EndToEndRunner::Models::TestResult, result
    end
  end

  def test_execute_tc_result_has_scenario_test_id
    executor = TestExecutor.new(provider: "opencode:glm", timeout: 10)
    scenario = create_scenario(test_id: "TS-REVIEW-005")
    tc = create_test_case(tc_id: "TC-003")

    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { raise IOError, "error" }) do
      result = executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario)
      assert_equal "TS-REVIEW-005", result.test_id
    end
  end

  def test_execute_passes_sandbox_and_env_to_prompt_builder
    executor = TestExecutor.new(provider: "claude:sonnet", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    env_vars = { "PROJECT_ROOT" => "/code" }

    captured_prompt = nil
    Ace::LLM::QueryInterface.stub(:query, ->(*args, **_kw) { captured_prompt = args[1]; { text: "- **Test ID**: TS-LINT-001\n- **Status**: pass\n- **Passed**: 1\n- **Failed**: 0\n- **Total**: 1\n- **Report Paths**: x\n- **Issues**: None" } }) do
      executor.execute(scenario, sandbox_path: "/tmp/sb", env_vars: env_vars)
    end

    assert captured_prompt.include?("--sandbox /tmp/sb"), "Prompt should contain --sandbox flag"
    assert captured_prompt.include?("--env PROJECT_ROOT=/code"), "Prompt should contain --env flag"
  end

  def test_execute_via_skill_passes_env_vars_as_subprocess_env
    executor = TestExecutor.new(provider: "claude:sonnet", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    env_vars = { "ACE_TMUX_SESSION" => "TS-TEST-001-e2e", "PROJECT_ROOT" => "/code" }

    captured_kwargs = nil
    Ace::LLM::QueryInterface.stub(:query, ->(*args, **kw) { captured_kwargs = kw; { text: "- **Test ID**: TS-LINT-001\n- **Status**: pass\n- **Passed**: 1\n- **Failed**: 0\n- **Total**: 1\n- **Report Paths**: x\n- **Issues**: None" } }) do
      executor.execute(scenario, sandbox_path: "/tmp/sb", env_vars: env_vars)
    end

    assert_equal env_vars, captured_kwargs[:subprocess_env], "env_vars should be passed as subprocess_env to QueryInterface.query"
  end

  def test_execute_tc_via_skill_passes_env_vars_as_subprocess_env
    executor = TestExecutor.new(provider: "claude:sonnet", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case
    env_vars = { "ACE_TMUX_SESSION" => "TS-TEST-001-e2e" }

    captured_kwargs = nil
    Ace::LLM::QueryInterface.stub(:query, ->(*args, **kw) { captured_kwargs = kw; { text: "- **Test ID**: TS-LINT-001\n- **TC ID**: TC-001\n- **Status**: pass\n- **Issues**: None" } }) do
      executor.execute_tc(test_case: tc, sandbox_path: "/tmp/sb", scenario: scenario, env_vars: env_vars)
    end

    assert_equal env_vars, captured_kwargs[:subprocess_env], "env_vars should be passed as subprocess_env to QueryInterface.query for TC execution"
  end

  def test_execute_via_skill_passes_nil_subprocess_env_when_no_env_vars
    executor = TestExecutor.new(provider: "claude:sonnet", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")

    captured_kwargs = nil
    Ace::LLM::QueryInterface.stub(:query, ->(*args, **kw) { captured_kwargs = kw; { text: "- **Test ID**: TS-LINT-001\n- **Status**: pass\n- **Passed**: 1\n- **Failed**: 0\n- **Total**: 1\n- **Report Paths**: x\n- **Issues**: None" } }) do
      executor.execute(scenario, sandbox_path: "/tmp/sb")
    end

    assert_nil captured_kwargs[:subprocess_env], "subprocess_env should be nil when env_vars not provided"
  end

  def test_non_claude_cli_uses_skill_invocation
    executor = TestExecutor.new(provider: "gemini:flash", timeout: 10)
    scenario = create_scenario(test_id: "TS-LINT-001")

    captured_prompt = nil
    Ace::LLM::QueryInterface.stub(:query, ->(*args, **_kw) { captured_prompt = args[1]; { text: "- **Test ID**: TS-LINT-001\n- **Status**: pass\n- **Passed**: 1\n- **Failed**: 0\n- **Total**: 1\n- **Report Paths**: x\n- **Issues**: None" } }) do
      executor.execute(scenario, sandbox_path: "/tmp/sb")
    end

    assert captured_prompt.include?("/ace-e2e-run"), "Non-claude CLI provider should use skill invocation"
    assert captured_prompt.include?("--sandbox /tmp/sb"), "Non-claude CLI should pass --sandbox"
  end

  def test_execute_verify_mode_runs_runner_then_verifier
    executor = TestExecutor.new(provider: "claude:sonnet", timeout: 10)
    scenario = create_scenario(test_id: "TS-B36TS-001")

    prompts = []
    responses = [
      { text: "- **Test ID**: TS-B36TS-001\n- **Status**: pass\n- **Passed**: 8\n- **Failed**: 0\n- **Total**: 8\n- **Issues**: None" },
      { text: "- **Test ID**: TS-B36TS-001\n- **Status**: partial\n- **TCs Passed**: 6\n- **TCs Failed**: 2\n- **TCs Total**: 8\n- **Score**: 0.75\n- **Verdict**: partial\n- **Failed TCs**: TC-003:test-spec-error, TC-007:tool-bug\n- **Issues**: None" }
    ]

    Ace::LLM::QueryInterface.stub(:query, lambda { |*args, **_kw|
      prompts << args[1]
      responses.shift
    }) do
      result = executor.execute(scenario, sandbox_path: "/tmp/sb", verify: true)

      assert_equal "partial", result.status
      assert_equal 8, result.test_cases.size
      assert_equal 2, result.test_cases.count { |tc| tc[:status] == "fail" }
    end

    assert_equal 2, prompts.size
    assert prompts[0].include?("/ace-e2e-run"), "First invocation should be runner command"
    assert prompts[1].include?("independent verifier"), "Second invocation should be verifier prompt"
  end

  def test_execute_goal_mode_standalone_uses_pipeline_and_always_runs_verifier
    Dir.mktmpdir do |tmpdir|
      scenario_dir = create_goal_mode_files(tmpdir)
      sandbox_path = File.join(tmpdir, "sandbox")
      report_dir = File.join(tmpdir, "reports")
      scenario = create_goal_scenario(scenario_dir)
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
          verify: false
        )

        assert_equal "partial", result.status
        assert_equal 2, result.total_count
        assert_equal 1, result.failed_count
        assert_equal report_dir, result.report_dir
      end

      assert_equal 2, calls.size, "runner and verifier should both execute"
      refute_includes calls[0][:prompt], "/ace-e2e-run"
      refute_includes calls[1][:prompt], "/ace-e2e-run"
      assert File.exist?(File.join(report_dir, "metadata.yml")), "goal-mode pipeline should write metadata"
    end
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

  def create_goal_scenario(dir_path)
    TestScenario.new(
      test_id: "TS-B36TS-001",
      title: "Goal Scenario",
      area: "timestamp",
      package: "ace-b36ts",
      priority: "high",
      duration: "~5min",
      file_path: File.join(dir_path, "scenario.yml"),
      content: "",
      mode: "goal",
      dir_path: dir_path,
      test_cases: [
        Ace::Test::EndToEndRunner::Models::TestCase.new(
          tc_id: "TC-001",
          title: "First",
          content: "",
          file_path: File.join(dir_path, "TC-001-first.runner.md"),
          mode: "goal",
          goal_format: "standalone"
        ),
        Ace::Test::EndToEndRunner::Models::TestCase.new(
          tc_id: "TC-002",
          title: "Second",
          content: "",
          file_path: File.join(dir_path, "TC-002-second.runner.md"),
          mode: "goal",
          goal_format: "standalone"
        )
      ],
      sandbox_layout: {
        "results/tc/01/" => "one",
        "results/tc/02/" => "two"
      }
    )
  end

  def create_goal_mode_files(tmpdir)
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
