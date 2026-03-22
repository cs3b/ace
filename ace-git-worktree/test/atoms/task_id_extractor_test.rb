# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/atoms/task_id_extractor"

class TaskIDExtractorTest < Minitest::Test
  include TestHelper

  def setup
    @extractor = Ace::Git::Worktree::Atoms::TaskIDExtractor
  end

  # Tests for .extract method

  def test_extract_from_simple_task_id
    task_data = { id: "v.0.9.0+task.121" }
    assert_equal "121", @extractor.extract(task_data)
  end

  def test_extract_from_subtask_id
    task_data = { id: "v.0.9.0+task.121.01" }
    assert_equal "121.01", @extractor.extract(task_data)
  end

  def test_extract_from_short_task_id
    task_data = { id: "v.0.9.0+t.121" }
    assert_equal "121", @extractor.extract(task_data)
  end

  def test_extract_from_short_ace_task_id
    task_data = { id: "v.0.9.0+ace-t.121" }
    assert_equal "121", @extractor.extract(task_data)
  end

  def test_extract_from_orchestrator_id
    task_data = { id: "v.0.9.0+task.121" }
    assert_equal "121", @extractor.extract(task_data)
  end

  def test_extract_from_backlog_task
    task_data = { id: "backlog+task.005" }
    assert_equal "005", @extractor.extract(task_data)
  end

  def test_extract_from_backlog_subtask
    task_data = { id: "backlog+task.005.02" }
    assert_equal "005.02", @extractor.extract(task_data)
  end

  def test_extract_with_task_number_fallback
    task_data = { task_number: "081" }
    assert_equal "081", @extractor.extract(task_data)
  end

  def test_extract_prefers_id_over_task_number
    # When both are present, :id should be used (it has subtask info)
    task_data = { id: "v.0.9.0+task.121.01", task_number: "121" }
    assert_equal "121.01", @extractor.extract(task_data)
  end

  def test_extract_with_nil_data
    assert_equal "unknown", @extractor.extract(nil)
  end

  def test_extract_with_empty_hash
    assert_equal "unknown", @extractor.extract({})
  end

  def test_extract_with_invalid_id
    task_data = { id: "invalid-id-format" }
    assert_equal "unknown", @extractor.extract(task_data)
  end

  # Tests for .normalize method

  def test_normalize_simple_number
    assert_equal "121", @extractor.normalize("121")
  end

  def test_normalize_subtask_number
    assert_equal "121.01", @extractor.normalize("121.01")
  end

  def test_normalize_orchestrator_number
    assert_equal "121", @extractor.normalize("121")
  end

  def test_normalize_with_task_prefix
    assert_equal "121", @extractor.normalize("task.121")
  end

  def test_normalize_with_short_task_prefix
    assert_equal "121", @extractor.normalize("t.121")
  end

  def test_normalize_with_short_ace_task_prefix
    assert_equal "121", @extractor.normalize("ace-t.121")
  end

  def test_normalize_subtask_with_task_prefix
    assert_equal "121.01", @extractor.normalize("task.121.01")
  end

  def test_normalize_subtask_with_short_task_prefix
    assert_equal "121.01", @extractor.normalize("t.121.01")
  end

  def test_normalize_fully_qualified_id
    assert_equal "121", @extractor.normalize("v.0.9.0+task.121")
  end

  def test_normalize_fully_qualified_subtask_id
    assert_equal "121.01", @extractor.normalize("v.0.9.0+task.121.01")
  end

  def test_normalize_backlog_id
    assert_equal "005", @extractor.normalize("backlog+task.005")
  end

  def test_normalize_backlog_subtask_id
    assert_equal "005.02", @extractor.normalize("backlog+task.005.02")
  end

  def test_normalize_with_nil
    assert_nil @extractor.normalize(nil)
  end

  def test_normalize_with_empty_string
    assert_nil @extractor.normalize("")
  end

  def test_normalize_with_whitespace
    assert_nil @extractor.normalize("   ")
  end

  def test_normalize_strips_whitespace
    assert_equal "121.01", @extractor.normalize("  121.01  ")
  end

  # Edge cases

  def test_extract_with_three_digit_task_number
    task_data = { id: "v.0.9.0+task.001" }
    assert_equal "001", @extractor.extract(task_data)
  end

  def test_normalize_three_digit_subtask
    assert_equal "001.01", @extractor.normalize("001.01")
  end

  def test_extract_does_not_match_partial_patterns
    # Should not match "121.1" (subtask must be 2 digits)
    task_data = { id: "v.0.9.0+task.121.1" }
    # Falls back to simple pattern since .1 doesn't match .XX
    assert_equal "121", @extractor.extract(task_data)
  end

  # Path extraction tests (handles ace-task.NNN in directory names)

  def test_normalize_from_path_with_multiple_task_patterns
    # Should match task.999 at end, not ace-task.261 in middle
    assert_equal "999", @extractor.normalize("/Users/mc/Ps/ace-task.261/.cache/test/task.999")
  end

  def test_normalize_from_path_with_ace_task_prefix
    # Should match task.081, not 261 from ace-task.261
    assert_equal "081", @extractor.normalize("/Users/mc/Ps/ace-task.261/worktrees/task.081")
  end

  def test_normalize_from_path_with_ace_t_prefix
    assert_equal "081", @extractor.normalize("/Users/mc/Ps/ace-task.261/worktrees/t.081")
  end

  def test_normalize_from_path_with_short_task_prefix
    assert_equal "081", @extractor.normalize("/Users/mc/Ps/worktrees/t.081")
  end

  # B36TS format tests (regression for ace-overseer work-on failure)

  def test_extract_from_b36ts_full_id
    task_data = { id: "8pp.t.hy4" }
    assert_equal "hy4", @extractor.extract(task_data)
  end

  def test_extract_from_b36ts_subtask_full_id
    task_data = { id: "8pp.t.hy4.a" }
    assert_equal "hy4.a", @extractor.extract(task_data)
  end

  def test_normalize_b36ts_short_ref
    assert_equal "hy4", @extractor.normalize("hy4")
  end

  def test_normalize_b36ts_full_id
    assert_equal "hy4", @extractor.normalize("8pp.t.hy4")
  end

  def test_normalize_b36ts_subtask_full_id
    assert_equal "hy4.a", @extractor.normalize("8pp.t.hy4.a")
  end

  # B36TS path extraction tests (ace-task.hy4 directory naming)

  def test_normalize_from_ace_task_b36ts_path
    assert_equal "hy4", @extractor.normalize("/home/mc/ace-task.hy4")
  end

  def test_normalize_from_ace_task_b36ts_path_with_trailing_slash
    assert_equal "hy4", @extractor.normalize("/home/mc/ace-task.hy4/")
  end

  def test_normalize_from_task_b36ts_path
    assert_equal "hy4", @extractor.normalize("/home/mc/task.hy4")
  end

  def test_normalize_from_ace_task_numeric_path
    assert_equal "261", @extractor.normalize("ace-task.261")
  end
end
