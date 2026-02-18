# frozen_string_literal: true

require "tmpdir"
require_relative "../test_helper"

class PruneSafetyCheckerTest < AceOverseerTestCase
  class FakeCollector
    def initialize(context)
      @context = context
    end

    def collect(_worktree_path)
      @context
    end
  end

  class FakeTaskLoader
    def initialize(task)
      @task = task
    end

    def find_task_by_reference(_task_ref)
      @task
    end
  end

  def test_marks_candidate_safe_when_all_conditions_pass
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/tmp/task.230",
      branch: "230-feature",
      assignment_status: { "assignment" => { "state" => "completed" } },
      git_status: { "clean" => true }
    )

    Dir.mktmpdir("task.230") do |worktree|
      checker = Ace::Overseer::Molecules::PruneSafetyChecker.new(
        context_collector: FakeCollector.new(context),
        task_loader_factory: -> { FakeTaskLoader.new({ status: "done" }) }
      )

      candidate = checker.check(worktree_path: worktree, task_ref: "230")

      assert candidate.safe_to_prune?
      assert_equal [], candidate.reasons
    end
  end

  def test_includes_reasons_when_not_safe
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "231",
      worktree_path: "/tmp/task.231",
      branch: "231-feature",
      assignment_status: { "assignment" => { "state" => "running" } },
      git_status: { "clean" => false }
    )

    Dir.mktmpdir("task.231") do |worktree|
      checker = Ace::Overseer::Molecules::PruneSafetyChecker.new(
        context_collector: FakeCollector.new(context),
        task_loader_factory: -> { FakeTaskLoader.new({ status: "in-progress" }) }
      )

      candidate = checker.check(worktree_path: worktree, task_ref: "231")

      refute candidate.safe_to_prune?
      assert_includes candidate.reasons, "assignment not complete"
      assert_includes candidate.reasons, "task not done"
      assert_includes candidate.reasons, "git not clean"
    end
  end
end
