# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/atoms/yaml_parser"

class YamlParserTest < AceTaskflowTestCase
  def setup
    @parser = Ace::Taskflow::Atoms::YamlParser
  end

  def test_parse_frontmatter_with_valid_yaml
    content = <<~CONTENT
      ---
      id: task.001
      status: pending
      priority: high
      ---

      # Task Content
    CONTENT

    result = @parser.parse_frontmatter(content)

    assert_equal "task.001", result["id"]
    assert_equal "pending", result["status"]
    assert_equal "high", result["priority"]
  end

  def test_parse_frontmatter_with_no_frontmatter
    content = "# Just a heading\n\nSome content"
    result = @parser.parse_frontmatter(content)

    assert_equal({}, result)
  end

  def test_parse_frontmatter_with_empty_content
    assert_equal({}, @parser.parse_frontmatter(""))
    assert_equal({}, @parser.parse_frontmatter(nil))
  end

  def test_parse_frontmatter_with_incomplete_frontmatter
    content = <<~CONTENT
      ---
      id: task.001
      # Missing closing delimiter
    CONTENT

    result = @parser.parse_frontmatter(content)
    assert_equal({}, result)
  end

  def test_parse_frontmatter_with_invalid_yaml
    content = <<~CONTENT
      ---
      invalid: : yaml: syntax
      ---

      Content
    CONTENT

    result = @parser.parse_frontmatter(content)
    assert_equal({}, result)
  end

  def test_parse_frontmatter_with_arrays
    content = <<~CONTENT
      ---
      dependencies:
        - task.001
        - task.002
      tags:
        - feature
        - urgent
      ---

      Content
    CONTENT

    result = @parser.parse_frontmatter(content)

    assert_equal ["task.001", "task.002"], result["dependencies"]
    assert_equal ["feature", "urgent"], result["tags"]
  end

  def test_extract_content_after_frontmatter
    content = <<~CONTENT
      ---
      id: task.001
      ---

      # Task Title

      Task description here.
    CONTENT

    result = @parser.extract_content(content)

    assert_match(/# Task Title/, result)
    assert_match(/Task description here/, result)
    refute_match(/^---/, result)
  end

  def test_extract_content_with_no_frontmatter
    content = "# Title\n\nContent here"
    result = @parser.extract_content(content)

    assert_equal content, result
  end

  def test_extract_content_from_empty_string
    assert_equal "", @parser.extract_content("")
    assert_equal "", @parser.extract_content(nil)
  end

  def test_extract_content_with_incomplete_frontmatter
    content = <<~CONTENT
      ---
      id: task.001
      # No closing delimiter
      Some content
    CONTENT

    result = @parser.extract_content(content)
    assert_equal content, result
  end

  def test_parse_returns_both_frontmatter_and_content
    content = <<~CONTENT
      ---
      id: task.001
      status: done
      ---

      # Completed Task

      This task is complete.
    CONTENT

    result = @parser.parse(content)

    assert_instance_of Hash, result
    assert_instance_of Hash, result[:frontmatter]
    assert_instance_of String, result[:content]

    assert_equal "task.001", result[:frontmatter]["id"]
    assert_equal "done", result[:frontmatter]["status"]
    assert_match(/# Completed Task/, result[:content])
  end

  def test_parse_with_multiline_content
    content = <<~CONTENT
      ---
      id: task.001
      ---

      Line 1
      Line 2
      Line 3
    CONTENT

    result = @parser.parse(content)

    assert_match(/Line 1/, result[:content])
    assert_match(/Line 2/, result[:content])
    assert_match(/Line 3/, result[:content])
  end

  def test_parse_frontmatter_with_date_time
    content = <<~CONTENT
      ---
      created_at: 2025-01-01
      ---

      Content
    CONTENT

    result = @parser.parse_frontmatter(content)
    assert result["created_at"]
  end

  def test_parse_frontmatter_with_nested_hash
    content = <<~CONTENT
      ---
      metadata:
        author: John
        version: 1.0
      ---

      Content
    CONTENT

    result = @parser.parse_frontmatter(content)

    assert_instance_of Hash, result["metadata"]
    assert_equal "John", result["metadata"]["author"]
    assert_equal 1.0, result["metadata"]["version"]
  end

  def test_parse_handles_empty_frontmatter
    content = <<~CONTENT
      ---
      ---

      Content only
    CONTENT

    result = @parser.parse(content)

    assert_equal({}, result[:frontmatter])
    assert_match(/Content only/, result[:content])
  end

  def test_parse_frontmatter_with_numbers
    content = <<~CONTENT
      ---
      sort: 100
      estimate: 4
      ---

      Content
    CONTENT

    result = @parser.parse_frontmatter(content)

    assert_equal 100, result["sort"]
    assert_equal 4, result["estimate"]
  end

  def test_parse_frontmatter_preserves_string_values
    content = <<~CONTENT
      ---
      id: "001"
      version: "1.0.0"
      ---

      Content
    CONTENT

    result = @parser.parse_frontmatter(content)

    assert_equal "001", result["id"]
    assert_equal "1.0.0", result["version"]
  end
end
