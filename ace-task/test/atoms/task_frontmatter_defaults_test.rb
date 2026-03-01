# frozen_string_literal: true

require "test_helper"

class TaskFrontmatterDefaultsTest < AceTaskTestCase
  Defaults = Ace::Task::Atoms::TaskFrontmatterDefaults

  def test_build_with_required_fields_only
    fm = Defaults.build(id: "8pp.t.q7w")

    assert_equal "8pp.t.q7w", fm["id"]
    assert_equal "pending", fm["status"]
    assert_equal "medium", fm["priority"]
    assert_nil fm["estimate"]
    assert_equal [], fm["dependencies"]
    assert_equal [], fm["tags"]
    refute fm.key?("parent")
  end

  def test_build_with_all_fields
    time = Time.utc(2026, 2, 26, 19, 15, 0)
    fm = Defaults.build(
      id: "8pp.t.q7w",
      status: "in-progress",
      priority: "high",
      tags: ["auth", "ui"],
      dependencies: ["8pp.t.abc"],
      created_at: time,
      parent: "8pp.t.xyz"
    )

    assert_equal "in-progress", fm["status"]
    assert_equal "high", fm["priority"]
    assert_equal ["auth", "ui"], fm["tags"]
    assert_equal ["8pp.t.abc"], fm["dependencies"]
    assert_equal "2026-02-26 19:15:00", fm["created_at"]
    assert_equal "8pp.t.xyz", fm["parent"]
  end

  def test_nil_status_defaults_to_pending
    fm = Defaults.build(id: "8pp.t.q7w", status: nil)
    assert_equal "pending", fm["status"]
  end

  def test_nil_priority_defaults_to_medium
    fm = Defaults.build(id: "8pp.t.q7w", priority: nil)
    assert_equal "medium", fm["priority"]
  end

  def test_format_time_returns_nil_for_nil
    assert_nil Defaults.format_time(nil)
  end

  def test_format_time_returns_formatted_string
    time = Time.utc(2026, 3, 1, 14, 30, 0)
    assert_equal "2026-03-01 14:30:00", Defaults.format_time(time)
  end
end
