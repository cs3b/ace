# frozen_string_literal: true

require_relative "../../test_helper"

class StatusAttentionTest < AceOverseerTestCase
  ATTENTION = Ace::Overseer::Organisms::StatusAttention

  # Build a snapshot the way StatusCollector#collect_sources does,
  # with fake per-source results.
  def snapshot(sources, config: {"status_sources" => {}}, hitl_events: [])
    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: nil, context_collector: nil, project_root: "/project",
      config: config, sources: sources,
      attention: ATTENTION.new(hitl_events: -> { hitl_events })
    )
    collector.collect_sources
  end

  class FakeSource
    attr_reader :origin

    def initialize(origin: "fake origin", data: nil, error: nil)
      @origin = origin
      @data = data
      @error = error
    end

    def fetch
      raise @error if @error

      @data
    end
  end

  def healthy_sources(overrides = {})
    {
      "worktrees" => FakeSource.new(data: {worktrees: []}),
      "forge" => FakeSource.new(data: []),
      "project_tasks" => FakeSource.new(data: []),
      "overseer_tree" => FakeSource.new(data: []),
      "herdr" => FakeSource.new(data: {workspaces: []}),
      "coworkers" => FakeSource.new(data: [])
    }.merge(overrides)
  end

  def tasks(*rows)
    rows.map { |row| {id: row[:id], status: row[:status], title: row.fetch(:title, ""), dependencies: row.fetch(:dependencies, []),
                      special_folder: row[:special_folder]} }
  end

  # --- blockers (dependencies with concrete reasons) ---

  def test_pending_task_with_unsatisfied_dependency_is_a_blocker_with_reason
    snap = snapshot(healthy_sources(
      "project_tasks" => FakeSource.new(data: tasks(
        {id: "t1", status: "done"},
        {id: "t2", status: "in-progress"},
        {id: "t3", status: "pending", dependencies: ["t1", "t2"]}
      ))
    ))

    blockers = snap[:attention][:blockers]
    assert_equal 1, blockers.length
    row = blockers.first
    assert_equal "dependency", row[:kind]
    assert_equal "t3", row[:task_id]
    assert_equal "project", row[:tree]
    assert_equal 1, row[:reasons].length
    assert_includes row[:reasons].first, "t2"
    assert_includes row[:reasons].first, "in-progress"
    assert_includes row[:next_action], "t3"
  end

  def test_missing_dependency_is_a_blocker_not_a_free_pass
    snap = snapshot(healthy_sources(
      "project_tasks" => FakeSource.new(data: tasks({id: "t9", status: "pending", dependencies: ["nope"]}))
    ))

    reasons = snap[:attention][:blockers].first[:reasons]
    assert_equal 1, reasons.length
    assert_includes reasons.first, "nope: dependency not found"
  end

  def test_overseer_tree_blocked_task_appears_even_with_satisfied_dependencies
    snap = snapshot(healthy_sources(
      "overseer_tree" => FakeSource.new(data: tasks({id: "o1", status: "blocked"}))
    ))

    row = snap[:attention][:blockers].first
    assert_equal "o1", row[:task_id]
    assert_equal "_overseer", row[:tree]
    assert_includes row[:reasons].join, "marked blocked"
  end

  def test_done_and_draft_tasks_never_block
    snap = snapshot(healthy_sources(
      "project_tasks" => FakeSource.new(data: tasks(
        {id: "t1", status: "done"},
        {id: "t2", status: "in-progress", dependencies: ["missing"]},
        {id: "t3", status: "draft", dependencies: ["missing"]}
      ))
    ))

    assert_equal [], snap[:attention][:blockers]
  end

  # --- failures beside healthy data ---

  def test_source_error_is_a_failure_row_next_to_healthy_sources
    snap = snapshot(healthy_sources(
      "herdr" => FakeSource.new(error: RuntimeError.new("runtime unreachable"))
    ))

    row = snap[:attention][:failures].first
    assert_equal "source_error", row[:kind]
    assert_equal "herdr", row[:subject]
    assert_includes row[:detail], "runtime unreachable"
    assert_includes row[:next_action], "unavailable, not empty"
    # healthy sources stay ok in the same snapshot
    assert_equal "ok", snap[:sources]["worktrees"][:status]
  end

  def test_failed_and_stalled_assignments_are_failures
    snap = snapshot(healthy_sources(
      "coworkers" => FakeSource.new(data: [
        {worktree: "/wt/a", active: false, evidence: nil, assignments: [
          {"id" => "asg1", "state" => "failed"},
          {"id" => "asg2", "state" => "stalled"},
          {"id" => "asg3", "state" => "running"}
        ]}
      ])
    ))

    kinds = snap[:attention][:failures].map { |row| [row[:kind], row[:subject]] }
    assert_includes kinds, ["failed_assignment", "asg1"]
    assert_includes kinds, ["stalled_assignment", "asg2"]
    refute_includes kinds.map(&:last), "asg3"
  end

  def test_per_worktree_probe_error_is_a_failure
    snap = snapshot(healthy_sources(
      "coworkers" => FakeSource.new(data: [
        {worktree: "/wt/b", error: "RuntimeError: probe boom"}
      ])
    ))

    row = snap[:attention][:failures].first
    assert_equal "probe_error", row[:kind]
    assert_equal "/wt/b", row[:subject]
    assert_includes row[:detail], "probe boom"
  end

  def test_pending_hitl_question_is_an_escalation_failure
    snap = snapshot(healthy_sources, hitl_events: [
      {"id" => "q7", "type" => "question", "title" => "Which branch?",
       "task" => "t3", "assignment" => "asg1", "result" => nil},
      {"id" => "r8", "type" => "report", "title" => "Done", "result" => "success"}
    ])

    rows = snap[:attention][:failures]
    escalation = rows.find { |row| row[:kind] == "escalation" }
    assert_equal "q7", escalation[:subject]
    assert_includes escalation[:next_action], "ace-hitl"
    # The unprocessed incoming report is surfaced too (waits on the
    # overseer just like a question), with its consumer as next_action.
    report = rows.find { |row| row[:kind] == "unprocessed_report" }
    assert_equal "r8", report[:subject]
    assert_includes report[:next_action], "process-reports"
    assert_equal 2, rows.length
  end

  def test_report_recorded_by_process_reports_is_not_permanently_unprocessed
    # ReportProcessor records processed_report on the step's metadata
    # through the ace-task owner; the overseer-tree source carries it.
    # Attention must derive processed state from that metadata instead of
    # labeling every inbox report unprocessed forever.
    snap = snapshot(
      healthy_sources("overseer_tree" => FakeSource.new(data: [
        {id: "8xg.t.mgr.0", status: "done", title: "Implement", dependencies: [],
         special_folder: "_overseer", processed_report: "r8"},
        {id: "8xg.t.mgr.1", status: "pending", title: "Integrate", dependencies: ["8xg.t.mgr.0"],
         special_folder: "_overseer", processed_report: nil}
      ])),
      hitl_events: [
        {"id" => "r8", "type" => "report", "title" => "Done", "result" => "success",
         "task" => "8xg.t.prj", "assignment" => "w1"},
        {"id" => "r9", "type" => "report", "title" => "Later", "result" => "success",
         "task" => "8xg.t.prj", "assignment" => nil}
      ]
    )

    rows = snap[:attention][:failures].select { |row| row[:kind] == "unprocessed_report" }
    assert_equal ["r9"], rows.map { |row| row[:subject] },
      "the processed report r8 must not stay a permanent unprocessed warning"
  end

  def test_hitl_inbox_failure_is_missing_data_not_healthy
    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: nil, context_collector: nil, project_root: "/project",
      config: {"status_sources" => {}}, sources: healthy_sources,
      attention: ATTENTION.new(hitl_events: -> { raise RuntimeError, "hitl down" })
    )

    attention = collector.collect_sources[:attention]

    assert_equal [], attention[:failures]
    row = attention[:missing_data].first
    assert_equal "hitl_unavailable", row[:kind]
    assert_includes row[:detail], "hitl down"
  end

  # --- missing data explicit; disabled source is not healthy ---

  def test_disabled_source_is_missing_data_and_never_ok
    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: nil, context_collector: nil, project_root: "/project",
      config: {"status_sources" => {"coworkers" => {"enabled" => false}}},
      sources: healthy_sources,
      attention: ATTENTION.new(hitl_events: -> { [] })
    )
    snap = collector.collect_sources

    assert_equal "disabled", snap[:sources]["coworkers"][:status]
    row = snap[:attention][:missing_data].find { |r| r[:kind] == "source_disabled" }
    refute_nil row, "disabled source must appear in missing_data"
    assert_equal "coworkers", row[:subject]
    assert_includes row[:detail], "does not confirm a free worktree"
  end

  def test_unknown_config_keys_are_missing_data
    snap = snapshot(healthy_sources,
      config: {"status_sources" => {"forg" => {"enabled" => true}, "forge" => {"limt" => 2}}})

    subjects = snap[:attention][:missing_data].select { |r| r[:kind] == "unknown_config" }.map { |r| r[:subject] }
    assert_includes subjects, "forg"
    assert_includes subjects, "forge.limt"
  end

  def test_errored_task_tree_leaves_readiness_unverified
    snap = snapshot(healthy_sources(
      "project_tasks" => FakeSource.new(error: RuntimeError.new("tree unreadable"))
    ))

    row = snap[:attention][:missing_data].find { |r| r[:kind] == "tree_unverified" }
    refute_nil row
    assert_includes row[:detail], "unverified"
    # no blockers can be derived — and none are claimed
    assert_equal [], snap[:attention][:blockers]
  end

  def test_unknown_task_status_is_missing_data
    snap = snapshot(healthy_sources(
      "project_tasks" => FakeSource.new(data: tasks({id: "t1", status: "mystery"}))
    ))

    row = snap[:attention][:missing_data].find { |r| r[:kind] == "unknown_task_status" }
    refute_nil row
    assert_equal "t1", row[:subject]
    assert_includes row[:detail], "mystery"
  end

  def test_unknown_executor_state_is_missing_data_and_not_a_free_worktree
    snap = snapshot(healthy_sources(
      "coworkers" => FakeSource.new(data: [
        {worktree: "/wt/c", active: true,
         evidence: {"assignment" => "asg9", "state" => "unparseable", "source" => "config"},
         assignments: []}
      ])
    ))

    row = snap[:attention][:missing_data].find { |r| r[:kind] == "unknown_executor" }
    refute_nil row
    assert_equal "/wt/c", row[:subject]
    assert_includes row[:detail], "cannot be treated as free"
  end

  def test_healthy_snapshot_has_empty_attention
    snap = snapshot(healthy_sources)

    assert_equal({blockers: [], failures: [], missing_data: []}, snap[:attention])
  end

  # --- JSON contract and table rendering (through the collector) ---

  def collector(sources, config: {"status_sources" => {"forge" => {"enabled" => false}}}, hitl_events: [])
    Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: nil, context_collector: nil, project_root: "/project",
      config: config, sources: sources,
      attention: ATTENTION.new(hitl_events: -> { hitl_events })
    )
  end

  def test_json_contract_carries_attention_sections
    snap = collector(healthy_sources(
      "project_tasks" => FakeSource.new(data: tasks(
        {id: "t1", status: "in-progress"},
        {id: "t2", status: "pending", dependencies: ["t1"]}
      ))
    ), hitl_events: [
      {"id" => "q1", "type" => "question", "title" => "Decide", "task" => nil, "assignment" => nil, "result" => nil}
    ]).collect_sources

    parsed = JSON.parse(JSON.generate(Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: nil, context_collector: nil, project_root: "/project"
    ).to_sources_h(snap)))

    attention = parsed.fetch("attention")
    assert_equal %w[blockers failures missing_data].sort, attention.keys.sort
    assert_equal "t2", attention["blockers"][0]["task_id"]
    assert_equal "dependency", attention["blockers"][0]["kind"]
    assert attention["blockers"][0]["reasons"].is_a?(Array)
    assert_equal "escalation", attention["failures"][0]["kind"]
    assert_equal "q1", attention["failures"][0]["subject"]
    assert_equal "source_disabled", attention["missing_data"][0]["kind"]
    # next_action present on every row
    attention.each_value do |rows|
      rows.each { |row| refute_nil row["next_action"] }
    end
  end

  def test_table_renders_attention_first_with_detail_and_next_action
    collector_obj = collector(healthy_sources(
      "herdr" => FakeSource.new(error: RuntimeError.new("runtime unreachable")),
      "project_tasks" => FakeSource.new(data: tasks(
        {id: "t1", status: "in-progress"},
        {id: "t2", status: "pending", dependencies: ["t1"]}
      ))
    ))

    table = collector_obj.to_sources_table(collector_obj.collect_sources)

    assert_operator table.index("-- attention"), :<, table.index("-- herdr")
    assert_includes table, "BLOCKER  dependency  t2 [project]"
    assert_includes table, "t1: predecessor not integrated yet (status: in-progress)"
    assert_includes table, "next: unblock the predecessor(s), then start or continue t2"
    assert_includes table, "FAILURE  source_error  herdr"
    assert_includes table, "MISSING DATA  source_disabled  forge"
  end

  def test_table_states_explicitly_when_nothing_needs_attention
    collector_obj = collector(healthy_sources, config: {"status_sources" => {}})
    table = collector_obj.to_sources_table(collector_obj.collect_sources)

    assert_includes table, "-- attention: none"
  end

  def test_blockers_from_overseer_tree_resolve_dependencies_across_trees
    snap = snapshot(healthy_sources(
      "project_tasks" => FakeSource.new(data: tasks({id: "p1", status: "in-progress"})),
      "overseer_tree" => FakeSource.new(data: tasks({id: "o2", status: "pending", dependencies: ["p1"]}))
    ))

    row = snap[:attention][:blockers].first
    assert_equal "o2", row[:task_id]
    assert_includes row[:reasons].first, "p1"
  end

  def test_overseer_task_in_both_trees_yields_one_correctly_labeled_blocker
    # The real project source lists in_folder: "all", so an _overseer task
    # appears in BOTH sources' data; provenance (special_folder) must keep
    # it out of the "project" tree — one row, labeled _overseer.
    snap = snapshot(healthy_sources(
      "project_tasks" => FakeSource.new(data: tasks(
        {id: "p1", status: "in-progress"},
        {id: "o1", status: "pending", dependencies: ["p1"], special_folder: "_overseer"},
        {id: "a9", status: "pending", dependencies: ["p1"], special_folder: "_archive"}
      )),
      "overseer_tree" => FakeSource.new(data: tasks({id: "o1", status: "pending", dependencies: ["p1"]}))
    ))

    rows = snap[:attention][:blockers]
    assert_equal 1, rows.length
    assert_equal "o1", rows.first[:task_id]
    assert_equal "_overseer", rows.first[:tree]
    # The archived stale task never surfaces as a project blocker.
    refute rows.any? { |r| r[:task_id] == "a9" }
  end
end
