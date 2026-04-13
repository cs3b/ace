# frozen_string_literal: true

require "stringio"
require "tmpdir"
require_relative "../../test_helper"

class PruneCommandTest < AceOverseerTestCase
  class FakePruneOrchestrator
    attr_reader :calls

    def initialize(result:)
      @result = result
      @calls = []
    end

    def call(**kwargs)
      @calls << kwargs
      @result
    end
  end

  def test_progress_output_passed_when_not_quiet
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [], unsafe: [], pruned: [], failed: [], aborted: false}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    capture_io do
      command.call(quiet: false, dry_run: false, yes: true, debug: false)
    end

    assert_equal 1, orchestrator.calls.length
    refute_nil orchestrator.calls.first[:on_progress]
  end

  def test_force_option_passed_to_orchestrator
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [], unsafe: [], forced: [], pruned: [], failed: [], aborted: false}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    capture_io do
      command.call(quiet: false, dry_run: false, yes: true, debug: false, force: true)
    end

    assert_equal true, orchestrator.calls.first[:force]
  end

  def test_targets_passed_to_orchestrator
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [], unsafe: [], forced: [], pruned: [], failed: [], aborted: false}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    capture_io do
      command.call(quiet: false, dry_run: false, yes: true, debug: false, force: false, targets: ["230", "265"])
    end

    assert_equal ["230", "265"], orchestrator.calls.first[:targets]
  end

  def test_dry_run_shows_force_tag
    safe_candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "230", worktree_path: "/wt/task.230",
      assignment_complete: true, task_done: true, git_clean: true, reasons: []
    )
    forced_candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "231", worktree_path: "/wt/task.231",
      assignment_complete: false, task_done: false, git_clean: false, reasons: ["git not clean"]
    )
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: true, safe: [safe_candidate], unsafe: [forced_candidate], forced: [forced_candidate], pruned: [], failed: []}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    out, = capture_io do
      command.call(quiet: false, dry_run: true, yes: false, debug: false, force: true)
    end

    assert_includes out, "task.230"
    assert_includes out, "task.231"
    assert_includes out, "[FORCE]"
    assert_includes out, "2 worktree(s) can be pruned."
  end

  def test_assignment_option_forwarded_to_orchestrator
    orchestrator = FakePruneOrchestrator.new(
      result: {
        dry_run: true,
        assignment_candidate: Ace::Overseer::Models::AssignmentPruneCandidate.new(
          assignment_id: "abc12", assignment_name: "work-on-task-230",
          assignment_state: "completed", location_path: "/cache/abc12"
        ),
        pruned_assignments: []
      }
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    out, = capture_io do
      command.call(quiet: false, dry_run: true, yes: false, debug: false, assignment: "abc12")
    end

    assert_equal "abc12", orchestrator.calls.first[:assignment_id]
    assert_includes out, "abc12"
    assert_includes out, "completed"
  end

  def test_assignment_prune_shows_removed
    orchestrator = FakePruneOrchestrator.new(
      result: {
        dry_run: false,
        assignment_candidate: Ace::Overseer::Models::AssignmentPruneCandidate.new(
          assignment_id: "abc12", assignment_name: "work-on-task-230",
          assignment_state: "completed", location_path: "/cache/abc12"
        ),
        pruned_assignments: [Ace::Overseer::Models::AssignmentPruneCandidate.new(
          assignment_id: "abc12", assignment_name: "work-on-task-230",
          assignment_state: "completed", location_path: "/cache/abc12"
        )]
      }
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    out, = capture_io do
      command.call(quiet: false, dry_run: false, yes: true, debug: false, assignment: "abc12")
    end

    assert_includes out, "Removed assignment abc12"
  end

  def test_no_progress_output_in_quiet_mode
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [], unsafe: [], pruned: [], failed: [], aborted: false}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    capture_io do
      command.call(quiet: true, dry_run: false, yes: true, debug: false)
    end

    assert_nil orchestrator.calls.first[:on_progress]
  end

  def test_quiet_mode_still_executes_orchestrator
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: true, safe: [], unsafe: [], pruned: [], failed: []}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    output = capture_io do
      command.call(quiet: true, dry_run: true, yes: false, debug: false)
    end

    assert_equal 1, orchestrator.calls.length
    assert_equal "", output.first
  end

  def test_requires_git_repo_before_running
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: true, safe: [], unsafe: [], pruned: [], failed: []}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    Dir.mktmpdir("overseer-no-repo") do |dir|
      Dir.chdir(dir) do
        error = assert_raises(Ace::Support::Cli::Error) do
          command.call(quiet: false, dry_run: true, yes: false, debug: false)
        end

        assert_equal Ace::Overseer::Atoms::RepoGuard::MESSAGE, error.message
        assert_empty orchestrator.calls
      end
    end
  end
end
