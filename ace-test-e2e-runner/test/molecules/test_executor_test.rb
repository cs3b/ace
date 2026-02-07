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
end
