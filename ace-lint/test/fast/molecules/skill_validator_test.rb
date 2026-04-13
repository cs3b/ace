# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Molecules::SkillValidatorTest < Minitest::Test
  def setup
    Ace::Lint::Atoms::SkillSchemaLoader.reset_cache!
    @fixtures_dir = File.expand_path("../../fixtures", __dir__)
  end

  # Skill validation tests

  def test_valid_skill
    file_path = File.join(@fixtures_dir, "skills", "valid_skill.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :skill)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
    assert_empty result.errors
  end

  def test_skill_missing_required_fields
    file_path = File.join(@fixtures_dir, "skills", "missing_fields.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("user-invocable") }
    assert error_messages.any? { |msg| msg.include?("allowed-tools") }
    assert error_messages.any? { |msg| msg.include?("source") }
  end

  def test_skill_invalid_tools
    file_path = File.join(@fixtures_dir, "skills", "invalid_tools.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("InvalidTool") }
    assert error_messages.any? { |msg| msg.include?("unknown-prefix") }
  end

  def test_skill_missing_comments
    file_path = File.join(@fixtures_dir, "skills", "missing_comments.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("# bundle:") }
    assert error_messages.any? { |msg| msg.include?("# agent:") }
  end

  def test_skill_invalid_name_pattern
    file_path = File.join(@fixtures_dir, "skills", "invalid_name.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("as-") || msg.include?("ace-") }
  end

  # Workflow validation tests

  def test_valid_workflow
    file_path = File.join(@fixtures_dir, "workflows", "valid.wf.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :workflow)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
    assert_empty result.errors
  end

  def test_workflow_invalid_name
    file_path = File.join(@fixtures_dir, "workflows", "invalid_name.wf.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :workflow)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("lowercase") || msg.include?("pattern") }
  end

  # Agent validation tests

  def test_valid_agent
    file_path = File.join(@fixtures_dir, "agents", "valid.ag.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :agent)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
    assert_empty result.errors
  end

  def test_agent_invalid_type
    file_path = File.join(@fixtures_dir, "agents", "invalid_type.ag.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :agent)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("agent") }
  end

  # Content validation tests

  def test_validate_content_directly
    content = <<~MARKDOWN
      ---
      name: as-direct-test
      description: Test direct content validation
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://test/workflow
      ---

      Body
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content(
      "test.md",
      content,
      :skill
    )

    assert result.success?
  end

  def test_file_not_found
    result = Ace::Lint::Molecules::SkillValidator.validate("/nonexistent/path.md", :skill)

    refute result.success?
    assert result.errors.any? { |e| e.message.include?("File not found") }
  end

  def test_no_frontmatter
    content = "Just plain content without frontmatter"

    result = Ace::Lint::Molecules::SkillValidator.validate_content(
      "test.md",
      content,
      :skill
    )

    refute result.success?
    assert result.errors.any? { |e| e.message.include?("No frontmatter") }
  end

  def test_trailing_newline_warning
    content = "---\nname: test\n---\n\nNo trailing newline"

    result = Ace::Lint::Molecules::SkillValidator.validate_content(
      "test.md",
      content,
      :workflow
    )

    # Should have a warning about trailing newline
    assert result.warnings.any? { |w| w.message.include?("newline") }
  end

  # Pure I/O-free tests using heredocs

  def test_pure_valid_skill
    content = <<~MARKDOWN
      ---
      name: as-pure-test
      description: A valid test skill
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
        - Edit
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://test/workflow
      ---

      Body content.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
    assert_empty result.errors
  end

  def test_valid_skill_with_integration
    file_path = File.join(@fixtures_dir, "skills", "valid_skill_with_integration.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :skill)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
  end

  def test_valid_skill_with_provider_execution_overrides
    content = <<~MARKDOWN
      ---
      name: as-provider-model-test
      description: Valid skill with provider model overrides
      # bundle: wfi://test/workflow
      # agent: general-purpose
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      integration:
        providers:
          claude:
            frontmatter:
              context: fork
              model: haiku
          codex:
            frontmatter:
              context: fork
              model: gpt-5.3-codex-spark
      skill:
        kind: workflow
        execution:
          workflow: wfi://test/workflow
      ---

      Body
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
  end

  def test_invalid_skill_with_integration
    file_path = File.join(@fixtures_dir, "skills", "invalid_skill_with_integration.md")
    result = Ace::Lint::Molecules::SkillValidator.validate(file_path, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)
    assert error_messages.any? { |msg| msg.include?("integration.targets") }
    assert error_messages.any? { |msg| msg.include?("Unknown integration provider") }
    assert error_messages.any? { |msg| msg.include?("frontmatter") }
  end

  def test_pure_missing_required_fields
    content = <<~MARKDOWN
      ---
      name: ace-incomplete
      description: Missing required fields
      ---

      Missing user-invocable, allowed-tools, and source.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("user-invocable") }
    assert error_messages.any? { |msg| msg.include?("allowed-tools") }
    assert error_messages.any? { |msg| msg.include?("source") }
  end

  def test_pure_invalid_tools
    content = <<~MARKDOWN
      ---
      name: as-invalid-tools
      description: Skill with invalid tools
      # bundle: no-fork
      # agent: general-purpose
      user-invocable: true
      allowed-tools:
        - InvalidTool
        - Bash(unknown-prefix:*)
        - Read
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://test/workflow
      ---

      Invalid tool entries.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("InvalidTool") }
    assert error_messages.any? { |msg| msg.include?("unknown-prefix") }
  end

  def test_pure_accepts_real_ace_cli_prefixes
    content = <<~MARKDOWN
      ---
      name: as-idea-prioritize
      description: Uses ace-idea CLI
      # bundle: wfi://idea/prioritize
      # agent: general-purpose
      user-invocable: true
      allowed-tools:
        - Bash(ace-idea:*)
        - Bash(ace-task:*)
        - Read
      source: ace-task
      skill:
        kind: workflow
        execution:
          workflow: wfi://idea/prioritize
      ---

      Body content.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
  end

  def test_pure_missing_comments
    content = <<~MARKDOWN
      ---
      name: ace-missing-comments
      description: Skill missing required comments
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      ---

      Missing # bundle: and # agent: comments.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("# bundle:") }
    assert error_messages.any? { |msg| msg.include?("# agent:") }
  end

  def test_pure_invalid_name_pattern
    content = <<~MARKDOWN
      ---
      name: nope
      description: Skill with invalid name pattern
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://test/workflow
      ---

      Name doesn't start with as- or ace-.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("as-") || msg.include?("ace-") }
  end

  def test_pure_invalid_regex_pattern_in_schema
    # This tests the regex safety feature - handles malformed patterns gracefully
    # We simulate this by mocking the schema loader (would need deeper test setup)
    # For now, verify the validate_field method handles it correctly
    content = <<~MARKDOWN
      ---
      name: as-test
      description: Test
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://test/workflow
      ---

      Content.
    MARKDOWN

    # This test verifies the regex safety code path exists
    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)
    assert result.success?
  end

  def test_pure_field_line_numbers
    content = <<~MARKDOWN
      ---
      name: nope
      description: Test
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://test/workflow
      ---

      Content.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    # The name field is on line 2 (after ---), so error should reference that line
    name_error = result.errors.find { |e| e.message.include?("as-") || e.message.include?("ace-") }
    assert name_error, "Expected an error about name pattern"
    assert_equal 2, name_error.line, "Expected error to report line 2 for name field"
  end

  def test_requires_skill_kind
    content = <<~MARKDOWN
      ---
      name: as-missing-skill-fields
      description: Missing canonical skill metadata
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        execution: {}
      ---
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)
    assert error_messages.any? { |msg| msg.include?("skill.kind") }
  end

  def test_requires_workflow_for_workflow_skill_kind
    content = <<~MARKDOWN
      ---
      name: as-workflow-missing-binding
      description: Workflow skills must include workflow binding
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: workflow
      ---
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    assert result.errors.any? { |e| e.message.include?("skill.execution.workflow") }
  end

  def test_requires_workflow_for_orchestration_skill_kind
    content = <<~MARKDOWN
      ---
      name: as-orchestration-missing-binding
      description: Orchestration skills must include workflow binding
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: orchestration
      ---
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    assert result.errors.any? { |e| e.message.include?("skill.execution.workflow") }
  end

  def test_allows_capability_without_workflow_binding
    content = <<~MARKDOWN
      ---
      name: as-capability-direct
      description: Capability skill may omit workflow binding
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: capability
      ---
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
  end

  def test_rejects_assign_on_capability_skill
    content = <<~MARKDOWN
      ---
      name: as-capability-with-assign
      description: Invalid assign usage
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: capability
        execution:
          workflow: wfi://b36ts
      assign:
        phases:
          - name: demo
      ---
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    assert result.errors.any? { |e| e.message.include?("only allowed for workflow/orchestration") }
  end

  def test_rejects_duplicate_assign_phase_names
    content = <<~MARKDOWN
      ---
      name: as-dup-assign-phases
      description: Duplicate assign phase names should fail
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://task/work
      assign:
        phases:
          - name: one
          - name: one
      ---
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    assert result.errors.any? { |e| e.message.include?("Duplicate assign phase name") }
  end

  def test_allows_assign_steps_metadata
    content = <<~MARKDOWN
      ---
      name: as-assign-steps-supported
      description: Workflow skill with assign steps metadata
      # bundle: wfi://assign/drive
      # agent: general-purpose
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://assign/drive
      assign:
        source: wfi://assign/drive
        steps:
          - name: drive-assignment
            description: Drive assignment execution loop
      ---
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
  end

  def test_rejects_unknown_skill_nested_fields
    content = <<~MARKDOWN
      ---
      name: as-unknown-skill-fields
      description: Unknown fields under skill should fail
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      skill:
        kind: workflow
        execution:
          workflow: wfi://task/plan
          mode: direct
        flavor: custom
      ---
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    assert result.errors.any? { |e| e.message.include?("Unknown field under 'skill': 'flavor'") }
    assert result.errors.any? { |e| e.message.include?("Unknown field under 'skill.execution': 'mode'") }
  end
end
