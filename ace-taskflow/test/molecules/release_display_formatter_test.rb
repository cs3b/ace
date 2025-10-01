# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/release_display_formatter"

class ReleaseDisplayFormatterTest < Minitest::Test
  def test_progress_bar_with_zero_tasks
    stats = { total: 0, statuses: {} }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.progress_bar(stats)

    assert_equal "□" * 20, result
  end

  def test_progress_bar_with_no_done_tasks
    stats = { total: 10, statuses: { "pending" => 10 } }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.progress_bar(stats)

    assert_equal "░" * 20, result
  end

  def test_progress_bar_with_all_done_tasks
    stats = { total: 10, statuses: { "done" => 10 } }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.progress_bar(stats)

    assert_equal "█" * 20, result
  end

  def test_progress_bar_with_50_percent_done
    stats = { total: 10, statuses: { "done" => 5, "pending" => 5 } }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.progress_bar(stats)

    assert_equal ("█" * 10) + ("░" * 10), result
  end

  def test_progress_bar_with_custom_width
    stats = { total: 10, statuses: { "done" => 5 } }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.progress_bar(stats, width: 10)

    assert_equal ("█" * 5) + ("░" * 5), result
  end

  def test_completion_percentage_zero_tasks
    stats = { total: 0 }
    assert_equal 0, Ace::Taskflow::Molecules::ReleaseDisplayFormatter.completion_percentage(stats)
  end

  def test_completion_percentage_no_done
    stats = { total: 10, statuses: { "pending" => 10 } }
    assert_equal 0, Ace::Taskflow::Molecules::ReleaseDisplayFormatter.completion_percentage(stats)
  end

  def test_completion_percentage_all_done
    stats = { total: 10, statuses: { "done" => 10 } }
    assert_equal 100, Ace::Taskflow::Molecules::ReleaseDisplayFormatter.completion_percentage(stats)
  end

  def test_completion_percentage_half_done
    stats = { total: 10, statuses: { "done" => 5, "pending" => 5 } }
    assert_equal 50, Ace::Taskflow::Molecules::ReleaseDisplayFormatter.completion_percentage(stats)
  end

  def test_completion_percentage_rounds
    stats = { total: 3, statuses: { "done" => 1, "pending" => 2 } }
    assert_equal 33, Ace::Taskflow::Molecules::ReleaseDisplayFormatter.completion_percentage(stats)
  end

  def test_format_progress_summary_no_tasks
    stats = { total: 0 }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_progress_summary(stats)

    assert_equal "Progress: No tasks", result
  end

  def test_format_progress_summary_with_tasks
    stats = { total: 10, statuses: { "done" => 3, "pending" => 7 } }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_progress_summary(stats)

    assert_includes result, "Progress:"
    assert_includes result, "30%"
    assert_includes result, "(3/10)"
  end

  def test_format_status_breakdown_empty
    stats = { statuses: {} }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_status_breakdown(stats)

    assert_equal [], result
  end

  def test_format_status_breakdown_done_only
    stats = { statuses: { "done" => 5 } }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_status_breakdown(stats)

    assert_equal ["  ✓ Done: 5"], result
  end

  def test_format_status_breakdown_all_statuses
    stats = {
      statuses: {
        "done" => 3,
        "in-progress" => 2,
        "pending" => 4,
        "blocked" => 1
      }
    }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_status_breakdown(stats)

    assert_equal 4, result.length
    assert_includes result, "  ✓ Done: 3"
    assert_includes result, "  ⚡ In Progress: 2"
    assert_includes result, "  ○ Pending: 4"
    assert_includes result, "  ⊘ Blocked: 1"
  end

  def test_format_status_breakdown_skips_zero_counts
    stats = { statuses: { "done" => 5, "pending" => 0 } }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_status_breakdown(stats)

    assert_equal 1, result.length
    assert_includes result, "Done"
    refute result.any? { |line| line.include?("Pending") }
  end

  def test_format_statistics_complete
    stats = {
      total: 10,
      statuses: { "done" => 3, "pending" => 7 }
    }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_statistics(stats)

    assert_includes result, "Progress:"
    assert_includes result, "Status breakdown:"
    assert_includes result, "Done: 3"
    assert_includes result, "Pending: 7"
  end

  def test_format_validation_result_passed
    result_data = {
      valid: true,
      issues: [],
      statistics: { total: 10, statuses: { "done" => 10 } }
    }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_validation_result(result_data)

    assert_equal "✓ Release validation: PASSED", result[:header]
    assert_equal [], result[:issues]
    assert_includes result[:stats], "100%"
  end

  def test_format_validation_result_failed
    result_data = {
      valid: false,
      issues: ["Missing tests", "Incomplete docs"],
      statistics: { total: 10, statuses: { "done" => 5 } }
    }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_validation_result(result_data)

    assert_equal "✗ Release validation: FAILED", result[:header]
    assert_equal ["  - Missing tests", "  - Incomplete docs"], result[:issues]
    assert_includes result[:stats], "50%"
  end

  def test_format_release_header
    release = {
      name: "v.0.9.0",
      status: "active",
      path: "/path/to/release"
    }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_release_header(release)

    assert_equal 3, result.length
    assert_equal "Release: v.0.9.0", result[0]
    assert_equal "Status: active", result[1]
    assert_equal "Path: /path/to/release", result[2]
  end

  def test_format_release_display
    release = {
      name: "v.0.9.0",
      status: "active",
      path: "/path/to/release",
      statistics: { total: 5, statuses: { "done" => 2, "pending" => 3 } }
    }
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_release_display(release)

    assert_includes result, "Release: v.0.9.0"
    assert_includes result, "Status: active"
    assert_includes result, "Path: /path/to/release"
    assert_includes result, "Progress:"
    assert_includes result, "40%"
  end

  def test_format_active_releases_list_empty
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_active_releases_list([])

    assert_equal "No active releases found.", result
  end

  def test_format_active_releases_list_single
    releases = [
      {
        name: "v.0.9.0",
        path: "/path/to/v.0.9.0",
        statistics: { total: 5, statuses: { "done" => 2 } }
      }
    ]
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_active_releases_list(releases)

    assert_includes result, "Active Releases (1):"
    assert_includes result, "v.0.9.0 (primary)"
    assert_includes result, "Path: /path/to/v.0.9.0"
    assert_includes result, "Progress:"
  end

  def test_format_active_releases_list_multiple
    releases = [
      { name: "v.0.10.0", path: "/path/to/v.0.10.0", statistics: { total: 5, statuses: {} } },
      { name: "v.0.9.0", path: "/path/to/v.0.9.0", statistics: { total: 3, statuses: {} } }
    ]
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_active_releases_list(releases)

    assert_includes result, "Active Releases (2):"
    assert_includes result, "v.0.10.0 (primary)"
    assert_includes result, "v.0.9.0"
    refute_includes result, "v.0.9.0 (primary)"
  end

  def test_format_active_releases_list_without_primary_marker
    releases = [
      { name: "v.0.9.0", path: "/path", statistics: { total: 0, statuses: {} } }
    ]
    result = Ace::Taskflow::Molecules::ReleaseDisplayFormatter.format_active_releases_list(
      releases,
      show_primary: false
    )

    assert_includes result, "v.0.9.0"
    refute_includes result, "(primary)"
  end
end
