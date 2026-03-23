# frozen_string_literal: true

require "test_helper"
require "ace/idea/atoms/idea_validation_rules"

class IdeaValidationRulesTest < AceIdeaTestCase
  Rules = Ace::Idea::Atoms::IdeaValidationRules

  # --- valid_status? ---

  def test_valid_status_accepts_pending
    assert Rules.valid_status?("pending")
  end

  def test_valid_status_accepts_in_progress
    assert Rules.valid_status?("in-progress")
  end

  def test_valid_status_accepts_done
    assert Rules.valid_status?("done")
  end

  def test_valid_status_accepts_obsolete
    assert Rules.valid_status?("obsolete")
  end

  def test_valid_status_rejects_unknown
    refute Rules.valid_status?("draft")
    refute Rules.valid_status?("new")
    refute Rules.valid_status?("")
  end

  # --- terminal_status? ---

  def test_terminal_status_done
    assert Rules.terminal_status?("done")
  end

  def test_terminal_status_obsolete
    assert Rules.terminal_status?("obsolete")
  end

  def test_terminal_status_pending_is_not_terminal
    refute Rules.terminal_status?("pending")
  end

  def test_terminal_status_in_progress_is_not_terminal
    refute Rules.terminal_status?("in-progress")
  end

  # --- valid_id? ---

  def test_valid_id_accepts_valid_b36ts
    id = Ace::Idea::Atoms::IdeaIdFormatter.generate
    assert Rules.valid_id?(id)
  end

  def test_valid_id_rejects_nil
    refute Rules.valid_id?(nil)
  end

  def test_valid_id_rejects_empty
    refute Rules.valid_id?("")
  end

  # --- scope_consistent? ---

  def test_scope_consistent_done_in_archive
    issues = Rules.scope_consistent?("done", "_archive")
    assert_empty issues
  end

  def test_scope_consistent_pending_in_root
    issues = Rules.scope_consistent?("pending", nil)
    assert_empty issues
  end

  def test_scope_inconsistent_done_not_in_archive
    issues = Rules.scope_consistent?("done", nil)
    assert_equal 1, issues.size
    assert_equal :warning, issues.first[:type]
    assert_match(/not in _archive/, issues.first[:message])
  end

  def test_scope_inconsistent_archive_but_pending
    issues = Rules.scope_consistent?("pending", "_archive")
    assert_equal 1, issues.size
    assert_match(/in _archive/, issues.first[:message])
  end

  def test_scope_inconsistent_maybe_with_terminal
    issues = Rules.scope_consistent?("done", "_maybe")
    # Should have both "not in _archive" and "in _maybe with terminal"
    assert issues.size >= 1
    messages = issues.map { |i| i[:message] }.join(" ")
    assert_match(/_maybe/, messages)
  end

  # --- missing_required_fields ---

  def test_missing_required_fields_all_present
    fm = {"id" => "abc123", "status" => "pending", "title" => "Test"}
    assert_empty Rules.missing_required_fields(fm)
  end

  def test_missing_required_fields_empty_hash
    missing = Rules.missing_required_fields({})
    assert_includes missing, "id"
    assert_includes missing, "status"
    assert_includes missing, "title"
  end

  def test_missing_required_fields_nil_frontmatter
    missing = Rules.missing_required_fields(nil)
    assert_equal 3, missing.size
  end

  def test_missing_required_fields_blank_values
    fm = {"id" => "", "status" => "pending", "title" => " "}
    missing = Rules.missing_required_fields(fm)
    assert_includes missing, "id"
    assert_includes missing, "title"
    refute_includes missing, "status"
  end

  # --- missing_recommended_fields ---

  def test_missing_recommended_fields_all_present
    fm = {"tags" => ["a"], "created_at" => "2026-01-01"}
    assert_empty Rules.missing_recommended_fields(fm)
  end

  def test_missing_recommended_fields_none_present
    missing = Rules.missing_recommended_fields({})
    assert_includes missing, "tags"
    assert_includes missing, "created_at"
  end

  # --- constants ---

  def test_valid_statuses_frozen
    assert Rules::VALID_STATUSES.frozen?
  end

  def test_terminal_statuses_subset_of_valid
    Rules::TERMINAL_STATUSES.each do |s|
      assert_includes Rules::VALID_STATUSES, s
    end
  end
end
