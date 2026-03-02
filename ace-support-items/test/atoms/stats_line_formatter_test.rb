# frozen_string_literal: true

require "test_helper"

class StatsLineFormatterTest < AceSupportItemsTestCase
  def test_format_basic_stats_line
    stats = { total: 9, by_field: { "pending" => 3, "in-progress" => 1, "done" => 5 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending in-progress done],
      status_icons: { "pending" => "○", "in-progress" => "▶", "done" => "✓" }
    )

    assert_equal "Tasks: ○ 3 | ▶ 1 | ✓ 5 • 9 total", line
  end

  def test_format_omits_zero_count_statuses
    stats = { total: 3, by_field: { "pending" => 3 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending in-progress done blocked cancelled],
      status_icons: { "pending" => "○", "in-progress" => "▶", "done" => "✓", "blocked" => "✗", "cancelled" => "—" }
    )

    assert_equal "Tasks: ○ 3 • 3 total", line
  end

  def test_format_with_emoji_icons
    stats = { total: 6, by_field: { "pending" => 3, "in-progress" => 1, "done" => 2 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Ideas",
      stats: stats,
      status_order: %w[pending in-progress done obsolete],
      status_icons: { "pending" => "⚪", "in-progress" => "🟡", "done" => "🟢", "obsolete" => "⚫" }
    )

    assert_equal "Ideas: ⚪ 3 | 🟡 1 | 🟢 2 • 6 total", line
  end

  def test_format_retro_style
    stats = { total: 7, by_field: { "active" => 2, "done" => 5 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Retros",
      stats: stats,
      status_order: %w[active done],
      status_icons: { "active" => "🟡", "done" => "🟢" }
    )

    assert_equal "Retros: 🟡 2 | 🟢 5 • 7 total", line
  end

  def test_format_single_status
    stats = { total: 5, by_field: { "done" => 5 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending done],
      status_icons: { "pending" => "○", "done" => "✓" }
    )

    assert_equal "Tasks: ✓ 5 • 5 total", line
  end

  def test_format_includes_unknown_statuses
    stats = { total: 5, by_field: { "pending" => 2, "draft" => 3 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending done],
      status_icons: { "pending" => "○", "done" => "✓" }
    )

    assert_equal "Tasks: ○ 2 | draft 3 • 5 total", line
  end

  def test_format_unknown_status_uses_icon_if_available
    stats = { total: 4, by_field: { "pending" => 1, "draft" => 3 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending done],
      status_icons: { "pending" => "○", "done" => "✓", "draft" => "◇" }
    )

    assert_equal "Tasks: ○ 1 | ◇ 3 • 4 total", line
  end

  def test_format_unknown_status_with_zero_count_omitted
    stats = { total: 3, by_field: { "pending" => 3, "weird" => 0 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending done],
      status_icons: { "pending" => "○", "done" => "✓" }
    )

    assert_equal "Tasks: ○ 3 • 3 total", line
  end

  def test_format_with_folder_stats_single_folder_no_breakdown
    stats = { total: 3, by_field: { "pending" => 3 } }
    folder_stats = { total: 3, by_field: { nil => 3 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending done],
      status_icons: { "pending" => "○", "done" => "✓" },
      folder_stats: folder_stats
    )

    assert_equal "Tasks: ○ 3 • 3 total", line
  end

  def test_format_with_folder_stats_multiple_folders
    stats = { total: 660, by_field: { "done" => 620, "draft" => 21, "pending" => 7, "in-progress" => 1 } }
    folder_stats = { total: 660, by_field: { "_archive" => 620, "" => 28, "_maybe" => 12 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[draft pending in-progress done],
      status_icons: { "draft" => "◇", "pending" => "○", "in-progress" => "▶", "done" => "✓" },
      folder_stats: folder_stats
    )

    assert_equal "Tasks: ◇ 21 | ○ 7 | ▶ 1 | ✓ 620 • 660 total — _archive 620 | next 28 | _maybe 12", line
  end

  def test_format_with_folder_stats_nil_folder_renders_as_next
    stats = { total: 5, by_field: { "pending" => 3, "done" => 2 } }
    folder_stats = { total: 5, by_field: { nil => 3, "_archive" => 2 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending done],
      status_icons: { "pending" => "○", "done" => "✓" },
      folder_stats: folder_stats
    )

    assert_includes line, "next 3"
    assert_includes line, "_archive 2"
  end

  def test_format_folder_stats_sorted_by_count_descending
    stats = { total: 10, by_field: { "pending" => 10 } }
    folder_stats = { total: 10, by_field: { "_maybe" => 2, nil => 5, "_archive" => 3 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending],
      status_icons: { "pending" => "○" },
      folder_stats: folder_stats
    )

    # Should be sorted: next 5 | _archive 3 | _maybe 2
    assert_includes line, "— next 5 | _archive 3 | _maybe 2"
  end

  # --- total_count: "X of Y" tests ---

  def test_format_with_total_count_shows_x_of_y
    stats = { total: 3, by_field: { "draft" => 3 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[draft pending done],
      status_icons: { "draft" => "◇", "pending" => "○", "done" => "✓" },
      total_count: 660
    )

    assert_equal "Tasks: ◇ 3 • 3 of 660", line
  end

  def test_format_with_total_count_equal_to_shown_shows_total
    stats = { total: 660, by_field: { "done" => 620, "draft" => 21, "pending" => 7, "in-progress" => 1 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[draft pending in-progress done],
      status_icons: { "draft" => "◇", "pending" => "○", "in-progress" => "▶", "done" => "✓" },
      total_count: 660
    )

    assert_equal "Tasks: ◇ 21 | ○ 7 | ▶ 1 | ✓ 620 • 660 total", line
  end

  def test_format_with_total_count_filtered_skips_folder_breakdown
    stats = { total: 20, by_field: { "draft" => 9, "pending" => 11 } }
    folder_stats = { total: 20, by_field: { "_maybe" => 20 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[draft pending],
      status_icons: { "draft" => "◇", "pending" => "○" },
      folder_stats: folder_stats,
      total_count: 660
    )

    assert_equal "Tasks: ◇ 9 | ○ 11 • 20 of 660", line
  end

  def test_format_with_total_count_nil_falls_back_to_shown
    stats = { total: 8, by_field: { "pending" => 8 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Ideas",
      stats: stats,
      status_order: %w[pending],
      status_icons: { "pending" => "⚪" },
      total_count: nil
    )

    assert_equal "Ideas: ⚪ 8 • 8 total", line
  end
end
