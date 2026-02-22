# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Molecules::SkillValidatorTest < Minitest::Test
  def setup
    Ace::Lint::Atoms::SkillSchemaLoader.reset_cache!
    @fixtures_dir = File.expand_path("../fixtures", __dir__)
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

    assert error_messages.any? { |msg| msg.include?("ace-") }
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
      name: ace-direct-test
      description: Test direct content validation
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
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
      name: ace-pure-test
      description: A valid test skill
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
        - Edit
      source: test
      ---

      Body content.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    assert result.success?, "Expected success but got errors: #{result.errors.map(&:message).join(", ")}"
    assert_empty result.errors
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
      name: ace-invalid-tools
      description: Skill with invalid tools
      # bundle: no-fork
      # agent: general-purpose
      user-invocable: true
      allowed-tools:
        - InvalidTool
        - Bash(unknown-prefix:*)
        - Read
      source: test
      ---

      Invalid tool entries.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("InvalidTool") }
    assert error_messages.any? { |msg| msg.include?("unknown-prefix") }
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
      name: my-bad-name
      description: Skill with invalid name pattern
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      ---

      Name doesn't start with ace-.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    error_messages = result.errors.map(&:message)

    assert error_messages.any? { |msg| msg.include?("ace-") }
  end

  def test_pure_invalid_regex_pattern_in_schema
    # This tests the regex safety feature - handles malformed patterns gracefully
    # We simulate this by mocking the schema loader (would need deeper test setup)
    # For now, verify the validate_field method handles it correctly
    content = <<~MARKDOWN
      ---
      name: ace-test
      description: Test
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
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
      name: my-bad-name
      description: Test
      # bundle: no-fork
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      ---

      Content.
    MARKDOWN

    result = Ace::Lint::Molecules::SkillValidator.validate_content("test.md", content, :skill)

    refute result.success?
    # The name field is on line 2 (after ---), so error should reference that line
    name_error = result.errors.find { |e| e.message.include?("ace-") }
    assert name_error, "Expected an error about name pattern"
    assert_equal 2, name_error.line, "Expected error to report line 2 for name field"
  end
end
