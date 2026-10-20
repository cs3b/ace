# frozen_string_literal: true

require "tmpdir"
require "time"
require_relative "../../test_helper"

class HandoffProbeTest < AceOverseerTestCase
  class FakeExecutorProbe
    def initialize(config: nil, assignments: [])
      @config = config
      @assignments = assignments
    end

    def probe(_worktree_path)
      {config: @config, assignments: @assignments}
    end
  end

  def setup
    super
    @worktree = Dir.mktmpdir("handoff-probe")
  end

  def teardown
    FileUtils.rm_rf(@worktree)
    super
  end

  def write_assignment(id, task_id:, created_at:, name: nil)
    dir = File.join(@worktree, ".ace-local", "assign", id)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "assignment.yaml"), {
      "id" => id,
      "name" => name || "#{task_id}-role",
      "task_id" => task_id,
      "created_at" => created_at.iso8601
    }.to_yaml)
    dir
  end

  def write_start_config(role, task_id:, assignment:)
    dir = File.join(@worktree, ".ace-local", "coworker", "prepare")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{role}.yml"), {
      "role" => role, "task" => task_id, "assignment" => assignment,
      "overseer" => "overseer@local"
    }.to_yaml)
  end

  def test_reads_ordered_legs_with_states_and_roles
    write_assignment("zzz", task_id: "8xg.t.abc", created_at: Time.utc(2026, 10, 19, 12), name: "8xg.t.abc-worker")
    write_assignment("aaa", task_id: "8xg.t.abc", created_at: Time.utc(2026, 10, 19, 13), name: "8xg.t.abc-reviewer")
    write_assignment("other", task_id: "8xg.t.other", created_at: Time.utc(2026, 10, 19, 14))
    write_start_config("worker", task_id: "8xg.t.abc", assignment: "zzz")
    write_start_config("reviewer", task_id: "8xg.t.abc", assignment: "aaa")

    probe = Ace::Overseer::Molecules::HandoffProbe.new(
      executor_probe: FakeExecutorProbe.new(assignments: [
        {"id" => "zzz", "name" => "8xg.t.abc-worker", "state" => "completed", "progress" => "1/1"},
        {"id" => "aaa", "name" => "8xg.t.abc-reviewer", "state" => "paused", "progress" => "0/2"}
      ])
    )

    result = probe.probe(@worktree, task_id: "8xg.t.abc")

    assert_equal 2, result[:legs].length
    assert_equal "zzz", result[:legs][0]["assignment"]
    assert_equal "worker", result[:legs][0]["role"]
    assert_equal "completed", result[:legs][0]["state"]
    assert_equal "reviewer", result[:legs][1]["role"]
    assert_equal "paused", result[:legs][1]["state"]
  end

  def test_assignment_missing_from_inventory_has_unknown_state_and_missing_role_is_nil
    write_assignment("w1", task_id: "8xg.t.abc", created_at: Time.utc(2026, 10, 19, 12))

    probe = Ace::Overseer::Molecules::HandoffProbe.new(executor_probe: FakeExecutorProbe.new)

    result = probe.probe(@worktree, task_id: "8xg.t.abc")

    assert_equal "", result[:legs][0]["state"]
    assert_nil result[:legs][0]["role"]
  end

  def test_unparseable_start_config_contributes_no_role
    write_assignment("w1", task_id: "8xg.t.abc", created_at: Time.utc(2026, 10, 19, 12))
    dir = File.join(@worktree, ".ace-local", "coworker", "prepare")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "worker.yml"), "role: [unclosed\n  - bad")

    probe = Ace::Overseer::Molecules::HandoffProbe.new(executor_probe: FakeExecutorProbe.new)

    result = probe.probe(@worktree, task_id: "8xg.t.abc")

    assert_nil result[:legs][0]["role"]
  end

  def test_executor_truth_passes_through
    write_assignment("w1", task_id: "8xg.t.abc", created_at: Time.utc(2026, 10, 19, 12))
    executor = FakeExecutorProbe.new(config: {"assignment" => "w1"}, assignments: [])

    result = Ace::Overseer::Molecules::HandoffProbe.new(executor_probe: executor)
      .probe(@worktree, task_id: "8xg.t.abc")

    assert_equal({"assignment" => "w1"}, result[:executor][:config])
  end
end
