# frozen_string_literal: true

require_relative "../test_helper"

class SkillPromptBuilderTest < Minitest::Test
  SkillPromptBuilder = Ace::Test::EndToEndRunner::Atoms::SkillPromptBuilder
  CliProviderAdapter = Ace::Test::EndToEndRunner::Atoms::CliProviderAdapter

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

  def test_cli_provider_adapter_alias_points_to_legacy_constant
    assert_same CliProviderAdapter, SkillPromptBuilder
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

  def test_cli_provider_resolves_role_references
    builder = SkillPromptBuilder.new({})

    # role:e2e-runner resolves to claude:haiku (a CLI provider)
    assert builder.cli_provider?("role:e2e-runner"),
      "role:e2e-runner should resolve to a CLI provider"
  end

  def test_cli_provider_rejects_unknown_role
    builder = SkillPromptBuilder.new({})

    refute builder.cli_provider?("role:nonexistent-role-xyz"),
      "unknown role should not be treated as CLI provider"
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

  # --- Config Injection ---

  def test_custom_config_overrides_cli_providers
    config = {
      "providers" => {
        "cli" => %w[custom-cli]
      }
    }
    builder = SkillPromptBuilder.new(config)

    assert builder.cli_provider?("custom-cli:model")
    refute builder.cli_provider?("claude:sonnet")
  end

  def test_empty_config_uses_defaults
    builder = SkillPromptBuilder.new({})

    assert builder.cli_provider?("claude:sonnet")
  end

  # --- Skill Name Coupling (guards against rename drift) ---

  def test_skill_name_matches_handbook_skill
    # Derives the expected skill name from the actual skill directory on disk.
    # If the skill is renamed, the directory name changes and this test fails,
    # forcing the developer to also update SkillPromptBuilder.
    skills_dir = File.expand_path("../../handbook/skills", __dir__)
    skill_dir = File.join(skills_dir, "as-e2e-run")
    # Skill name matches directory name (as-e2e-run)
    expected_name = File.basename(skill_dir)

    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    scenario_p = @builder.build_skill_prompt(scenario)
    tc_p = @builder.build_tc_skill_prompt(
      test_case: create_test_case, scenario: scenario, sandbox_path: "/tmp/sb"
    )

    assert File.directory?(skill_dir),
      "Handbook skill directory missing: #{skill_dir}"
    assert_includes scenario_p, "/#{expected_name}",
      "SkillPromptBuilder#build_skill_prompt must use current skill name '#{expected_name}'"
    assert_includes tc_p, "/#{expected_name}",
      "SkillPromptBuilder#build_tc_skill_prompt must use current skill name '#{expected_name}'"
  end

  # --- Skill Prompt Building ---

  def test_build_skill_prompt_format
    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    prompt = @builder.build_skill_prompt(scenario)

    assert_includes prompt, "/as-e2e-run ace-lint TS-LINT-001"
    assert_includes prompt, "not in bash"
    assert_includes prompt, "- **Status**: pass | fail | partial"
  end

  def test_build_skill_prompt_with_different_package
    scenario = create_scenario(package: "ace-review", test_id: "TS-REVIEW-002")
    prompt = @builder.build_skill_prompt(scenario)

    assert_includes prompt, "/as-e2e-run ace-review TS-REVIEW-002"
  end

  def test_build_skill_prompt_with_run_id
    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    prompt = @builder.build_skill_prompt(scenario, run_id: "abc123")

    assert_includes prompt, "/as-e2e-run ace-lint TS-LINT-001 --run-id abc123"
  end

  def test_build_skill_prompt_without_run_id_has_no_flag
    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    prompt = @builder.build_skill_prompt(scenario)

    refute prompt.include?("--run-id")
  end

  def test_build_skill_prompt_with_sandbox_path
    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    prompt = @builder.build_skill_prompt(scenario, sandbox_path: "/tmp/sandbox/ts001")

    assert prompt.include?("--sandbox /tmp/sandbox/ts001")
  end

  def test_build_skill_prompt_with_env_vars
    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    prompt = @builder.build_skill_prompt(scenario, env_vars: {"PROJECT_ROOT" => "/code", "MODE" => "test"})

    assert prompt.include?("--env PROJECT_ROOT=/code,MODE=test")
  end

  def test_build_skill_prompt_without_sandbox_no_flag
    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    prompt = @builder.build_skill_prompt(scenario)

    refute prompt.include?("--sandbox")
    refute prompt.include?("--env")
  end

  # --- Non-Claude CLI Provider Uses Skill Prompt ---

  def test_non_claude_cli_provider_builds_skill_prompt
    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    prompt = @builder.build_skill_prompt(scenario, sandbox_path: "/tmp/sandbox")

    assert prompt.include?("/as-e2e-run")
    assert prompt.include?("--sandbox /tmp/sandbox")
  end

  # --- TC-Level Skill Prompt ---

  def test_build_tc_skill_prompt_format
    scenario = create_scenario(package: "ace-lint", test_id: "TS-LINT-001")
    tc = create_test_case(tc_id: "TC-001")
    prompt = @builder.build_tc_skill_prompt(test_case: tc, scenario: scenario, sandbox_path: "/tmp/sandbox")

    assert prompt.include?("/as-e2e-run ace-lint TS-LINT-001 TC-001")
  end

  def test_build_tc_skill_prompt_includes_tc_mode_flag
    scenario = create_scenario
    tc = create_test_case
    prompt = @builder.build_tc_skill_prompt(test_case: tc, scenario: scenario, sandbox_path: "/tmp/sandbox")

    assert prompt.include?("--tc-mode")
    assert_includes prompt, "- **TC ID**: ..."
  end

  def test_build_tc_skill_prompt_includes_sandbox_path
    scenario = create_scenario
    tc = create_test_case
    prompt = @builder.build_tc_skill_prompt(test_case: tc, scenario: scenario, sandbox_path: "/my/sandbox/path")

    assert prompt.include?("--sandbox /my/sandbox/path")
  end

  def test_build_tc_skill_prompt_with_run_id
    scenario = create_scenario
    tc = create_test_case
    prompt = @builder.build_tc_skill_prompt(test_case: tc, scenario: scenario, sandbox_path: "/tmp/sb", run_id: "abc123")

    assert prompt.include?("--run-id abc123")
  end

  def test_build_tc_skill_prompt_without_run_id
    scenario = create_scenario
    tc = create_test_case
    prompt = @builder.build_tc_skill_prompt(test_case: tc, scenario: scenario, sandbox_path: "/tmp/sb")

    refute prompt.include?("--run-id")
  end

  private

  def create_scenario(overrides = {})
    defaults = {
      test_id: "TS-TEST-001",
      title: "Test Title",
      area: "test",
      package: "ace-test",
      file_path: "/tmp/test/scenario.yml",
      content: "# Test content"
    }
    Ace::Test::EndToEndRunner::Models::TestScenario.new(**defaults.merge(overrides))
  end

  def create_test_case(overrides = {})
    defaults = {
      tc_id: "TC-001",
      title: "Test Case Title",
      content: "## Objective\n\nVerify something.\n\n## Steps\n\n1. Do something",
      file_path: "/tmp/test/TC-001-test-case.tc.md"
    }
    Ace::Test::EndToEndRunner::Models::TestCase.new(**defaults.merge(overrides))
  end
end
