# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_field_updater"

class TaskFieldUpdaterTest < Minitest::Test
  def setup
    @updater = Ace::Taskflow::Molecules::TaskFieldUpdater
  end

  # ========================================
  # parse_field_updates tests (delegated to FieldArgumentParser)
  # ========================================

  def test_parse_simple_string_field
    result = @updater.parse_field_updates(["priority=high"])

    assert_equal({ "priority" => "high" }, result)
  end

  def test_parse_multiple_fields
    result = @updater.parse_field_updates([
      "priority=high",
      "estimate=1 week",
      "worktree.branch=090-task-update"
    ])

    expected = {
      "priority" => "high",
      "estimate" => "1 week",
      "worktree.branch" => "090-task-update"
    }
    assert_equal expected, result
  end

  def test_parse_invalid_syntax_raises_error
    error = assert_raises(Ace::Taskflow::Molecules::TaskFieldUpdater::FieldUpdateError) do
      @updater.parse_field_updates(["invalid_no_equals"])
    end

    assert_match(/Invalid field syntax/, error.message)
  end

  # ========================================
  # validate_types tests
  # ========================================

  def test_validate_types_accepts_compatible_types
    yaml_hash = { "priority" => "high", "count" => 5 }
    updates = { "priority" => "low", "count" => 10 }

    errors = @updater.validate_types(yaml_hash, updates)

    assert_empty errors
  end

  def test_validate_types_allows_new_fields
    yaml_hash = { "priority" => "high" }
    updates = { "estimate" => "1 week" }

    errors = @updater.validate_types(yaml_hash, updates)

    assert_empty errors
  end

  def test_validate_types_allows_string_to_any_type
    yaml_hash = { "field" => "string value" }
    updates = { "field" => 42 }

    errors = @updater.validate_types(yaml_hash, updates)

    assert_empty errors
  end

  def test_validate_types_detects_type_mismatch
    yaml_hash = { "count" => 5 }
    updates = { "count" => ["array"] }

    errors = @updater.validate_types(yaml_hash, updates)

    assert_equal 1, errors.length
    assert_match(/Field 'count' expects Integer, got Array/, errors.first)
  end

  def test_validate_types_handles_nested_fields
    yaml_hash = { "worktree" => { "created_at" => 12345 } }
    updates = { "worktree.created_at" => "2025-11-02" }

    errors = @updater.validate_types(yaml_hash, updates)

    # Should detect type mismatch: Integer vs String
    assert_equal 1, errors.length
  end

  def test_validate_types_ignores_empty_existing_values
    yaml_hash = { "description" => "" }
    updates = { "description" => ["array"] }

    errors = @updater.validate_types(yaml_hash, updates)

    # Empty strings can become any type
    assert_empty errors
  end

  def test_validate_types_ignores_nil_existing_values
    yaml_hash = { "description" => nil }
    updates = { "description" => 42 }

    errors = @updater.validate_types(yaml_hash, updates)

    # Nil can become any type
    assert_empty errors
  end
end