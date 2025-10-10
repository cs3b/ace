# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/atoms/safe_yaml_parser"

class SafeYamlParserTest < Minitest::Test
  def test_parse_valid_frontmatter
    content = <<~MARKDOWN
      ---
      id: v.0.9.0+task.001
      status: pending
      priority: high
      ---

      # Task Title

      Content here
    MARKDOWN

    result = Ace::Taskflow::Atoms::SafeYamlParser.parse_with_recovery(content)

    assert_equal "v.0.9.0+task.001", result[:frontmatter]["id"]
    assert_equal "pending", result[:frontmatter]["status"]
    assert_equal "high", result[:frontmatter]["priority"]
    assert result[:content].include?("# Task Title")
    assert_empty result[:errors]
    assert_empty result[:warnings]
    refute result[:recovered]
  end

  def test_recover_missing_closing_delimiter
    content = <<~MARKDOWN
      ---
      id: v.0.9.0+task.002
      status: pending
      priority: medium

      # Task Title

      Content without closing delimiter
    MARKDOWN

    result = Ace::Taskflow::Atoms::SafeYamlParser.parse_with_recovery(content)

    assert_equal "v.0.9.0+task.002", result[:frontmatter]["id"]
    assert_equal "pending", result[:frontmatter]["status"]
    assert result[:content].include?("# Task Title")
    assert_empty result[:errors]
    assert result[:warnings].any? { |w| w.include?("Recovered from missing closing delimiter") }
    assert result[:recovered]
  end

  def test_fix_missing_delimiter
    content = <<~MARKDOWN
      ---
      id: v.0.9.0+task.003
      status: done

      # Task Content
    MARKDOWN

    fixed = Ace::Taskflow::Atoms::SafeYamlParser.fix_frontmatter(content)

    assert fixed.include?("---\nid: v.0.9.0+task.003")
    assert fixed.include?("status: done\n---\n")
    assert fixed.include?("# Task Content")
  end

  def test_handle_malformed_yaml
    content = <<~MARKDOWN
      ---
      id: v.0.9.0+task.004
      status: pending
      dependencies: [task.001 task.002]
      invalid_line
      ---

      # Content
    MARKDOWN

    result = Ace::Taskflow::Atoms::SafeYamlParser.parse_with_recovery(content)

    assert result[:errors].any?
    assert result[:content].include?("# Content")
  end

  def test_content_without_frontmatter
    content = "# Just a markdown file\n\nNo frontmatter here"

    result = Ace::Taskflow::Atoms::SafeYamlParser.parse_with_recovery(content)

    assert_empty result[:frontmatter]
    assert_equal content, result[:content]
    assert_empty result[:errors]
    assert_empty result[:warnings]
    refute result[:recovered]
  end

  def test_validate_frontmatter
    content = <<~MARKDOWN
      ---
      status: pending
      priority: high
      ---

      # Missing ID Field
    MARKDOWN

    validation = Ace::Taskflow::Atoms::SafeYamlParser.validate_frontmatter(content)

    refute validation[:valid]
    assert validation[:issues].any? { |i| i[:message].include?("Missing required field: id") }
  end

  def test_partial_yaml_recovery
    content = <<~MARKDOWN
      ---
      id: v.0.9.0+task.005
      status: pending
      priority: high
      estimate: 2h
      dependencies: []
      some_broken: {unclosed
      ---

      # Content
    MARKDOWN

    result = Ace::Taskflow::Atoms::SafeYamlParser.parse_with_recovery(content)

    # Should recover partial data even with broken lines
    assert result[:frontmatter]["id"]
    assert result[:frontmatter]["status"]
    assert result[:errors].any?
  end

  def test_empty_content
    result = Ace::Taskflow::Atoms::SafeYamlParser.parse_with_recovery("")

    assert_empty result[:frontmatter]
    assert_empty result[:content]
    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_nil_content
    result = Ace::Taskflow::Atoms::SafeYamlParser.parse_with_recovery(nil)

    assert_empty result[:frontmatter]
    assert_empty result[:content]
    assert_empty result[:errors]
    assert_empty result[:warnings]
  end
end