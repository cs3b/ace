# frozen_string_literal: true

require "test_helper"

class TaskFilePatternTest < AceTaskTestCase
  Pattern = Ace::Task::Atoms::TaskFilePattern

  def test_primary_file_matches_folder_id
    assert Pattern.primary_file?("8pp.t.q7w-fix-login.s.md", "8pp.t.q7w")
  end

  def test_primary_file_without_slug
    assert Pattern.primary_file?("8pp.t.q7w.s.md", "8pp.t.q7w")
  end

  def test_subtask_file_not_primary
    refute Pattern.primary_file?("8pp.t.q7w.a-setup-db.s.md", "8pp.t.q7w")
  end

  def test_idea_file_not_primary
    refute Pattern.primary_file?("8pp.t.q7w.idea.s.md", "8pp.t.q7w")
  end

  def test_subtask_file_detected
    assert Pattern.subtask_file?("8pp.t.q7w.a-setup-db.s.md")
  end

  def test_primary_file_not_subtask
    refute Pattern.subtask_file?("8pp.t.q7w-fix-login.s.md")
  end

  def test_idea_file_not_subtask
    refute Pattern.subtask_file?("foo.idea.s.md")
  end

  def test_extract_id_primary
    assert_equal "8pp.t.q7w", Pattern.extract_id_from_filename("8pp.t.q7w-fix-login.s.md")
  end

  def test_extract_id_subtask
    assert_equal "8pp.t.q7w.a", Pattern.extract_id_from_filename("8pp.t.q7w.a-setup-db.s.md")
  end

  def test_extract_id_no_slug
    assert_equal "8pp.t.q7w", Pattern.extract_id_from_filename("8pp.t.q7w.s.md")
  end

  def test_extract_id_returns_nil_for_non_spec
    assert_nil Pattern.extract_id_from_filename("readme.md")
  end

  def test_subtask_chars_include_digits
    assert Pattern.subtask_file?("8pp.t.q7w.0-overflow.s.md")
  end
end
