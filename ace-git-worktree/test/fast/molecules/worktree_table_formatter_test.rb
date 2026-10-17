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

  # header, separator, then two lines (columns + path) per worktree
  def row_line(lines)
    lines[2]
  end

  def path_line(lines)
    lines[3]
  end

  def test_headers_and_columns_at_default_width
    lines = render([worktree(path: "/Users/mc/Ps/ace")], columns: "120")

    assert_equal "Task  Branch                       Age  Commit                    Changes  PR",
      lines.first
    assert_equal 5, lines.length
    assert_equal "", lines[4]
    assert lines[1].match?(/\A-+\z/)
  end

  def test_full_path_on_its_own_line_below_the_row
    path = "/Users/mc/Ps/ace/.ace-wt/ei9-campaign-composition"
    lines = render([worktree(path: path)], columns: "120")

    # default layout: task(4) + gutter + branch(25) + gutter + age(5) + gutter
    # = 40 spaces -> the path aligns under the Commit column
    expected = "#{' ' * 40}~/Ps/ace/.ace-wt/ei9-campaign-composition"
    assert_equal expected, path_line(lines)
    refute_includes row_line(lines), "ace-wt"
  end

  def test_dynamic_task_width_fits_120
    path = "/Users/mc/Ps/ace/.ace-wt/codex-r3-bounded-convergence"
    lines = render([worktree(path: path, task_id: "k9y", task_ids: %w[k9y xza])], columns: "120")
    row = row_line(lines)

    assert_operator lines[1].length, :<=, 120
    assert_operator row.length, :<=, 120
    assert_includes row, "k9y+1"
  end

  def test_columns_shrink_to_fit_80
    wt = worktree(path: "/Users/mc/Ps/ace/.ace-wt/ei9-campaign-composition", branch: "codex/ei9-campaign-composition-join")
    lines = render([wt], columns: "80")

    lines[0, 3].each { |line| assert_operator line.length, :<=, 80, line.inspect }
    assert_includes lines.first, "Commit"
  end

  def test_columns_shrink_and_commit_drops_at_60
    wt = worktree(path: "/Users/mc/Ps/ace/.ace-wt/ei9", branch: "codex/ei9-campaign")
    lines = render([wt], columns: "60")

    lines[0, 3].each { |line| assert_operator line.length, :<=, 60, line.inspect }
    assert_includes lines.first, "Task"
    assert_includes lines.first, "Branch"
  end

  def test_minimum_layout_drops_commit_only
    formatter = Formatter.new(width: 0, env: ENV_HOME)
    wt = worktree(path: "/x")
    # width 0 forces every column down to its minimum, then drops Commit.
    lines = formatter.render([wt])

    refute_includes lines.first, "Commit"
    assert_includes lines.first, "Task"
    assert_includes lines.first, "PR"
  end

  def test_right_aligned_age_and_changes
    wt = worktree(path: "/x", age_hours: 8.0 / 60, staged: 2, unstaged: 1)
    row = row_line(render([wt], columns: "120"))

    assert_match(/\s{2}8m\s{2}/, row)
    assert_match(/\s{2}3\s{2}/, row)
  end

  def test_branch_middle_elided
    branch = "codex/ei9-campaign-composition-join"
    row = row_line(render([worktree(path: "/x", branch: branch)], columns: "120"))

    assert_includes row, "codex/ei9-ca…osition-join"
  end

  def test_detached_branch_label
    row = row_line(render([worktree(path: "/x", branch: nil)], columns: "120"))

    assert_includes row, "detached"
  end

  def test_commit_subject_right_truncated
    subject = "feat(ace-assign): complete the campaign composition join implementation"
    row = row_line(render([worktree(path: "/x", subject: subject)], columns: "120"))

    assert_includes row, subject[0, 23] + "…"
    refute_includes row, subject
  end

  def test_probe_failure_renders_question_marks
    row = row_line(render([worktree(path: "/x", probe_failed: true)], columns: "120"))

    assert_equal 3, row.scan("?").length
  end

  def test_clean_tree_and_no_commit_cells
    wt = WorktreeInfo.new(path: "/x", branch: "main", commit: "abc")
    row = row_line(render([wt], columns: "120"))

    assert_includes row, "never"
    assert_includes row, "-"
  end

  def test_pr_cells
    row = row_line(render([worktree(path: "/x", pr: {number: 142, state: "merged", draft: false})], columns: "120"))

    assert_includes row, "#142 merged"
  end

  def test_path_shortens_home_in_compact_mode
    line = path_line(render([worktree(path: "/Users/mc/Ps/ace")], columns: "120"))

    assert_includes line, "~/Ps/ace"
  end

  def test_full_mode_prints_absolute_paths_untruncated_and_may_exceed_width
    long_path = "/Users/mc/Ps/ace/.ace-wt/ei9-campaign-composition-join-extremely-long-worktree-name"
    lines = render([worktree(path: long_path)], columns: "40", full: true)
    line = path_line(lines)

    assert_includes line, File.expand_path(long_path)
    assert_operator line.length, :>, 40
  end

  def test_path_lines_are_never_truncated
    deep = "/Users/mc/Ps/ace/.ace-wt/#{'x' * 200}"
    line = path_line(render([worktree(path: deep)], columns: "80"))

    assert_includes line, "x" * 200
  end

  def test_lines_are_right_trimmed
    render([worktree(path: "/x")], columns: "120").each do |line|
      assert_equal line.rstrip, line
    end
  end

  def test_changes_four_digit_count
    row = row_line(render([worktree(path: "/x", staged: 1234)], columns: "120"))

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
