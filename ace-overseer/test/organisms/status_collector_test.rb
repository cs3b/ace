# frozen_string_literal: true

require_relative "../test_helper"

class StatusCollectorTest < AceOverseerTestCase
  FakeWorktree = Struct.new(:path, :task_id) do
    def task_associated?
      true
    end
  end

  class FakeWorktreeManager
    def initialize(worktrees)
      @worktrees = worktrees
    end

    def list_all(**_options)
      { success: true, worktrees: @worktrees }
    end
  end

  class FakeContextCollector
    def initialize(context, main_context: nil)
      @context = context
      @main_context = main_context
    end

    def collect(path, location_type: :worktree)
      location_type == :main ? @main_context : @context
    end
  end

  def make_assignment(id:, state:, name: "work-on-task", total: 5, done: 2, failed: 0, in_progress: 1, pending: 2)
    {
      "assignment" => { "state" => state, "id" => id, "name" => name },
      "phase_summary" => { "total" => total, "done" => done, "failed" => failed, "in_progress" => in_progress, "pending" => pending }
    }
  end

  def test_collect_and_format
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8or5kx", state: "running")],
      git_status: { "clean" => true }
    )

    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: FakeWorktreeManager.new([FakeWorktree.new("/wt/ace-task.230", "230")]),
      context_collector: FakeContextCollector.new(context),
      project_root: nil
    )

    snapshot = collector.collect
    payload = collector.to_h(snapshot)
    table = collector.to_table(snapshot)

    assert_equal 1, payload[:worktrees].length
    assert_equal "230", payload[:worktrees][0][:task_id]
    assert_equal 1, payload[:worktrees][0][:assignments].length
    assert_includes table, "ace-task.230"
    assert_includes table, "8or5kx"
    assert_includes table, "2/5"
  end

  def test_collect_includes_main_branch_when_it_has_assignments
    worktree_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8or5kx", state: "running")],
      git_status: { "clean" => true }
    )

    main_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "main",
      worktree_path: "/project",
      branch: "main",
      assignments: [
        make_assignment(id: "xyz99", state: "completed", total: 3, done: 3, failed: 0, in_progress: 0, pending: 0),
        make_assignment(id: "abc12", state: "running", total: 5, done: 1, failed: 0, in_progress: 1, pending: 3)
      ],
      git_status: { "clean" => true },
      location_type: :main
    )

    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: FakeWorktreeManager.new([FakeWorktree.new("/wt/ace-task.230", "230")]),
      context_collector: FakeContextCollector.new(worktree_context, main_context: main_context),
      project_root: "/project"
    )

    snapshot = collector.collect

    assert_equal 2, snapshot[:contexts].length
    assert_equal :main, snapshot[:contexts].first.location_type
  end

  def test_collect_excludes_main_branch_when_no_assignments
    worktree_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8or5kx", state: "running")],
      git_status: { "clean" => true }
    )

    main_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "main",
      worktree_path: "/project",
      branch: "main",
      assignments: [],
      git_status: { "clean" => true },
      location_type: :main
    )

    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: FakeWorktreeManager.new([FakeWorktree.new("/wt/ace-task.230", "230")]),
      context_collector: FakeContextCollector.new(worktree_context, main_context: main_context),
      project_root: "/project"
    )

    snapshot = collector.collect

    assert_equal 1, snapshot[:contexts].length
    assert_equal "230", snapshot[:contexts].first.task_id
  end
end
