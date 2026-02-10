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

      assert_equal "MT-LINT-001", result.test_id
      assert_equal "error", result.status
      assert_equal "Unexpected execution error", result.summary
      assert_includes result.error, "IOError"
      assert_includes result.error, "stream closed in another thread"
    end
  end

  def test_execute_via_prompt_catches_unexpected_error
    executor = TestExecutor.new(provider: "google:gemini-pro", timeout: 10)
    scenario = create_scenario

    # Stub QueryInterface.query to raise an Errno::EPIPE
    Ace::LLM::QueryInterface.stub(:query, ->(*_args, **_kw) { raise Errno::EPIPE, "Broken pipe" }) do
      result = executor.execute(scenario)

      assert_equal "MT-LINT-001", result.test_id
      assert_equal "error", result.status
      assert_equal "Unexpected execution error", result.summary
      assert_includes result.error, "Errno::EPIPE"
      assert_includes result.error, "Broken pipe"
    end
  end

  # --- TC-Level Execution ---

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

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "MT-LINT-001",
      title: "Test Title",
      area: "lint",
      package: "ace-lint",
      priority: "high",
      duration: "~15min",
      file_path: "/tmp/test.mt.md",
      content: "# Test content"
    }
    TestScenario.new(**defaults.merge(overrides))
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
