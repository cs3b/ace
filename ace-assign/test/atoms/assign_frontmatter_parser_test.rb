# frozen_string_literal: true

require_relative "../test_helper"

class AssignFrontmatterParserTest < AceAssignTestCase
  Parser = Ace::Assign::Atoms::AssignFrontmatterParser

  # === Happy path ===

  def test_parse_full_task_frontmatter
    frontmatter = {
      "id" => "v.0.9.0+task.148",
      "status" => "in-progress",
      "assign" => {
        "goal" => "implement-with-pr",
        "variables" => { "taskref" => "148", "review_cycles" => 2 },
        "hints" => [
          { "include" => "security-audit" },
          { "skip" => "lint" }
        ]
      }
    }

    result = Parser.parse(frontmatter)

    assert result[:valid]
    assert_empty result[:errors]
    assert_equal "implement-with-pr", result[:config][:goal]
    assert_equal({ "taskref" => "148", "review_cycles" => 2 }, result[:config][:variables])
    assert_equal 2, result[:config][:hints].size
    assert_equal({ action: :include, step: "security-audit" }, result[:config][:hints][0])
    assert_equal({ action: :skip, step: "lint" }, result[:config][:hints][1])
  end

  def test_parse_workflow_frontmatter_with_sub_steps
    frontmatter = {
      "name" => "work-on-task",
      "assign" => {
        "sub-steps" => %w[onboard implement verify-tests],
        "context" => "fork"
      }
    }

    result = Parser.parse(frontmatter)

    assert result[:valid]
    assert_empty result[:errors]
    assert_equal %w[onboard implement verify-tests], result[:config][:sub_steps]
    assert_equal "fork", result[:config][:context]
  end

  def test_parse_with_parent_field
    frontmatter = {
      "assign" => {
        "goal" => "implement",
        "parent" => "abc123"
      }
    }

    result = Parser.parse(frontmatter)

    assert result[:valid]
    assert_equal "abc123", result[:config][:parent]
  end

  def test_parse_minimal_assign_block
    frontmatter = {
      "assign" => {
        "goal" => "quick-fix"
      }
    }

    result = Parser.parse(frontmatter)

    assert result[:valid]
    assert_equal "quick-fix", result[:config][:goal]
    assert_equal({}, result[:config][:variables])
    assert_empty result[:config][:hints]
    assert_empty result[:config][:sub_steps]
    assert_nil result[:config][:context]
    assert_nil result[:config][:parent]
  end

  # === No assign block ===

  def test_parse_without_assign_block_returns_nil_config
    frontmatter = {
      "id" => "v.0.9.0+task.148",
      "status" => "in-progress"
    }

    result = Parser.parse(frontmatter)

    assert result[:valid]
    assert_nil result[:config]
    assert_empty result[:errors]
  end

  def test_parse_nil_frontmatter_returns_nil_config
    result = Parser.parse(nil)

    assert result[:valid]
    assert_nil result[:config]
    assert_empty result[:errors]
  end

  def test_parse_empty_hash_returns_nil_config
    result = Parser.parse({})

    assert result[:valid]
    assert_nil result[:config]
    assert_empty result[:errors]
  end

  def test_parse_non_hash_returns_nil_config
    result = Parser.parse("not a hash")

    assert result[:valid]
    assert_nil result[:config]
    assert_empty result[:errors]
  end

  # === Validation errors ===

  def test_parse_assign_not_hash_returns_error
    frontmatter = { "assign" => "not a hash" }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert_nil result[:config]
    assert_includes result[:errors].first, "must be a mapping"
  end

  def test_parse_unknown_fields_returns_error
    frontmatter = {
      "assign" => {
        "goal" => "implement",
        "unknown_field" => "value",
        "another_bad" => true
      }
    }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("Unknown assign fields") }
    assert result[:errors].any? { |e| e.include?("unknown_field") }
  end

  def test_parse_goal_not_string_returns_error
    frontmatter = { "assign" => { "goal" => 123 } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.goal must be a string") }
  end

  def test_parse_variables_not_hash_returns_error
    frontmatter = { "assign" => { "variables" => "not a hash" } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.variables must be a mapping") }
  end

  def test_parse_hints_not_array_returns_error
    frontmatter = { "assign" => { "hints" => "not an array" } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.hints must be an array") }
  end

  def test_parse_hints_entry_not_hash_returns_error
    frontmatter = { "assign" => { "hints" => ["not a hash"] } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.hints[0] must be a mapping") }
  end

  def test_parse_hints_missing_action_returns_error
    frontmatter = { "assign" => { "hints" => [{ "bad_key" => "value" }] } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("'include' or 'skip' key") }
  end

  def test_parse_hints_mutually_exclusive_actions_returns_error
    frontmatter = { "assign" => { "hints" => [{ "include" => "security", "skip" => "lint" }] } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("cannot have both 'include' and 'skip'") }
  end

  def test_parse_sub_steps_not_array_returns_error
    frontmatter = { "assign" => { "sub-steps" => "not an array" } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.sub-steps must be an array") }
  end

  def test_parse_sub_steps_entries_not_strings_returns_error
    frontmatter = { "assign" => { "sub-steps" => [123, "valid"] } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.sub-steps entries must be strings") }
  end

  def test_parse_context_not_string_returns_error
    frontmatter = { "assign" => { "context" => 123 } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.context must be a string") }
  end

  def test_parse_context_invalid_value_returns_error
    frontmatter = { "assign" => { "context" => "invalid" } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.context must be one of") }
  end

  def test_parse_parent_not_string_returns_error
    frontmatter = { "assign" => { "parent" => 123 } }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].any? { |e| e.include?("assign.parent must be a string") }
  end

  def test_parse_multiple_errors_reported
    frontmatter = {
      "assign" => {
        "goal" => 123,
        "variables" => "bad",
        "hints" => "bad"
      }
    }

    result = Parser.parse(frontmatter)

    refute result[:valid]
    assert result[:errors].size >= 3
  end
end
