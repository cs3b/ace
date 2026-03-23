# frozen_string_literal: true

require_relative "../test_helper"

class TreeFormatterTest < AceAssignTestCase
  Formatter = Ace::Assign::Atoms::TreeFormatter

  def test_empty_list
    result = Formatter.format([])
    assert_equal "No assignments found.", result
  end

  def test_single_root_assignment
    infos = [make_info(id: "aaa111", name: "task-148", state: :running, progress: "1/3")]

    result = Formatter.format(infos)

    assert_includes result, "task-148"
    assert_includes result, "aaa111"
    assert_includes result, "running"
    assert_includes result, "1/3"
  end

  def test_multiple_roots_no_hierarchy
    infos = [
      make_info(id: "aaa111", name: "task-148", state: :running, progress: "1/3"),
      make_info(id: "bbb222", name: "task-149", state: :completed, progress: "3/3")
    ]

    result = Formatter.format(infos)

    assert_includes result, "task-148"
    assert_includes result, "task-149"
  end

  def test_parent_child_hierarchy
    infos = [
      make_info(id: "parent1", name: "main-task", state: :running, progress: "1/3"),
      make_info(id: "child1", name: "onboard", state: :completed, progress: "1/1", parent: "parent1"),
      make_info(id: "child2", name: "implement", state: :running, progress: "0/1", parent: "parent1")
    ]

    result = Formatter.format(infos)
    lines = result.split("\n")

    # Root should be first line
    assert_includes lines[0], "main-task"
    # Children should be indented
    assert_includes result, "onboard"
    assert_includes result, "implement"
    # Tree connectors should be present
    assert(result.include?("+--") || result.include?("\\--"), "Should have tree connectors")
  end

  def test_multi_level_hierarchy
    infos = [
      make_info(id: "root", name: "root-task", state: :running, progress: "0/5"),
      make_info(id: "child1", name: "work-on-task", state: :running, progress: "1/3", parent: "root"),
      make_info(id: "grand1", name: "onboard-sub", state: :completed, progress: "1/1", parent: "child1"),
      make_info(id: "grand2", name: "implement-sub", state: :running, progress: "0/1", parent: "child1")
    ]

    result = Formatter.format(infos)

    assert_includes result, "root-task"
    assert_includes result, "work-on-task"
    assert_includes result, "onboard-sub"
    assert_includes result, "implement-sub"
  end

  def test_orphans_treated_as_roots
    # Parent "missing" is not in the list
    infos = [
      make_info(id: "orphan1", name: "orphan-task", state: :paused, progress: "0/1", parent: "missing"),
      make_info(id: "root1", name: "root-task", state: :running, progress: "1/2")
    ]

    result = Formatter.format(infos)
    lines = result.split("\n")

    # Both should appear as roots (no indentation beyond root level)
    root_lines = lines.select { |l| !l.start_with?(" ", "|", "+", "\\") }
    assert root_lines.size >= 2
  end

  def test_last_child_uses_backslash_connector
    infos = [
      make_info(id: "parent1", name: "main", state: :running, progress: "1/2"),
      make_info(id: "child1", name: "only-child", state: :completed, progress: "1/1", parent: "parent1")
    ]

    result = Formatter.format(infos)

    # Last (only) child should use backslash
    assert_includes result, "\\-- only-child"
  end

  def test_child_before_parent_ordering
    # Child appears before parent in the input list — should still attach correctly
    infos = [
      make_info(id: "child1", name: "onboard", state: :completed, progress: "1/1", parent: "parent1"),
      make_info(id: "parent1", name: "main-task", state: :running, progress: "1/3")
    ]

    result = Formatter.format(infos)
    lines = result.split("\n")

    # Parent should be root, child should be nested under it
    assert_includes lines[0], "main-task"
    assert(result.include?("\\-- onboard") || result.include?("+-- onboard"),
      "Child should appear as nested under parent, got:\n#{result}")
    # Child should NOT appear as a root
    root_lines = lines.select { |l| !l.start_with?(" ", "|", "+", "\\") }
    assert_equal 1, root_lines.size, "Only one root expected, got:\n#{result}"
  end

  def test_multiple_children_connectors
    infos = [
      make_info(id: "parent1", name: "main", state: :running, progress: "1/3"),
      make_info(id: "child1", name: "first", state: :completed, progress: "1/1", parent: "parent1"),
      make_info(id: "child2", name: "second", state: :running, progress: "0/1", parent: "parent1"),
      make_info(id: "child3", name: "third", state: :pending, progress: "0/1", parent: "parent1")
    ]

    result = Formatter.format(infos)

    # First two children use +, last uses \
    assert_includes result, "+-- first"
    assert_includes result, "+-- second"
    assert_includes result, "\\-- third"
  end

  private

  # Helper to create mock AssignmentInfo objects
  def make_info(id:, name:, state:, progress:, parent: nil)
    assignment = StubAssignment.new(id: id, name: name, parent: parent)
    StubAssignmentInfo.new(assignment: assignment, state: state, progress: progress)
  end

  # Minimal stub for Assignment
  StubAssignment = Struct.new(:id, :name, :parent, keyword_init: true)

  # Minimal stub for AssignmentInfo
  class StubAssignmentInfo
    attr_reader :assignment, :state, :progress

    def initialize(assignment:, state:, progress:)
      @assignment = assignment
      @state = state
      @progress = progress
    end

    def id = assignment.id
    def name = assignment.name
    def parent = assignment.parent
    def updated_at = Time.now
    def created_at = Time.now
  end
end
