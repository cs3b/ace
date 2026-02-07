# frozen_string_literal: true

require_relative "../test_helper"

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
    scenario = create_scenario(test_id: "MT-LINT-001")
    prompt = @builder.build(scenario)
    assert prompt.include?("MT-LINT-001"), "Prompt should include test ID"
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

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "MT-TEST-001",
      title: "Test Title",
      area: "test",
      package: "ace-test",
      file_path: "/tmp/test.mt.md",
      content: "# Test content"
    }
    Ace::Test::EndToEndRunner::Models::TestScenario.new(**defaults.merge(overrides))
  end
end
