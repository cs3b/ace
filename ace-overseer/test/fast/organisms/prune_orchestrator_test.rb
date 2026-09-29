# frozen_string_literal: true

require "stringio"
require "tmpdir"
require_relative "../../test_helper"

class PruneOrchestratorTest < AceOverseerTestCase
  FakeWorktree = Struct.new(:path, :task_id, :bare) do
    def initialize(path, task_id, bare = false)
      super
    end

    def task_associated?
      true
    end
  end

  NonTaskWorktree = Struct.new(:path, :task_id, :bare) do
    def initialize(path, task_id = nil, bare = false)
      super
    end

    def task_associated?
      false
    end
  end

  class FakeManager
    attr_reader :remove_calls, :prune_calls

    def initialize(worktrees)
      @worktrees = worktrees
      @remove_calls = []
      @prune_calls = 0
    end

    def list_all(**_options)
      {success: true, worktrees: @worktrees}
    end

    def prune
      @prune_calls += 1
      {success: true}
    end

    def remove(path, **options)
      @remove_calls << {path: path, options: options}
      {success: true}
    end
  end

  class FakeChecker
    # candidates: path (or default) => candidate or array of candidates
    # handed out in order per path (first call = preview, next = recheck).
    def initialize(candidates, default: nil)
      @by_path = candidates
      @default = default
      @checks = []
    end

    attr_reader :checks

    def check(worktree_path:, **_kwargs)
      entry = @by_path.fetch(worktree_path, @default)
      @checks << worktree_path
      case entry
      when Array
        entry.shift || entry.last
      else
        entry
      end
    end
  end

  class RaisingChecker
    def check(**_kwargs)
      raise "boom"
    end
  end

  class PathAwareChecker
    def initialize(candidate)
      @candidate = candidate
    end

    def check(worktree_path:, **_kwargs)
      raise Errno::ENOENT, worktree_path if worktree_path.include?("/missing/")

      @candidate
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

  class FakeExclusion
    attr_reader :exclusive_keys, :removed_keys

    def initialize
      @exclusive_keys = []
      @removed_keys = []
    end

    def with_exclusive(key)
      @exclusive_keys << key
      yield
    end

    def record_removed!(key)
      @removed_keys << key
    end

    def task_key(task_id) = "task:#{task_id}"
    def assignment_key(id) = "assignment:#{id}"
    def worktree_key(path) = "worktree:#{path}"
  end

  def build_candidate(task_id:, safe:, reasons: [], path: nil)
    Ace::Overseer::Models::PruneCandidate.new(
      task_id: task_id,
      worktree_path: path || "/wt/task.#{task_id}",
      assignment_complete: safe,
      task_done: safe,
      git_clean: safe,
      attempts_terminal: safe,
      preserved: safe,
      reasons: reasons
    )
  end

  def build_orchestrator(manager:, checker:, exclusion: FakeExclusion.new, config: {})
    Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: config,
      lifecycle_exclusion: exclusion
    )
  end

  def test_dry_run_does_not_remove_or_mutate_metadata
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new({"/wt/task.230" => build_candidate(task_id: "230", safe: true)})

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    result = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)

    assert_equal true, result[:dry_run]
    assert_equal 1, result[:safe].length
    assert_equal [], manager.remove_calls
    assert_equal 0, manager.prune_calls, "dry-run must not prune stale metadata"
  end

  def test_yes_prunes_only_safe_candidates_without_force_flags
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new({
      "/wt/task.230" => build_candidate(task_id: "230", safe: true),
      "/wt/task.231" => build_candidate(task_id: "231", safe: false, reasons: ["git not clean"])
    })
    exclusion = FakeExclusion.new
    tmux_run_calls = nil

    orchestrator = nil
    tmux = FakeTmuxExecutor.new
    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: tmux,
      config: {},
      lifecycle_exclusion: exclusion
    )

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal false, result[:aborted]
    assert_equal 1, result[:pruned].length
    assert_equal 1, manager.remove_calls.length
    assert_equal "/wt/task.230", manager.remove_calls.first[:path]
    assert_equal false, manager.remove_calls.first[:options][:ignore_untracked]
    assert_equal false, manager.remove_calls.first[:options][:delete_branch]
    assert_equal false, manager.remove_calls.first[:options][:force]
    assert_equal ["task:230"], exclusion.exclusive_keys
    assert_equal ["task:230"], exclusion.removed_keys
    kill_calls = tmux.run_calls.select { |c| c.include?("kill-window") }
    assert_equal 1, kill_calls.length
  end

  def test_force_cannot_prune_unsafe_candidates
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new({
      "/wt/task.230" => build_candidate(task_id: "230", safe: true),
      "/wt/task.231" => build_candidate(task_id: "231", safe: false, reasons: ["git not clean"])
    })

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    result = orchestrator.call(dry_run: false, yes: true, force: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal 1, result[:pruned].length
    assert_equal 1, manager.remove_calls.length
    assert_equal "/wt/task.230", manager.remove_calls.first[:path]
    assert_equal 1, result[:unsafe].length
    assert_empty result[:forced]
  end

  def test_force_skips_confirmation_for_safe_candidates
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new({"/wt/task.230" => build_candidate(task_id: "230", safe: true)})
    output = StringIO.new

    orchestrator = build_orchestrator(manager: manager, checker: checker)
    result = orchestrator.call(dry_run: false, yes: false, force: true, input: StringIO.new(""), output: output)

    refute_includes output.string, "Continue?"
    assert_equal 1, result[:pruned].length
  end

  def test_apply_rechecks_under_exclusion_and_blocks_changed_candidate
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    safe_candidate = build_candidate(task_id: "230", safe: true)
    changed_candidate = build_candidate(task_id: "230", safe: false, reasons: ["git not clean"])
    checker = FakeChecker.new({"/wt/task.230" => [safe_candidate, changed_candidate]})
    exclusion = FakeExclusion.new

    orchestrator = build_orchestrator(manager: manager, checker: checker, exclusion: exclusion)

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal 2, checker.checks.length, "apply must recheck under the exclusion"
    assert_empty result[:pruned]
    assert_empty manager.remove_calls
    assert_equal 1, result[:blocked].length
    assert_includes result[:blocked].first[:reasons].join(", "), "git not clean"
  end

  def test_mixed_batch_prunes_independent_safe_candidates_and_reports_blocked
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231")
    ])
    checker = FakeChecker.new({
      "/wt/task.230" => [
        build_candidate(task_id: "230", safe: true),
        build_candidate(task_id: "230", safe: false, reasons: ["preservation not proven: HEAD changed"])
      ],
      "/wt/task.231" => build_candidate(task_id: "231", safe: true)
    })

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal 1, result[:pruned].length
    assert_equal "231", result[:pruned].first.task_id
    assert_equal 1, result[:blocked].length
    assert_equal "230", result[:blocked].first[:candidate].task_id
  end

  def test_on_progress_receives_scanning_messages
    messages = []
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new({"/wt/task.230" => build_candidate(task_id: "230", safe: true)})

    orchestrator = build_orchestrator(manager: manager, checker: checker)

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
    checker = FakeChecker.new({
      "/wt/task.230" => build_candidate(task_id: "230", safe: true),
      "/wt/task.231" => build_candidate(task_id: "231", safe: false, reasons: ["task not done"])
    })

    orchestrator = build_orchestrator(manager: manager, checker: checker)

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

  def test_targets_filter_by_task_id
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.230", "230"),
      FakeWorktree.new("/wt/task.231", "231"),
      FakeWorktree.new("/wt/task.232", "232")
    ])
    checker = FakeChecker.new({
      "/wt/task.230" => build_candidate(task_id: "230", safe: true),
      "/wt/task.232" => build_candidate(task_id: "232", safe: true)
    })

    orchestrator = build_orchestrator(manager: manager, checker: checker)

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

  def test_unmatched_explicit_targets_are_errors
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new([])

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    error = assert_raises(Ace::Overseer::Error) do
      orchestrator.call(
        dry_run: true, yes: false, targets: ["nope"],
        input: StringIO.new(""), output: StringIO.new
      )
    end
    assert_includes error.message, "no worktree matches"
  end

  def test_empty_automatic_selection_is_a_noop
    manager = FakeManager.new([NonTaskWorktree.new("/wt/plain")])
    checker = FakeChecker.new([])

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_empty result[:pruned]
    assert_empty manager.remove_calls
  end

  def test_ignores_non_task_worktrees
    manager = FakeManager.new([
      NonTaskWorktree.new("/wt/ace-improve-review"),
      FakeWorktree.new("/wt/task.230", "230")
    ])
    checker = FakeChecker.new({"/wt/task.230" => build_candidate(task_id: "230", safe: true)})

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    result = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)

    assert_equal 1, result[:safe].length
    assert_equal "230", result[:safe].first.task_id
  end

  def test_marks_missing_worktree_paths_as_unsafe_without_crashing
    manager = FakeManager.new([
      FakeWorktree.new("/wt/task.236", "236"),
      FakeWorktree.new("/missing/task.237", "237")
    ])
    checker = PathAwareChecker.new(build_candidate(task_id: "236", safe: true))

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    result = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)

    assert_equal 1, result[:safe].length
    assert_equal 1, result[:unsafe].length
    assert_includes result[:unsafe].first.reasons.join(", "), "worktree directory missing"
  end

  def test_checker_errors_are_converted_to_unsafe_candidates
    Dir.mktmpdir("task.238") do |worktree|
      manager = FakeManager.new([FakeWorktree.new(worktree, "238")])
      checker = RaisingChecker.new

      orchestrator = build_orchestrator(manager: manager, checker: checker)

      result = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)

      assert_equal 0, result[:safe].length
      assert_equal 1, result[:unsafe].length
      assert_includes result[:unsafe].first.reasons.join(", "), "prune safety check failed"
    end
  end

  def test_prompt_can_abort
    manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
    checker = FakeChecker.new({"/wt/task.230" => build_candidate(task_id: "230", safe: true)})

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    result = orchestrator.call(
      dry_run: false,
      yes: false,
      input: StringIO.new("n\n"),
      output: StringIO.new
    )

    assert_equal true, result[:aborted]
    assert_equal [], manager.remove_calls
    assert_equal 0, manager.prune_calls, "aborting must not prune stale metadata"
  end

  def test_preservation_manifest_entries_must_match_selection
    Dir.mktmpdir("prune-manifest") do |tmp|
      manager = FakeManager.new([FakeWorktree.new("/wt/task.230", "230")])
      checker = FakeChecker.new({"/wt/task.230" => build_candidate(task_id: "230", safe: true)})
      manifest_path = File.join(tmp, "m.yml")
      File.write(manifest_path, YAML.dump("version" => 1, "candidates" => []))
      unmatched_record = Ace::Overseer::Molecules::PreservationManifest::Record.new(
        worktree_path: "/other/wt", source_repo: "/x", source_base: "a", source_head: "b",
        destination_repo: "/y", destination_base: "c", destination_head: "d",
        destination_branch: "refs/heads/main"
      )
      loader = ->(_path) { Ace::Overseer::Molecules::PreservationManifest.new([unmatched_record]) }

      orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
        worktree_manager: manager,
        prune_checker: checker,
        tmux_executor: FakeTmuxExecutor.new,
        config: {},
        lifecycle_exclusion: FakeExclusion.new,
        preservation_manifest_loader: loader
      )

      error = assert_raises(Ace::Overseer::Error) do
        orchestrator.call(
          dry_run: true, yes: false, preservation_manifest: manifest_path,
          input: StringIO.new(""), output: StringIO.new
        )
      end
      assert_includes error.message, "do not match"
    end
  end

  # === Assignment pruning tests ===

  class FakeAssignmentPruneChecker
    def initialize(candidate)
      @candidate = candidate
      @checks = 0
    end

    attr_reader :checks

    def check(assignment_id:)
      @checks += 1
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

  def build_assignment_orchestrator(checker:, mgr:, exclusion: FakeExclusion.new)
    Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: FakeManager.new([]),
      prune_checker: FakeChecker.new([]),
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      assignment_prune_checker: checker,
      assignment_manager: mgr,
      lifecycle_exclusion: exclusion
    )
  end

  def test_assignment_dry_run_returns_candidate
    candidate = build_assignment_candidate(id: "abc12", state: "completed", safe: true)
    checker = FakeAssignmentPruneChecker.new(candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = build_assignment_orchestrator(checker: checker, mgr: mgr)

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
    exclusion = FakeExclusion.new

    orchestrator = build_assignment_orchestrator(checker: checker, mgr: mgr, exclusion: exclusion)

    result = orchestrator.call(
      dry_run: false, yes: true, assignment_id: "abc12",
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal 1, result[:pruned_assignments].length
    assert_equal ["abc12"], mgr.delete_calls
    assert_equal 2, checker.checks, "must recheck under the exclusion before deletion"
    assert_equal ["assignment:abc12"], exclusion.exclusive_keys
    assert_equal ["assignment:abc12"], exclusion.removed_keys
  end

  def test_assignment_prune_blocked_even_with_force
    candidate = build_assignment_candidate(id: "abc12", state: "running", safe: false, reasons: ["assignment still running"])
    checker = FakeAssignmentPruneChecker.new(candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = build_assignment_orchestrator(checker: checker, mgr: mgr)

    result = orchestrator.call(
      dry_run: false, yes: true, force: true, assignment_id: "abc12",
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal true, result[:blocked]
    assert_empty result[:pruned_assignments]
    assert_empty mgr.delete_calls
  end

  def test_assignment_prune_recheck_blocks_changed_candidate
    safe_candidate = build_assignment_candidate(id: "abc12", state: "completed", safe: true)
    running_candidate = build_assignment_candidate(id: "abc12", state: "running", safe: false, reasons: ["attempt at1 is running"])
    checker = FakeChecker.new([])
    assignment_checker = Class.new do
      def initialize(first, second)
        @candidates = [first, second]
        @index = 0
      end

      def check(assignment_id:)
        candidate = @candidates[@index]
        @index += 1
        candidate
      end
    end.new(safe_candidate, running_candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: FakeManager.new([]),
      prune_checker: FakeChecker.new([]),
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      assignment_prune_checker: assignment_checker,
      assignment_manager: mgr,
      lifecycle_exclusion: FakeExclusion.new
    )

    result = orchestrator.call(
      dry_run: false, yes: true, assignment_id: "abc12",
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal true, result[:blocked]
    assert_empty mgr.delete_calls
  end

  def test_assignment_prune_abortable
    candidate = build_assignment_candidate(id: "abc12", state: "completed", safe: true)
    checker = FakeAssignmentPruneChecker.new(candidate)
    mgr = FakeAssignmentManager.new

    orchestrator = build_assignment_orchestrator(checker: checker, mgr: mgr)

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
      NonTaskWorktree.new("/home/mc/ace-e2e-glm", nil)
    ])
    non_task_candidate = build_candidate(task_id: "unknown", safe: true, path: "/home/mc/ace-e2e-glm")
    checker = FakeChecker.new({"/home/mc/ace-e2e-glm" => non_task_candidate})

    orchestrator = build_orchestrator(manager: manager, checker: checker)

    result = orchestrator.call(
      dry_run: false, yes: true, force: true, targets: ["ace-e2e-glm"],
      input: StringIO.new(""), output: StringIO.new
    )

    assert_equal 1, result[:pruned].length
    assert_equal "/home/mc/ace-e2e-glm", manager.remove_calls.first[:path]
  end
end
