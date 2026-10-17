# frozen_string_literal: true

require "tmpdir"
require_relative "../../test_helper"
require_relative "../../support/prune_git_fixtures"

class PruneSafetyCheckerTest < AceOverseerTestCase
  class FakeCollector
    def initialize(context)
      @context = context
    end

    def collect(_worktree_path)
      @context
    end
  end

  class FakeTaskManager
    def initialize(task_data)
      @task_data = task_data
    end

    def show(_task_ref)
      return nil unless @task_data

      FakeTask.new(@task_data[:status])
    end
  end

  FakeTask = Struct.new(:status)

  class StubPreservationChecker
    attr_reader :last_proof_args

    def initialize(preserved:)
      @preserved = preserved
      @last_proof_args = nil
    end

    def proof(**args)
      @last_proof_args = args
      if @preserved
        Ace::Overseer::Models::PreservationProof.preserved(:accepted_ancestor, head: "p" * 40)
      else
        Ace::Overseer::Models::PreservationProof.blocked("HEAD not contained in accepted base")
      end
    end
  end

  TERMINAL_STEPS = {"total" => 5, "done" => 5, "failed" => 0, "active" => 0, "pending" => 0}.freeze

  def completed_entry(state: "completed", summary: TERMINAL_STEPS)
    entry = {"assignment" => {"id" => "assign1", "state" => state}}
    entry["step_summary"] = summary unless summary.nil?
    entry
  end

  def build_context(worktree_path:, assignments: [completed_entry])
    Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: worktree_path,
      branch: "230-feature",
      assignments: assignments,
      git_status: {"clean" => true}
    )
  end

  def build_context_with_branch(worktree_path:, branch:, assignments: [completed_entry])
    Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: worktree_path,
      branch: branch,
      assignments: assignments,
      git_status: {"clean" => true}
    )
  end

  def build_checker(worktree_path:, context:, preserved: true, task_status: "done")
    Ace::Overseer::Molecules::PruneSafetyChecker.new(
      context_collector: FakeCollector.new(context),
      task_loader_factory: -> { FakeTaskManager.new({status: task_status}) },
      preservation_checker: StubPreservationChecker.new(preserved: preserved)
    )
  end

  def build_worktree
    repo = PruneGitFixtures::Repo.new(File.join(Dir.mktmpdir("prune-checker"), "source")).init
    repo.write("base.txt", "base\n")
    repo.commit("base")
    worktree = repo.add_worktree(File.join(repo.path, "..", "wt"), "task-work")
    [repo, worktree]
  end

  def accepted_base_for(repo)
    {branch: "main", head: repo.rev("main")}
  end

  def test_marks_candidate_safe_when_all_conditions_pass
    _repo, worktree = build_worktree
    checker = build_checker(worktree_path: worktree.path, context: build_context(worktree_path: worktree.path))

    candidate = checker.check(
      worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo)
    )

    assert candidate.safe_to_prune?
    assert_equal [], candidate.reasons
  end

  def test_includes_reasons_when_not_safe
    _repo, worktree = build_worktree
    context = build_context(
      worktree_path: worktree.path,
      assignments: [completed_entry(state: "running", summary: {"active" => 1, "pending" => 1})]
    )
    checker = build_checker(worktree_path: worktree.path, context: context, preserved: false, task_status: "in-progress")

    candidate = checker.check(worktree_path: worktree.path, task_ref: "231", accepted_base: accepted_base_for(_repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons, "assignment not complete"
    assert_includes candidate.reasons, "task not done"
    assert_includes candidate.reasons, "preservation not proven: HEAD not contained in accepted base"
  end

  def test_untracked_files_block_prune_as_work
    _repo, worktree = build_worktree
    File.write(File.join(worktree.path, "uncommitted-note.txt"), "untracked work\n")
    checker = build_checker(worktree_path: worktree.path, context: build_context(worktree_path: worktree.path))

    candidate = checker.check(worktree_path: worktree.path, task_ref: "232", accepted_base: accepted_base_for(_repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons, "git not clean"
  end

  def test_modified_tracked_files_block_prune
    _repo, worktree = build_worktree
    File.write(File.join(worktree.path, "base.txt"), "modified\n")
    checker = build_checker(worktree_path: worktree.path, context: build_context(worktree_path: worktree.path))

    candidate = checker.check(worktree_path: worktree.path, task_ref: "232", accepted_base: accepted_base_for(_repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons, "git not clean"
  end

  def test_active_local_step_blocks_prune
    _repo, worktree = build_worktree
    context = build_context(
      worktree_path: worktree.path,
      assignments: [completed_entry(summary: {"total" => 3, "done" => 2, "failed" => 0, "active" => 1, "pending" => 0})]
    )
    checker = build_checker(worktree_path: worktree.path, context: context)

    candidate = checker.check(
      worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo)
    )

    refute candidate.work_terminal
    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "1 active and 0 pending"
  end

  def test_pending_local_step_blocks_prune
    _repo, worktree = build_worktree
    context = build_context(
      worktree_path: worktree.path,
      assignments: [completed_entry(summary: {"total" => 1, "done" => 0, "failed" => 0, "active" => 0, "pending" => 1})]
    )
    checker = build_checker(worktree_path: worktree.path, context: context)

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "pending step"
  end

  def test_unreadable_local_step_state_blocks_prune
    _repo, worktree = build_worktree
    context = build_context(worktree_path: worktree.path, assignments: [completed_entry(summary: "not-a-summary")])
    checker = build_checker(worktree_path: worktree.path, context: context)

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "step state unreadable"
  end

  def test_one_running_assignment_blocks_even_when_another_completed
    _repo, worktree = build_worktree
    context = build_context(
      worktree_path: worktree.path,
      assignments: [completed_entry, completed_entry(state: "running", summary: {"active" => 1, "pending" => 0})]
    )
    checker = build_checker(worktree_path: worktree.path, context: context)

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo))

    refute candidate.assignment_complete
    refute candidate.safe_to_prune?
    assert_includes candidate.reasons, "assignment not complete"
  end

  def test_missing_task_record_is_not_proof_of_safety
    _repo, worktree = build_worktree
    checker = build_checker(worktree_path: worktree.path, context: build_context(worktree_path: worktree.path), task_status: nil)

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons, "task not done"
  end

  def test_detached_head_yields_no_verified_branch
    _repo, worktree = build_worktree
    worktree.git!("checkout", "-q", "--detach")
    detached_sha = worktree.rev("HEAD")
    context = build_context_with_branch(worktree_path: worktree.path, branch: detached_sha)
    checker = build_checker(worktree_path: worktree.path, context: context)

    candidate = checker.check(
      worktree_path: worktree.path, task_ref: "230", accepted_base: {branch: "main", head: "a" * 40}
    )

    assert candidate.preserved
    assert_nil candidate.verified_branch
    assert_equal "p" * 40, candidate.verified_head
  end

  def test_hex_named_branch_is_not_mistaken_for_detached_head
    repo = PruneGitFixtures::Repo.new(File.join(Dir.mktmpdir("prune-checker"), "hexrepo")).init
    repo.write("base.txt", "base\n")
    repo.commit("base")
    hex_branch = "b" * 40
    worktree = repo.add_worktree(File.join(repo.path, "..", "wt-hex"), nil)
    worktree.git!("checkout", "-q", "-b", hex_branch)

    checker = Ace::Overseer::Molecules::PruneSafetyChecker.new(
      context_collector: FakeCollector.new(
        build_context_with_branch(worktree_path: worktree.path, branch: hex_branch)
      ),
      task_loader_factory: -> { FakeTaskManager.new({status: "done"}) },
      preservation_checker: StubPreservationChecker.new(preserved: true)
    )

    candidate = checker.check(
      worktree_path: worktree.path, task_ref: "230", accepted_base: {branch: "main", head: "a" * 40}
    )

    assert candidate.preserved
    assert_equal hex_branch, candidate.verified_branch
  end

  def test_proof_receives_the_symbolic_branch_read_before_it
    _repo, worktree = build_worktree
    checker = build_checker(worktree_path: worktree.path, context: build_context(worktree_path: worktree.path))

    candidate = checker.check(
      worktree_path: worktree.path, task_ref: "230", accepted_base: {branch: "main", head: "a" * 40}
    )

    assert_equal "task-work", checker.preservation_checker.last_proof_args[:candidate_branch]
    assert_equal "task-work", candidate.verified_branch
  end

  def test_no_accepted_base_blocks_preservation
    _repo, worktree = build_worktree
    checker = build_checker(worktree_path: worktree.path, context: build_context(worktree_path: worktree.path))

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: nil)

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "no surviving accepted base"
  end
end
