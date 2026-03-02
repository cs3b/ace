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

  def test_format_with_completion_rate
    stats = { total: 8, by_field: { "pending" => 2, "in-progress" => 1, "done" => 5 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending in-progress done],
      status_icons: { "pending" => "○", "in-progress" => "▶", "done" => "✓" },
      completion_values: ["done"]
    )

    assert_equal "Tasks: ○ 2 | ▶ 1 | ✓ 5 • 8 total • 63% complete", line
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
      status_icons: { "pending" => "⚪", "in-progress" => "🟡", "done" => "🟢", "obsolete" => "⚫" },
      completion_values: ["done"]
    )

    assert_equal "Ideas: ⚪ 3 | 🟡 1 | 🟢 2 • 6 total • 33% complete", line
  end

  def test_format_retro_style
    stats = { total: 7, by_field: { "active" => 2, "done" => 5 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Retros",
      stats: stats,
      status_order: %w[active done],
      status_icons: { "active" => "🟡", "done" => "🟢" },
      completion_values: ["done"]
    )

    assert_equal "Retros: 🟡 2 | 🟢 5 • 7 total • 71% complete", line
  end

  def test_format_single_status
    stats = { total: 5, by_field: { "done" => 5 } }

    line = Ace::Support::Items::Atoms::StatsLineFormatter.format(
      label: "Tasks",
      stats: stats,
      status_order: %w[pending done],
      status_icons: { "pending" => "○", "done" => "✓" },
      completion_values: ["done"]
    )

    assert_equal "Tasks: ✓ 5 • 5 total • 100% complete", line
  end
end
