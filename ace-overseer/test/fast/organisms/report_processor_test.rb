# frozen_string_literal: true

require_relative "../../test_helper"

class ReportProcessorTest < AceOverseerTestCase
  FakeTask = Struct.new(:id, :status, :metadata, :subtasks, :dependencies, keyword_init: true)

  class FakeInbox
    def initialize(events)
      @events = events
    end

    def incoming_events
      @events
    end
  end

  class FakeTaskManager
    attr_reader :updates

    def initialize(managers, vanish: nil)
      @managers = managers
      @vanish = vanish
      @updates = []
    end

    def list(in_folder: "next", **)
      @managers
    end

    def show(ref)
      @managers.find { |m| m.id.to_s == ref.to_s } ||
        @managers.flat_map(&:subtasks).find { |s| s.id.to_s == ref.to_s }
    end

    def update(ref, set: {}, **)
      return nil if ref.to_s == @vanish

      @updates << {ref: ref.to_s, set: set}
      task = show(ref)
      set.each do |key, value|
        key == "status" ? task.status = value : task.metadata[key] = value
      end
      task
    end
  end

  class FakeHandoff
    attr_reader :calls

    def initialize(error: nil, status: "ready", next_role: "reviewer")
      @error = error
      @status = status
      @next_role = next_role
      @calls = []
    end

    def call(task_ref:, **)
      @calls << task_ref
      raise @error if @error

      {task_ref: task_ref, status: @status, worktree_path: "/wt/prj",
        next: (@next_role.nil? ? nil : {"role" => @next_role, "assignment" => "r1",
          "start_config" => ".ace-local/coworker/prepare/#{@next_role}.yml"})}
    end
  end

  class FakeWorkOn
    attr_reader :calls

    def initialize(error: nil)
      @error = error
      @calls = []
    end

    def call(task_ref:, **)
      @calls << task_ref
      raise @error if @error

      {task_ref: task_ref, assignment_id: "a9", worktree_path: "/wt/step"}
    end
  end

  def step(id, status: "progress", metadata: {}, dependencies: [])
    FakeTask.new(id: id, status: status, metadata: metadata, subtasks: [], dependencies: dependencies)
  end

  def manager(steps:, metadata: {"project_task" => "8xg.t.prj"})
    FakeTask.new(id: "8xg.t.mgr", status: "in-progress", metadata: metadata,
      subtasks: steps, dependencies: [])
  end

  def report(id: "ab12cd", result: "success", type: "report", assignment: "w1", task: "8xg.t.prj")
    {"id" => id, "type" => type, "result" => result, "task" => task,
     "assignment" => assignment, "step" => nil, "title" => "Work done"}
  end

  def processor(events:, managers:, handoff: FakeHandoff.new, work_on: FakeWorkOn.new)
    Ace::Overseer::Organisms::ReportProcessor.new(
      inbox: FakeInbox.new(events),
      task_manager: FakeTaskManager.new(managers),
      handoff: handoff,
      work_on: work_on
    )
  end

  def test_success_report_updates_step_and_starts_next_unblocked_step_via_work_on
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ])]
    work_on = FakeWorkOn.new

    result = processor(events: [report], managers: managers, work_on: work_on).call

    assert_equal 1, result[:counts][:success]
    update = result[:outcomes].first
    assert_equal "8xg.t.mgr.0", update[:step_ref]
    assert_equal "done", managers.first.subtasks.first.status
    assert_equal "ab12cd", managers.first.subtasks.first.metadata["processed_report"]
    assert_equal ["8xg.t.mgr.1"], work_on.calls
    assert_equal "work-on", update[:continuation][:action]
    assert_equal "8xg.t.mgr.1", update[:continuation][:step_ref]
  end

  def test_success_report_continues_same_worktree_through_handoff_gate
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ], metadata: {"project_task" => "8xg.t.prj", "worktree" => ".ace-wt/prj"})]
    handoff = FakeHandoff.new

    result = processor(events: [report], managers: managers, handoff: handoff).call

    assert_equal 1, handoff.calls.length
    assert_equal "8xg.t.prj", handoff.calls.first
    continuation = result[:outcomes].first[:continuation]
    assert_equal "handoff", continuation[:action]
    assert_equal "reviewer", continuation.dig(:next, "role")
  end

  def test_repeated_report_does_not_start_the_next_step_twice
    steps = [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ]
    task_manager = FakeTaskManager.new([manager(steps: steps)])
    handoff = FakeHandoff.new
    work_on = FakeWorkOn.new
    orchestrator = Ace::Overseer::Organisms::ReportProcessor.new(
      inbox: FakeInbox.new([report]), task_manager: task_manager,
      handoff: handoff, work_on: work_on)

    first = orchestrator.call
    # Same event delivered again (redelivery after an interruption).
    second = orchestrator.call

    assert_equal 1, first[:counts][:success]
    assert_equal 1, second[:counts][:duplicate]
    assert_equal 1, task_manager.updates.length
    assert_equal 1, work_on.calls.length
    assert_empty handoff.calls
  end

  def test_error_report_keeps_step_open_and_does_not_continue
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ])]
    work_on = FakeWorkOn.new

    result = processor(events: [report(result: "error")], managers: managers, work_on: work_on).call

    assert_equal 1, result[:counts][:error]
    assert_equal "progress", managers.first.subtasks.first.status
    assert_equal "error", managers.first.subtasks.first.metadata["report_result"]
    assert_empty work_on.calls
    assert_nil result[:outcomes].first[:continuation]
    assert_includes result[:outcomes].first[:message], "not treated as success"
  end

  def test_question_surfaces_answer_path_and_writes_nothing
    managers = [manager(steps: [step("8xg.t.mgr.0", metadata: {"assignment" => "w1"})])]
    task_manager = FakeTaskManager.new(managers)
    orchestrator = Ace::Overseer::Organisms::ReportProcessor.new(
      inbox: FakeInbox.new([report(type: "question")]), task_manager: task_manager,
      handoff: FakeHandoff.new, work_on: FakeWorkOn.new)

    result = orchestrator.call

    assert_equal 1, result[:counts][:needs_answer]
    assert_empty task_manager.updates
    assert_equal "progress", managers.first.subtasks.first.status
    assert_includes result[:outcomes].first[:message], "ace-hitl update ab12cd --answer"
  end

  def test_report_about_unknown_task_is_kept_for_clarification
    task_manager = FakeTaskManager.new([manager(steps: [step("8xg.t.mgr.0", metadata: {"assignment" => "w1"})])])
    orchestrator = Ace::Overseer::Organisms::ReportProcessor.new(
      inbox: FakeInbox.new([report(task: "8xg.t.other", assignment: "zz9")]),
      task_manager: task_manager, handoff: FakeHandoff.new, work_on: FakeWorkOn.new)

    result = orchestrator.call

    assert_equal 1, result[:counts][:unmatched]
    assert_empty task_manager.updates
  end

  def test_blocked_next_step_continuation_reports_reason_without_starting
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.missing"])
    ])]
    work_on = FakeWorkOn.new

    result = processor(events: [report], managers: managers, work_on: work_on).call

    assert_equal 1, result[:counts][:success]
    continuation = result[:outcomes].first[:continuation]
    assert_equal "none", continuation[:action]
    assert_includes continuation[:reason], "no unblocked step"
    assert_empty work_on.calls
  end

  def test_refused_handoff_continuation_is_blocked_not_success
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ], metadata: {"project_task" => "8xg.t.prj", "worktree" => ".ace-wt/prj"})]
    handoff = FakeHandoff.new(error: Ace::Overseer::Error.new("Handoff refused: predecessor running"))

    result = processor(events: [report], managers: managers, handoff: handoff).call

    continuation = result[:outcomes].first[:continuation]
    assert_equal "blocked", continuation[:action]
    assert_includes continuation[:reason], "Handoff refused"
    assert_includes result[:outcomes].first[:message], "blocked"
  end

  def test_dry_run_interprets_without_writes_or_continuation
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ])]
    task_manager = FakeTaskManager.new(managers)
    orchestrator = Ace::Overseer::Organisms::ReportProcessor.new(
      inbox: FakeInbox.new([report]), task_manager: task_manager,
      handoff: FakeHandoff.new, work_on: FakeWorkOn.new)

    result = orchestrator.call(dry_run: true)

    assert result[:dry_run]
    assert_equal 1, result[:counts][:success]
    assert_equal "progress", managers.first.subtasks.first.status
    assert_empty task_manager.updates
    assert_includes result[:outcomes].first[:message], "dry-run"
  end

  def test_all_steps_terminal_reports_manager_closable
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "done")
    ])]
    work_on = FakeWorkOn.new

    result = processor(events: [report], managers: managers, work_on: work_on).call

    continuation = result[:outcomes].first[:continuation]
    assert_equal "none", continuation[:action]
    assert_includes continuation[:reason], "close the managing task"
    assert_empty work_on.calls
  end

  def test_distinct_id_success_report_for_done_step_is_not_re_advanced
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "done",
        metadata: {"assignment" => "w1", "processed_report" => "ab12cd", "report_result" => "success"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ])]
    handoff = FakeHandoff.new
    work_on = FakeWorkOn.new
    orchestrator = Ace::Overseer::Organisms::ReportProcessor.new(
      inbox: FakeInbox.new([report(id: "ef99xy")]), task_manager: FakeTaskManager.new(managers),
      handoff: handoff, work_on: work_on)

    result = orchestrator.call

    assert_equal 1, result[:counts][:duplicate]
    assert_equal 0, result[:counts][:success]
    assert_equal "done", managers.first.subtasks.first.status
    assert_equal "ab12cd", managers.first.subtasks.first.metadata["processed_report"]
    assert_empty work_on.calls
    assert_empty handoff.calls
    assert_nil result[:outcomes].first[:continuation]
  end

  def test_nil_update_return_blocks_and_keeps_report_for_clarification
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ])]
    work_on = FakeWorkOn.new
    orchestrator = Ace::Overseer::Organisms::ReportProcessor.new(
      inbox: FakeInbox.new([report]), task_manager: FakeTaskManager.new(managers, vanish: "8xg.t.mgr.0"),
      handoff: FakeHandoff.new, work_on: work_on)

    result = orchestrator.call

    outcome = result[:outcomes].first
    assert_equal "blocked", outcome[:continuation][:action]
    assert_includes outcome[:continuation][:reason], "no longer resolves"
    assert_includes outcome[:message], "kept in ace-hitl for clarification"
    assert_empty work_on.calls
  end

  def test_sequence_complete_handoff_is_not_described_as_next_role
    managers = [manager(steps: [
      step("8xg.t.mgr.0", status: "progress", metadata: {"assignment" => "w1"}),
      step("8xg.t.mgr.1", status: "pending", dependencies: ["8xg.t.mgr.0"])
    ], metadata: {"project_task" => "8xg.t.prj", "worktree" => ".ace-wt/prj"})]
    handoff = FakeHandoff.new(status: "sequence_complete", next_role: nil)

    result = processor(events: [report], managers: managers, handoff: handoff).call

    message = result[:outcomes].first[:message]
    assert_includes message, "sequence complete"
    refute_includes message, "handed to the next role"
  end
end

