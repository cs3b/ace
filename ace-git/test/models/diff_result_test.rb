# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/models/diff_result"

class DiffResultTest < AceGitTestCase
  def test_initialize_with_all_attributes
    result = Ace::Git::Models::DiffResult.new(
      content: "diff content",
      stats: {additions: 10, deletions: 5, total_changes: 15},
      files: ["lib/test.rb", "test/test_test.rb"],
      metadata: {range: "HEAD~1..HEAD"},
      filtered: true
    )

    assert_equal "diff content", result.content
    assert_equal 10, result.stats[:additions]
    assert_equal 5, result.stats[:deletions]
    assert_equal ["lib/test.rb", "test/test_test.rb"], result.files
    assert_equal({range: "HEAD~1..HEAD"}, result.metadata)
    assert result.filtered
  end

  def test_empty_returns_true_for_nil_content
    result = Ace::Git::Models::DiffResult.new(
      content: nil,
      stats: {},
      files: []
    )

    assert result.empty?
  end

  def test_empty_returns_true_for_whitespace_only_content
    result = Ace::Git::Models::DiffResult.new(
      content: "   \n  \t  ",
      stats: {},
      files: []
    )

    assert result.empty?
  end

  def test_empty_returns_false_for_non_empty_content
    result = Ace::Git::Models::DiffResult.new(
      content: "diff --git a/file.rb b/file.rb",
      stats: {},
      files: []
    )

    refute result.empty?
  end

  def test_has_changes_returns_true_when_total_changes_positive
    result = Ace::Git::Models::DiffResult.new(
      content: "some diff",
      stats: {total_changes: 5},
      files: ["file.rb"]
    )

    assert result.has_changes?
  end

  def test_has_changes_returns_false_when_total_changes_zero
    result = Ace::Git::Models::DiffResult.new(
      content: "",
      stats: {total_changes: 0},
      files: []
    )

    refute result.has_changes?
  end

  def test_has_changes_returns_false_when_total_changes_nil
    result = Ace::Git::Models::DiffResult.new(
      content: "",
      stats: {},
      files: []
    )

    refute result.has_changes?
  end

  def test_line_count_uses_stats_when_available
    result = Ace::Git::Models::DiffResult.new(
      content: "line1\nline2\nline3",
      stats: {line_count: 100},
      files: []
    )

    assert_equal 100, result.line_count
  end

  def test_line_count_counts_newlines_when_no_stats
    result = Ace::Git::Models::DiffResult.new(
      content: "line1\nline2\nline3",
      stats: {},
      files: []
    )

    assert_equal 3, result.line_count
  end

  def test_line_count_returns_zero_for_nil_content
    result = Ace::Git::Models::DiffResult.new(
      content: nil,
      stats: {},
      files: []
    )

    assert_equal 0, result.line_count
  end

  def test_summary_formats_correctly
    result = Ace::Git::Models::DiffResult.new(
      content: "diff content",
      stats: {additions: 25, deletions: 10},
      files: ["a.rb", "b.rb", "c.rb"]
    )

    assert_equal "3 files, +25 -10", result.summary
  end

  def test_to_h_includes_all_fields
    result = Ace::Git::Models::DiffResult.new(
      content: "diff",
      stats: {additions: 1, deletions: 2, total_changes: 3},
      files: ["file.rb"],
      metadata: {range: "HEAD"},
      filtered: true
    )

    hash = result.to_h

    assert_equal "diff", hash[:content]
    assert_equal({additions: 1, deletions: 2, total_changes: 3}, hash[:stats])
    assert_equal ["file.rb"], hash[:files]
    assert_equal({range: "HEAD"}, hash[:metadata])
    assert hash[:filtered]
    refute hash[:empty]
    assert hash[:has_changes]
    assert_kind_of Integer, hash[:line_count]
    assert_kind_of String, hash[:summary]
  end

  def test_from_parsed_creates_result
    parsed_data = {
      content: "parsed diff",
      stats: {additions: 5, deletions: 3},
      files: ["parsed.rb"],
      line_count: 50
    }

    result = Ace::Git::Models::DiffResult.from_parsed(
      parsed_data,
      metadata: {source: "test"},
      filtered: true
    )

    assert_equal "parsed diff", result.content
    assert_equal 5, result.stats[:additions]
    assert_equal 50, result.stats[:line_count]
    assert_equal ["parsed.rb"], result.files
    assert_equal({source: "test"}, result.metadata)
    assert result.filtered
  end

  def test_empty_class_method_creates_empty_result
    result = Ace::Git::Models::DiffResult.empty(metadata: {reason: "no changes"})

    assert result.empty?
    refute result.has_changes?
    assert_equal "", result.content
    assert_equal [], result.files
    assert_equal 0, result.stats[:additions]
    assert_equal 0, result.stats[:deletions]
    assert_equal({reason: "no changes"}, result.metadata)
    refute result.filtered
  end

  def test_default_filtered_is_false
    result = Ace::Git::Models::DiffResult.new(
      content: "diff",
      stats: {},
      files: []
    )

    refute result.filtered
  end

  def test_default_metadata_is_empty_hash
    result = Ace::Git::Models::DiffResult.new(
      content: "diff",
      stats: {},
      files: []
    )

    assert_equal({}, result.metadata)
  end
end
