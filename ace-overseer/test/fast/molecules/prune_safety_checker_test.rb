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

    def initialize(preserved:, recorded_base: nil)
      @preserved = preserved
      @recorded_base = recorded_base
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

  def build_context(worktree_path:, assignments: [{"assignment" => {"id" => "assign1", "state" => "completed"}}])
    Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: worktree_path,
      branch: "230-feature",
      assignments: assignments,
      git_status: {"clean" => true}
    )
  end

def build_context_with_branch(worktree_path:, branch:, assignments: [{"assignment" => {"id" => "assign1", "state" => "completed"}}])
  Ace::Overseer::Models::WorkContext.new(
    task_id: "230",
    worktree_path: worktree_path,
    branch: branch,
    assignments: assignments,
    git_status: {"clean" => true}
  )
end

  def build_checker(worktree_path:, context:, preserved: true, attempts: [],
    attempt_store: nil, task_status: "done", recorded_base: "recordedbase" * 6)
    Ace::Overseer::Molecules::PruneSafetyChecker.new(
      context_collector: FakeCollector.new(context),
      task_loader_factory: -> { FakeTaskManager.new({status: task_status}) },
      preservation_checker: StubPreservationChecker.new(preserved: preserved, recorded_base: recorded_base),
      attempt_store_factory: ->(_cache_base) {
        attempt_store || FakeAttemptStore.new(attempts)
      }
    )
  end

  class FakeAttemptStore
    def initialize(attempts)
      @attempts = attempts
    end

    def list(_assignment_id)
      @attempts
    end
  end

  class FakeAttempt
    attr_reader :attempt_id, :state, :base_head

    def initialize(attempt_id:, state:, base_head:)
      @attempt_id = attempt_id
      @state = state
      @base_head = base_head
    end

    def binding
      Struct.new(:base_head).new(base_head)
    end

    def active?
      %w[reserved running].include?(state)
    end

    def uncertain?
      state == "uncertain"
    end
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
      assignments: [{"assignment" => {"id" => "assign1", "state" => "running"}}]
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

  def test_active_attempt_blocks_and_supplies_recorded_baseline
    _repo, worktree = build_worktree
    attempt = FakeAttempt.new(attempt_id: "at1", state: "running", base_head: "aa" * 20)
    checker = build_checker(
      worktree_path: worktree.path,
      context: build_context(worktree_path: worktree.path),
      attempts: [attempt]
    )

    candidate = checker.check(
      worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo)
    )

    refute candidate.attempts_terminal
    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "attempt at1"
    assert_equal "aa" * 20, checker.preservation_checker.last_proof_args[:recorded_base]
  end

  def test_uncertain_attempt_blocks_prune
    _repo, worktree = build_worktree
    attempt = FakeAttempt.new(attempt_id: "at2", state: "uncertain", base_head: "bb" * 20)
    checker = build_checker(
      worktree_path: worktree.path,
      context: build_context(worktree_path: worktree.path),
      attempts: [attempt]
    )

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "uncertain"
  end

  def test_unreadable_attempt_store_blocks_when_assignments_exist
    _repo, worktree = build_worktree
    checker = build_checker(
      worktree_path: worktree.path,
      context: build_context(worktree_path: worktree.path),
      attempt_store: nil,
      recorded_base: nil
    )
    # Point the factory at a cache base that does not exist.
    checker = Ace::Overseer::Molecules::PruneSafetyChecker.new(
      context_collector: FakeCollector.new(build_context(worktree_path: worktree.path)),
      task_loader_factory: -> { FakeTaskManager.new({status: "done"}) },
      preservation_checker: StubPreservationChecker.new(preserved: true),
      attempt_store_factory: ->(_cache_base) { raise Errno::ENOENT, "missing cache" }
    )

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(_repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "unreadable"
  end

  def test_journal_checkout_outside_evidence_ref_blocks_prune
    repo, worktree = build_worktree
    journal_checkout = File.join(worktree.path, ".ace-local", "assign", "evidence-checkout", "journal")
    repo.git!("worktree", "add", "-q", "--detach", journal_checkout)
    checker = build_checker(worktree_path: worktree.path, context: build_context(worktree_path: worktree.path))

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: accepted_base_for(repo))

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "refs/ace/execution"
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

  def test_no_accepted_base_blocks_preservation
    _repo, worktree = build_worktree
    checker = build_checker(worktree_path: worktree.path, context: build_context(worktree_path: worktree.path))

    candidate = checker.check(worktree_path: worktree.path, task_ref: "230", accepted_base: nil)

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "no surviving accepted base"
  end
end
