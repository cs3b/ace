# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/worktree_repo_fixture"

class WorktreeProbeTest < Minitest::Test
  include WorktreeRepoFixture

  def setup
    @repo = build_repo
    write_task(@repo, "8xa.t.ega-alpha", id: "8xa.t.ega")
    commit_file(@repo, "README.md", "root\n", message: "root commit")
    @main_sha = git_output("-C", @repo, "rev-parse", "HEAD").strip
    @probe_class = Ace::Git::Worktree::Molecules::WorktreeProbe
  end

  def teardown
    remove_repo(@repo)
  end

  def probe_for(worktree_path, base_ref: @main_sha)
    @probe_class.new(project_root: @repo, base_ref: base_ref).probe(worktree_path)
  end

  def test_reports_head_metadata
    wt = create_worktree(@repo, "fresh", branch: "fresh")
    commit_file(wt, "work.txt", "work\n", message: "feat: work", date: Time.utc(2026, 10, 17, 10, 0, 0))

    payload = probe_for(wt)

    assert_equal "feat: work", payload[:head_subject]
    assert_equal Time.utc(2026, 10, 17, 10, 0, 0).to_i, payload[:head_committer_epoch]
    assert_equal 40, payload[:head_sha].length
  end

  def test_clean_worktree_has_zero_changes
    wt = create_worktree(@repo, "clean", branch: "clean")
    payload = probe_for(wt)

    assert_equal 0, payload[:staged]
    assert_equal 0, payload[:unstaged]
    assert_equal 0, payload[:untracked]
    assert_empty payload[:changed_task_files]
    assert_empty payload[:committed_task_files]
  end

  def test_uncommitted_changes_are_counted
    wt = create_worktree(@repo, "dirty", branch: "dirty")
    write_file(wt, "README.md", "modified\n")
    write_file(wt, "staged.txt", "staged\n")
    git!("-C", wt, "add", "staged.txt")

    payload = probe_for(wt)

    assert_equal 1, payload[:staged]
    assert_equal 1, payload[:unstaged]
    assert_equal 0, payload[:untracked]
    refute_includes payload[:uncommitted_paths], "untracked.txt"
  end

  def test_untracked_files_outside_task_tree_are_not_scanned
    wt = create_worktree(@repo, "dirty", branch: "dirty")
    write_file(wt, "untracked.txt", "x\n")

    payload = probe_for(wt)

    assert_equal 0, payload[:untracked]
    assert_empty payload[:uncommitted_paths]
  end

  def test_untracked_task_files_are_detected_selectively
    wt = create_worktree(@repo, "task-dirty", branch: "task-dirty")
    write_file(wt, ".ace-tasks/8xa.t.ega-alpha/notes.md", "note\n")
    write_file(wt, "stray.txt", "stray\n")

    probe = @probe_class.new(project_root: @repo, base_ref: @main_sha)
    paths = probe.untracked_task_files(wt)

    assert_includes paths, ".ace-tasks/8xa.t.ega-alpha/notes.md"
    assert_equal [".ace-tasks/8xa.t.ega-alpha/notes.md"], paths
  end

  def test_untracked_task_files_on_missing_worktree_is_empty
    probe = @probe_class.new(project_root: @repo, base_ref: @main_sha)

    assert_empty probe.untracked_task_files(File.join(@repo, "does-not-exist"))
  end

  def test_modified_tracked_task_files_are_detected
    wt = create_worktree(@repo, "task-dirty", branch: "task-dirty")
    commit_file(wt, ".ace-tasks/8xa.t.ega-alpha/spec.md", "base\n", message: "chore: add spec")
    write_file(wt, ".ace-tasks/8xa.t.ega-alpha/spec.md", "changed\n")

    payload = probe_for(wt)

    assert_includes payload[:changed_task_files], ".ace-tasks/8xa.t.ega-alpha/spec.md"
  end

  def test_committed_task_files_are_detected_against_merge_base
    wt = create_worktree(@repo, "task-commit", branch: "task-commit")
    commit_file(wt, ".ace-tasks/8xa.t.ega-alpha/spec.md", "spec change\n", message: "docs: update task")

    payload = probe_for(wt)

    assert_includes payload[:committed_task_files], ".ace-tasks/8xa.t.ega-alpha/spec.md"
    assert_empty payload[:changed_task_files]
  end

  def test_current_symlink_resolves_task_directory
    wt = create_worktree(@repo, "linked", branch: "linked")
    task_dir = File.join(@repo, ".ace-tasks/8xa.t.ega-alpha")
    target = File.join(wt, "_current")
    File.symlink(File.expand_path(task_dir), target)

    payload = probe_for(wt)

    assert_equal File.realpath(task_dir), payload[:symlink_target]
  end

  def test_symlink_outside_task_tree_is_ignored
    wt = create_worktree(@repo, "foreign-link", branch: "foreign-link")
    File.symlink(@repo, File.join(wt, "_current"))

    assert_nil probe_for(wt)[:symlink_target]
  end

  def test_missing_worktree_returns_nil
    assert_nil probe_for(File.join(@repo, "does-not-exist"))
  end

  def test_unborn_worktree_reports_no_commit
    wt = create_worktree(@repo, "unborn", branch: "unborn")
    git!("-C", wt, "checkout", "--quiet", "--orphan", "unborn-detached")

    payload = probe_for(wt)

    assert_nil payload[:head_sha]
    assert_nil payload[:head_committer_epoch]
    assert_nil payload[:head_subject]
  end
end
