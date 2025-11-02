# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_field_updater"

class TaskFieldUpdaterTest < Minitest::Test
  def setup
    @updater = Ace::Taskflow::Molecules::TaskFieldUpdater
  end

  # ========================================
  # parse_field_updates tests
  # ========================================

  def test_parse_simple_string_field
    result = @updater.parse_field_updates(["priority=high"])

    assert_equal({ "priority" => "high" }, result)
  end

  def test_parse_quoted_string_field
    result = @updater.parse_field_updates(['estimate="2 weeks"'])

    assert_equal({ "estimate" => "2 weeks" }, result)
  end

  def test_parse_integer_field
    result = @updater.parse_field_updates(["count=42"])

    assert_equal({ "count" => 42 }, result)
  end

  def test_parse_boolean_true_field
    result = @updater.parse_field_updates(["completed=true"])

    assert_equal({ "completed" => true }, result)
  end

  def test_parse_boolean_false_field
    result = @updater.parse_field_updates(["completed=false"])

    assert_equal({ "completed" => false }, result)
  end

  def test_parse_array_field
    result = @updater.parse_field_updates(["dependencies=[082, 083]"])

    assert_equal({ "dependencies" => [82, 83] }, result)
  end

  def test_parse_empty_array_field
    result = @updater.parse_field_updates(["dependencies=[]"])

    assert_equal({ "dependencies" => [] }, result)
  end

  def test_parse_empty_value_field
    result = @updater.parse_field_updates(["description="])

    assert_equal({ "description" => "" }, result)
  end

  def test_parse_nested_field
    result = @updater.parse_field_updates(["worktree.branch=081-fix-auth"])

    assert_equal({ "worktree.branch" => "081-fix-auth" }, result)
  end

  def test_parse_deeply_nested_field
    result = @updater.parse_field_updates(["a.b.c.d=value"])

    assert_equal({ "a.b.c.d" => "value" }, result)
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

  def test_parse_field_with_equals_in_value
    result = @updater.parse_field_updates(['note="x=y"'])

    assert_equal({ "note" => "x=y" }, result)
  end

  def test_parse_invalid_syntax_raises_error
    error = assert_raises(Ace::Taskflow::Molecules::TaskFieldUpdater::FieldUpdateError) do
      @updater.parse_field_updates(["invalid_no_equals"])
    end

    assert_match(/Invalid field syntax/, error.message)
  end

  def test_parse_float_field
    result = @updater.parse_field_updates(["percentage=95.5"])

    assert_equal({ "percentage" => 95.5 }, result)
  end

  # ========================================
  # apply_updates tests
  # ========================================

  def test_apply_simple_field_update
    yaml_hash = { "priority" => "low", "status" => "pending" }
    updates = { "priority" => "high" }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "high", result["priority"]
    assert_equal "pending", result["status"]
  end

  def test_apply_new_field_update
    yaml_hash = { "priority" => "low" }
    updates = { "estimate" => "1 week" }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "1 week", result["estimate"]
    assert_equal "low", result["priority"]
  end

  def test_apply_nested_field_update_existing_parent
    yaml_hash = { "worktree" => { "branch" => "old-branch" } }
    updates = { "worktree.branch" => "new-branch" }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "new-branch", result["worktree"]["branch"]
  end

  def test_apply_nested_field_update_creates_parent
    yaml_hash = { "priority" => "high" }
    updates = { "worktree.branch" => "081-fix-auth" }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "081-fix-auth", result["worktree"]["branch"]
    assert result["worktree"].is_a?(Hash)
  end

  def test_apply_deeply_nested_field_update
    yaml_hash = {}
    updates = { "a.b.c.d" => "value" }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "value", result["a"]["b"]["c"]["d"]
  end

  def test_apply_multiple_nested_fields
    yaml_hash = {}
    updates = {
      "worktree.branch" => "090-task-update",
      "worktree.path" => ".ace-wt/task.090",
      "worktree.created_at" => "2025-11-02 10:00:00"
    }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "090-task-update", result["worktree"]["branch"]
    assert_equal ".ace-wt/task.090", result["worktree"]["path"]
    assert_equal "2025-11-02 10:00:00", result["worktree"]["created_at"]
  end

  def test_apply_mixed_simple_and_nested_fields
    yaml_hash = { "priority" => "low" }
    updates = {
      "priority" => "high",
      "worktree.branch" => "feature",
      "estimate" => "2h"
    }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "high", result["priority"]
    assert_equal "feature", result["worktree"]["branch"]
    assert_equal "2h", result["estimate"]
  end

  def test_apply_update_preserves_other_fields
    yaml_hash = {
      "id" => "v.0.9.0+task.090",
      "status" => "pending",
      "priority" => "high",
      "dependencies" => []
    }
    updates = { "status" => "in-progress" }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "in-progress", result["status"]
    assert_equal "v.0.9.0+task.090", result["id"]
    assert_equal "high", result["priority"]
    assert_equal [], result["dependencies"]
  end

  def test_apply_update_with_empty_value
    yaml_hash = { "description" => "old description" }
    updates = { "description" => "" }

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal "", result["description"]
  end

  def test_apply_nested_update_raises_error_when_parent_not_hash
    yaml_hash = { "worktree" => "not-a-hash" }
    updates = { "worktree.branch" => "value" }

    error = assert_raises(Ace::Taskflow::Molecules::TaskFieldUpdater::FieldUpdateError) do
      @updater.apply_updates(yaml_hash, updates)
    end

    assert_match(/Cannot update nested field/, error.message)
    assert_match(/not a hash/, error.message)
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

  # ========================================
  # Integration tests
  # ========================================

  def test_full_workflow_parse_apply_validate
    # Parse field updates
    field_args = [
      "priority=high",
      "estimate=1 week",
      "worktree.branch=090-task-update"
    ]
    updates = @updater.parse_field_updates(field_args)

    # Validate types
    yaml_hash = {
      "id" => "v.0.9.0+task.090",
      "status" => "pending",
      "priority" => "medium"
    }
    errors = @updater.validate_types(yaml_hash, updates)
    assert_empty errors

    # Apply updates
    result = @updater.apply_updates(yaml_hash, updates)

    # Verify result
    assert_equal "high", result["priority"]
    assert_equal "1 week", result["estimate"]
    assert_equal "090-task-update", result["worktree"]["branch"]
    assert_equal "v.0.9.0+task.090", result["id"]
    assert_equal "pending", result["status"]
  end

  def test_full_workflow_with_array_update
    field_args = ["dependencies=[082, 083, 084]"]
    updates = @updater.parse_field_updates(field_args)

    yaml_hash = { "dependencies" => [] }
    errors = @updater.validate_types(yaml_hash, updates)
    assert_empty errors

    result = @updater.apply_updates(yaml_hash, updates)

    assert_equal [82, 83, 84], result["dependencies"]
  end

  def test_full_workflow_with_type_inference
    field_args = [
      "count=42",
      "percentage=95.5",
      "completed=true",
      "name=test",
      'description="quoted string"'
    ]
    updates = @updater.parse_field_updates(field_args)

    # Verify type inference
    assert_equal 42, updates["count"]
    assert_equal 95.5, updates["percentage"]
    assert_equal true, updates["completed"]
    assert_equal "test", updates["name"]
    assert_equal "quoted string", updates["description"]
  end
end
