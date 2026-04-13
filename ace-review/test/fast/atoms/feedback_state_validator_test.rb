# frozen_string_literal: true

require "test_helper"

class FeedbackStateValidatorTest < AceReviewTest
  # ============================================================================
  # valid_transition? Tests
  # ============================================================================

  def test_valid_transition_draft_to_pending
    assert Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("draft", "pending")
  end

  def test_valid_transition_draft_to_invalid
    assert Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("draft", "invalid")
  end

  def test_valid_transition_draft_to_skip
    assert Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("draft", "skip")
  end

  def test_valid_transition_pending_to_done
    assert Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("pending", "done")
  end

  def test_valid_transition_pending_to_skip
    assert Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("pending", "skip")
  end

  def test_invalid_transition_draft_to_done
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("draft", "done")
  end

  def test_invalid_transition_pending_to_pending
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("pending", "pending")
  end

  def test_invalid_transition_pending_to_invalid
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("pending", "invalid")
  end

  def test_invalid_transition_from_terminal_done
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("done", "pending")
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("done", "draft")
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("done", "skip")
  end

  def test_invalid_transition_from_terminal_invalid
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("invalid", "pending")
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("invalid", "draft")
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("invalid", "done")
  end

  def test_invalid_transition_from_terminal_skip
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("skip", "pending")
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("skip", "draft")
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("skip", "done")
  end

  def test_invalid_transition_from_unknown_status
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?("unknown", "pending")
    refute Ace::Review::Atoms::FeedbackStateValidator.valid_transition?(nil, "pending")
  end

  # ============================================================================
  # allowed_transitions Tests
  # ============================================================================

  def test_allowed_transitions_from_draft
    allowed = Ace::Review::Atoms::FeedbackStateValidator.allowed_transitions("draft")

    assert_includes allowed, "pending"
    assert_includes allowed, "invalid"
    assert_includes allowed, "skip"
    refute_includes allowed, "done"
    assert_equal 3, allowed.length
  end

  def test_allowed_transitions_from_pending
    allowed = Ace::Review::Atoms::FeedbackStateValidator.allowed_transitions("pending")

    assert_includes allowed, "done"
    assert_includes allowed, "skip"
    refute_includes allowed, "pending"
    refute_includes allowed, "invalid"
    assert_equal 2, allowed.length
  end

  def test_allowed_transitions_from_terminal_states
    %w[invalid skip done].each do |status|
      allowed = Ace::Review::Atoms::FeedbackStateValidator.allowed_transitions(status)
      assert_empty allowed, "#{status} should have no allowed transitions"
    end
  end

  def test_allowed_transitions_from_unknown_status
    allowed = Ace::Review::Atoms::FeedbackStateValidator.allowed_transitions("unknown")
    assert_empty allowed
  end

  def test_allowed_transitions_returns_copy
    allowed1 = Ace::Review::Atoms::FeedbackStateValidator.allowed_transitions("draft")
    allowed2 = Ace::Review::Atoms::FeedbackStateValidator.allowed_transitions("draft")

    # Modifying one shouldn't affect the other
    allowed1 << "test"
    refute_includes allowed2, "test"
  end

  # ============================================================================
  # terminal? Tests
  # ============================================================================

  def test_terminal_done
    assert Ace::Review::Atoms::FeedbackStateValidator.terminal?("done")
  end

  def test_terminal_invalid
    assert Ace::Review::Atoms::FeedbackStateValidator.terminal?("invalid")
  end

  def test_terminal_skip
    assert Ace::Review::Atoms::FeedbackStateValidator.terminal?("skip")
  end

  def test_not_terminal_draft
    refute Ace::Review::Atoms::FeedbackStateValidator.terminal?("draft")
  end

  def test_not_terminal_pending
    refute Ace::Review::Atoms::FeedbackStateValidator.terminal?("pending")
  end

  # ============================================================================
  # should_archive? Tests
  # ============================================================================

  def test_should_archive_done
    assert Ace::Review::Atoms::FeedbackStateValidator.should_archive?("done")
  end

  def test_should_archive_invalid
    assert Ace::Review::Atoms::FeedbackStateValidator.should_archive?("invalid")
  end

  def test_should_archive_skip
    assert Ace::Review::Atoms::FeedbackStateValidator.should_archive?("skip")
  end

  def test_should_not_archive_draft
    refute Ace::Review::Atoms::FeedbackStateValidator.should_archive?("draft")
  end

  def test_should_not_archive_pending
    refute Ace::Review::Atoms::FeedbackStateValidator.should_archive?("pending")
  end
end
