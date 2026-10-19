# frozen_string_literal: true

require_relative "../../test_helper"

class DependencyReadinessTest < AceOverseerTestCase
  TaskStub = Struct.new(:id, :status, :dependencies, keyword_init: true)

  def lookup_for(tasks)
    ->(ref) { tasks[ref] }
  end

  def test_ready_without_dependencies
    result = Ace::Overseer::Atoms::DependencyReadiness.check(
      TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: []),
      lookup: lookup_for({})
    )

    assert_equal :ready, result[:status]
    assert_nil result[:reasons]
  end

  def test_satisfied_only_by_done_predecessor
    tasks = {"8xh.t.grm.3" => TaskStub.new(id: "8xh.t.grm.3", status: "done", dependencies: [])}
    result = Ace::Overseer::Atoms::DependencyReadiness.check(
      TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: ["8xh.t.grm.3"]),
      lookup: lookup_for(tasks)
    )

    assert_equal :ready, result[:status]
  end

  def test_work_done_on_implement_step_does_not_unlock_integration_dependency
    tasks = {
      "8xh.t.grm.1" => TaskStub.new(id: "8xh.t.grm.1", status: "done", dependencies: []),
      "8xh.t.grm.3" => TaskStub.new(id: "8xh.t.grm.3", status: "pending", dependencies: ["8xh.t.grm.1"])
    }
    result = Ace::Overseer::Atoms::DependencyReadiness.check(
      TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: ["8xh.t.grm.3"]),
      lookup: lookup_for(tasks)
    )

    assert_equal :blocked, result[:status]
    assert_equal ["8xh.t.grm.3: predecessor not integrated yet (status: pending)"], result[:reasons]
  end

  def test_terminal_without_result_is_not_satisfaction
    %w[skipped cancelled].each do |status|
      tasks = {"8xh.t.gsc.0" => TaskStub.new(id: "8xh.t.gsc.0", status: status, dependencies: [])}
      result = Ace::Overseer::Atoms::DependencyReadiness.check(
        TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: ["8xh.t.gsc.0"]),
        lookup: lookup_for(tasks)
      )

      assert_equal :blocked, result[:status], status
      assert_equal ["8xh.t.gsc.0: predecessor #{status} (no accepted/integrated result)"], result[:reasons]
    end
  end

  def test_in_progress_and_blocked_predecessors_are_waiting_reasons
    %w[in-progress blocked pending].each do |status|
      tasks = {"8xh.t.grm.3" => TaskStub.new(id: "8xh.t.grm.3", status: status, dependencies: [])}
      result = Ace::Overseer::Atoms::DependencyReadiness.check(
        TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: ["8xh.t.grm.3"]),
        lookup: lookup_for(tasks)
      )

      assert_equal :blocked, result[:status], status
      assert_includes result[:reasons].first, "not integrated yet (status: #{status})"
    end
  end

  def test_missing_dependency_is_reported
    result = Ace::Overseer::Atoms::DependencyReadiness.check(
      TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: ["8xh.t.gone"]),
      lookup: lookup_for({})
    )

    assert_equal :blocked, result[:status]
    assert_equal ["8xh.t.gone: dependency not found"], result[:reasons]
  end

  def test_direct_cyclic_dependency_is_reported
    tasks = {
      "8xh.t.grn.0" => TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: ["8xh.t.grn.0"])
    }
    result = Ace::Overseer::Atoms::DependencyReadiness.check(
      tasks["8xh.t.grn.0"],
      lookup: lookup_for(tasks)
    )

    assert_equal :blocked, result[:status]
    assert_equal ["8xh.t.grn.0: cyclic dependency (8xh.t.grn.0 -> 8xh.t.grn.0)"], result[:reasons]
  end

  def test_mutual_dependency_cycle_stays_blocked
    tasks = {
      "8xh.t.grn.0" => TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: ["8xh.t.grn.1"]),
      "8xh.t.grn.1" => TaskStub.new(id: "8xh.t.grn.1", status: "pending", dependencies: ["8xh.t.grn.0"])
    }
    result = Ace::Overseer::Atoms::DependencyReadiness.check(
      tasks["8xh.t.grn.0"],
      lookup: lookup_for(tasks)
    )

    # Neither member can ever reach done, so the cycle is blocked under the
    # waiting reason; the start decision is identical to an explicit cycle.
    assert_equal :blocked, result[:status]
    assert_equal ["8xh.t.grn.1: predecessor not integrated yet (status: pending)"], result[:reasons]
  end

  def test_multiple_reasons_are_all_reported
    tasks = {
      "8xh.t.grm.3" => TaskStub.new(id: "8xh.t.grm.3", status: "pending", dependencies: []),
      "8xh.t.gsc.0" => TaskStub.new(id: "8xh.t.gsc.0", status: "cancelled", dependencies: [])
    }
    result = Ace::Overseer::Atoms::DependencyReadiness.check(
      TaskStub.new(id: "8xh.t.grn.0", status: "pending", dependencies: ["8xh.t.grm.3", "8xh.t.gsc.0"]),
      lookup: lookup_for(tasks)
    )

    assert_equal :blocked, result[:status]
    assert_equal 2, result[:reasons].length
  end
end
