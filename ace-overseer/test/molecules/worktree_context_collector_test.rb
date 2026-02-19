# frozen_string_literal: true

require "tmpdir"
require_relative "../test_helper"

class WorktreeContextCollectorTest < AceOverseerTestCase
  FakeRepoStatus = Struct.new(:branch, :payload) do
    def to_h
      payload
    end
  end

  FakeQueueState = Struct.new(:summary_data) do
    def summary
      summary_data
    end
  end

  FakeAssignmentInfo = Struct.new(:id, :name, :state, :queue_state)

  class FakeDiscoverer
    def initialize(infos)
      @infos = infos
    end

    def find_all(include_completed: false)
      @infos
    end
  end

  class ErrorDiscoverer
    def find_all(include_completed: false)
      raise "boom"
    end
  end

  def make_info(id:, name:, state:, total: 5, done: 2, failed: 0, in_progress: 1, pending: 2)
    queue_state = FakeQueueState.new({ total: total, done: done, failed: failed, in_progress: in_progress, pending: pending })
    FakeAssignmentInfo.new(id, name, state, queue_state)
  end

  def test_collect_returns_context_with_assignments_and_git_status
    info = make_info(id: "8or5kx", name: "work-on-task-230", state: :running)

    Dir.mktmpdir("task.230") do |worktree|
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        repo_status_loader: -> { FakeRepoStatus.new("230-feature", { "clean" => true }) },
        assignment_discoverer_factory: -> { FakeDiscoverer.new([info]) }
      )

      context = collector.collect(worktree)

      assert_equal "230", context.task_id
      assert_equal "230-feature", context.branch
      assert_equal 1, context.assignments.size
      assert_equal "running", context.assignment_status.dig("assignment", "state")
      assert_equal "8or5kx", context.assignment_status.dig("assignment", "id")
      assert_equal true, context.git_status["clean"]
    end
  end

  def test_collect_returns_multiple_assignments
    infos = [
      make_info(id: "8pdt3d", name: "work-on-task-266", state: :stalled, total: 2, done: 0, failed: 0, in_progress: 0, pending: 2),
      make_info(id: "8pdtdb", name: "work-on-task-270", state: :completed, total: 10, done: 10, failed: 0, in_progress: 0, pending: 0)
    ]

    Dir.mktmpdir("task.266") do |worktree|
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        repo_status_loader: -> { FakeRepoStatus.new("266-feature", { "clean" => true }) },
        assignment_discoverer_factory: -> { FakeDiscoverer.new(infos) }
      )

      context = collector.collect(worktree)

      assert_equal 2, context.assignments.size
      assert_equal 2, context.assignment_count
      assert_equal "8pdt3d", context.assignments[0].dig("assignment", "id")
      assert_equal "8pdtdb", context.assignments[1].dig("assignment", "id")
      assert_equal 0, context.assignments[0].dig("phase_summary", "done")
      assert_equal 10, context.assignments[1].dig("phase_summary", "done")
    end
  end

  def test_collect_handles_no_assignments
    Dir.mktmpdir("task.231") do |worktree|
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        repo_status_loader: -> { FakeRepoStatus.new("231-feature", { "clean" => false }) },
        assignment_discoverer_factory: -> { FakeDiscoverer.new([]) }
      )

      context = collector.collect(worktree)

      assert_equal [], context.assignments
      assert_nil context.assignment_status
      assert_equal false, context.git_status["clean"]
    end
  end

  def test_collect_handles_discoverer_error
    Dir.mktmpdir("task.235") do |worktree|
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        repo_status_loader: -> { FakeRepoStatus.new("235-feature", { "clean" => true }) },
        assignment_discoverer_factory: -> { ErrorDiscoverer.new }
      )

      context = collector.collect(worktree)

      assert_equal [], context.assignments
      assert_equal 0, context.assignment_count
    end
  end

  def test_collect_sets_project_root_path_per_worktree_and_restores_it
    original_root = ENV["PROJECT_ROOT_PATH"]

    Dir.mktmpdir("task.232") do |worktree|
      captured_root = nil
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        repo_status_loader: -> {
          captured_root = ENV["PROJECT_ROOT_PATH"]
          FakeRepoStatus.new("232-feature", { "clean" => true })
        },
        assignment_discoverer_factory: -> { FakeDiscoverer.new([]) }
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
        repo_status_loader: -> { raise "boom" },
        assignment_discoverer_factory: -> { FakeDiscoverer.new([]) }
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
        repo_status_loader: -> { FakeRepoStatus.new("267-rename-something", { "clean" => true }) },
        assignment_discoverer_factory: -> { FakeDiscoverer.new([]) }
      )

      context = collector.collect(worktree)

      assert_equal "266", context.task_id
    end
  end

  def test_collect_passes_location_type
    Dir.mktmpdir("main-branch") do |worktree|
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        repo_status_loader: -> { FakeRepoStatus.new("main", { "clean" => true }) },
        assignment_discoverer_factory: -> { FakeDiscoverer.new([]) }
      )

      context = collector.collect(worktree, location_type: :main)

      assert_equal :main, context.location_type
    end
  end

  def test_collect_extracts_four_digit_task_ids_from_worktree_path
    Dir.mktmpdir("collector-root") do |root|
      worktree = File.join(root, "task.1234")
      Dir.mkdir(worktree)
      collector = Ace::Overseer::Molecules::WorktreeContextCollector.new(
        repo_status_loader: -> { FakeRepoStatus.new("1234-feature", { "clean" => true }) },
        assignment_discoverer_factory: -> { FakeDiscoverer.new([]) }
      )

      context = collector.collect(worktree)

      assert_equal "1234", context.task_id
    end
  end
end
