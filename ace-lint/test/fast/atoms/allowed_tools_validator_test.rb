# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Atoms::AllowedToolsValidatorTest < Minitest::Test
  KNOWN_TOOLS = %w[Bash Read Edit Write TodoWrite Task].freeze
  KNOWN_BASH_PREFIXES = %w[ace-bundle ace-git npm git].freeze

  def test_valid_simple_tools
    errors = validate(["Read", "Edit", "Write"])

    assert_empty errors
  end

  def test_valid_bash_patterns
    errors = validate(["Bash(ace-bundle:*)", "Bash(git:*)"])

    assert_empty errors
  end

  def test_mixed_valid_tools
    errors = validate(["Bash(ace-git:*)", "Read", "TodoWrite"])

    assert_empty errors
  end

  def test_invalid_tool_name
    errors = validate(["InvalidTool", "Read"])

    assert_equal 1, errors.size
    assert_equal "InvalidTool", errors.first[:tool]
    assert_includes errors.first[:message], "Unknown tool"
  end

  def test_invalid_bash_prefix
    errors = validate(["Bash(unknown-prefix:*)"])

    assert_equal 1, errors.size
    assert_includes errors.first[:tool], "Bash(unknown-prefix:*)"
    assert_includes errors.first[:message], "Unknown Bash prefix"
  end

  def test_multiple_invalid_entries
    errors = validate(["BadTool", "Bash(bad-prefix:*)", "Read"])

    assert_equal 2, errors.size
  end

  def test_comma_separated_string_format
    errors = validate("Read, Edit, Write")

    assert_empty errors
  end

  def test_comma_separated_with_invalid
    errors = validate("Read, BadTool, Write")

    assert_equal 1, errors.size
    assert_equal "BadTool", errors.first[:tool]
  end

  def test_empty_array
    errors = validate([])

    assert_empty errors
  end

  def test_nil_tools
    errors = validate(nil)

    assert_empty errors
  end

  def test_whitespace_handling
    errors = validate(["  Read  ", " Edit"])

    assert_empty errors
  end

  def test_error_message_includes_total_count_for_unknown_tool
    errors = validate(["UnknownTool"])

    assert_equal 1, errors.size
    # Error message should include total count of known tools
    assert_includes errors.first[:message], "(#{KNOWN_TOOLS.size} total)"
  end

  def test_error_message_includes_total_count_for_unknown_bash_prefix
    errors = validate(["Bash(unknown-prefix:*)"])

    assert_equal 1, errors.size
    # Error message should include total count of known prefixes
    assert_includes errors.first[:message], "(#{KNOWN_BASH_PREFIXES.size} total)"
  end

  private

  def validate(tools)
    Ace::Lint::Atoms::AllowedToolsValidator.validate(
      tools,
      known_tools: KNOWN_TOOLS,
      known_bash_prefixes: KNOWN_BASH_PREFIXES
    )
  end
end
