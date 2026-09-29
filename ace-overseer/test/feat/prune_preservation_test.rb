# frozen_string_literal: true

require "stringio"
require "tmpdir"
require_relative "../test_helper"
require_relative "../support/prune_git_fixtures"

# Destructive-boundary integration tests: real Git repositories, real
# lifecycle exclusion, real preservation proofs. Proves that a safe
# controlled path actually removes a candidate, and that every blocked path
# preserves the candidate.
class PrunePreservationIntegrationTest < AceOverseerTestCase
  class StaticManager
    attr_reader :remove_calls, :prune_calls

    def initialize(worktrees, repo_root:)
      @worktrees = worktrees
      @repo_root = repo_root
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

    # Real removal through Git: no force, no untracked suppression.
    def remove(path, **options)
      @remove_calls << {path: path, options: options}
      _out, status = Open3.capture2("git", "-C", @repo_root, "worktree", "remove", path)
      status.success? ? {success: true} : {success: false, error: "git worktree remove failed"}
    end
  end

  class StaticCollector
    def initialize(assignments)
      @assignments = assignments
    end

    def collect(_worktree_path)
      Ace::Overseer::Models::WorkContext.new(
        task_id: "230",
        worktree_path: nil,
        branch: "task-work",
        assignments: @assignments,
        git_status: {"clean" => true}
      )
    end
  end

  class StaticTaskManager
    def show(_ref)
      Struct.new(:status).new("done")
    end
  end

  class FakeTmuxExecutor
    def run(_cmd)
      ""
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("prune-integration")
    @exclusion_root = File.join(@tmp, "exclusion")
    @exclusion = Ace::Assign::Molecules::LifecycleExclusion.new(root: @exclusion_root)

    @repo = PruneGitFixtures::Repo.new(File.join(@tmp, "source")).init
    @repo.write("base.txt", "base\n")
    @repo.commit("base")
    @worktree = @repo.add_worktree(File.join(@tmp, "wt-task"), "task-work")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def commit_and_merge_work
    @worktree.write("feature.txt", "1\n")
    @worktree.commit("task work")
    @repo.checkout("main")
    @repo.git!("merge", "--no-ff", "--no-edit", "-q", "task-work")
  end

  def worktree_entry
    FakeWorktreeEntry.new(@worktree.path, "230")
  end

  FakeWorktreeEntry = Struct.new(:path, :task_id, :bare) do
    def initialize(path, task_id, bare = false)
      super
    end

    def task_associated?
      true
    end
  end

  def build_orchestrator(manager)
    checker = Ace::Overseer::Molecules::PruneSafetyChecker.new(
      context_collector: StaticCollector.new([{"assignment" => {"id" => "assign1", "state" => "completed"}}]),
      task_loader_factory: -> { StaticTaskManager.new }
    )
    Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: manager,
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      lifecycle_exclusion: @exclusion
    )
  end

  def test_safe_candidate_is_actually_removed_with_its_branch
    commit_and_merge_work
    manager = StaticManager.new([worktree_entry], repo_root: @repo.path)
    orchestrator = build_orchestrator(manager)

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_equal 1, result[:pruned].length
    refute File.directory?(@worktree.path), "worktree must be gone"
    assert @exclusion.removed?(@exclusion.task_key("230")), "removal must be recorded"
    branches = @repo.git!("branch", "--format=%(refname:short)").split("\n")
    refute_includes branches, "task-work", "proven branch must be deleted"
    assert_includes branches, "main"
  end

  def test_unmerged_unsafe_candidate_is_preserved_even_with_force
    @worktree.write("feature.txt", "unmerged work\n")
    @worktree.commit("unmerged")
    manager = StaticManager.new([worktree_entry], repo_root: @repo.path)
    orchestrator = build_orchestrator(manager)

    result = orchestrator.call(dry_run: false, yes: true, force: true, input: StringIO.new(""), output: StringIO.new)

    assert_empty result[:pruned]
    assert_equal 1, result[:unsafe].length
    assert_includes result[:unsafe].first.reasons.join(" "), "preservation not proven"
    assert File.directory?(@worktree.path), "candidate must be preserved"
    branches = @repo.git!("branch", "--format=%(refname:short)").split("\n")
    assert_includes branches, "task-work"
  end

  def test_untracked_files_are_work_and_block_deletion
    commit_and_merge_work
    File.write(File.join(@worktree.path, "notes.txt"), "untracked work\n")
    manager = StaticManager.new([worktree_entry], repo_root: @repo.path)
    orchestrator = build_orchestrator(manager)

    result = orchestrator.call(dry_run: false, yes: true, force: true, input: StringIO.new(""), output: StringIO.new)

    assert_empty result[:pruned]
    assert File.directory?(@worktree.path)
    assert File.file?(File.join(@worktree.path, "notes.txt"))
  end

  def test_head_change_after_preview_blocks_the_candidate
    commit_and_merge_work
    manager = StaticManager.new([worktree_entry], repo_root: @repo.path)
    orchestrator = build_orchestrator(manager)

    preview = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)
    assert_equal 1, preview[:safe].length, "preview must classify as safe" #{preview[:unsafe].map(&:reasons).inspect}

    # A writer lands a late commit between preview and apply.
    @worktree.write("late.txt", "late change\n")
    @worktree.commit("late change")

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_empty result[:pruned]
    assert_empty result[:blocked]
    assert_equal 1, result[:unsafe].length
    assert_includes result[:unsafe].first.reasons.join(" "), "preservation not proven"
    assert File.directory?(@worktree.path), "changed candidate must be preserved"
  end

def test_accepted_base_reset_between_preview_and_apply_blocks_the_candidate
  commit_and_merge_work
  manager = StaticManager.new([worktree_entry], repo_root: @repo.path)
  orchestrator = build_orchestrator(manager)

  preview = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)
  assert_equal 1, preview[:safe].length, "preview must classify as safe"

  # The accepted base is reset after preview: the stale tip must not
  # authorize deletion inside the apply recheck.
  @repo.git!("update-ref", "refs/heads/main", @repo.rev("main~1"))

  result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

  assert_empty result[:pruned]
  assert_equal 1, result[:unsafe].length
  assert_includes result[:unsafe].first.reasons.join(" "), "preservation not proven"
  assert File.directory?(@worktree.path), "candidate must be preserved"
  assert @repo.git!("branch", "--format=%(refname:short)").split("
").include?("task-work")
end

def test_unresolvable_base_after_preview_blocks_the_candidate
  commit_and_merge_work
  manager = StaticManager.new([worktree_entry], repo_root: @repo.path)
  orchestrator = build_orchestrator(manager)

  preview = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)
  assert_equal 1, preview[:safe].length, "preview must classify as safe"

  # The main checkout detaches between preview and apply: the fresh base
  # cannot be resolved, so the apply must block instead of reusing the
  # stale pre-confirmation base.
  @repo.git!("checkout", "-q", "--detach")

  result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

  assert_empty result[:pruned]
  assert_equal 1, result[:unsafe].length
  assert_includes result[:unsafe].first.reasons.join(" "), "no surviving accepted base"
  assert File.directory?(@worktree.path), "candidate must be preserved"
end

def test_head_mismatch_after_recheck_preserves_worktree_and_branch
  commit_and_merge_work
  # A checker whose proven identity no longer matches the live worktree:
  # the pre-removal binding guard must catch the drift and preserve both.
  checker = PruneSafetyCheckerDouble.new(proven_head: "f" * 40)
  orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
    worktree_manager: StaticManager.new([worktree_entry], repo_root: @repo.path),
    prune_checker: checker,
    tmux_executor: FakeTmuxExecutor.new,
    config: {},
    lifecycle_exclusion: @exclusion
  )

  result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

  assert_empty result[:pruned]
  assert_equal 1, result[:failed].length
  assert_includes result[:failed].first[:error], "preserving"
  assert File.directory?(@worktree.path), "worktree must be preserved"
  assert @repo.git!("branch", "--format=%(refname:short)").split("
").include?("task-work")
end

# A minimal checker double: always safe, verifies a configurable identity.
class PruneSafetyCheckerDouble
  attr_reader :proven_head

  def initialize(proven_head:)
    @proven_head = proven_head
  end

  def check(worktree_path:, task_ref:, manifest_record: nil, accepted_base: nil)
    Ace::Overseer::Models::PruneCandidate.new(
      task_id: task_ref,
      worktree_path: worktree_path,
      assignment_complete: true,
      task_done: true,
      git_clean: true,
      attempts_terminal: true,
      preserved: true,
      verified_head: proven_head,
      verified_branch: "task-work",
      reasons: []
    )
  end
end

  def test_dry_run_changes_nothing
    commit_and_merge_work
    manager = StaticManager.new([worktree_entry], repo_root: @repo.path)
    orchestrator = build_orchestrator(manager)

    result = orchestrator.call(dry_run: true, yes: false, input: StringIO.new(""), output: StringIO.new)

    assert_equal 1, result[:safe].length, result[:unsafe].map(&:reasons).inspect
    assert_equal 0, manager.prune_calls, "dry-run must not mutate metadata"
    assert_equal 0, manager.remove_calls.length
    assert File.directory?(@worktree.path)
    refute @exclusion.removed?(@exclusion.task_key("230"))
  end

  def test_branch_identity_change_preserves_branch_after_worktree_removal_boundary
    commit_and_merge_work
    manager = StaticManager.new([worktree_entry], repo_root: @repo.path)
    checker = Ace::Overseer::Molecules::PruneSafetyChecker.new(
      context_collector: StaticCollector.new([{"assignment" => {"id" => "assign1", "state" => "completed"}}]),
      task_loader_factory: -> { StaticTaskManager.new }
    )

    # Intercept between worktree removal and branch deletion: the branch tip
    # is moved to a different commit, so the identity recheck must preserve
    # the branch instead of deleting it.
    orchestrator = Ace::Overseer::Organisms::PruneOrchestrator.new(
      worktree_manager: InterceptingManager.new(manager, before_branch_delete: -> {
        @repo.git!("update-ref", "refs/heads/task-work", @repo.rev("main~0"))
      }),
      prune_checker: checker,
      tmux_executor: FakeTmuxExecutor.new,
      config: {},
      lifecycle_exclusion: @exclusion
    )

    result = orchestrator.call(dry_run: false, yes: true, input: StringIO.new(""), output: StringIO.new)

    assert_empty result[:pruned]
    assert_equal 1, result[:failed].length, result.inspect
    assert_includes result[:failed].first[:error], "changed after preview"
    branches = @repo.git!("branch", "--format=%(refname:short)").split("\n")
    assert_includes branches, "task-work", "branch must survive a failed deletion boundary"
  end

  class InterceptingManager < SimpleDelegator
    def initialize(inner, before_branch_delete:)
      super(inner)
      @before_branch_delete = before_branch_delete
    end

    def remove(path, **options)
      result = __getobj__.remove(path, **options)
      @before_branch_delete.call if result[:success]
      result
    end
  end
end
