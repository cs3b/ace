# frozen_string_literal: true

require_relative "../test_helper"

class WorkContextTest < AceOverseerTestCase
  def test_initializes_with_expected_attributes
    assignments = [{"assignment" => {"state" => "running", "id" => "abc123", "name" => "work-on-task-230"}}]
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/task.230",
      branch: "230-feature",
      assignments: assignments,
      git_status: {"clean" => true},
      tmux_window: "t230"
    )

    assert_equal "230", context.task_id
    assert_equal "/tmp/task.230", context.worktree_path
    assert_equal "230-feature", context.branch
    assert_equal assignments, context.assignments
    assert_equal true, context.git_status["clean"]
    assert_equal "t230", context.tmux_window
  end

  def test_defaults_for_assignments_and_location_type
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/task.230",
      branch: "230-feature"
    )

    assert_equal [], context.assignments
    assert_equal 0, context.assignment_count
    assert_equal :worktree, context.location_type
  end

  def test_assignment_status_returns_first_assignment
    assignments = [
      {"assignment" => {"state" => "running", "id" => "a1"}},
      {"assignment" => {"state" => "completed", "id" => "a2"}}
    ]
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/task.230",
      branch: "230-feature",
      assignments: assignments
    )

    assert_equal "a1", context.assignment_status.dig("assignment", "id")
  end

  def test_assignment_status_returns_nil_when_no_assignments
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/task.230",
      branch: "230-feature"
    )

    assert_nil context.assignment_status
  end

  def test_assignment_count_derived_from_assignments_size
    assignments = [
      {"assignment" => {"id" => "a1"}},
      {"assignment" => {"id" => "a2"}},
      {"assignment" => {"id" => "a3"}}
    ]
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/task.230",
      branch: "230-feature",
      assignments: assignments,
      location_type: :main
    )

    assert_equal 3, context.assignment_count
    assert_equal :main, context.location_type
  end

  def test_to_h_includes_assignments_and_location_type
    assignments = [{"assignment" => {"id" => "a1"}}]
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "231",
      worktree_path: "/tmp/task.231",
      branch: "231-feature",
      assignments: assignments,
      location_type: :main
    )

    h = context.to_h
    assert_equal assignments, h[:assignments]
    assert_equal :main, h[:location_type]
  end

  def test_to_h_returns_expected_payload
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "231",
      worktree_path: "/tmp/task.231",
      branch: "231-feature"
    )

    assert_equal "231", context.to_h[:task_id]
    assert_equal "/tmp/task.231", context.to_h[:worktree_path]
    assert_equal "231-feature", context.to_h[:branch]
  end
end
