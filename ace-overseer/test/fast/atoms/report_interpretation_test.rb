# frozen_string_literal: true

require_relative "../../test_helper"

class ReportInterpretationTest < AceOverseerTestCase
  FakeTask = Struct.new(:id, :status, :metadata, :subtasks, keyword_init: true)

  def step(id, status: "progress", metadata: {})
    FakeTask.new(id: id, status: status, metadata: metadata, subtasks: [])
  end

  def manager(id, steps:, metadata: {})
    FakeTask.new(id: id, status: "in-progress", metadata: metadata, subtasks: steps)
  end

  def report(id: "ab12cd", result: "success", task: "8xg.t.prj", assignment: "w1")
    {"id" => id, "type" => "report", "result" => result, "task" => task,
     "assignment" => assignment, "step" => nil, "title" => "Work done"}
  end

  def test_success_report_matches_step_by_assignment_and_advances_it
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.0", status: "done", metadata: {"assignment" => "p1"}),
      step("8xg.t.mgr.1", status: "progress", metadata: {"assignment" => "w1"})
    ], metadata: {"project_task" => "8xg.t.prj"})

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report, managers: [manager])

    assert_equal :success, verdict[:status]
    assert_equal "8xg.t.mgr.1", verdict[:step_ref]
    assert_equal "8xg.t.mgr", verdict[:manager_ref]
    assert_equal "done", verdict[:set]["status"]
    assert_equal "ab12cd", verdict[:set]["processed_report"]
    assert_equal "success", verdict[:set]["report_result"]
  end

  def test_report_without_assignment_matches_project_task_with_single_active_step
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.0", status: "done"),
      step("8xg.t.mgr.1", status: "progress")
    ], metadata: {"project_task" => "8xg.t.prj"})

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(assignment: nil), managers: [manager])

    assert_equal :success, verdict[:status]
    assert_equal "8xg.t.mgr.1", verdict[:step_ref]
  end

  def test_repeated_delivery_is_duplicate_and_never_re_runs
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.1", status: "done",
        metadata: {"assignment" => "w1", "processed_report" => "ab12cd", "report_result" => "success"})
    ], metadata: {"project_task" => "8xg.t.prj"})

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report, managers: [manager])

    assert_equal :duplicate, verdict[:status]
    assert_equal "success", verdict[:recorded_result]
    assert_nil verdict[:set]
  end

  def test_error_report_keeps_step_open_and_never_counts_as_success
    manager = manager("8xg.t.mgr", steps: [step("8xg.t.mgr.1", metadata: {"assignment" => "w1"})])

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(result: "error"), managers: [manager])

    assert_equal :error, verdict[:status]
    assert verdict[:escalate]
    assert_equal "ab12cd", verdict[:set]["processed_report"]
    assert_equal "error", verdict[:set]["report_result"]
    refute verdict[:set].key?("status")
  end

  def test_question_needs_answer_and_writes_nothing
    manager = manager("8xg.t.mgr", steps: [step("8xg.t.mgr.1", metadata: {"assignment" => "w1"})])
    event = report.merge("type" => "question")

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: event, managers: [manager])

    assert_equal :needs_answer, verdict[:status]
    assert_equal "ab12cd", verdict[:event_id]
    assert_nil verdict[:set]
  end

  def test_report_about_unknown_task_or_assignment_is_unmatched
    manager = manager("8xg.t.mgr", steps: [step("8xg.t.mgr.1", metadata: {"assignment" => "w1"})])

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(task: "8xg.t.other", assignment: "zz9"), managers: [manager])

    assert_equal :unmatched, verdict[:status]
    assert_includes verdict[:reason], "matches no open step"
    assert_includes verdict[:reason], "event ab12cd"
  end

  def test_ambiguous_project_task_match_is_unmatched
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.0", status: "progress"),
      step("8xg.t.mgr.1", status: "progress")
    ], metadata: {"project_task" => "8xg.t.prj"})

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(assignment: nil), managers: [manager])

    assert_equal :unmatched, verdict[:status]
  end

  def test_empty_tree_reports_are_unmatched
    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report, managers: [])

    assert_equal :unmatched, verdict[:status]
  end

  def test_distinct_id_success_report_for_done_step_is_not_re_advanced
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.1", status: "done",
        metadata: {"assignment" => "w1", "processed_report" => "ab12cd", "report_result" => "success"}),
      step("8xg.t.mgr.2", status: "pending")
    ], metadata: {"project_task" => "8xg.t.prj"})

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(id: "ef99xy"), managers: [manager])

    assert_equal :duplicate, verdict[:status]
    assert_equal "8xg.t.mgr.1", verdict[:step_ref]
    assert_equal "success", verdict[:recorded_result]
    assert_nil verdict[:set]
  end

  # Crash cut (PR #393 final audit finding #4): preparation became done
  # with its readiness report recorded, but the continuation never
  # dispatched. The re-delivered readiness (no assignment) must resolve
  # to the recorded duplicate instead of unmatched, so the caller can
  # re-evaluate continuation from current state.
  def test_redelivered_readiness_on_done_preparation_is_duplicate_not_unmatched
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.0", status: "done",
        metadata: {"processed_report" => "ab12cd", "report_result" => "success"}),
      step("8xg.t.mgr.1", status: "progress", metadata: {"assignment" => "w1"})
    ], metadata: {"project_task" => "8xg.t.prj"})

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(assignment: nil), managers: [manager])

    assert_equal :duplicate, verdict[:status]
    assert_equal "8xg.t.mgr.0", verdict[:step_ref]
    assert_equal "success", verdict[:recorded_result]
    assert_nil verdict[:set]
  end

  def test_assignment_prefers_non_terminal_step_over_done_step
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.0", status: "done", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "progress", metadata: {"assignment" => "w1"})
    ], metadata: {"project_task" => "8xg.t.prj"})

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report, managers: [manager])

    assert_equal :success, verdict[:status]
    assert_equal "8xg.t.mgr.1", verdict[:step_ref]
  end

  def test_ambiguous_cross_manager_assignment_match_is_unmatched
    managers = [
      manager("8xg.t.mgr.a", steps: [step("8xg.t.mgr.a.0", metadata: {"assignment" => "w1"})]),
      manager("8xg.t.mgr.b", steps: [step("8xg.t.mgr.b.0", metadata: {"assignment" => "w1"})])
    ]

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report, managers: managers)

    assert_equal :unmatched, verdict[:status]
  end

  def test_ambiguous_cross_manager_project_task_match_is_unmatched
    managers = [
      manager("8xg.t.mgr.a", steps: [step("8xg.t.mgr.a.0")], metadata: {"project_task" => "8xg.t.prj"}),
      manager("8xg.t.mgr.b", steps: [step("8xg.t.mgr.b.0")], metadata: {"project_task" => "8xg.t.prj"})
    ]

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(assignment: nil), managers: managers)

    assert_equal :unmatched, verdict[:status]
  end

  def test_explicit_unknown_assignment_never_falls_back_to_task_only_matching
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.0", status: "done", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", metadata: {"assignment" => "r1"})
    ], metadata: {"project_task" => "8xg.t.prj"})

    # A stale report names an assignment no step records: task matches the
    # manager, but the report belongs to no open allocation.
    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(assignment: "stale-assignment"), managers: [manager])

    assert_equal :unmatched, verdict[:status]
    assert_includes verdict[:reason], "assignment stale-assignment"
    assert_equal "pending", manager.subtasks.last.status
  end

  def test_planner_readiness_report_completes_only_a_preparation_step
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.0", status: "progress")
    ], metadata: {"project_task" => "8xg.t.prj"})

    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(assignment: nil), managers: [manager])

    assert_equal :success, verdict[:status]
    assert_equal "8xg.t.mgr.0", verdict[:step_ref]
  end

  def test_planner_readiness_report_never_completes_a_remaining_role_step
    manager = manager("8xg.t.mgr", steps: [
      step("8xg.t.mgr.0", status: "done"),
      step("8xg.t.mgr.1", status: "done"),
      step("8xg.t.mgr.2", status: "done"),
      step("8xg.t.mgr.3", status: "pending", metadata: {"assignment" => "integrator"})
    ], metadata: {"project_task" => "8xg.t.prj"})

    # An old planner readiness report (task + success, no assignment) must
    # not complete the sole remaining integration step: absence of an
    # assignment is not evidence that whichever role remains finished.
    verdict = Ace::Overseer::Atoms::ReportInterpretation.evaluate(
      event: report(id: "planner-ready", assignment: nil), managers: [manager])

    assert_equal :unmatched, verdict[:status]
    assert_equal "pending", manager.subtasks.last.status
  end
end
