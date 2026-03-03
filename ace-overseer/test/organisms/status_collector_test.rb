# frozen_string_literal: true

require_relative "../test_helper"

class StatusCollectorTest < AceOverseerTestCase
  FakeWorktree = Struct.new(:path, :task_id, :bare) do
    def initialize(path, task_id, bare = false)
      super(path, task_id, bare)
    end

    def task_associated?
      true
    end
  end

  NonTaskWorktree = Struct.new(:path, :task_id, :bare) do
    def initialize(path, task_id = nil, bare = false)
      super(path, task_id, bare)
    end

    def task_associated?
      false
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
    attr_reader :collect_assignments_only_calls

    def initialize(context, main_context: nil, quick_context: nil)
      @context = context
      @main_context = main_context
      @quick_context = quick_context
      @collect_assignments_only_calls = []
    end

    def collect(path, location_type: :worktree)
      location_type == :main ? @main_context : @context
    end

    def collect_assignments_only(path, cached_branch:, cached_git_status:, location_type: :worktree)
      @collect_assignments_only_calls << { path: path, cached_branch: cached_branch, location_type: location_type }
      @quick_context || @context
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

  def test_collect_quick_reuses_git_data_and_refreshes_assignments
    original_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8or5kx", state: "running")],
      git_status: { "clean" => true, "pr_metadata" => { "number" => 99 } }
    )

    updated_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8or5kx", state: "completed", total: 5, done: 5, failed: 0, in_progress: 0, pending: 0)],
      git_status: { "clean" => true, "pr_metadata" => { "number" => 99 } }
    )

    context_collector = FakeContextCollector.new(original_context, quick_context: updated_context)

    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: FakeWorktreeManager.new([FakeWorktree.new("/wt/ace-task.230", "230")]),
      context_collector: context_collector,
      project_root: nil
    )

    previous_snapshot = { contexts: [original_context] }
    snapshot = collector.collect_quick(previous_snapshot)

    assert_equal 1, snapshot[:contexts].length
    assert_equal 1, context_collector.collect_assignments_only_calls.length
    call = context_collector.collect_assignments_only_calls.first
    assert_equal "/wt/ace-task.230", call[:path]
    assert_equal "230-feature", call[:cached_branch]
  end

  def test_collect_quick_falls_back_to_full_collect_when_no_previous
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

    snapshot = collector.collect_quick({ contexts: [] })

    assert_equal 1, snapshot[:contexts].length
  end

  def test_collect_includes_non_task_worktree_with_assignments
    non_task_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "unknown",
      worktree_path: "/wt/ace-e2e-glm",
      branch: "ace-e2e-glm",
      assignments: [make_assignment(id: "glm01", state: "running")],
      git_status: { "clean" => true }
    )

    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: FakeWorktreeManager.new([NonTaskWorktree.new("/wt/ace-e2e-glm")]),
      context_collector: FakeContextCollector.new(non_task_context),
      project_root: "/project"
    )

    snapshot = collector.collect
    paths = snapshot[:contexts].map(&:worktree_path)

    assert_includes paths, "/wt/ace-e2e-glm"
  end

  def test_collect_excludes_non_task_worktree_without_assignments
    non_task_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "unknown",
      worktree_path: "/wt/ace-e2e-glm",
      branch: "ace-e2e-glm",
      assignments: [],
      git_status: { "clean" => true }
    )

    collector = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: FakeWorktreeManager.new([NonTaskWorktree.new("/wt/ace-e2e-glm")]),
      context_collector: FakeContextCollector.new(non_task_context),
      project_root: "/project"
    )

    snapshot = collector.collect
    paths = snapshot[:contexts].map(&:worktree_path)

    refute_includes paths, "/wt/ace-e2e-glm"
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
