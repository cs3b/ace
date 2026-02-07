# frozen_string_literal: true

require_relative "../test_helper"

class SkillPromptBuilderTest < Minitest::Test
  SkillPromptBuilder = Ace::Test::EndToEndRunner::Atoms::SkillPromptBuilder

  def setup
    @builder = SkillPromptBuilder.new
  end

  def teardown
    SkillPromptBuilder.reset_default_instance!
  end

  # --- Provider Detection ---

  def test_cli_provider_detects_claude
    assert SkillPromptBuilder.cli_provider?("claude:sonnet")
    assert SkillPromptBuilder.cli_provider?("claude:opus")
  end

  def test_cli_provider_detects_gemini
    assert SkillPromptBuilder.cli_provider?("gemini:flash")
    assert SkillPromptBuilder.cli_provider?("gemini:pro")
  end

  def test_cli_provider_detects_codex
    assert SkillPromptBuilder.cli_provider?("codex:latest")
    assert SkillPromptBuilder.cli_provider?("codexoss:latest")
  end

  def test_cli_provider_detects_opencode
    assert SkillPromptBuilder.cli_provider?("opencode:model")
  end

  def test_cli_provider_rejects_api_providers
    refute SkillPromptBuilder.cli_provider?("google:gemini-2.5-flash")
    refute SkillPromptBuilder.cli_provider?("anthropic:claude-3")
    refute SkillPromptBuilder.cli_provider?("glite")
    refute SkillPromptBuilder.cli_provider?("openai:gpt-4")
  end

  def test_cli_provider_handles_nil_and_empty
    refute SkillPromptBuilder.cli_provider?(nil)
    refute SkillPromptBuilder.cli_provider?("")
  end

  # --- Skill Awareness ---

  def test_skill_aware_for_claude
    assert SkillPromptBuilder.skill_aware?("claude:sonnet")
    assert SkillPromptBuilder.skill_aware?("claude:opus")
  end

  def test_skill_aware_false_for_other_cli_providers
    refute SkillPromptBuilder.skill_aware?("gemini:flash")
    refute SkillPromptBuilder.skill_aware?("codex:latest")
    refute SkillPromptBuilder.skill_aware?("opencode:model")
  end

  # --- Provider Name Extraction ---

  def test_provider_name_extracts_before_colon
    assert_equal "claude", SkillPromptBuilder.provider_name("claude:sonnet")
    assert_equal "google", SkillPromptBuilder.provider_name("google:gemini-2.5-flash")
    assert_equal "gemini", SkillPromptBuilder.provider_name("gemini:flash")
  end

  def test_provider_name_handles_no_colon
    assert_equal "glite", SkillPromptBuilder.provider_name("glite")
  end

  # --- Required CLI Args ---

  def test_required_cli_args_for_claude
    assert_equal "dangerously-skip-permissions", SkillPromptBuilder.required_cli_args("claude:sonnet")
  end

  def test_required_cli_args_for_codex
    assert_equal "full-auto", SkillPromptBuilder.required_cli_args("codex:latest")
  end

  def test_required_cli_args_nil_for_gemini
    assert_nil SkillPromptBuilder.required_cli_args("gemini:flash")
  end

  def test_required_cli_args_nil_for_api_provider
    assert_nil SkillPromptBuilder.required_cli_args("google:gemini-2.5-flash")
  end

  # --- Config Injection ---

  def test_custom_config_overrides_cli_providers
    config = {
      "providers" => {
        "cli" => %w[custom-cli],
        "skill_aware" => %w[custom-cli],
        "cli_args" => {"custom-cli" => "auto-mode"}
      }
    }
    builder = SkillPromptBuilder.new(config)

    assert builder.cli_provider?("custom-cli:model")
    refute builder.cli_provider?("claude:sonnet")
    assert builder.skill_aware?("custom-cli:model")
    assert_equal "auto-mode", builder.required_cli_args("custom-cli:model")
  end

  def test_empty_config_uses_defaults
    builder = SkillPromptBuilder.new({})

    assert builder.cli_provider?("claude:sonnet")
    assert builder.skill_aware?("claude:sonnet")
    assert_equal "dangerously-skip-permissions", builder.required_cli_args("claude:sonnet")
  end

  # --- Skill Prompt Building ---

  def test_build_skill_prompt_format
    scenario = create_scenario(package: "ace-lint", test_id: "MT-LINT-001")
    prompt = @builder.build_skill_prompt(scenario)

    assert_equal "/ace:run-e2e-test ace-lint MT-LINT-001", prompt
  end

  def test_build_skill_prompt_with_different_package
    scenario = create_scenario(package: "ace-review", test_id: "MT-REVIEW-002")
    prompt = @builder.build_skill_prompt(scenario)

    assert_equal "/ace:run-e2e-test ace-review MT-REVIEW-002", prompt
  end

  def test_build_skill_prompt_with_run_id
    scenario = create_scenario(package: "ace-lint", test_id: "MT-LINT-001")
    prompt = @builder.build_skill_prompt(scenario, run_id: "abc123")

    assert_equal "/ace:run-e2e-test ace-lint MT-LINT-001 --run-id abc123", prompt
  end

  def test_build_skill_prompt_without_run_id_has_no_flag
    scenario = create_scenario(package: "ace-lint", test_id: "MT-LINT-001")
    prompt = @builder.build_skill_prompt(scenario)

    refute prompt.include?("--run-id")
  end

  # --- Workflow Prompt Building ---

  def test_build_workflow_prompt_includes_test_id
    scenario = create_scenario(test_id: "MT-LINT-001")
    prompt = @builder.build_workflow_prompt(scenario, workflow_content: "# Workflow")

    assert prompt.include?("MT-LINT-001")
  end

  def test_build_workflow_prompt_includes_package
    scenario = create_scenario(package: "ace-lint")
    prompt = @builder.build_workflow_prompt(scenario, workflow_content: "# Workflow")

    assert prompt.include?("ace-lint")
  end

  def test_build_workflow_prompt_includes_workflow_content
    scenario = create_scenario
    workflow = "## Step 1\n\nDo the thing\n\n## Step 2\n\nDo another thing"
    prompt = @builder.build_workflow_prompt(scenario, workflow_content: workflow)

    assert prompt.include?("Do the thing")
    assert prompt.include?("Do another thing")
  end

  def test_build_workflow_prompt_includes_scenario_content
    scenario = create_scenario(content: "### TC-001: Verify lint output")
    prompt = @builder.build_workflow_prompt(scenario, workflow_content: "# Workflow")

    assert prompt.include?("TC-001: Verify lint output")
  end

  def test_build_workflow_prompt_includes_return_contract
    scenario = create_scenario
    prompt = @builder.build_workflow_prompt(scenario, workflow_content: "# Workflow")

    assert prompt.include?("**Test ID**")
    assert prompt.include?("**Status**")
    assert prompt.include?("**Report Paths**")
  end

  def test_build_workflow_prompt_with_run_id
    scenario = create_scenario
    prompt = @builder.build_workflow_prompt(scenario, workflow_content: "# Workflow", run_id: "xyz789")

    assert prompt.include?("**Run ID:** xyz789")
  end

  def test_build_workflow_prompt_without_run_id_has_no_run_id_line
    scenario = create_scenario
    prompt = @builder.build_workflow_prompt(scenario, workflow_content: "# Workflow")

    refute prompt.include?("**Run ID:**")
  end

  # --- System Prompt ---

  def test_system_prompt_nil_for_skill_aware_provider
    assert_nil @builder.system_prompt_for("claude:sonnet")
  end

  def test_system_prompt_for_non_skill_aware_cli_provider
    prompt = @builder.system_prompt_for("gemini:flash")

    refute_nil prompt
    assert prompt.include?("E2E test executor")
    assert prompt.include?("execute")
  end

  def test_system_prompt_for_api_provider
    prompt = @builder.system_prompt_for("google:gemini-2.5-flash")

    refute_nil prompt
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
