# frozen_string_literal: true

require "test_helper"

class DependencyAwareSmartSorterTest < AceTaskTestCase
  SCORES = {"critical" => 4, "high" => 3, "medium" => 2, "low" => 1}.freeze

  def build_task(id, priority: "medium", status: "pending", dependencies: [], special_folder: nil, position: nil)
    Ace::Task::Models::Task.new(
      id: id,
      status: status,
      title: id,
      priority: priority,
      estimate: nil,
      dependencies: dependencies,
      tags: [],
      content: "",
      path: "/tmp/tasks/#{id}",
      file_path: "/tmp/tasks/#{id}/#{id}.s.md",
      special_folder: special_folder,
      created_at: Time.utc(2026, 1, 15),
      subtasks: [],
      parent_id: nil,
      metadata: position ? {"position" => position} : {}
    )
  end

  def sort_tasks(tasks, external_statuses: {})
    Ace::Task::Molecules::DependencyAwareSmartSorter.sort(
      tasks,
      score_fn: ->(task) { SCORES.fetch(task.priority, 0).to_f },
      pin_accessor: ->(task) { task.metadata["position"] },
      external_statuses: external_statuses
    )
  end

  # --- ready first ---

  def test_dependency_free_task_sorts_before_pending_dependent
    dependent = build_task("8aa.t.bbb", dependencies: ["8aa.t.aaa"])
    dependency = build_task("8aa.t.aaa")

    result = sort_tasks([dependent, dependency])

    assert_equal ["8aa.t.aaa", "8aa.t.bbb"], result.tasks.map(&:id)
    assert_empty result.cycle_ids
  end

  def test_done_dependency_does_not_demote_task
    done = build_task("8aa.t.aaa", status: "done")
    dependent = build_task("8aa.t.bbb", priority: "high", dependencies: ["8aa.t.aaa"])
    unmet = build_task("8aa.t.ccc", dependencies: ["zzz.t.nope"])

    result = sort_tasks([unmet, dependent, done])

    assert_equal ["8aa.t.bbb", "8aa.t.aaa", "8aa.t.ccc"], result.tasks.map(&:id)
  end

  def test_archived_dependency_does_not_demote_task
    archived = build_task("8aa.t.aaa", special_folder: "_archive")
    dependent = build_task("8aa.t.bbb", priority: "high", dependencies: ["8aa.t.aaa"])
    unmet = build_task("8aa.t.ccc", priority: "critical", dependencies: ["zzz.t.nope"])

    result = sort_tasks([unmet, dependent, archived])

    assert_equal ["8aa.t.bbb", "8aa.t.aaa", "8aa.t.ccc"], result.tasks.map(&:id)
  end

  def test_missing_dependency_keeps_task_out_of_ready_group
    orphan = build_task("8aa.t.bbb", dependencies: ["zzz.t.nope"])
    ready = build_task("8aa.t.aaa", priority: "low")

    result = sort_tasks([orphan, ready])

    assert_equal ["8aa.t.aaa", "8aa.t.bbb"], result.tasks.map(&:id)
  end

  def test_external_statuses_satisfy_out_of_listing_dependencies
    dependent = build_task("8aa.t.bbb", dependencies: ["8wm.t.vs0"])
    witness = build_task("8aa.t.aaa", priority: "low")

    satisfied = sort_tasks([dependent, witness], external_statuses: {"8wm.t.vs0" => ["pending", "_archive"]})
    assert_equal ["8aa.t.bbb", "8aa.t.aaa"], satisfied.tasks.map(&:id)

    unmet = sort_tasks([dependent, witness], external_statuses: {"8wm.t.vs0" => ["pending", nil]})
    assert_equal ["8aa.t.aaa", "8aa.t.bbb"], unmet.tasks.map(&:id)
  end

  def test_done_task_is_ready_despite_unmet_dependencies
    done = build_task("8aa.t.bbb", status: "done", dependencies: ["8aa.t.aaa"])
    dependency = build_task("8aa.t.aaa", priority: "low")

    result = sort_tasks([done, dependency])

    assert_equal ["8aa.t.bbb", "8aa.t.aaa"], result.tasks.map(&:id)
    assert_empty result.cycle_ids
  end

  # --- topological tail ---

  def test_dependency_chain_orders_shallow_unmet_before_deeper
    root = build_task("8aa.t.aaa")
    middle = build_task("8aa.t.bbb", dependencies: ["8aa.t.aaa"])
    deep = build_task("8aa.t.ccc", dependencies: ["8aa.t.bbb"])

    result = sort_tasks([deep, middle, root])

    assert_equal ["8aa.t.aaa", "8aa.t.bbb", "8aa.t.ccc"], result.tasks.map(&:id)
  end

  def test_depth_uses_longest_unmet_path
    root = build_task("8aa.t.aaa", priority: "high")
    quick_ready = build_task("8aa.t.xxx", priority: "low")
    middle = build_task("8aa.t.bbb", dependencies: ["8aa.t.aaa"])
    joined = build_task("8aa.t.ccc", dependencies: ["8aa.t.bbb", "8aa.t.xxx"])

    result = sort_tasks([joined, middle, quick_ready, root])

    assert_equal ["8aa.t.aaa", "8aa.t.xxx", "8aa.t.bbb", "8aa.t.ccc"], result.tasks.map(&:id)
  end

  def test_depth_tie_breaks_with_score
    low = build_task("8aa.t.aaa", priority: "low", dependencies: ["8aa.t.zzz"])
    high = build_task("8aa.t.bbb", priority: "high", dependencies: ["8aa.t.yyy"])
    low_unmet = build_task("8aa.t.zzz", priority: "low")
    high_unmet = build_task("8aa.t.yyy", priority: "high")

    result = sort_tasks([low, high, low_unmet, high_unmet])

    assert_equal ["8aa.t.yyy", "8aa.t.zzz", "8aa.t.bbb", "8aa.t.aaa"], result.tasks.map(&:id)
  end

  def test_priority_orders_within_ready_group
    low = build_task("8aa.t.aaa", priority: "low")
    high = build_task("8aa.t.bbb", priority: "high")

    result = sort_tasks([low, high])

    assert_equal ["8aa.t.bbb", "8aa.t.aaa"], result.tasks.map(&:id)
  end

  def test_pinned_task_sorts_first_within_ready_group
    pinned = build_task("8aa.t.aaa", priority: "low", position: "1")
    high = build_task("8aa.t.bbb", priority: "high")

    result = sort_tasks([high, pinned])

    assert_equal ["8aa.t.aaa", "8aa.t.bbb"], result.tasks.map(&:id)
  end

  # --- cycles ---

  def test_two_task_cycle_renders_tail_with_cycle_ids
    ready = build_task("8aa.t.aaa")
    unmet = build_task("8aa.t.ccc", dependencies: ["zzz.t.nope"])
    cycle_a = build_task("8aa.t.xxx", priority: "high", dependencies: ["8aa.t.yyy"])
    cycle_b = build_task("8aa.t.yyy", dependencies: ["8aa.t.xxx"])

    result = sort_tasks([cycle_b, unmet, cycle_a, ready])

    assert_equal "8aa.t.ccc", result.tasks[1].id
    assert_equal ["8aa.t.xxx", "8aa.t.yyy"], result.tasks.last(2).map(&:id).sort
    assert_equal ["8aa.t.xxx", "8aa.t.yyy"], result.cycle_ids.sort
  end

  def test_self_dependency_is_cyclic
    self_cycle = build_task("8aa.t.sss", dependencies: ["8aa.t.sss"])
    ready = build_task("8aa.t.aaa")

    result = sort_tasks([self_cycle, ready])

    assert_equal ["8aa.t.aaa", "8aa.t.sss"], result.tasks.map(&:id)
    assert_equal ["8aa.t.sss"], result.cycle_ids
  end

  def test_done_task_with_self_dependency_is_ready_not_cyclic
    done_self = build_task("8aa.t.sss", status: "done", dependencies: ["8aa.t.sss"])

    result = sort_tasks([done_self])

    assert_equal ["8aa.t.sss"], result.tasks.map(&:id)
    assert_empty result.cycle_ids
  end

  def test_pending_done_pair_with_satisfied_edge_stays_out_of_cycle
    pending = build_task("8aa.t.aaa", dependencies: ["8aa.t.bbb"])
    done = build_task("8aa.t.bbb", status: "done", dependencies: ["8aa.t.aaa"])

    result = sort_tasks([pending, done])

    assert_equal ["8aa.t.aaa", "8aa.t.bbb"], result.tasks.map(&:id)
    assert_empty result.cycle_ids
  end

  def test_task_downstream_of_cycle_is_not_marked_cyclic
    cycle_a = build_task("8aa.t.xxx", dependencies: ["8aa.t.yyy"])
    cycle_b = build_task("8aa.t.yyy", dependencies: ["8aa.t.xxx"])
    downstream = build_task("8aa.t.ddd", dependencies: ["8aa.t.xxx"])

    result = sort_tasks([downstream, cycle_a, cycle_b])

    assert_equal "8aa.t.ddd", result.tasks.first.id
    assert_equal ["8aa.t.xxx", "8aa.t.yyy"], result.tasks.last(2).map(&:id).sort
    assert_equal ["8aa.t.xxx", "8aa.t.yyy"], result.cycle_ids.sort
  end

  # --- determinism ---

  def test_output_is_deterministic_across_runs_and_insertion_orders
    tasks = [
      build_task("8aa.t.aaa", priority: "low"),
      build_task("8aa.t.bbb", priority: "high"),
      build_task("8aa.t.ccc", priority: "medium", dependencies: ["8aa.t.aaa"]),
      build_task("8aa.t.xxx", priority: "critical", dependencies: ["8aa.t.yyy"]),
      build_task("8aa.t.yyy", priority: "low", dependencies: ["8aa.t.xxx"])
    ]

    first = sort_tasks(tasks)
    second = sort_tasks(tasks)
    reversed = sort_tasks(tasks.reverse)

    assert_equal first.tasks.map(&:id), second.tasks.map(&:id)
    assert_equal first.tasks.map(&:id), reversed.tasks.map(&:id)
    assert_equal ["8aa.t.bbb", "8aa.t.aaa", "8aa.t.ccc", "8aa.t.xxx", "8aa.t.yyy"], first.tasks.map(&:id)
  end

  def test_empty_input_returns_empty_result
    result = sort_tasks([])

    assert_empty result.tasks
    assert_empty result.cycle_ids
  end
end
