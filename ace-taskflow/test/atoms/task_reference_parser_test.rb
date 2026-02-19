# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/atoms/task_reference_parser"

class TaskReferenceParserTest < Minitest::Test
  def setup
    @parser = Ace::Taskflow::Atoms::TaskReferenceParser
  end

  def test_parse_qualified_reference
    result = @parser.parse("v.0.9.0+task.018")

    assert_equal "v.0.9.0", result[:release]
    assert_equal "018", result[:number]
    assert result[:qualified]
    assert_equal "v.0.9.0+task.018", result[:original]
  end

  def test_parse_backlog_reference
    result = @parser.parse("backlog+task.025")

    assert_equal "backlog", result[:release]
    assert_equal "025", result[:number]
    assert result[:qualified]
  end

  def test_parse_simple_reference
    result = @parser.parse("018")

    assert_equal "current", result[:release]
    assert_equal "018", result[:number]
    refute result[:qualified]
  end

  def test_parse_task_dot_reference
    result = @parser.parse("task.018")

    assert_equal "current", result[:release]
    assert_equal "018", result[:number]
    refute result[:qualified]
  end

  def test_parse_current_reference
    result = @parser.parse("current+018")

    assert_equal "current", result[:release]
    assert_equal "018", result[:number]
    assert result[:qualified]
  end

  def test_parse_invalid_reference
    assert_nil @parser.parse("invalid")
    assert_nil @parser.parse("")
    assert_nil @parser.parse(nil)
  end

  def test_valid_predicate
    assert @parser.valid?("v.0.9.0+task.018")
    assert @parser.valid?("backlog+task.025")
    assert @parser.valid?("018")
    assert @parser.valid?("task.018")

    refute @parser.valid?("invalid")
    refute @parser.valid?("")
  end

  def test_qualified_predicate
    assert @parser.qualified?("v.0.9.0+task.018")
    assert @parser.qualified?("backlog+task.025")
    assert @parser.qualified?("current+018")

    refute @parser.qualified?("018")
    refute @parser.qualified?("task.018")
  end

  def test_is_release_version_predicate
    assert @parser.is_release_version?("v.0.9.0")
    assert @parser.is_release_version?("v.0.10.0-beta")

    refute @parser.is_release_version?("backlog")
    refute @parser.is_release_version?("current")
    refute @parser.is_release_version?("018")
  end

  def test_format_qualified_reference
    assert_equal "v.0.9.0+task.018", @parser.format("v.0.9.0", "18", qualified: true)
    assert_equal "backlog+task.025", @parser.format("backlog", 25, qualified: true)
    assert_equal "current+018", @parser.format("current", 18, qualified: true)
    assert_equal "018", @parser.format("current", 18, qualified: false)
  end

  def test_convert_reference_formats
    assert_equal "current+018", @parser.convert("018", :qualified)
    assert_equal "current+018", @parser.convert("018", :qualified, release: "current")
    assert_equal "v.0.9.0+task.018", @parser.convert("018", :qualified, release: "v.0.9.0")
    assert_equal "018", @parser.convert("v.0.9.0+task.018", :simple)
    assert_nil @parser.convert("invalid", :qualified)
  end

  def test_convert_preserves_subtask_to_qualified
    # Simple subtask -> qualified should preserve subtask
    assert_equal "v.0.9.0+task.121.01", @parser.convert("121.01", :qualified, release: "v.0.9.0")
    assert_equal "backlog+task.025.03", @parser.convert("025.03", :qualified, release: "backlog")
  end

  def test_convert_preserves_subtask_to_simple
    # Qualified subtask -> simple should preserve subtask
    assert_equal "121.01", @parser.convert("v.0.9.0+task.121.01", :simple)
    assert_equal "025.03", @parser.convert("backlog+task.025.03", :simple)
  end

  def test_convert_round_trip_with_subtask
    # Round-trip conversion should preserve subtask
    original = "121.01"
    qualified = @parser.convert(original, :qualified, release: "v.0.9.0")
    simple = @parser.convert(qualified, :simple)
    assert_equal original, simple
  end

  def test_extract_references_from_text
    text = "See tasks v.0.9.0+task.018 and backlog+task.025, also task.003"
    references = @parser.extract_references(text)

    assert_includes references, "v.0.9.0+task.018"
    assert_includes references, "backlog+task.025"
    assert_includes references, "task.003"
  end

  def test_extract_references_finds_hierarchical_qualified
    text = "See subtask v.0.9.0+task.121.01 and v.0.9.0+task.122.03"
    references = @parser.extract_references(text)

    assert_includes references, "v.0.9.0+task.121.01"
    assert_includes references, "v.0.9.0+task.122.03"
  end

  def test_extract_references_finds_hierarchical_simple
    text = "See task.121.01 and also task.122.03"
    references = @parser.extract_references(text)

    assert_includes references, "task.121.01"
    assert_includes references, "task.122.03"
  end

  def test_extract_references_mixed_hierarchical_and_simple
    text = "Tasks: v.0.9.0+task.121.01, task.003, backlog+task.025.03"
    references = @parser.extract_references(text)

    assert_includes references, "v.0.9.0+task.121.01"
    assert_includes references, "task.003"
    assert_includes references, "backlog+task.025.03"
    assert_equal 3, references.length
  end

  def test_extract_references_no_duplicates_for_hierarchical
    # When a hierarchical reference is found, the non-hierarchical shouldn't also be added
    text = "Task v.0.9.0+task.121.01 is a subtask"
    references = @parser.extract_references(text)

    assert_includes references, "v.0.9.0+task.121.01"
    # Should NOT include v.0.9.0+task.121 (parent) since only hierarchical was in text
    refute references.include?("v.0.9.0+task.121")
  end

  # ========== Hierarchical Task ID Tests (Subtask Support) ==========

  def test_parse_hierarchical_simple_00_raises_error
    error = assert_raises(ArgumentError) { @parser.parse("121.00") }
    assert_match(/\.00 orchestrator references are no longer supported/, error.message)
    assert_match(/Use the parent task ID instead/, error.message)
    assert_match(/'121'/, error.message)
  end

  def test_parse_hierarchical_qualified_00_raises_error
    error = assert_raises(ArgumentError) { @parser.parse("v.0.9.0+task.121.00") }
    assert_match(/\.00 orchestrator references are no longer supported/, error.message)
    assert_match(/'121'/, error.message)
  end

  def test_valid_returns_false_for_00_references
    refute @parser.valid?("121.00")
    refute @parser.valid?("v.0.9.0+task.121.00")
  end

  def test_qualified_returns_false_for_00_references
    refute @parser.qualified?("121.00")
    refute @parser.qualified?("v.0.9.0+task.121.00")
  end

  def test_format_raises_for_subtask_00
    error = assert_raises(ArgumentError) { @parser.format("v.0.9.0", "121", subtask: "00") }
    assert_match(/\.00 orchestrator references are no longer supported/, error.message)

    error = assert_raises(ArgumentError) { @parser.format("v.0.9.0", "121", subtask: 0) }
    assert_match(/\.00 orchestrator references are no longer supported/, error.message)
  end

  def test_parse_hierarchical_simple_subtask
    result = @parser.parse("121.01")

    assert_equal "current", result[:release]
    assert_equal "121", result[:number]
    assert_equal "01", result[:subtask]
    refute result[:qualified]
  end

  def test_parse_hierarchical_high_subtask
    result = @parser.parse("121.99")

    assert_equal "current", result[:release]
    assert_equal "121", result[:number]
    assert_equal "99", result[:subtask]
  end

  def test_parse_hierarchical_with_task_prefix
    result = @parser.parse("task.121.01")

    assert_equal "current", result[:release]
    assert_equal "121", result[:number]
    assert_equal "01", result[:subtask]
  end

  def test_parse_hierarchical_qualified_subtask
    result = @parser.parse("v.0.9.0+task.121.01")

    assert_equal "v.0.9.0", result[:release]
    assert_equal "121", result[:number]
    assert_equal "01", result[:subtask]
    assert result[:qualified]
    assert_equal "v.0.9.0+task.121.01", result[:original]
  end

  def test_parse_hierarchical_backlog_subtask
    result = @parser.parse("backlog+task.025.03")

    assert_equal "backlog", result[:release]
    assert_equal "025", result[:number]
    assert_equal "03", result[:subtask]
    assert result[:qualified]
  end

  def test_parse_hierarchical_without_task_prefix_qualified
    result = @parser.parse("v.0.9.0+121.05")

    assert_equal "v.0.9.0", result[:release]
    assert_equal "121", result[:number]
    assert_equal "05", result[:subtask]
    assert result[:qualified]
  end

  def test_parse_non_hierarchical_has_nil_subtask
    result = @parser.parse("121")

    assert_equal "current", result[:release]
    assert_equal "121", result[:number]
    assert_nil result[:subtask]
  end

  def test_parse_qualified_non_hierarchical_has_nil_subtask
    result = @parser.parse("v.0.9.0+task.018")

    assert_equal "v.0.9.0", result[:release]
    assert_equal "018", result[:number]
    assert_nil result[:subtask]
  end

  def test_parse_invalid_subtask_single_digit
    # Invalid: subtask must be exactly 2 digits
    assert_nil @parser.parse("121.1")
  end

  def test_parse_invalid_subtask_three_digits
    # Invalid: subtask must be exactly 2 digits
    assert_nil @parser.parse("121.001")
  end

  def test_parse_invalid_trailing_dot
    assert_nil @parser.parse("121.")
  end

  # ========== Helper Method Tests ==========

  def test_is_subtask_true_for_01
    parsed = @parser.parse("121.01")
    assert @parser.is_subtask?(parsed)
  end

  def test_is_subtask_true_for_99
    parsed = @parser.parse("121.99")
    assert @parser.is_subtask?(parsed)
  end

  def test_is_subtask_false_for_simple
    parsed = @parser.parse("121")
    refute @parser.is_subtask?(parsed)
  end

  def test_is_subtask_false_for_nil
    refute @parser.is_subtask?(nil)
  end

  def test_is_hierarchical_true_for_subtask
    parsed = @parser.parse("121.01")
    assert @parser.is_hierarchical?(parsed)
  end

  def test_is_hierarchical_false_for_simple
    parsed = @parser.parse("121")
    refute @parser.is_hierarchical?(parsed)
  end

  def test_parent_number_for_subtask
    parsed = @parser.parse("121.01")
    assert_equal "121", @parser.parent_number(parsed)
  end

  def test_parent_number_for_simple
    parsed = @parser.parse("121")
    assert_equal "121", @parser.parent_number(parsed)
  end

  # ========== Format Method Tests with Subtasks ==========

  def test_format_with_subtask_qualified
    assert_equal "v.0.9.0+task.121.01", @parser.format("v.0.9.0", "121", subtask: "01", qualified: true)
  end

  def test_format_with_subtask_integer
    assert_equal "v.0.9.0+task.121.05", @parser.format("v.0.9.0", "121", subtask: 5, qualified: true)
  end

  def test_format_with_subtask_simple
    assert_equal "121.01", @parser.format("current", "121", subtask: "01", qualified: false)
  end

  def test_format_backlog_with_subtask
    assert_equal "backlog+task.025.03", @parser.format("backlog", "25", subtask: "03", qualified: true)
  end

  def test_format_without_subtask_unchanged
    # Ensure backward compatibility - format without subtask works as before
    assert_equal "v.0.9.0+task.018", @parser.format("v.0.9.0", "18", qualified: true)
    assert_equal "018", @parser.format("current", 18, qualified: false)
  end

  # ========== Canonical ID Tests with Subtasks ==========

  def test_normalize_canonical_id_with_subtask
    resolver = MockReleaseResolver.new("v.0.9.0")

    # Simple subtask -> canonical
    canonical = @parser.normalize_to_canonical_id("121.01", resolver)
    assert_equal "v.0.9.0+task.121.01", canonical

    # Qualified subtask -> canonical
    canonical = @parser.normalize_to_canonical_id("v.0.9.0+task.122.03", resolver)
    assert_equal "v.0.9.0+task.122.03", canonical
  end

  def test_normalize_canonical_id_without_subtask_unchanged
    resolver = MockReleaseResolver.new("v.0.9.0")

    # Ensure backward compatibility
    canonical = @parser.normalize_to_canonical_id("018", resolver)
    assert_equal "v.0.9.0+task.018", canonical
  end
end

# Mock release resolver for testing normalize_to_canonical_id
class MockReleaseResolver
  def initialize(current_release)
    @current_release = current_release
  end

  def resolve_release(release)
    return @current_release if release == "current"
    release
  end
end