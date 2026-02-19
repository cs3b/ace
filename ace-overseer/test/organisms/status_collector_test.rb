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

  def test_collect_and_format
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignment_status: {
        "assignment" => { "state" => "running" },
        "current_phase" => { "number" => "020", "name" => "work-on-task" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
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
    assert_equal({ "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 },
                 payload[:worktrees][0][:phase_summary])
    assert_includes table, "Assign"
    assert_includes table, "230"
    assert_includes table, "2/5"
  end

  def test_collect_includes_main_branch_when_it_has_assignment
    worktree_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignment_status: {
        "assignment" => { "state" => "running" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
      git_status: { "clean" => true }
    )

    main_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "main",
      worktree_path: "/project",
      branch: "main",
      assignment_status: {
        "assignment" => { "state" => "completed", "id" => "xyz99" },
        "phase_summary" => { "total" => 3, "done" => 3, "failed" => 0, "in_progress" => 0, "pending" => 0 }
      },
      git_status: { "clean" => true },
      location_type: :main,
      assignment_count: 2
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

  def test_collect_excludes_main_branch_when_no_assignment
    worktree_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignment_status: {
        "assignment" => { "state" => "running" },
        "phase_summary" => { "total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2 }
      },
      git_status: { "clean" => true }
    )

    main_context = Ace::Overseer::Models::WorkContext.new(
      task_id: "main",
      worktree_path: "/project",
      branch: "main",
      assignment_status: nil,
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
