# frozen_string_literal: true

require_relative "../../test_helper"

module Molecules
  # Task 8xs.t.pu0.3: the standing local observation projects the six
  # source classes from their owners with stable keys/revisions, and a
  # failing source degrades only itself.
  class LocalSourcesTest < Minitest::Test
    FakeTask = Struct.new(:id, :status, :title, :dependencies, :subtasks, keyword_init: true)

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

    def sources(tasks: {}, worktrees: [], worktree_error: nil, probe: nil)
      Ace::Overseer::Molecules::LocalSources.new(
        task_manager: FakeTaskManager.new(tasks),
        worktree_manager: FakeWorktreeManager.new(worktrees, error: worktree_error),
        probe_factory: ->(_path) { probe || FakeProbe.new({config: nil, assignments: []}) }
      )
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

    def test_worktree_failure_degrades_only_the_worktree_dependent_sources
      result = sources(worktree_error: "tmux socket gone").call

      assert_equal "degraded", result["sources"]["worktrees"]["status"]
      assert_equal "degraded", result["sources"]["coworkers"]["status"]
      assert_equal "ok", result["sources"]["project_tasks"]["status"]
      assert_equal "ok", result["sources"]["overseer_tasks"]["status"]
      marker = result["events"].find { |row| row["type"] == "source-health" }
      refute_nil marker, "the degraded source is visible data, not an empty healthy list"
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
