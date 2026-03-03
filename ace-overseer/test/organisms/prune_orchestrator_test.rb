# frozen_string_literal: true

require "stringio"
require_relative "../test_helper"

class PruneOrchestratorTest < AceOverseerTestCase
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

    def initialize(session_name: "test-session")
      @session_name = session_name
      @run_calls = []
    end

    def run(cmd)
      @run_calls << cmd
      cmd.include?("display-message") ? @session_name : true
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
      config: {}
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
      config: {}
    )

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal false, result[:aborted]
    assert_equal 1, result[:pruned].length
    assert_equal 1, manager.remove_calls.length
    assert_equal "/wt/task.230", manager.remove_calls.first[:path]
    assert_equal true, manager.remove_calls.first[:options][:ignore_untracked]
    assert_equal true, manager.remove_calls.first[:options][:delete_branch]
    assert_equal false, manager.remove_calls.first[:options][:force]
    kill_calls = tmux.run_calls.select { |c| c.include?("kill-window") }
    assert_equal 1, kill_calls.length
  end

  def test_on_progress_receives_scanning_messages
    messages = []
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new([build_candidate(task_id: "230", safe: true)])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    orchestrator.call(
      dry_run: false, yes: true,
      input: StringIO.new(""), output: StringIO.new,
      on_progress: ->(msg) { messages << msg }
    )

    assert messages.any? { |m| m.include?("Scanning") }
    assert messages.any? { |m| m.include?("Checking") }
  end

  def test_candidates_displayed_before_confirmation_prompt
    output = StringIO.new
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new([
      build_candidate(task_id: "230", safe: true),
      build_candidate(task_id: "231", safe: false, reasons: ["task not done"])
    ])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    orchestrator.call(
      dry_run: false, yes: false,
      input: StringIO.new("n\n"), output: output
    )

    text = output.string
    safe_pos = text.index("Safe to prune")
    skip_pos = text.index("Skipping")
    prompt_pos = text.index("Continue?")

    assert safe_pos, "Expected 'Safe to prune' in output"
    assert skip_pos, "Expected 'Skipping' in output"
    assert prompt_pos, "Expected 'Continue?' in output"
    assert safe_pos < prompt_pos, "Candidates should appear before prompt"
    assert skip_pos < prompt_pos, "Skipped items should appear before prompt"
    assert_includes text, "task.230"
    assert_includes text, "task.231"
    assert_includes text, "task not done"
  end

  def test_force_prunes_unsafe_candidates
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
      config: {}
    )

    result = orchestrator.call(dry_run: false, yes: true, force: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal 2, result[:pruned].length
    assert_equal 2, manager.remove_calls.length
    assert_equal true, manager.remove_calls.first[:options][:force]
    assert_equal true, manager.remove_calls.first[:options][:delete_branch]
    assert_equal true, manager.remove_calls.last[:options][:force]
    assert_equal true, manager.remove_calls.last[:options][:delete_branch]
    kill_calls = tmux.run_calls.select { |c| c.include?("kill-window") }
    assert_equal 2, kill_calls.length
  end

  def test_force_passes_force_to_worktree_manager
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new([build_candidate(task_id: "230", safe: true)])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    orchestrator.call(dry_run: false, yes: true, force: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal true, manager.remove_calls.first[:options][:force]
    assert_equal true, manager.remove_calls.first[:options][:delete_branch]
  end

  def test_targets_filter_by_task_id
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231"),
      FakeWorktree.new("/wt/task.232", "232")
    ])
    checker = FakeChecker.new([
      build_candidate(task_id: "230", safe: true),
      build_candidate(task_id: "232", safe: true)
    ])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    result = orchestrator.call(
      dry_run: false, yes: true, targets: ["230", "232"],
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal 2, result[:pruned].length
    paths = manager.remove_calls.map { |c| c[:path] }
    assert_includes paths, "/wt/task.230"
    assert_includes paths, "/wt/task.232"
    refute_includes paths, "/wt/task.231"
  end

  def test_targets_filter_by_path_substring
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new([
      build_candidate(task_id: "231", safe: true)
    ])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    result = orchestrator.call(
      dry_run: false, yes: true, targets: ["task.231"],
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal 1, result[:pruned].length
    assert_equal "/wt/task.231", manager.remove_calls.first[:path]
  end

  def test_force_with_targets
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new([
      build_candidate(task_id: "230", safe: false, reasons: ["task not done"])
    ])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    result = orchestrator.call(
      dry_run: false, yes: true, force: true, targets: ["230"],
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal 1, result[:pruned].length
    assert_equal "/wt/task.230", manager.remove_calls.first[:path]
    assert_equal true, manager.remove_calls.first[:options][:force]
    assert_equal true, manager.remove_calls.first[:options][:delete_branch]
  end

  def test_force_dry_run_shows_forced_candidates
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new([
      build_candidate(task_id: "230", safe: true),
      build_candidate(task_id: "231", safe: false, reasons: ["git not clean"])
    ])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    result = orchestrator.call(dry_run: true, yes: false, force: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal 1, result[:safe].length
    assert_equal 1, result[:forced].length
    assert_equal "231", result[:forced].first.task_id
  end

  def test_force_display_shows_force_removing
    output = StringIO.new
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new([
      build_candidate(task_id: "230", safe: true),
      build_candidate(task_id: "231", safe: false, reasons: ["task not done"])
    ])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    orchestrator.call(dry_run: false, yes: true, force: true, input: StringIO.new(""), output: output)

    text = output.string
    assert_includes text, "Force removing"
    refute_includes text, "Skipping"
  end

  # === Assignment pruning tests ===

  class FakeAssignmentPruneChecker
    def initialize(candidate)
      @candidate = candidate
    end

    def check(assignment_id:)
      @candidate
    end
  end

  class FakeAssignmentManager
    attr_reader :delete_calls

    def initialize(success: true)
      @success = success
      @delete_calls = []
    end

    def delete(assignment_id)
      @delete_calls << assignment_id
      @success
    end
  end

  def build_assignment_candidate(id:, state:, safe:, reasons: [])
    Ace::Overseer::Models::AssignmentPruneCandidate.new(
      assignment_id: id,
      assignment_name: "work-on-task-230",
      assignment_state: state,
      location_path: "/cache/#{id}",
      reasons: reasons
    )
  end

  def test_assignment_dry_run_returns_candidate
    candidate = build_assignment_candidate(id: "abc12", state: "completed", safe: true)
    checker = FakeAssignmentPruneChecker.new(candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: FakeManager.new([]),
      prune_checker: FakeChecker.new([]),
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      assignment_prune_checker: checker,
      assignment_manager: mgr
    )

    result = orchestrator.call(
      dry_run: true, yes: false, assignment_id: "abc12",
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal true, result[:dry_run]
    assert_equal "abc12", result[:assignment_candidate].assignment_id
    assert_empty result[:pruned_assignments]
    assert_empty mgr.delete_calls
  end

  def test_assignment_prune_with_yes
    candidate = build_assignment_candidate(id: "abc12", state: "completed", safe: true)
    checker = FakeAssignmentPruneChecker.new(candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: FakeManager.new([]),
      prune_checker: FakeChecker.new([]),
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      assignment_prune_checker: checker,
      assignment_manager: mgr
    )

    result = orchestrator.call(
      dry_run: false, yes: true, assignment_id: "abc12",
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal 1, result[:pruned_assignments].length
    assert_equal ["abc12"], mgr.delete_calls
  end

  def test_assignment_prune_blocked_without_force
    candidate = build_assignment_candidate(id: "abc12", state: "running", safe: false, reasons: ["assignment still running"])
    checker = FakeAssignmentPruneChecker.new(candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: FakeManager.new([]),
      prune_checker: FakeChecker.new([]),
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      assignment_prune_checker: checker,
      assignment_manager: mgr
    )

    result = orchestrator.call(
      dry_run: false, yes: true, assignment_id: "abc12",
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal true, result[:blocked]
    assert_empty result[:pruned_assignments]
    assert_empty mgr.delete_calls
  end

  def test_assignment_prune_force_override
    candidate = build_assignment_candidate(id: "abc12", state: "running", safe: false, reasons: ["assignment still running"])
    checker = FakeAssignmentPruneChecker.new(candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: FakeManager.new([]),
      prune_checker: FakeChecker.new([]),
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      assignment_prune_checker: checker,
      assignment_manager: mgr
    )

    result = orchestrator.call(
      dry_run: false, yes: true, force: true, assignment_id: "abc12",
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal 1, result[:pruned_assignments].length
    assert_equal ["abc12"], mgr.delete_calls
  end

  def test_assignment_prune_abortable
    candidate = build_assignment_candidate(id: "abc12", state: "completed", safe: true)
    checker = FakeAssignmentPruneChecker.new(candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: FakeManager.new([]),
      prune_checker: FakeChecker.new([]),
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      assignment_prune_checker: checker,
      assignment_manager: mgr
    )

    result = orchestrator.call(
      dry_run: false, yes: false, assignment_id: "abc12",
      input: StringIO.new("n\n"), output: StringIO.new
    )

    assert_equal true, result[:aborted]
    assert_empty mgr.delete_calls
  end

  def test_non_task_worktree_can_be_pruned_when_targeted_by_path
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      NonTaskWorktree.new("/home/mc/ace-e2e-glm")
    ])
    non_task_candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "unknown",
      worktree_path: "/home/mc/ace-e2e-glm",
      assignment_complete: true,
      task_done: true,
      git_clean: true,
      reasons: []
    )
    checker = FakeChecker.new([non_task_candidate])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
    )

    result = orchestrator.call(
      dry_run: false, yes: true, force: true, targets: ["ace-e2e-glm"],
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal 1, result[:pruned].length
    assert_equal "/home/mc/ace-e2e-glm", manager.remove_calls.first[:path]
  end

  def test_prompt_can_abort
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new([build_candidate(task_id: "230", safe: true)])

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {}
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
