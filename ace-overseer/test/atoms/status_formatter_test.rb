# frozen_string_literal: true

require_relative "../test_helper"

class StatusFormatterTest < AceOverseerTestCase
  def make_assignment(id:, state:, name: "work-on-task", total: 5, done: 2, failed: 0, in_progress: 1, pending: 2, current_step: nil)
    h = {
      "assignment" => { "state" => state, "id" => id, "name" => name },
      "step_summary" => { "total" => total, "done" => done, "failed" => failed, "in_progress" => in_progress, "pending" => pending }
    }
    h["current_step"] = current_step if current_step
    h
  end

  def test_formats_location_row_with_pr_and_git
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8op2ab", state: "completed", total: 5, done: 5, failed: 0, in_progress: 0, pending: 0)],
      git_status: { "clean" => true, "pr_metadata" => { "number" => 206, "state" => "MERGED", "isDraft" => false } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_location_row(context)

    assert_includes row, "ace-task.230"
    assert_includes row, "#206 MRG"
    assert_includes row, "\u2713"  # ✓ for clean git
  end

  def test_formats_assignment_sub_row
    assignment = make_assignment(id: "8op2ab", state: "completed", name: "work-on-task-230", total: 5, done: 5, failed: 0, in_progress: 0, pending: 0)

    row = Ace::Overseer::Atoms::StatusFormatter.format_assignment_row(assignment)

    assert row.start_with?("  "), "Assignment row should be indented"
    assert_includes row, "8op2ab"
    assert_includes row, "work-on-task-230"
    assert_includes row, "\u2713"   # ✓ for completed
    assert_includes row, "5/5"
  end

  def test_formats_hierarchical_dashboard
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignments: [
        make_assignment(id: "8or5kx", state: "running"),
        make_assignment(id: "8or5ky", state: "completed", total: 3, done: 3, failed: 0, in_progress: 0, pending: 0)
      ],
      git_status: { "clean" => true }
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([context])
    lines = dashboard.split("\n")

    # First two lines are header + separator
    assert_includes lines[0], "ID"
    assert_includes lines[0], "Name"
    assert_includes lines[0], "Progress"
    assert_match(/\u2500+/, lines[1])
    # Location header follows
    assert_includes lines[2], "ace-task.230"
    # Next lines are assignment sub-rows
    assert_includes lines[3], "8or5kx"
    assert_includes lines[3], "work-on-task"
    assert_includes lines[4], "8or5ky"
  end

  def test_formats_empty_dashboard
    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([])

    assert_includes dashboard, "No active assignments."
  end

  def test_progress_with_failures
    assignment = make_assignment(id: "8fail1", state: "failed", total: 5, done: 3, failed: 1, in_progress: 0, pending: 1)

    row = Ace::Overseer::Atoms::StatusFormatter.format_assignment_row(assignment)

    assert_includes row, "3/5 (1 failed)"
    assert_includes row, "\u2717"   # ✗ for failed state
  end

  def test_no_assignments_shows_location_only
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "100",
      worktree_path: "/tmp/ace-task.100",
      branch: "100-feature",
      assignments: [],
      git_status: { "clean" => true }
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([context])
    lines = dashboard.split("\n")

    assert_equal 3, lines.size  # header + separator + location
    assert_includes lines[2], "ace-task.100"
  end

  def test_pr_draft
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "265",
      worktree_path: "/tmp/ace-task.265",
      branch: "265-feature",
      assignments: [make_assignment(id: "8abc12", state: "paused", total: 3, done: 0, failed: 0, in_progress: 0, pending: 3)],
      git_status: { "clean" => true, "pr_metadata" => { "number" => 210, "state" => "OPEN", "isDraft" => true } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_location_row(context)

    assert_includes row, "#210 DFT"
  end

  def test_pr_open
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "235",
      worktree_path: "/tmp/ace-task.235",
      branch: "235-feature",
      assignments: [make_assignment(id: "8or5kx", state: "running")],
      git_status: { "clean" => true, "pr_metadata" => { "number" => 207, "state" => "OPEN", "isDraft" => false } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_location_row(context)

    assert_includes row, "#207 OPN"
  end

  def test_sort_order_pr_descending
    ctx_no_pr = Ace::Overseer::Models::WorkContext.new(
      task_id: "270",
      worktree_path: "/tmp/ace-task.270",
      branch: "270-feature",
      assignments: [make_assignment(id: "a1", state: "paused", total: 1, done: 0, failed: 0, in_progress: 0, pending: 1)],
      git_status: { "clean" => true }
    )

    ctx_pr_low = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "a2", state: "completed", total: 5, done: 5, failed: 0, in_progress: 0, pending: 0)],
      git_status: { "clean" => true, "pr_metadata" => { "number" => 200, "state" => "MERGED", "isDraft" => false } }
    )

    ctx_pr_high = Ace::Overseer::Models::WorkContext.new(
      task_id: "235",
      worktree_path: "/tmp/ace-task.235",
      branch: "235-feature",
      assignments: [make_assignment(id: "a3", state: "running")],
      git_status: { "clean" => true, "pr_metadata" => { "number" => 207, "state" => "OPEN", "isDraft" => false } }
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([ctx_pr_low, ctx_no_pr, ctx_pr_high])

    lines = dashboard.split("\n")
    # Skip header, separator, and blank lines; select only location rows
    location_lines = lines.reject { |l| l.start_with?("  ") || l.strip.empty? || l.match?(/\A\u2500+\z/) }

    # No-PR row first (by task_id desc), then PR 207, then PR 200
    assert_includes location_lines[0], "ace-task.270"
    assert_includes location_lines[1], "ace-task.235"
    assert_includes location_lines[2], "ace-task.230"
  end

  def test_ansi_color_codes_present
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8op2ab", state: "completed", total: 5, done: 5, failed: 0, in_progress: 0, pending: 0)],
      git_status: { "clean" => true, "pr_metadata" => { "number" => 206, "state" => "MERGED", "isDraft" => false } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_location_row(context)

    assert_match(/\e\[\d+m/, row)
    assert_includes row, "\e[0m"
  end

  def test_stalled_state_icon
    assignment = make_assignment(id: "8stall", state: "stalled", total: 2, done: 0, failed: 0, in_progress: 1, pending: 1)

    row = Ace::Overseer::Atoms::StatusFormatter.format_assignment_row(assignment)

    assert_includes row, "\u25FC"  # ◼ for stalled
    assert_match(/\e\[33m/, row)   # yellow color
  end

  def test_git_dirty_with_count
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "265",
      worktree_path: "/tmp/ace-task.265",
      branch: "265-feature",
      assignments: [make_assignment(id: "8abc12", state: "paused", total: 3, done: 0, failed: 0, in_progress: 0, pending: 3)],
      git_status: { "dirty_files" => 4 }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_location_row(context)

    assert_includes row, "\u2717 4"  # ✗ 4
  end

  def test_git_unknown_state
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "100",
      worktree_path: "/tmp/ace-task.100",
      branch: "100-feature",
      assignments: [],
      git_status: nil
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_location_row(context)

    assert_includes row, "?"
  end

  def test_main_location_shows_main_label
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "main",
      worktree_path: "/project",
      branch: "main",
      assignments: [
        make_assignment(id: "xyz99", state: "completed", total: 3, done: 3, failed: 0, in_progress: 0, pending: 0),
        make_assignment(id: "abc12", state: "running", total: 5, done: 1, failed: 0, in_progress: 1, pending: 3)
      ],
      git_status: { "clean" => true },
      location_type: :main
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([context])
    lines = dashboard.split("\n")

    assert_includes lines[2], "main"
    assert_includes lines[3], "xyz99"
    assert_includes lines[4], "abc12"
  end

  def test_main_branch_sorts_last
    main_ctx = Ace::Overseer::Models::WorkContext.new(
      task_id: "main",
      worktree_path: "/project",
      branch: "main",
      assignments: [make_assignment(id: "xyz99", state: "completed", total: 3, done: 3, failed: 0, in_progress: 0, pending: 0)],
      git_status: { "clean" => true },
      location_type: :main
    )

    worktree_ctx = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8or5kx", state: "running")],
      git_status: { "clean" => true }
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([main_ctx, worktree_ctx])
    lines = dashboard.split("\n")
    location_lines = lines.reject { |l| l.start_with?("  ") || l.strip.empty? || l.match?(/\A\u2500+\z/) }

    assert_includes location_lines[0], "ace-task.230"
    assert_includes location_lines[1], "main"
  end

  def test_blank_line_between_groups
    ctx1 = Ace::Overseer::Models::WorkContext.new(
      task_id: "271",
      worktree_path: "/tmp/ace-task.271",
      branch: "271-feature",
      assignments: [make_assignment(id: "a1", state: "running")],
      git_status: { "clean" => true }
    )
    ctx2 = Ace::Overseer::Models::WorkContext.new(
      task_id: "266",
      worktree_path: "/tmp/ace-task.266",
      branch: "266-feature",
      assignments: [make_assignment(id: "a2", state: "completed", total: 4, done: 4, failed: 0, in_progress: 0, pending: 0)],
      git_status: { "clean" => true }
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([ctx1, ctx2])
    lines = dashboard.split("\n")

    # header(0), separator(1), group1-location(2), group1-assignment(3),
    # blank(4), group2-location(5), group2-assignment(6)
    assert_equal "", lines[4], "Expected blank line between groups"
  end

  def test_progress_bar_in_assignment_row
    assignment = make_assignment(id: "8op2ab", state: "completed", total: 10, done: 10, failed: 0, in_progress: 0, pending: 0)

    row = Ace::Overseer::Atoms::StatusFormatter.format_assignment_row(assignment)

    assert_includes row, "\u2588"  # filled bar segment
    assert_includes row, "10/10"
  end

  def test_progress_bar_partial_fill
    assignment = make_assignment(id: "8half1", state: "running", total: 10, done: 5, failed: 0, in_progress: 1, pending: 4)

    row = Ace::Overseer::Atoms::StatusFormatter.format_assignment_row(assignment)

    assert_includes row, "\u2588"  # filled segments
    assert_includes row, "\u2500"  # empty segments
    assert_includes row, "5/10"
  end

  def test_current_step_shown_when_present
    assignment = make_assignment(id: "8run1", state: "running", total: 5, done: 2, failed: 0, in_progress: 1, pending: 2, current_step: "implement")

    row = Ace::Overseer::Atoms::StatusFormatter.format_assignment_row(assignment)

    assert_includes row, "implement"
    assert_includes row, "2/5"
  end

  def test_current_step_absent_when_nil
    assignment = make_assignment(id: "8done1", state: "completed", total: 5, done: 5, failed: 0, in_progress: 0, pending: 0)

    row = Ace::Overseer::Atoms::StatusFormatter.format_assignment_row(assignment)

    refute_includes row, "implement"
    assert_includes row, "5/5"
  end

  def test_format_watch_footer_with_minutes_and_seconds
    footer = Ace::Overseer::Atoms::StatusFormatter.format_watch_footer(222)

    assert_includes footer, "Updated:"
    assert_includes footer, "3m 42s"
    assert_includes footer, "full refresh in"
    assert_match(/\e\[2m/, footer) # dim color
  end

  def test_format_watch_footer_seconds_only
    footer = Ace::Overseer::Atoms::StatusFormatter.format_watch_footer(45)

    assert_includes footer, "45s"
    refute_includes footer, "m "
  end

  def test_format_watch_footer_zero_seconds
    footer = Ace::Overseer::Atoms::StatusFormatter.format_watch_footer(0)

    assert_includes footer, "0s"
  end

  def test_assignment_row_with_missing_id
    assignment = {
      "assignment" => { "state" => "running", "name" => "work-on-task" },
      "step_summary" => { "total" => 3, "done" => 1, "failed" => 0, "in_progress" => 1, "pending" => 1 }
    }

    row = Ace::Overseer::Atoms::StatusFormatter.format_assignment_row(assignment)

    assert_includes row, "-"
  end
end
