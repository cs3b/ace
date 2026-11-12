# frozen_string_literal: true

require_relative "../../test_helper"

module Molecules
  # Task 8xs.t.pu0.3: the standing local observation projects
  # source classes from their owners with stable keys/revisions, and a
  # failing source degrades only itself.
  class LocalSourcesTest < Minitest::Test
    FakeTask = Struct.new(:id, :status, :title, :dependencies, :subtasks, :metadata, keyword_init: true)

    class FakeTaskManager
      def initialize(tasks)
        @tasks = tasks
      end

      def list(in_folder: "next", **)
        @tasks.fetch(in_folder, [])
      end
    end

    Worktree = Struct.new(:path, :branch, :bare)

    class FakeWorktreeManager
      def initialize(worktrees, error: nil)
        @worktrees = worktrees
        @error = error
      end

      def list_all
        return {success: false, error: @error} if @error

        {success: true, worktrees: @worktrees}
      end
    end

    class FakeProbe
      def initialize(report)
        @report = report
      end

      def probe(_path)
        @report
      end
    end

    def sources(tasks: {}, worktrees: [], worktree_error: nil, probe: nil, **options)
      no_project_sessions = Object.new
      def no_project_sessions.configured? = false
      Ace::Overseer::Molecules::LocalSources.new(
        task_manager: FakeTaskManager.new(tasks),
        worktree_manager: FakeWorktreeManager.new(worktrees, error: worktree_error),
        probe_factory: ->(_path) { probe || FakeProbe.new({config: nil, assignments: []}) },
        project_sessions: no_project_sessions, **options
      )
    end

    def test_native_executor_disappearance_revises_the_worktree_without_assignment_change
      worktree = Worktree.new("/lab/ace/.ace-wt/task-1", "work", false)
      worker = {"terminal_id" => "term_123abc", "cwd" => worktree.path,
        "name" => "coworker-job-7", "agent_status" => "working", "completion_seq" => 7}
      agents = [worker, worker.merge("terminal_id" => "term_456def", "cwd" => "/lab/other")]
      response = Struct.new(:parsed_json).new({"result" => {"agents" => agents}})
      herdr = Object.new
      herdr.define_singleton_method(:agent_list) { response }
      observer = sources(worktrees: [worktree], herdr: herdr, env: {"ACE_RUNTIME" => "herdr"})
      executor = -> { observer.call.fetch("events").find { |row| row["type"] == "executor" } }

      running = executor.call
      assert_equal [{"terminal" => "term_123abc", "agent" => "coworker-job-7", "completion_seq" => 7}], running.fetch("sessions")
      worker["agent_status"] = "done"
      assert_equal running, executor.call, "transient turn status is not executor disappearance"

      worker["completion_seq"] = 8
      finished_turn = executor.call
      assert_equal running.fetch("key"), finished_turn.fetch("key")
      refute_equal running.fetch("revision"), finished_turn.fetch("revision"),
        "a completed turn without an assignment report must wake the coordinator"
      assert_equal finished_turn, executor.call, "unchanged completion must not wake again"
      worker["agent_status"] = "working"
      worker.delete("completion_seq") # Native Herdr omits completion while working.
      resumed = executor.call
      refute_equal finished_turn.fetch("revision"), resumed.fetch("revision")
      assert_equal resumed, executor.call, "ongoing work with no completion remains stable"
      worker["agent_status"] = "done"
      worker["completion_seq"] = 9
      refute_equal finished_turn.fetch("revision"), executor.call.fetch("revision")

      agents.delete(worker)
      stopped = executor.call
      assert_equal running.fetch("key"), stopped.fetch("key")
      refute_equal running.fetch("revision"), stopped.fetch("revision")
      assert_empty stopped.fetch("sessions")
      assert_equal stopped, executor.call
    end

    def test_expected_executor_missing_without_observing_its_live_session
      worktree = Worktree.new("/lab/ace/.ace-wt/task-1", "work", false)
      binding = {"worktree" => worktree.path, "assignment" => "job-7", "terminal" => "term_123abc"}
      step = FakeTask.new(id: "step-1", status: "pending", metadata: {})
      manager = FakeTask.new(id: "manager", status: "pending", subtasks: [step])
      response = Struct.new(:parsed_json).new({"result" => {"agents" => []}})
      herdr = Object.new
      herdr.define_singleton_method(:agent_list) { response }
      assignments = [{"id" => "job-7", "state" => "paused"}]
      probe = FakeProbe.new({config: nil, assignments: assignments})
      observer = sources(tasks: {"_overseer" => [manager]}, worktrees: [worktree],
        herdr: herdr, probe: probe, env: {"ACE_RUNTIME" => "herdr"})
      executor = -> { observer.call.fetch("events").find { |row| row["type"] == "executor" } }

      before = executor.call
      assert_empty before.fetch("missing_sessions")
      step.metadata.merge!(binding)
      after = executor.call
      assert_equal before.fetch("key"), after.fetch("key")
      refute_equal before.fetch("revision"), after.fetch("revision")
      assert_equal [{"task" => "step-1", "assignment" => "job-7", "terminal" => "term_123abc"}],
        after.fetch("missing_sessions")

      assignments[0]["state"] = "completed"
      assert_empty executor.call.fetch("missing_sessions")
    end

    def test_unavailable_native_inventory_degrades_instead_of_reporting_all_executors_absent
      worktree = Worktree.new("/lab/ace/.ace-wt/task-1", "work", false)
      response = Struct.new(:parsed_json).new({"error" => {"code" => "server_not_running"}})
      herdr = Object.new
      herdr.define_singleton_method(:agent_list) { response }
      result = sources(worktrees: [worktree], herdr: herdr, env: {"ACE_RUNTIME" => "herdr"}).call

      assert_equal "degraded", result.dig("sources", "coworkers", "status")
      refute result.fetch("events").any? { |row| row["type"] == "executor" }
    end

    def test_projects_task_worktree_executor_and_assignment_rows_with_stable_revisions
      task = FakeTask.new(id: "8xs.t.pu0", status: "in-progress", title: "program",
        dependencies: [], subtasks: [])
      overseer_task = FakeTask.new(id: "8xs.t.pu1", status: "pending", title: "coord",
        dependencies: ["8xs.t.pu0"], subtasks: [])
      worktree = Worktree.new("/lab/wt/feature", "codex/feature", false)
      probe = FakeProbe.new({config: {"assignment" => "job-7"},
        assignments: [{"id" => "job-7", "name" => "implement", "state" => "running",
                       "progress" => {"done" => 2, "total" => 5}}]})

      result = sources(
        tasks: {"next" => [task], "_overseer" => [overseer_task]},
        worktrees: [worktree], probe: probe
      ).call

      keys = result["events"].map { |row| row["key"] }
      assert_includes keys, "task:8xs.t.pu0"
      assert_includes keys, "overseer-task:8xs.t.pu1"
      assert_includes keys, "worktree:#{Digest::SHA256.hexdigest("/lab/wt/feature")}"
      assert_includes keys, "executor:#{Digest::SHA256.hexdigest("/lab/wt/feature")}"
      assert_includes keys, "assignment:job-7"

      executor = result["events"].find { |row| row["type"] == "executor" }
      assert_equal true, executor["active"], "a commissioned running assignment is live"

      assert_equal({"project_tasks" => {"status" => "ok"}, "overseer_tasks" => {"status" => "ok"},
        "worktrees" => {"status" => "ok"}, "coworkers" => {"status" => "ok"}}, result["sources"])

      # Identical state -> identical revisions (healthy silence).
      again = sources(
        tasks: {"next" => [task], "_overseer" => [overseer_task]},
        worktrees: [worktree], probe: probe
      ).call
      assert_equal result["events"].sort_by { |row| row["key"] },
        again["events"].sort_by { |row| row["key"] }

      # A real change revises exactly that row.
      moved = FakeTask.new(id: "8xs.t.pu0", status: "done", title: "program",
        dependencies: [], subtasks: [])
      changed = sources(
        tasks: {"next" => [moved], "_overseer" => [overseer_task]},
        worktrees: [worktree], probe: probe
      ).call
      task_row = changed["events"].find { |row| row["key"] == "task:8xs.t.pu0" }
      refute_equal result["events"].find { |row| row["key"] == "task:8xs.t.pu0" }["revision"],
        task_row["revision"]
    end

    def test_assignment_progress_is_visible_without_revising_actionable_state
      assignment = {"id" => "job-7", "state" => "running", "progress" => {"done" => 1, "total" => 3}}
      observer = sources(worktrees: [Worktree.new("/lab/ace/.ace-wt/feature", "work", false)],
        probe: FakeProbe.new({config: nil, assignments: [assignment]}))
      row = -> { observer.call.fetch("events").find { |event| event["type"] == "assignment" } }
      before = row.call
      assignment["progress"] = {"done" => 2, "total" => 3}
      progressed = row.call
      assert_equal before["revision"], progressed["revision"]
      assert_equal 2, progressed.dig("progress", "done")
      assignment["state"] = "completed"
      refute_equal progressed["revision"], row.call["revision"]
    end

    def test_live_commission_step_transitions_do_not_wake_but_failure_and_exit_do
      assert_live_step_transitions({"assignment" => "job-7"})
    end

    def test_role_specific_config_does_not_require_a_default_commission_to_suppress_step_transitions
      assert_live_step_transitions(nil)
    end

    def assert_live_step_transitions(config)
      worktree = Worktree.new("/lab/ace/.ace-wt/feature", "work", false)
      assignment = {"id" => "job-7", "state" => "paused", "progress" => {"done" => 0}}
      agents = [{"terminal_id" => "term_123abc", "cwd" => worktree.path, "name" => "coworker-job-7"}]
      herdr = Object.new
      herdr.define_singleton_method(:agent_list) { Struct.new(:parsed_json).new({"result" => {"agents" => agents}}) }
      probe = FakeProbe.new({config: config, assignments: [assignment]})
      observer = sources(worktrees: [worktree], probe: probe, herdr: herdr, env: {"ACE_RUNTIME" => "herdr"})
      rows = -> { observer.call.fetch("events").select { |row| %w[executor assignment].include?(row["type"]) } }
      revisions = -> { rows.call.map { |row| row.fetch("revision") } }
      before = revisions.call
      assignment["state"] = "running"
      assignment["progress"] = {"done" => 1}
      assert_equal before, revisions.call
      assert_equal "running", rows.call.find { |row| row["type"] == "assignment" }.fetch("state")
      assert_equal "running", rows.call.find { |row| row["type"] == "executor" }.dig("evidence", "state")
      assignment["state"] = "paused"
      assert_equal before, revisions.call
      %w[stalled failed completed unknown].each do |state|
        assignment["state"] = state
        revisions.call.zip(before).each { |actual, original| refute_equal original, actual, state }
      end
      assignment["state"] = "paused"
      agents.first["name"] = "coworker-job-8"
      unrelated = revisions.call
      assignment["state"] = "running"
      refute_equal unrelated, revisions.call, "another coworker in the same worktree is not this commission"
      assignment["state"] = "paused"
      agents.clear
      refute_equal before, revisions.call, "disappearance during a step gap must remain actionable"
      absent = revisions.call
      assignment["state"] = "running"
      refute_equal absent, revisions.call, "without a live session, retain exact assignment states"
    end

    def test_worktree_failure_degrades_only_the_worktree_dependent_sources
      result = sources(worktree_error: "tmux socket gone").call

      assert_equal "degraded", result["sources"]["worktrees"]["status"]
      assert_equal "degraded", result["sources"]["coworkers"]["status"]
      assert_equal "ok", result["sources"]["project_tasks"]["status"]
      assert_equal "ok", result["sources"]["overseer_tasks"]["status"]
      marker = result["events"].find { |row| row["type"] == "source-health" }
      refute_nil marker, "the degraded source is visible data, not an empty healthy list"
    end

    def test_project_session_failure_is_visible_without_hiding_local_tasks
      sessions = Object.new
      def sessions.configured? = true
      def sessions.call = raise(Ace::Overseer::Error, "herdr unavailable")
      task = FakeTask.new(id: "8xs.t.pu0", status: "pending", title: "work", dependencies: [], subtasks: [])
      result = Ace::Overseer::Molecules::LocalSources.new(
        task_manager: FakeTaskManager.new({"next" => [task]}),
        worktree_manager: FakeWorktreeManager.new([]), project_sessions: sessions
      ).call
      assert_equal "degraded", result.fetch("sources").fetch("project_sessions").fetch("status")
      assert result.fetch("events").any? { |row| row["key"] == "source:project_sessions" }
      assert result.fetch("events").any? { |row| row["key"] == "task:8xs.t.pu0" }
    end

    def test_unavailable_project_session_degrades_source_but_keeps_healthy_rows
      sessions = Object.new
      def sessions.configured? = true
      def sessions.call
        [{"key" => "bad", "revision" => "bad-revision", "type" => "project-session", "state" => "unavailable"},
         {"key" => "good", "type" => "project-session", "state" => "working"}]
      end
      result = Ace::Overseer::Molecules::LocalSources.new(
        task_manager: FakeTaskManager.new({}), worktree_manager: FakeWorktreeManager.new([]),
        project_sessions: sessions
      ).call
      assert_equal "degraded", result.fetch("sources").fetch("project_sessions").fetch("status")
      assert_equal %w[bad good source:project_sessions], result.fetch("events").map { |row| row.fetch("key") }
    end

    def test_repeated_identical_failure_keeps_the_same_revision
      first = sources(worktree_error: "tmux socket gone").call
      second = sources(worktree_error: "another socket problem").call

      first_marker = first["events"].find { |row| row["key"] == "source:worktrees" }
      second_marker = second["events"].find { |row| row["key"] == "source:worktrees" }
      assert_equal first_marker["revision"], second_marker["revision"],
        "an identical failure class never re-wakes"
    end

    def test_task_failure_degrades_only_tasks
      failing = Object.new
      def failing.list(**)
        raise "task store unreadable"
      end

      result = Ace::Overseer::Molecules::LocalSources.new(
        task_manager: failing,
        worktree_manager: FakeWorktreeManager.new([]),
        probe_factory: ->(_path) { FakeProbe.new({config: nil, assignments: []}) }
      ).call

      assert_equal "degraded", result["sources"]["project_tasks"]["status"]
      assert_equal "degraded", result["sources"]["overseer_tasks"]["status"]
      assert_equal "ok", result["sources"]["worktrees"]["status"]
    end
  end
end
