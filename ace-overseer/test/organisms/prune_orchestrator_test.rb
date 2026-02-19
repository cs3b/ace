# frozen_string_literal: true

require "stringio"
require_relative "../test_helper"

class PruneOrchestratorTest < AceOverseerTestCase
  FakeWorktree = Struct.new(:path, :task_id) do
    def task_associated?
      true
    end
  end

  class FakeManager
    attr_reader :remove_calls

    def initialize(worktrees)
      @worktrees = worktrees
      @remove_calls = []
    end

    def list_all(**_options)
      { success: true, worktrees: @worktrees }
    end

    def remove(path, **options)
      @remove_calls << { path: path, options: options }
      { success: true }
    end
  end

  class FakeChecker
    def initialize(candidates)
      @candidates = candidates
      @index = 0
    end

    def check(**_kwargs)
      candidate = @candidates[@index]
      @index += 1
      candidate
    end
  end

  class FakeTmuxExecutor
    attr_reader :run_calls

    def initialize
      @run_calls = []
    end

    def run(cmd)
      @run_calls << cmd
      true
    end
  end

  def build_candidate(task_id:, safe:, reasons: [])
    Ace::Overseer::Models::PruneCandidate.new(
      task_id: task_id,
      worktree_path: "/wt/task.#{task_id}",
      assignment_complete: safe,
      task_done: safe,
      git_clean: safe,
      reasons: reasons
    )
  end

  def test_dry_run_does_not_remove
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new([build_candidate(task_id: "230", safe: true)])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: { "window_name_format" => "t{task_id}", "tmux_session_name" => "ace" }
    )

    result = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)

    assert_equal true, result[:dry_run]
    assert_equal 1, result[:safe].length
    assert_equal [], manager.remove_calls
  end

  def test_yes_prunes_only_safe_candidates
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new([
      build_candidate(task_id: "230", safe: true),
      build_candidate(task_id: "231", safe: false, reasons: ["git not clean"])
    ])
    tmux = FakeTmuxExecutor.new

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: tmux,
      config: { "window_name_format" => "t{task_id}", "tmux_session_name" => "ace" }
    )

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal false, result[:aborted]
    assert_equal 1, result[:pruned].length
    assert_equal 1, manager.remove_calls.length
    assert_equal "/wt/task.230", manager.remove_calls.first[:path]
    assert_equal true, manager.remove_calls.first[:options][:ignore_untracked]
    assert_equal false, manager.remove_calls.first[:options][:force]
    assert_equal 1, tmux.run_calls.length
  end

  def test_prompt_can_abort
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new([build_candidate(task_id: "230", safe: true)])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: { "window_name_format" => "t{task_id}", "tmux_session_name" => "ace" }
    )

    result = orchestrator.call(
      dry_run: false,
      yes: false,
      input: StringIO.new("n\n"),
      output: StringIO.new
    )

    assert_equal true, result[:aborted]
    assert_equal [], manager.remove_calls
  end
end
