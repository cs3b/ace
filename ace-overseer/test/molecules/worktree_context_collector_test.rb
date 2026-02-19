# frozen_string_literal: true

require "tmpdir"
require_relative "../test_helper"

class WorktreeContextCollectorTest < AceOverseerTestCase
  FakeAssignment = Struct.new(:id, :name)
  FakeState = Struct.new(:assignment_state) do
    def summary
      { total: 5, done: 2, failed: 0, in_progress: 1, pending: 2 }
    end
  end
  FakePhase = Struct.new(:number, :name, :status, :skill)
  FakeRepoStatus = Struct.new(:branch, :payload) do
    def to_h
      payload
    end
  end

  class ActiveExecutor
    def status
      {
        assignment: FakeAssignment.new("8or5kx", "work-on-task-230"),
        state: FakeState.new(:running),
        current: FakePhase.new("020", "work-on-task", :in_progress, "ace:work-on-task")
      }
    end
  end

  class NoAssignmentExecutor
    def status
      raise Ace::Assign::NoActiveAssignmentError.new
    end
  end

  def test_collect_returns_context_with_assignment_and_git_status
    Dir.mktmpdir("task.230") do |worktree|
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        assignment_executor_factory: -> { ActiveExecutor.new },
        repo_status_loader: -> { FakeRepoStatus.new("230-feature", { "clean" => true }) }
      )

      context = collector.collect(worktree)

      assert_equal "230", context.task_id
      assert_equal "230-feature", context.branch
      assert_equal "running", context.assignment_status.dig("assignment", "state")
      assert_equal true, context.git_status["clean"]
    end
  end

  def test_collect_handles_no_active_assignment
    Dir.mktmpdir("task.231") do |worktree|
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        assignment_executor_factory: -> { NoAssignmentExecutor.new },
        repo_status_loader: -> { FakeRepoStatus.new("231-feature", { "clean" => false }) }
      )

      context = collector.collect(worktree)

      assert_nil context.assignment_status
      assert_equal false, context.git_status["clean"]
    end
  end

  def test_collect_sets_project_root_path_per_worktree_and_restores_it
    original_root = ENV["PROJECT_ROOT_PATH"]

    Dir.mktmpdir("task.232") do |worktree|
      captured_root = nil
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        assignment_executor_factory: -> {
          captured_root = ENV["PROJECT_ROOT_PATH"]
          NoAssignmentExecutor.new
        },
        repo_status_loader: -> { FakeRepoStatus.new("232-feature", { "clean" => true }) }
      )

      collector.collect(worktree)

      assert_equal worktree, captured_root
      assert_equal original_root, ENV["PROJECT_ROOT_PATH"]
    end
  end

  def test_collect_restores_project_root_path_on_error
    original_root = ENV["PROJECT_ROOT_PATH"]

    Dir.mktmpdir("task.233") do |worktree|
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        assignment_executor_factory: -> { raise "boom" },
        repo_status_loader: -> { FakeRepoStatus.new("233-feature", {}) }
      )

      assert_raises(RuntimeError) { collector.collect(worktree) }
      assert_equal original_root, ENV["PROJECT_ROOT_PATH"]
    end
  end

  def test_collect_extracts_task_id_from_ace_task_path
    Dir.mktmpdir("collector-root") do |root|
      worktree = File.join(root, "ace-task.266")
      Dir.mkdir(worktree)
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        assignment_executor_factory: -> { NoAssignmentExecutor.new },
        repo_status_loader: -> { FakeRepoStatus.new("267-rename-something", { "clean" => true }) }
      )

      context = collector.collect(worktree)

      assert_equal "266", context.task_id
    end
  end

  def test_collect_extracts_four_digit_task_ids_from_worktree_path
    Dir.mktmpdir("collector-root") do |root|
      worktree = File.join(root, "task.1234")
      Dir.mkdir(worktree)
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        assignment_executor_factory: -> { NoAssignmentExecutor.new },
        repo_status_loader: -> { FakeRepoStatus.new("1234-feature", { "clean" => true }) }
      )

      context = collector.collect(worktree)

      assert_equal "1234", context.task_id
    end
  end
end
