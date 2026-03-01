# frozen_string_literal: true

require "test_helper"
require "ace/retro/atoms/retro_validation_rules"

class RetroValidationRulesTest < AceRetroTestCase
  Rules = Ace::Retro::Atoms::RetroValidationRules

  # --- valid_status? ---

  def test_valid_status_accepts_active
    assert Rules.valid_status?("active")
  end

  def test_valid_status_accepts_done
    assert Rules.valid_status?("done")
  end

  def test_valid_status_rejects_unknown
    refute Rules.valid_status?("draft")
    refute Rules.valid_status?("pending")
    refute Rules.valid_status?("")
  end

  # --- terminal_status? ---

  def test_terminal_status_done
    assert Rules.terminal_status?("done")
  end

  def test_terminal_status_active_is_not_terminal
    refute Rules.terminal_status?("active")
  end

  # --- valid_id? ---

  def test_valid_id_accepts_valid_b36ts
    id = Ace::Retro::Atoms::RetroIdFormatter.generate
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

  def test_scope_consistent_active_in_root
    issues = Rules.scope_consistent?("active", nil)
    assert_empty issues
  end

  def test_scope_inconsistent_done_not_in_archive
    issues = Rules.scope_consistent?("done", nil)
    assert_equal 1, issues.size
    assert_equal :warning, issues.first[:type]
    assert_match(/not in _archive/, issues.first[:message])
  end

  def test_scope_inconsistent_archive_but_active
    issues = Rules.scope_consistent?("active", "_archive")
    assert_equal 1, issues.size
    assert_match(/in _archive/, issues.first[:message])
  end

  # --- missing_required_fields ---

  def test_missing_required_fields_all_present
    fm = { "id" => "abc123", "status" => "active", "title" => "Test", "type" => "standard", "created_at" => "2026-01-01" }
    assert_empty Rules.missing_required_fields(fm)
  end

  def test_missing_required_fields_empty_hash
    missing = Rules.missing_required_fields({})
    assert_includes missing, "id"
    assert_includes missing, "status"
    assert_includes missing, "title"
    assert_includes missing, "type"
    assert_includes missing, "created_at"
  end

  def test_missing_required_fields_nil_frontmatter
    missing = Rules.missing_required_fields(nil)
    assert_equal 5, missing.size
  end

  def test_missing_required_fields_blank_values
    fm = { "id" => "", "status" => "active", "title" => " ", "type" => "standard", "created_at" => "2026-01-01" }
    missing = Rules.missing_required_fields(fm)
    assert_includes missing, "id"
    assert_includes missing, "title"
    refute_includes missing, "status"
  end

  # --- missing_recommended_fields ---

  def test_missing_recommended_fields_all_present
    fm = { "tags" => ["a"] }
    assert_empty Rules.missing_recommended_fields(fm)
  end

  def test_missing_recommended_fields_none_present
    missing = Rules.missing_recommended_fields({})
    assert_includes missing, "tags"
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
