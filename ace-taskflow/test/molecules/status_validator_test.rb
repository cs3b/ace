# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/status_validator"

# Tests for strict mode behavior (legacy behavior)
# For flexible mode tests, see status_validator_flexible_test.rb
class StatusValidatorTest < Minitest::Test
  def test_valid_transition_pending_to_in_progress
    # Valid in both modes
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("pending", "in-progress", flexible: false)
  end

  def test_valid_transition_in_progress_to_done
    # Valid in both modes
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("in-progress", "done", flexible: false)
  end

  def test_valid_transition_done_to_pending
    # Valid in both modes
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("done", "pending", flexible: false)
  end

  def test_invalid_transition_pending_to_done
    # Invalid in strict mode
    refute Ace::Taskflow::Molecules::StatusValidator.valid_transition?("pending", "done", flexible: false)
  end

  def test_invalid_transition_done_to_in_progress
    # Invalid in strict mode
    refute Ace::Taskflow::Molecules::StatusValidator.valid_transition?("done", "in-progress", flexible: false)
  end

  def test_valid_transition_to_blocked
    # Valid in both modes
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("pending", "blocked", flexible: false)
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("in-progress", "blocked", flexible: false)
  end

  def test_valid_transition_from_blocked
    # Valid in both modes
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("blocked", "pending", flexible: false)
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("blocked", "in-progress", flexible: false)
  end

  def test_unknown_status_returns_false
    # Unknown status should be invalid in strict mode
    refute Ace::Taskflow::Molecules::StatusValidator.valid_transition?("unknown", "pending", flexible: false)
  end

  def test_allowed_transitions_for_pending
    # Strict mode: use transition matrix
    allowed = Ace::Taskflow::Molecules::StatusValidator.allowed_transitions("pending", flexible: false)

    assert_includes allowed, "in-progress"
    assert_includes allowed, "blocked"
    refute_includes allowed, "done"
  end

  def test_allowed_transitions_for_in_progress
    # Strict mode: use transition matrix
    allowed = Ace::Taskflow::Molecules::StatusValidator.allowed_transitions("in-progress", flexible: false)

    assert_includes allowed, "done"
    assert_includes allowed, "pending"
    assert_includes allowed, "blocked"
  end

  def test_allowed_transitions_for_unknown_status
    # Strict mode: unknown status has no allowed transitions
    allowed = Ace::Taskflow::Molecules::StatusValidator.allowed_transitions("unknown", flexible: false)

    assert_equal [], allowed
  end

  def test_all_statuses_includes_all_states
    # Works the same in both modes
    statuses = Ace::Taskflow::Molecules::StatusValidator.all_statuses

    assert_includes statuses, "draft"
    assert_includes statuses, "pending"
    assert_includes statuses, "in-progress"
    assert_includes statuses, "blocked"
    assert_includes statuses, "done"
  end
end
