# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/status_validator"

class StatusValidatorFlexibleTest < AceTaskflowTestCase
  def setup
    @validator = Ace::Taskflow::Molecules::StatusValidator
  end

  # Test flexible mode (default behavior)
  def test_flexible_mode_allows_any_transition
    # Any status to any other status should be valid in flexible mode
    assert @validator.valid_transition?("pending", "done", flexible: true)
    assert @validator.valid_transition?("draft", "done", flexible: true)
    assert @validator.valid_transition?("blocked", "done", flexible: true)
    assert @validator.valid_transition?("ready-for-review", "done", flexible: true)
    assert @validator.valid_transition?("custom-status", "another-custom", flexible: true)
  end

  def test_flexible_mode_is_default
    # Flexible mode should be the default when no parameter is provided
    assert @validator.valid_transition?("pending", "done")
    assert @validator.valid_transition?("custom", "done")
  end

  def test_strict_mode_enforces_transition_matrix
    # In strict mode, only predefined transitions are valid
    refute @validator.valid_transition?("pending", "done", flexible: false)
    assert @validator.valid_transition?("in-progress", "done", flexible: false)
    refute @validator.valid_transition?("draft", "done", flexible: false)
  end

  def test_strict_mode_rejects_custom_statuses
    # Custom statuses should fail in strict mode since they're not in the matrix
    refute @validator.valid_transition?("ready-for-review", "done", flexible: false)
    refute @validator.valid_transition?("custom-status", "done", flexible: false)
  end

  # Test idempotent operations
  def test_idempotent_operation_same_status
    assert @validator.idempotent_operation?("pending", "pending")
    assert @validator.idempotent_operation?("done", "done")
    assert @validator.idempotent_operation?("in-progress", "in-progress")
    assert @validator.idempotent_operation?("custom-status", "custom-status")
  end

  def test_not_idempotent_different_statuses
    refute @validator.idempotent_operation?("pending", "done")
    refute @validator.idempotent_operation?("in-progress", "pending")
  end

  # Test custom status validation
  def test_valid_status_flexible_mode
    # Any non-empty string is valid in flexible mode
    assert @validator.valid_status?("pending", flexible: true)
    assert @validator.valid_status?("ready-for-review", flexible: true)
    assert @validator.valid_status?("custom-anything", flexible: true)
    assert @validator.valid_status?("status-with-dashes", flexible: true)
  end

  def test_invalid_status_empty_or_nil
    # Empty or nil statuses are never valid
    refute @validator.valid_status?(nil, flexible: true)
    refute @validator.valid_status?("", flexible: true)
    refute @validator.valid_status?("   ", flexible: true)

    refute @validator.valid_status?(nil, flexible: false)
    refute @validator.valid_status?("", flexible: false)
  end

  def test_valid_status_strict_mode
    # Only known statuses are valid in strict mode
    assert @validator.valid_status?("pending", flexible: false)
    assert @validator.valid_status?("done", flexible: false)
    assert @validator.valid_status?("in-progress", flexible: false)
    assert @validator.valid_status?("deferred", flexible: false)

    refute @validator.valid_status?("ready-for-review", flexible: false)
    refute @validator.valid_status?("custom", flexible: false)
  end

  # Test allowed transitions
  def test_allowed_transitions_flexible_mode
    # In flexible mode, can transition to any status except same
    transitions = @validator.allowed_transitions("pending", flexible: true)

    assert transitions.include?("done")
    assert transitions.include?("in-progress")
    assert transitions.include?("blocked")
    refute transitions.include?("pending") # Cannot transition to same status
  end

  def test_allowed_transitions_strict_mode
    # In strict mode, use predefined matrix
    pending_transitions = @validator.allowed_transitions("pending", flexible: false)
    assert_equal ["in-progress", "blocked", "deferred"], pending_transitions

    in_progress_transitions = @validator.allowed_transitions("in-progress", flexible: false)
    assert_equal ["done", "pending", "blocked", "deferred"], in_progress_transitions
  end

  def test_all_statuses_returns_known_statuses
    all = @validator.all_statuses

    assert all.include?("pending")
    assert all.include?("done")
    assert all.include?("in-progress")
    assert all.include?("blocked")
    assert all.include?("draft")
    assert all.include?("deferred")
  end
end
