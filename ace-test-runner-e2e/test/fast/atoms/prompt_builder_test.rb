# frozen_string_literal: true

require_relative "../../test_helper"

class PromptBuilderTest < Minitest::Test
  def setup
    @builder = Ace::Test::EndToEndRunner::Atoms::PromptBuilder.new
  end

  def test_system_prompt_is_defined
    system_prompt = Ace::Test::EndToEndRunner::Atoms::PromptBuilder::SYSTEM_PROMPT
    refute_nil system_prompt
    refute_empty system_prompt
    assert system_prompt.include?("JSON"), "System prompt should mention JSON output format"
    assert system_prompt.include?("test_id"), "System prompt should define test_id field"
    assert system_prompt.include?("status"), "System prompt should define status field"
  end

  def test_build_prompt_includes_test_id
    scenario = create_scenario(test_id: "TS-LINT-001")
    prompt = @builder.build(scenario)
    assert prompt.include?("TS-LINT-001"), "Prompt should include test ID"
  end

  def test_build_prompt_includes_package
    scenario = create_scenario(package: "ace-lint")
    prompt = @builder.build(scenario)
    assert prompt.include?("ace-lint"), "Prompt should include package name"
  end

  def test_build_prompt_includes_title
    scenario = create_scenario(title: "Ruby Validator Fallback")
    prompt = @builder.build(scenario)
    assert prompt.include?("Ruby Validator Fallback"), "Prompt should include title"
  end

  def test_build_prompt_includes_content
    scenario = create_scenario(content: "## Test Cases\n\n### TC-001: Check something")
    prompt = @builder.build(scenario)
    assert prompt.include?("TC-001"), "Prompt should include test content"
  end

  # --- TC-Level Prompts ---

  def test_tc_system_prompt_is_defined
    tc_prompt = Ace::Test::EndToEndRunner::Atoms::PromptBuilder::TC_SYSTEM_PROMPT
    refute_nil tc_prompt
    refute_empty tc_prompt
    assert tc_prompt.include?("tc_id"), "TC system prompt should define tc_id field"
    assert tc_prompt.include?("single test case"), "TC system prompt should mention single test case"
  end

  def test_tc_system_prompt_mentions_sandbox
    tc_prompt = Ace::Test::EndToEndRunner::Atoms::PromptBuilder::TC_SYSTEM_PROMPT
    assert tc_prompt.include?("pre-populated"), "TC system prompt should mention pre-populated sandbox"
  end

  def test_tc_system_prompt_no_execute_all_instruction
    tc_prompt = Ace::Test::EndToEndRunner::Atoms::PromptBuilder::TC_SYSTEM_PROMPT
    refute tc_prompt.include?("Execute ALL test cases"), "TC system prompt should not mention executing all TCs"
  end

  def test_build_tc_includes_test_id
    scenario = create_scenario(test_id: "TS-LINT-001")
    tc = create_test_case
    prompt = @builder.build_tc(test_case: tc, scenario: scenario, sandbox_path: "/tmp/sandbox")
    assert prompt.include?("TS-LINT-001"), "TC prompt should include scenario test ID"
  end

  def test_build_tc_includes_tc_id
    tc = create_test_case(tc_id: "TC-003")
    prompt = @builder.build_tc(test_case: tc, scenario: create_scenario, sandbox_path: "/tmp/sandbox")
    assert prompt.include?("TC-003"), "TC prompt should include TC ID"
  end

  def test_build_tc_includes_package
    scenario = create_scenario(package: "ace-lint")
    tc = create_test_case
    prompt = @builder.build_tc(test_case: tc, scenario: scenario, sandbox_path: "/tmp/sandbox")
    assert prompt.include?("ace-lint"), "TC prompt should include package"
  end

  def test_build_tc_includes_sandbox_path
    tc = create_test_case
    prompt = @builder.build_tc(test_case: tc, scenario: create_scenario, sandbox_path: "/tmp/my-sandbox")
    assert prompt.include?("/tmp/my-sandbox"), "TC prompt should include sandbox path"
  end

  def test_build_tc_includes_tc_content
    tc = create_test_case(content: "## Steps\n\n1. Run ace-lint valid.rb")
    prompt = @builder.build_tc(test_case: tc, scenario: create_scenario, sandbox_path: "/tmp/sandbox")
    assert prompt.include?("Run ace-lint valid.rb"), "TC prompt should include TC content"
  end

  def test_build_tc_does_not_include_full_scenario_content
    scenario = create_scenario(content: "FULL SCENARIO CONTENT MARKER")
    tc = create_test_case(content: "## TC steps only")
    prompt = @builder.build_tc(test_case: tc, scenario: scenario, sandbox_path: "/tmp/sandbox")
    refute prompt.include?("FULL SCENARIO CONTENT MARKER"), "TC prompt should not include full scenario content"
  end

  # --- Pending TC Support ---

  def test_build_tc_pending_returns_skip_prompt
    tc = create_test_case(tc_id: "TC-003", pending: "Requires sandbox environment")
    prompt = @builder.build_tc(test_case: tc, scenario: create_scenario, sandbox_path: "/tmp/sandbox")
    assert prompt.include?("SKIP"), "Pending TC prompt should say SKIP"
    assert prompt.include?("TC-003"), "Pending TC prompt should include TC ID"
    assert prompt.include?("pending"), "Pending TC prompt should mention pending"
    assert prompt.include?("Requires sandbox environment"), "Pending TC prompt should include reason"
    assert prompt.include?('"skip"'), "Pending TC prompt should instruct skip status"
    refute prompt.include?("Execute the test case"), "Pending TC prompt should not ask for execution"
  end

  def test_build_tc_active_not_affected_by_pending
    tc = create_test_case(tc_id: "TC-001")
    prompt = @builder.build_tc(test_case: tc, scenario: create_scenario, sandbox_path: "/tmp/sandbox")
    refute prompt.include?("SKIP"), "Active TC prompt should not say SKIP"
    assert prompt.include?("Execute the test case"), "Active TC prompt should ask for execution"
  end

  def test_build_includes_pending_instruction_for_scenario_with_pending_tcs
    pending_tc = Ace::Test::EndToEndRunner::Models::TestCase.new(
      tc_id: "TC-003", title: "Pending TC", content: "# steps",
      file_path: "/tmp/TC-003.tc.md", pending: "Requires sandbox"
    )
    scenario = create_scenario(test_cases: [
      create_test_case(tc_id: "TC-001"),
      pending_tc
    ])
    prompt = @builder.build(scenario)
    assert prompt.include?("SKIP these test cases"), "Build prompt should mention pending TCs"
    assert prompt.include?("TC-003"), "Build prompt should list pending TC ID"
    assert prompt.include?("Requires sandbox"), "Build prompt should include pending reason"
  end

  def test_build_no_pending_instruction_when_no_pending_tcs
    scenario = create_scenario(test_cases: [create_test_case(tc_id: "TC-001")])
    prompt = @builder.build(scenario)
    refute prompt.include?("SKIP these test cases"), "Build prompt should not mention pending when none exist"
  end

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "TS-TEST-001",
      title: "Test Title",
      area: "test",
      package: "ace-test",
      file_path: "/tmp/test/scenario.yml",
      content: "# Test content",
      test_cases: []
    }
    Ace::Test::EndToEndRunner::Models::TestScenario.new(**defaults.merge(overrides))
  end

  def create_test_case(overrides = {})
    defaults = {
      tc_id: "TC-001",
      title: "Test Case Title",
      content: "## Objective\n\nVerify something.\n\n## Steps\n\n1. Do something\n\n## Expected\n\n- Result",
      file_path: "/tmp/test/TC-001-test-case.tc.md"
    }
    Ace::Test::EndToEndRunner::Models::TestCase.new(**defaults.merge(overrides))
  end
end
