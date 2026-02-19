# frozen_string_literal: true

require_relative "../test_helper"

class StatusFormatterTest < AceOverseerTestCase
  def test_formats_single_row
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-streamline-task-lifecycle",
      assignment_status: {
        "assignment" => { "state" => "completed", "id" => "8op2ab" },
        "current_phase" => nil,
        "phase_summary" => { "total" => 5, "done" => 5, "failed" => 0, "in_progress" => 0, "pending" => 0 }
      },
      git_status: { "clean" => true, "pr_metadata" => { "number" => 206, "state" => "MERGED", "isDraft" => false } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "230"
    assert_includes row, "\u2713"       # ✓ for completed state
    assert_includes row, "5/5"
    assert_includes row, "#206 MRG"
    assert_includes row, "8op2ab"
  end

  def test_formats_dashboard
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignment_status: {
        "assignment" => { "state" => "running" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
      git_status: { "clean" => true }
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([context])

    assert_includes dashboard, "230"
    assert_includes dashboard, "2/5"
    assert_includes dashboard, "\u25B6"  # ► for running
  end

  def test_formats_empty_dashboard
    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([])

    assert_includes dashboard, "No active assignments."
  end

  def test_progress_with_failures
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "243",
      worktree_path: "/tmp/ace-task.243",
      branch: "243-feature",
      assignment_status: {
        "assignment" => { "state" => "failed" },
        "phase_summary" => { "total" => 5, "done" => 3, "failed" => 1, "in_progress" => 0, "pending" => 1 }
      },
      git_status: { "dirty_files" => 2 }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "3/5 (1 failed)"
    assert_includes row, "\u2717"   # ✗ for failed state or dirty git
  end

  def test_no_assignment
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "100",
      worktree_path: "/tmp/ace-task.100",
      branch: "100-feature",
      assignment_status: nil,
      git_status: { "clean" => true }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "-"   # none state icon
  end

  def test_pr_draft
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "265",
      worktree_path: "/tmp/ace-task.265",
      branch: "265-feature",
      assignment_status: {
        "assignment" => { "state" => "paused" },
        "phase_summary" => { "total" => 3, "done" => 0, "failed" => 0, "in_progress" => 0, "pending" => 3 }
      },
      git_status: { "clean" => true, "pr_metadata" => { "number" => 210, "state" => "OPEN", "isDraft" => true } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "#210 DFT"
  end

  def test_pr_open
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "235",
      worktree_path: "/tmp/ace-task.235",
      branch: "235-feature",
      assignment_status: {
        "assignment" => { "state" => "running" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
      git_status: { "clean" => true, "pr_metadata" => { "number" => 207, "state" => "OPEN", "isDraft" => false } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "#207 OPN"
  end

  def test_sort_order_pr_descending
    ctx_no_pr = Ace::Overseer::Models::WorkContext.new(
      task_id: "270",
      worktree_path: "/tmp/ace-task.270",
      branch: "270-feature",
      assignment_status: { "assignment" => { "state" => "paused" }, "phase_summary" => { "total" => 1, "done" => 0, "failed" => 0, "in_progress" => 0, "pending" => 1 } },
      git_status: { "clean" => true }
    )

    ctx_pr_low = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignment_status: { "assignment" => { "state" => "completed" }, "phase_summary" => { "total" => 5, "done" => 5, "failed" => 0, "in_progress" => 0, "pending" => 0 } },
      git_status: { "clean" => true, "pr_metadata" => { "number" => 200, "state" => "MERGED", "isDraft" => false } }
    )

    ctx_pr_high = Ace::Overseer::Models::WorkContext.new(
      task_id: "235",
      worktree_path: "/tmp/ace-task.235",
      branch: "235-feature",
      assignment_status: { "assignment" => { "state" => "running" }, "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 } },
      git_status: { "clean" => true, "pr_metadata" => { "number" => 207, "state" => "OPEN", "isDraft" => false } }
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([ctx_pr_low, ctx_no_pr, ctx_pr_high])

    lines = dashboard.split("\n")
    data_lines = lines[2..] # skip header and separator

    # No-PR row first, then PR 207, then PR 200
    assert_includes data_lines[0], "270"
    assert_includes data_lines[1], "235"
    assert_includes data_lines[2], "230"
  end

  def test_ansi_color_codes_present
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignment_status: {
        "assignment" => { "state" => "completed" },
        "phase_summary" => { "total" => 5, "done" => 5, "failed" => 0, "in_progress" => 0, "pending" => 0 }
      },
      git_status: { "clean" => true, "pr_metadata" => { "number" => 206, "state" => "MERGED", "isDraft" => false } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    # Should contain ANSI escape codes
    assert_match(/\e\[\d+m/, row)
    # Should contain reset codes
    assert_includes row, "\e[0m"
  end

  def test_stalled_state_icon
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "267",
      worktree_path: "/tmp/ace-task.267",
      branch: "267-feature",
      assignment_status: {
        "assignment" => { "state" => "stalled" },
        "phase_summary" => { "total" => 2, "done" => 0, "failed" => 0, "in_progress" => 1, "pending" => 1 }
      },
      git_status: { "clean" => true }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "\u25FC"  # ◼ for stalled
    assert_match(/\e\[33m/, row)   # yellow color
  end

  def test_git_dirty_with_count
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "265",
      worktree_path: "/tmp/ace-task.265",
      branch: "265-feature",
      assignment_status: {
        "assignment" => { "state" => "paused" },
        "phase_summary" => { "total" => 3, "done" => 0, "failed" => 0, "in_progress" => 0, "pending" => 3 }
      },
      git_status: { "dirty_files" => 4 }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "\u2717 4"  # ✗ 4
  end

  def test_git_unknown_state
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "100",
      worktree_path: "/tmp/ace-task.100",
      branch: "100-feature",
      assignment_status: nil,
      git_status: nil
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "?"
  end

  def test_assignment_id_column
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "235",
      worktree_path: "/tmp/ace-task.235",
      branch: "235-feature",
      assignment_status: {
        "assignment" => { "state" => "running", "id" => "8or5kx" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
      git_status: { "clean" => true, "pr_metadata" => { "number" => 207, "state" => "OPEN", "isDraft" => false } }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "8or5kx"
  end

  def test_assignment_count_displayed_when_greater_than_one
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "235",
      worktree_path: "/tmp/ace-task.235",
      branch: "235-feature",
      assignment_status: {
        "assignment" => { "state" => "running", "id" => "8or5kx" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
      git_status: { "clean" => true },
      assignment_count: 3
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "8or5kx (3)"
  end

  def test_assignment_count_hidden_when_one
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "235",
      worktree_path: "/tmp/ace-task.235",
      branch: "235-feature",
      assignment_status: {
        "assignment" => { "state" => "running", "id" => "8or5kx" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
      git_status: { "clean" => true },
      assignment_count: 1
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "8or5kx"
    refute_includes row, "(1)"
  end

  def test_main_location_shows_main_in_task_column
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "main",
      worktree_path: "/project",
      branch: "main",
      assignment_status: {
        "assignment" => { "state" => "completed", "id" => "xyz99" },
        "phase_summary" => { "total" => 3, "done" => 3, "failed" => 0, "in_progress" => 0, "pending" => 0 }
      },
      git_status: { "clean" => true },
      location_type: :main,
      assignment_count: 2
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    assert_includes row, "main"
    assert_includes row, "xyz99 (2)"
  end

  def test_main_branch_sorts_last
    main_ctx = Ace::Overseer::Models::WorkContext.new(
      task_id: "main",
      worktree_path: "/project",
      branch: "main",
      assignment_status: {
        "assignment" => { "state" => "completed", "id" => "xyz99" },
        "phase_summary" => { "total" => 3, "done" => 3, "failed" => 0, "in_progress" => 0, "pending" => 0 }
      },
      git_status: { "clean" => true },
      location_type: :main
    )

    worktree_ctx = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/ace-task.230",
      branch: "230-feature",
      assignment_status: {
        "assignment" => { "state" => "running" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
      git_status: { "clean" => true }
    )

    dashboard = Ace::Overseer::Atoms::StatusFormatter.format_dashboard([main_ctx, worktree_ctx])
    lines = dashboard.split("\n")
    data_lines = lines[2..] # skip header and separator

    assert_includes data_lines[0], "230"
    assert_includes data_lines[1], "main"
  end

  def test_assignment_id_missing
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "100",
      worktree_path: "/tmp/ace-task.100",
      branch: "100-feature",
      assignment_status: {
        "assignment" => { "state" => "running" },
        "phase_summary" => { "total" => 3, "done" => 1, "failed" => 0, "in_progress" => 1, "pending" => 1 }
      },
      git_status: { "clean" => true }
    )

    row = Ace::Overseer::Atoms::StatusFormatter.format_row(context)

    # Should show "-" for missing assignment ID
    assert_includes row, "-"
  end
end
