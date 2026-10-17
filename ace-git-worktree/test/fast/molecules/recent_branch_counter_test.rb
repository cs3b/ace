# frozen_string_literal: true

require_relative "../../test_helper"

class RecentBranchCounterTest < Minitest::Test
  WorktreeInfo = Ace::Git::Worktree::Models::WorktreeInfo
  Counter = Ace::Git::Worktree::Molecules::RecentBranchCounter

  NOW = Time.utc(2026, 10, 17, 12, 0, 0)
  BRANCHES = [
    WorktreeInfo.new(path: "/repo", branch: "main", commit: "a"),
    WorktreeInfo.new(path: "/repo/wt/a", branch: "codex/a", commit: "b")
  ].freeze

  def listing(rows)
    rows.map { |branch, epoch| "#{branch}\x00#{epoch}\n" }.join
  end

  def count(rows, window_hours: 18, worktrees: BRANCHES)
    Counter.new(worktrees: worktrees, window_hours: window_hours, now: NOW,
      runner: -> { listing(rows) }).count
  end

  def test_counts_recent_branches_without_worktrees
    recent = (NOW - 3600).to_i

    assert_equal 1, count([["main", (NOW - 60).to_i], ["codex/a", (NOW - 60).to_i], ["feature/fresh", recent]])
  end

  def test_stale_branches_are_not_counted
    stale = (NOW - (19 * 3600)).to_i

    assert_equal 0, count([["feature/stale", stale]])
  end

  def test_checked_out_branches_are_excluded
    recent = (NOW - 60).to_i

    assert_equal 0, count([["main", recent], ["codex/a", recent]])
  end

  def test_primary_branch_is_excluded
    recent = (NOW - 60).to_i

    assert_equal 0, count([["main", recent]])
  end

  def test_window_parameter_is_honored
    two_days_ago = (NOW - (36 * 3600)).to_i

    assert_equal 1, count([["feature/two-days", two_days_ago]], window_hours: 48)
    assert_equal 0, count([["feature/two-days", two_days_ago]], window_hours: 18)
  end

  def test_runner_failure_counts_zero
    counter = Counter.new(worktrees: BRANCHES, window_hours: 18, now: NOW,
      runner: -> { raise "git failed" })

    assert_equal 0, counter.count
  end

  def test_malformed_rows_are_ignored
    output = "no-separator\nfeature/x\x00not-an-int\n"
    counter = Counter.new(worktrees: BRANCHES, window_hours: 18, now: NOW, runner: -> { output })

    assert_equal 0, counter.count
  end
end
