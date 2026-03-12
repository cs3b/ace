# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Atoms::SkillSchemaLoaderTest < Minitest::Test
  def setup
    Ace::Lint::Atoms::SkillSchemaLoader.reset_cache!
  end

  def test_loads_config
    config = Ace::Lint::Atoms::SkillSchemaLoader.config

    assert config.is_a?(Hash)
    assert config.key?("known_tools")
    assert config.key?("known_bash_prefixes")
    assert config.key?("schemas")
  end

  def test_known_tools_includes_expected_tools
    tools = Ace::Lint::Atoms::SkillSchemaLoader.known_tools

    assert_includes tools, "Bash"
    assert_includes tools, "Read"
    assert_includes tools, "Edit"
    assert_includes tools, "Write"
    assert_includes tools, "TodoWrite"
    assert_includes tools, "Task"
  end

  def test_known_bash_prefixes_includes_expected_prefixes
    prefixes = Ace::Lint::Atoms::SkillSchemaLoader.known_bash_prefixes

    assert_includes prefixes, "ace-bundle"
    assert_includes prefixes, "ace-git"
    assert_includes prefixes, "ace-lint"
    assert_includes prefixes, "git"
  end

  def test_schema_for_skill
    schema = Ace::Lint::Atoms::SkillSchemaLoader.schema_for(:skill)

    assert schema.is_a?(Hash)
    assert_includes schema["required_fields"], "name"
    assert_includes schema["required_fields"], "description"
    assert_includes schema["required_fields"], "user-invocable"
    assert_includes schema["required_fields"], "allowed-tools"
    assert_includes schema["required_fields"], "source"
    assert_includes schema["required_nested_fields"], "skill.kind"
    assert_includes schema["required_nested_fields"], "skill.execution.workflow"
    assert_includes schema["required_comments"], "# bundle:"
    assert_includes schema["required_comments"], "# agent:"
    assert_equal "string", schema.dig("field_validations", "skill.kind", "type")
  end

  def test_schema_for_workflow
    schema = Ace::Lint::Atoms::SkillSchemaLoader.schema_for(:workflow)

    assert schema.is_a?(Hash)
    assert_includes schema["required_fields"], "name"
    assert_includes schema["required_fields"], "description"
    assert_includes schema["required_fields"], "allowed-tools"
  end

  def test_schema_for_agent
    schema = Ace::Lint::Atoms::SkillSchemaLoader.schema_for(:agent)

    assert schema.is_a?(Hash)
    assert_includes schema["required_fields"], "name"
    assert_includes schema["required_fields"], "description"
    assert_includes schema["required_fields"], "type"
  end

  def test_schema_for_unknown_type
    schema = Ace::Lint::Atoms::SkillSchemaLoader.schema_for(:unknown)

    assert_equal({}, schema)
  end

  def test_reset_cache
    # Load config first
    config1 = Ace::Lint::Atoms::SkillSchemaLoader.config

    # Reset and load again
    Ace::Lint::Atoms::SkillSchemaLoader.reset_cache!
    config2 = Ace::Lint::Atoms::SkillSchemaLoader.config

    # Both should be equal but potentially different objects
    assert_equal config1, config2
  end
end
