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

  class SafeLabChecker
    def initialize(terminal: true)
      @terminal = terminal
    end

    def check(lab_client:, work_id:, preservation_proof: nil)
      if @terminal
        Struct.new(:safe?, :reason, keyword_init: true).new(safe?: true, reason: nil)
      else
        Struct.new(:safe?, :reason, keyword_init: true).new(safe?: false, reason: "lab work #{work_id} is running (active writer)")
      end
    end
  end

  class FakeLabClient
    attr_reader :calls

    def initialize(entry: nil)
      @calls = []
      @entry = entry
    end

    def call(*arguments, **options)
      @calls << {arguments: arguments, options: options}
      "destroyed"
    end

    def work_entry(_work_id)
      @entry
    end
  end

  class StubPreservationChecker
    def accepted_base_for(_repo)
      {branch: "main", head: "a" * 40}
    end

    def ancestry_proof(repo:, head:, accepted_base:)
      Ace::Overseer::Models::PreservationProof.preserved(:accepted_ancestor)
    end
  end

  def lab_command(client, checker: SafeLabChecker.new)
    Ace::Overseer::CLI::Commands::Prune.new(
      lab_client: client,
      lab_safety_checker: checker,
      preservation_checker: StubPreservationChecker.new
    )
  end

  def lab_entry(state: "completed")
    {"id" => "W321", "state" => state, "repo" => "/repos/x", "head" => "b" * 40, "branch" => "main"}
  end

  def test_lab_dry_run_classifies_without_destroying
    client = FakeLabClient.new(entry: lab_entry)
    command = lab_command(client)

    output = capture_io do
      command.call(runtime: "lab", targets: %w[W321], dry_run: true)
    end.first

    assert_includes output, "W321: safe"
    assert_empty client.calls
  end

  def test_lab_prune_requires_exact_work_and_confirmation
    command = lab_command(FakeLabClient.new(entry: lab_entry))

    error = assert_raises(Ace::Support::Cli::Error) { command.call(runtime: "lab", dry_run: true) }
    assert_equal "provide at least one exact Lab Work ID to prune", error.message

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(runtime: "lab", targets: ["W321"], dry_run: false, yes: false)
    end
    assert_equal "Lab prune requires --yes after reviewing --dry-run", error.message
  end

  def test_lab_prune_delegates_exact_destroy_to_lab
    client = FakeLabClient.new(entry: lab_entry)
    command = lab_command(client)

    output = capture_io do
      command.call(runtime: "lab", targets: ["W321"], dry_run: false, yes: true)
    end.first

    assert_equal %w[work destroy W321 --confirm], client.calls.first[:arguments]
    assert_equal false, client.calls.first[:options][:json]
    assert_includes output, "destroyed"
  end

  def test_lab_active_work_never_destroys
    client = FakeLabClient.new(entry: lab_entry(state: "running"))
    command = lab_command(client, checker: SafeLabChecker.new(terminal: false))

    error = assert_raises(Ace::Support::Cli::Error) do
      capture_io { command.call(runtime: "lab", targets: ["W321"], dry_run: false, yes: true) }
    end
    assert_includes error.message, "1 lab work(s) blocked"
    assert_empty client.calls

    output = capture_io do
      command.call(runtime: "lab", targets: ["W321"], dry_run: true)
    end.first
    assert_includes output, "BLOCKED"
    assert_includes output, "active writer"
  end

  def test_lab_undocumented_preservation_blocks
    client = FakeLabClient.new(entry: {"id" => "W321", "state" => "completed"})
    command = lab_command(client, checker: Ace::Overseer::Molecules::LabPruneSafetyChecker.new)

    output = capture_io do
      command.call(runtime: "lab", targets: ["W321"], dry_run: true)
    end.first

    assert_includes output, "BLOCKED"
    assert_includes output, "does not document preservation data"
  end

  def test_progress_output_passed_when_not_quiet
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [], unsafe: [], forced: [], pruned: [], failed: [], blocked: [], aborted: false}
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
      result: {dry_run: false, safe: [], unsafe: [], forced: [], pruned: [], failed: [], blocked: [], aborted: false}
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

  def test_preservation_manifest_forwarded_to_orchestrator
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: true, safe: [], unsafe: [], forced: [], pruned: [], failed: [], blocked: []}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    capture_io do
      command.call(quiet: false, dry_run: true, yes: false, preservation: "/tmp/dest.yml")
    end

    assert_equal "/tmp/dest.yml", orchestrator.calls.first[:preservation_manifest]
  end

  def test_dry_run_lists_blocked_candidates_with_reasons
    safe_candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "230", worktree_path: "/wt/task.230",
      assignment_complete: true, task_done: true, git_clean: true,
      attempts_terminal: true, preserved: true, reasons: []
    )
    blocked_candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "231", worktree_path: "/wt/task.231",
      assignment_complete: true, task_done: true, git_clean: false,
      attempts_terminal: true, preserved: false, reasons: ["git not clean"]
    )
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: true, safe: [safe_candidate], unsafe: [blocked_candidate], forced: [], pruned: [], failed: [], blocked: []}
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
    assert_includes out, "Blocked candidates:"
    assert_includes out, "task.231"
    assert_includes out, "git not clean"
    assert_includes out, "1 worktree(s) can be pruned; 1 blocked."
    refute_includes out, "[FORCE]"
  end

  def test_apply_with_blocked_candidates_exits_nonzero
    safe_candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "230", worktree_path: "/wt/task.230",
      assignment_complete: true, task_done: true, git_clean: true,
      attempts_terminal: true, preserved: true, reasons: []
    )
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [], unsafe: [safe_candidate], forced: [],
               pruned: [], failed: [], blocked: [{candidate: safe_candidate, reasons: ["git not clean"]}], aborted: false}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    error = assert_raises(Ace::Support::Cli::Error) do
      capture_io { command.call(quiet: false, dry_run: false, yes: true, debug: false) }
    end
    assert_includes error.message, "1 candidate(s) blocked or failed"
  end

  def test_apply_success_exits_zero
    pruned_candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "230", worktree_path: "/wt/task.230",
      assignment_complete: true, task_done: true, git_clean: true,
      attempts_terminal: true, preserved: true, reasons: []
    )
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [pruned_candidate], unsafe: [], forced: [],
               pruned: [pruned_candidate], failed: [], blocked: [], aborted: false}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    out, = capture_io do
      command.call(quiet: false, dry_run: false, yes: true, debug: false)
    end

    assert_includes out, "Removed worktree task.230"
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

  def test_assignment_blocked_exits_nonzero
    orchestrator = FakePruneOrchestrator.new(
      result: {
        dry_run: false,
        assignment_candidate: Ace::Overseer::Models::AssignmentPruneCandidate.new(
          assignment_id: "abc12", assignment_name: "work-on-task-230",
          assignment_state: "running", location_path: "/cache/abc12",
          attempts_terminal: false, reasons: ["attempt at1 is running"]
        ),
        pruned_assignments: [],
        blocked: true
      }
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    error = assert_raises(Ace::Support::Cli::Error) do
      capture_io { command.call(quiet: false, dry_run: false, yes: true, debug: false, assignment: "abc12") }
    end
    assert_includes error.message, "blocked"
    assert_includes error.message, "attempt at1 is running"
  end

  def test_no_progress_output_in_quiet_mode
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [], unsafe: [], forced: [], pruned: [], failed: [], blocked: [], aborted: false}
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

  def test_quiet_still_reports_results_and_failures
    pruned_candidate = Ace::Overseer::Models::PruneCandidate.new(
      task_id: "230", worktree_path: "/wt/task.230",
      assignment_complete: true, task_done: true, git_clean: true,
      attempts_terminal: true, preserved: true, reasons: []
    )
    orchestrator = FakePruneOrchestrator.new(
      result: {dry_run: false, safe: [], unsafe: [], forced: [],
               pruned: [pruned_candidate], failed: [], blocked: [{candidate: pruned_candidate, reasons: ["changed"]}], aborted: false}
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    out = capture_io do
      error = assert_raises(Ace::Support::Cli::Error) do
        command.call(quiet: true, dry_run: false, yes: true, debug: false)
      end
      assert_includes error.message, "blocked or failed"
    end.first

    assert_includes out, "Blocked after recheck: task.230: changed"
    assert_includes out, "1 worktree(s) pruned."
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
