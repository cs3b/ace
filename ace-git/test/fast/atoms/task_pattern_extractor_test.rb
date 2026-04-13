# frozen_string_literal: true

require "test_helper"

class TaskPatternExtractorTest < AceGitTestCase
  def setup
    super
    @extractor = Ace::Git::Atoms::TaskPatternExtractor
  end

  def test_extract_from_branch_extracts_simple_number
    assert_equal "117", @extractor.extract_from_branch("117-feature-name")
  end

  def test_extract_from_branch_extracts_dotted_number
    assert_equal "121.01", @extractor.extract_from_branch("121.01-archive")
  end

  def test_extract_from_branch_extracts_subtask_number
    assert_equal "140.03", @extractor.extract_from_branch("140.03-migrate-package")
  end

  def test_extract_from_branch_returns_nil_for_main
    assert_nil @extractor.extract_from_branch("main")
  end

  def test_extract_from_branch_returns_nil_for_feature_without_leading_number
    assert_nil @extractor.extract_from_branch("feature-123")
  end

  def test_extract_from_branch_returns_nil_for_nil
    assert_nil @extractor.extract_from_branch(nil)
  end

  def test_extract_from_branch_returns_nil_for_empty_string
    assert_nil @extractor.extract_from_branch("")
  end

  def test_extract_from_branch_returns_nil_for_detached_head
    assert_nil @extractor.extract_from_branch("HEAD")
  end

  def test_extract_from_branch_with_custom_pattern
    patterns = ['^task-(\d+)']
    assert_equal "456", @extractor.extract_from_branch("task-456-feature", patterns: patterns)
  end

  def test_extract_shortcut_method
    assert_equal "117", @extractor.extract("117-feature-name")
    assert_nil @extractor.extract("main")
  end

  def test_has_task_pattern
    assert @extractor.has_task_pattern?("117-feature-name")
    refute @extractor.has_task_pattern?("main")
  end
end
