# frozen_string_literal: true

require_relative "../../test_helper"
require "stringio"

class WorktreeTableFormatterTest < Minitest::Test
  WorktreeInfo = Ace::Git::Worktree::Models::WorktreeInfo
  Formatter = Ace::Git::Worktree::Molecules::WorktreeTableFormatter

  ENV_HOME = {"HOME" => "/Users/mc"}

  def worktree(path:, task_id: nil, task_ids: nil, branch: "main", age_hours: 3.0,
    subject: "spec(8xf.t.ei9-wave-3): define", staged: 0, unstaged: 0, untracked: 0,
    pr: nil, probe_failed: false)
    task_ids ||= task_id ? [task_id] : []
    uncommitted = if (staged + unstaged + untracked).positive?
      {staged: staged, unstaged: unstaged, untracked: untracked, total: staged + unstaged + untracked}
    end
    last_commit = probe_failed ? nil : {
      sha: "abc1234", age_hours: age_hours,
      committed_at: "2026-10-17T11:20:00Z", subject: subject
    }
    WorktreeInfo.new(
      path: path, branch: branch, commit: "abc1234", task_id: task_id,
      task_ids: task_ids, last_commit: last_commit, uncommitted: uncommitted, pr: pr,
      active_within_window: true, probe_error: probe_failed
    )
  end

  def render(worktrees, columns:, full: false)
    Formatter.new(width: Integer(columns, 10), full: full, env: ENV_HOME).render(worktrees)
  end

  def test_headers_and_columns_at_default_width
    lines = render([worktree(path: "/Users/mc/Ps/ace")], columns: "120")

    assert_equal "Task  Branch                       Age  Commit                    Changes  PR           Path",
      lines.first
    assert_equal 3, lines.length
    assert lines[1].match?(/\A-+\z/)
  end

  def test_dynamic_task_width_shrinks_path_at_120
    path = "/Users/mc/Ps/ace/.ace-wt/codex-r3-bounded-convergence"
    lines = render([worktree(path: path, task_id: "k9y", task_ids: %w[k9y xza])], columns: "120")
    row = lines[2]

    assert_equal 120, lines[1].length
    assert_operator row.length, :<=, 120
    assert_includes row, "k9y+1"
    assert_match(/\A…/, row.split(/\s{2,}/).last)
  end

  def test_columns_shrink_to_fit_80
    wt = worktree(path: "/Users/mc/Ps/ace/.ace-wt/ei9-campaign-composition", branch: "codex/ei9-campaign-composition-join")
    lines = render([wt], columns: "80")

    lines.each { |line| assert_operator line.length, :<=, 80, line.inspect }
    assert_includes lines.first, "Path"
    assert_includes lines.first, "Commit"
  end

  def test_path_column_dropped_at_60
    wt = worktree(path: "/Users/mc/Ps/ace/.ace-wt/ei9", branch: "codex/ei9-campaign")
    lines = render([wt], columns: "60")

    lines.each { |line| assert_operator line.length, :<=, 60, line.inspect }
    refute_includes lines.first, "Path"
    assert_includes lines.first, "Task"
  end

  def test_minimum_layout_is_71_columns
    formatter = Formatter.new(width: 0, env: ENV_HOME)
    wt = worktree(path: "/x")
    # width 0 forces every column down to its minimum; Path is dropped only
    # when the 71-column minimum layout still overflows.
    lines = formatter.render([wt])
    refute_includes lines.first, "Path"
  end

  def test_right_aligned_age_and_changes
    wt = worktree(path: "/x", age_hours: 8.0 / 60, staged: 2, unstaged: 1)
    row = render([wt], columns: "120").last

    assert_match(/\s{2}8m\s{2}/, row)
    assert_match(/\s{2}3\s{2}/, row)
  end

  def test_branch_middle_elided
    branch = "codex/ei9-campaign-composition-join"
    row = render([worktree(path: "/x", branch: branch)], columns: "120").last

    assert_includes row, "codex/ei9-ca…osition-join"
  end

  def test_detached_branch_label
    row = render([worktree(path: "/x", branch: nil)], columns: "120").last

    assert_includes row, "detached"
  end

  def test_commit_subject_right_truncated
    subject = "feat(ace-assign): complete the campaign composition join implementation"
    row = render([worktree(path: "/x", subject: subject)], columns: "120").last

    assert_includes row, subject[0, 23] + "…"
    refute_includes row, subject
  end

  def test_probe_failure_renders_question_marks
    row = render([worktree(path: "/x", probe_failed: true)], columns: "120").last

    assert_equal 3, row.scan("?").length
  end

  def test_clean_tree_and_no_commit_cells
    wt = WorktreeInfo.new(path: "/x", branch: "main", commit: "abc")
    row = render([wt], columns: "120").last

    assert_includes row, "never"
    assert_includes row, "-"
  end

  def test_pr_cells
    row = render([worktree(path: "/x", pr: {number: 142, state: "merged", draft: false})], columns: "120").last

    assert_includes row, "#142 merged"
  end

  def test_path_shortens_home_in_compact_mode
    row = render([worktree(path: "/Users/mc/Ps/ace")], columns: "120").last

    assert_includes row, "~/Ps/ace"
  end

  def test_full_mode_prints_absolute_paths_untruncated_and_may_exceed_width
    long_path = "/Users/mc/Ps/ace/.ace-wt/ei9-campaign-composition-join-extremely-long-worktree-name"
    lines = render([worktree(path: long_path)], columns: "40", full: true)
    row = lines.last

    assert_includes row, File.expand_path(long_path)
    assert_operator row.length, :>, 40
  end

  def test_lines_are_right_trimmed
    render([worktree(path: "/x")], columns: "120").each do |line|
      assert_equal line.rstrip, line
    end
  end

  def test_changes_four_digit_count
    row = render([worktree(path: "/x", staged: 1234)], columns: "120").last

    assert_includes row, "1234"
  end

  def test_detected_width_uses_columns
    assert_equal 80, Formatter.detected_width(env: {"COLUMNS" => "80"}, stdout: StringIO.new)
  end

  def test_detected_width_ignores_small_columns
    refute_equal 30, Formatter.detected_width(env: {"COLUMNS" => "30"}, stdout: StringIO.new)
    assert_equal 120, Formatter.detected_width(env: {"COLUMNS" => "30"}, stdout: StringIO.new)
  end

  def test_detected_width_defaults_to_120
    assert_equal 120, Formatter.detected_width(env: {}, stdout: StringIO.new)
  end
end
