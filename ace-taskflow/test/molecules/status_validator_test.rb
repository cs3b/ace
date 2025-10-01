# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/status_validator"

class StatusValidatorTest < Minitest::Test
  def test_valid_transition_pending_to_in_progress
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("pending", "in-progress")
  end

  def test_valid_transition_in_progress_to_done
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("in-progress", "done")
  end

  def test_valid_transition_done_to_pending
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("done", "pending")
  end

  def test_invalid_transition_pending_to_done
    refute Ace::Taskflow::Molecules::StatusValidator.valid_transition?("pending", "done")
  end

  def test_invalid_transition_done_to_in_progress
    refute Ace::Taskflow::Molecules::StatusValidator.valid_transition?("done", "in-progress")
  end

  def test_valid_transition_to_blocked
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("pending", "blocked")
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("in-progress", "blocked")
  end

  def test_valid_transition_from_blocked
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("blocked", "pending")
    assert Ace::Taskflow::Molecules::StatusValidator.valid_transition?("blocked", "in-progress")
  end

  def test_unknown_status_returns_false
    refute Ace::Taskflow::Molecules::StatusValidator.valid_transition?("unknown", "pending")
  end

  def test_allowed_transitions_for_pending
    allowed = Ace::Taskflow::Molecules::StatusValidator.allowed_transitions("pending")

    assert_includes allowed, "in-progress"
    assert_includes allowed, "blocked"
    refute_includes allowed, "done"
  end

  def test_allowed_transitions_for_in_progress
    allowed = Ace::Taskflow::Molecules::StatusValidator.allowed_transitions("in-progress")

    assert_includes allowed, "done"
    assert_includes allowed, "pending"
    assert_includes allowed, "blocked"
  end

  def test_allowed_transitions_for_unknown_status
    allowed = Ace::Taskflow::Molecules::StatusValidator.allowed_transitions("unknown")

    assert_equal [], allowed
  end

  def test_all_statuses_includes_all_states
    statuses = Ace::Taskflow::Molecules::StatusValidator.all_statuses

    assert_includes statuses, "draft"
    assert_includes statuses, "pending"
    assert_includes statuses, "in-progress"
    assert_includes statuses, "blocked"
    assert_includes statuses, "done"
  end
end
