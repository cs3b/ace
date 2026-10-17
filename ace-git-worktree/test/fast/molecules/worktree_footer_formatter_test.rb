# frozen_string_literal: true

require_relative "../../test_helper"

class WorktreeFooterFormatterTest < Minitest::Test
  Formatter = Ace::Git::Worktree::Molecules::WorktreeFooterFormatter

  def test_header_echoes_window_and_counts
    formatter = Formatter.new(window_label: "18h")
    assert_equal "Active worktrees (last 18h) -- 3 of 88:", formatter.header(active_count: 3, total_count: 88)
  end

  def test_header_echoes_custom_window
    formatter = Formatter.new(window_label: "3d")
    assert_equal "Active worktrees (last 3d) -- 0 of 5:", formatter.header(active_count: 0, total_count: 5)
  end

  def test_no_active_message
    assert_equal "No active worktrees in the last 18h.", Formatter.new(window_label: "18h").no_active_message
  end

  def test_compact_footer_lines
    formatter = Formatter.new(window_label: "18h")
    lines = formatter.lines(inactive: 85, task_associated: 14, usable: 71, recent_branches: 4)

    assert_equal "Inactive: 85  (use --full to list all)", lines.first
    assert_equal "Task-associated: 14    Usable: 71    Recent branches without worktrees: 4", lines.last
  end

  def test_full_footer_omits_full_hint
    formatter = Formatter.new(window_label: "18h", full: true)
    lines = formatter.lines(inactive: 0, task_associated: 14, usable: 71, recent_branches: 4)

    assert_equal "Inactive: 0", lines.first
  end
end
