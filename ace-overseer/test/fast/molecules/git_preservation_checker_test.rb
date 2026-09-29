# frozen_string_literal: true

require "tmpdir"
require_relative "../../test_helper"
require_relative "../../support/prune_git_fixtures"

class GitPreservationCheckerTest < AceOverseerTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("prune-proof")
    @checker = Ace::Overseer::Molecules::GitPreservationChecker.new
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  # Source repo with a task worktree holding unmerged work.
  def build_source
    source = PruneGitFixtures::Repo.new(File.join(@tmp, "source")).init
    source.write("base.txt", "base\n")
    source.commit("base")
    worktree = source.add_worktree(File.join(@tmp, "wt-task"), "task-work")
    [source, worktree]
  end

  # Successor repo whose main carries extra successor-only content, so a
  # cherry-picked landing has a different tree than the source HEAD and the
  # content-transition proof path is exercised (not tree equality).
  def build_successor(source)
    successor = source.clone_to(File.join(@tmp, "successor"))
    successor.checkout("main")
    successor.write("successor-only.txt", "successor\n")
    successor.commit("successor work")
    successor.checkout("landing", create: true)
    successor
  end

  def commit_work(repo, files)
    files.each { |relative, content| repo.write(relative, content) }
    repo.commit("task work")
  end

  def accepted_base_for(repo)
    @checker.accepted_base_for(repo.path)
  end

  def test_accepted_ancestor_preserves
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n"})
    source.checkout("main")
    source.git!("merge", "--no-ff", "--no-edit", "-q", "task-work")

    proof = @checker.proof(worktree_path: worktree.path, accepted_base: accepted_base_for(source))

    assert_predicate proof, :preserved?
    assert_equal :accepted_ancestor, proof.method
  end

  def test_unmerged_head_without_manifest_blocks
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n"})

    proof = @checker.proof(worktree_path: worktree.path, accepted_base: accepted_base_for(source))

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "not contained in accepted base"
  end

  def test_squash_migration_with_identical_tree_preserves_by_tree_equality
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n"})
    source_head = worktree.rev("HEAD")

    successor = source.clone_to(File.join(@tmp, "successor"))
    successor.checkout("main")
    successor.checkout("landing", create: true)
    FileUtils.cp_r(File.join(worktree.path, "feature.txt"), File.join(successor.path, "feature.txt"))
    successor.git!("add", "-A")
    successor.git!("commit", "-q", "-m", "squashed task work")
    destination_head = successor.rev("HEAD")
    refute_equal source_head, destination_head

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: destination_head)
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )

    assert_predicate proof, :preserved?
    assert_equal :tree_equality, proof.method
  end

  def test_cherry_picked_migration_preserves_by_content_transition
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n", "docs/a.md" => "doc\n"})
    source_head = worktree.rev("HEAD")

    successor = build_successor(source)
    successor.git!("cherry-pick", source_head)
    destination_head = successor.rev("HEAD")
    refute_equal source_head, destination_head

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: destination_head)
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )

    assert_predicate proof, :preserved?
    assert_equal :content_transition, proof.method
  end

  def test_matching_title_with_different_content_blocks
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n"})

    successor = build_successor(source)
    successor.write("feature.txt", "different content\n")
    successor.git!("commit", "--allow-empty", "-q", "-m", "task work")
    destination_head = successor.rev("HEAD")

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: destination_head)
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "differs from the source transition"
  end

  def test_unaccepted_destination_head_blocks
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n"})

    successor = build_successor(source)
    successor.git!("cherry-pick", worktree.rev("HEAD"))
    destination_head = successor.rev("HEAD")
    # Reset landing so the declared destination head is not on the branch.
    successor.git!("update-ref", "refs/heads/landing", successor.rev("main"))

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: destination_head)
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "not accepted on"
  end

  def test_changed_source_head_after_preview_blocks
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n"})

    successor = build_successor(source)
    successor.git!("cherry-pick", worktree.rev("HEAD"))

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: successor.rev("HEAD"))
    worktree.write("late.txt", "late change\n")
    worktree.commit("late change")

    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "does not match the candidate's current HEAD"
  end

  def test_declared_source_repo_must_be_the_candidates_common_repository
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n"})

    other = PruneGitFixtures::Repo.new(File.join(@tmp, "elsewhere")).init
    other.write("x", "x\n")
    other.commit("x")

    successor = build_successor(source)
    successor.git!("cherry-pick", worktree.rev("HEAD"))

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: successor.rev("HEAD"),
      source_repo: other.path)
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "is not the candidate's common repository"
  end

  def test_missing_independent_baseline_disables_patch_range_proof
    source, worktree = build_source
    commit_work(worktree, {"feature.txt" => "1\n"})

    successor = build_successor(source)
    successor.git!("cherry-pick", worktree.rev("HEAD"))

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: successor.rev("HEAD"))

    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: nil
    )

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "no independently recorded creation baseline"
  end

  def test_baseline_mismatch_blocks_patch_range_proof
    source, worktree = build_source
    source.checkout("main")
    source.write("distractor.txt", "d\n")
    source.commit("distractor")
    commit_work(worktree, {"feature.txt" => "1\n"})

    successor = build_successor(source)
    successor.git!("cherry-pick", worktree.rev("HEAD"))

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: successor.rev("HEAD"))

    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: source.rev("main")
    )

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "does not match the recorded creation baseline"
  end

  def test_unpreserved_baseline_blocks_even_with_matching_content
    source = PruneGitFixtures::Repo.new(File.join(@tmp, "source")).init
    source.write("base.txt", "base\n")
    base = source.commit("base")

    # The baseline carries unique committed work and is NOT on main.
    source.branch("baseline-line", base)
    baseline_repo = source.add_worktree(File.join(@tmp, "wt-baseline"), nil, "baseline-line")
    baseline_repo.write("unique.txt", "unique\n")
    baseline = baseline_repo.commit("baseline with unique work")

    # The task branches from that baseline, so its range starts there.
    worktree = source.add_worktree(File.join(@tmp, "wt-task"), "task-work", baseline)
    commit_work(worktree, {"feature.txt" => "1\n"})

    successor = source.clone_to(File.join(@tmp, "successor"))
    successor.checkout("main")
    successor.checkout("landing", create: true)
    successor.git!("cherry-pick", worktree.rev("HEAD"))

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: successor.rev("HEAD"),
      source_base: baseline)

    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: {branch: "main", head: source.rev("main")},
      manifest_record: record,
      recorded_base: baseline
    )

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "baseline"
    assert_includes proof.reason, "not preserved"
  end

  def test_empty_range_identity_is_not_proof
    source, worktree = build_source
    worktree.git!("commit", "-q", "--allow-empty", "-m", "empty task commit")
    head = worktree.rev("HEAD")
    refute_equal source.rev("main"), head

    successor = build_successor(source)
    successor.git!("commit", "-q", "--allow-empty", "-m", "task work")
    destination_head = successor.rev("HEAD")

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: destination_head,
      source_base: head, source_head: head)
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: head
    )

    refute_predicate proof, :preserved?
    assert_includes proof.reason, "empty-range"
  end

def test_squash_with_unrelated_destination_content_preserves_by_transition
  source, worktree = build_source
  worktree.write("a.txt", "1\n")
  worktree.commit("work one")
  worktree.write("b.txt", "2\n")
  worktree.commit("work two")
  worktree.write("c.txt", "3\n")
  worktree.commit("work three")
  source_head = worktree.rev("HEAD")

  successor = build_successor(source)
  # Squash all three commits into one landing commit.
  successor.git!("cherry-pick", "--no-commit", source_head + "~2")
  successor.git!("cherry-pick", "--no-commit", source_head + "~1")
  successor.git!("cherry-pick", "--no-commit", source_head)
  successor.git!("commit", "-q", "-m", "squashed task work")
  destination_head = successor.rev("HEAD")

  record = build_record(source, worktree, successor,
    destination_base: successor.rev("main"), destination_head: destination_head)
  proof = @checker.proof(
    worktree_path: worktree.path,
    accepted_base: accepted_base_for(source),
    manifest_record: record,
    recorded_base: record.resolved_source_base,
    candidate_branch: "task-work"
  )

  assert_predicate proof, :preserved?
  assert_equal :content_transition, proof.method
end

def test_destination_on_the_candidate_branch_is_rejected
  source, worktree = build_source
  commit_work(worktree, {"feature.txt" => "1\n"})
  source.checkout("main")
  source.git!("merge", "--no-ff", "--no-edit", "-q", "task-work")

  # Reset main so ancestry fails and the manifest path is exercised; the
  # declared destination is the candidate's own branch (task-work).
  source.git!("update-ref", "refs/heads/main", source.rev("main~1"))

  record = build_record(source, worktree, source,
    destination_base: worktree.rev("HEAD~1"), destination_head: worktree.rev("HEAD"),
    destination_branch: "refs/heads/task-work")
  proof = @checker.proof(
    worktree_path: worktree.path,
    accepted_base: {branch: "main", head: source.rev("main")},
    manifest_record: record,
    recorded_base: record.resolved_source_base,
    candidate_branch: "task-work"
  )

  refute_predicate proof, :preserved?
  assert_includes proof.reason, "scheduled for deletion"
end

  def test_binary_modes_and_symlinks_compare_exactly
    source, worktree = build_source
    worktree.write("blob.bin", [0x00, 0xFF, 0x13, 0x37].pack("C*"))
    worktree.write("script.sh", "#!/bin/sh\necho hi\n")
    worktree.chmod("script.sh", 0o755)
    worktree.symlink("link", "blob.bin")
    worktree.commit("rich content")
    source_head = worktree.rev("HEAD")

    successor = build_successor(source)
    successor.git!("cherry-pick", source_head)
    destination_head = successor.rev("HEAD")

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: destination_head)
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )
    assert_predicate proof, :preserved?

    # A single flipped binary byte must break the proof.
    tampered = source.clone_to(File.join(@tmp, "tampered"))
    tampered.checkout("main")
    tampered.write("successor-only.txt", "successor\n")
    tampered.commit("successor work")
    tampered.checkout("landing", create: true)
    tampered.checkout("task-work")
    tampered.write("blob.bin", [0x00, 0xFE, 0x13, 0x37].pack("C*"))
    tampered.git!("commit", "-q", "-a", "--amend", "--no-edit")
    tampered.checkout("landing")
    tampered.git!("cherry-pick", tampered.rev("task-work"))

    record = build_record(source, worktree, tampered,
      destination_base: tampered.rev("main"), destination_head: tampered.rev("landing"))
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )
    refute_predicate proof, :preserved?
    assert_includes proof.reason, "differs from the source transition"
  end

  def test_deleted_and_added_paths_compare
    source, worktree = build_source
    worktree.remove("base.txt")
    worktree.write("new.txt", "new\n")
    worktree.commit("delete and add")
    source_head = worktree.rev("HEAD")

    successor = build_successor(source)
    successor.git!("cherry-pick", source_head)

    record = build_record(source, worktree, successor,
      destination_base: successor.rev("main"), destination_head: successor.rev("HEAD"))
    proof = @checker.proof(
      worktree_path: worktree.path,
      accepted_base: accepted_base_for(source),
      manifest_record: record,
      recorded_base: record.resolved_source_base
    )

    assert_predicate proof, :preserved?
    assert_equal :content_transition, proof.method
  end

  private

  def build_record(source, worktree, successor, destination_base:, destination_head:,
    source_repo: source.path, source_base: worktree.git!("merge-base", "main", "task-work"), source_head: nil,
    destination_branch: "refs/heads/landing")
    worktree_path = File.realpath(worktree.path)
    source_repo_handle = source_repo == source.path ? source : PruneGitFixtures::Repo.new(source_repo)
    Ace::Overseer::Molecules::PreservationManifest::Record.new(
      worktree_path: worktree_path,
      source_repo: source_repo,
      source_base: source_base,
      source_head: source_head || worktree.rev("HEAD"),
      destination_repo: successor.path,
      destination_base: destination_base,
      destination_head: destination_head,
      destination_branch: destination_branch,
      resolved_source_base: source_repo_handle.rev(source_base),
      resolved_source_head: source_head || worktree.rev("HEAD"),
      resolved_destination_base: successor.rev(destination_base),
      resolved_destination_head: successor.rev(destination_head),
      resolved_destination_branch_tip: successor.rev(destination_branch)
    )
  end
end
