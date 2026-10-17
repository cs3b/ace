# frozen_string_literal: true

require "test_helper"

class WorktreeInfoTest < Minitest::Test
  include TestHelper

  WorktreeInfo = Ace::Git::Worktree::Models::WorktreeInfo

  def test_extract_task_id_ignores_parent_directory_numbers
    # Porcelain output where parent path contains an incidental 3-digit number
    # (e.g., ace-task.273) but the worktree directory is task.999-feature
    porcelain = <<~PORCELAIN
      worktree /home/mc/ace-task.273/.ace-wt/task.999-feature
      HEAD abc1234567890abcdef1234567890abcdef123456
      branch refs/heads/999-feature-branch
    PORCELAIN

    worktrees = WorktreeInfo.from_git_output_list(porcelain)
    assert_equal 1, worktrees.size
    assert_equal "999", worktrees.first.task_id
  end

  def test_extract_task_id_from_simple_worktree_path
    porcelain = <<~PORCELAIN
      worktree /project/.ace-wt/task.081
      HEAD abc1234567890abcdef1234567890abcdef123456
      branch refs/heads/081-fix-auth-bug
    PORCELAIN

    worktrees = WorktreeInfo.from_git_output_list(porcelain)
    assert_equal "081", worktrees.first.task_id
  end

  def test_extract_task_id_falls_back_to_branch
    porcelain = <<~PORCELAIN
      worktree /project/.ace-wt/some-dir
      HEAD abc1234567890abcdef1234567890abcdef123456
      branch refs/heads/142-implement-feature
    PORCELAIN

    worktrees = WorktreeInfo.from_git_output_list(porcelain)
    assert_equal "142", worktrees.first.task_id
  end

  def test_from_git_output_single_line
    line = "/project/.ace-wt/task.081 abc1234 [081-fix-auth-bug]"
    info = WorktreeInfo.from_git_output(line)

    assert_equal "/project/.ace-wt/task.081", info.path
    assert_equal "081-fix-auth-bug", info.branch
    assert_equal "081", info.task_id
  end

  def test_from_git_output_detached_head
    line = "/project/.ace-wt/detached abc1234 (detached HEAD)"
    info = WorktreeInfo.from_git_output(line)

    assert info.detached
    assert_nil info.branch
  end

  def test_task_associated
    info = WorktreeInfo.new(path: "/p", commit: "abc", task_id: "081")
    assert info.task_associated?

    info2 = WorktreeInfo.new(path: "/p", commit: "abc", task_id: nil)
    refute info2.task_associated?
  end
end

class WorktreeInfoEnrichmentTest < Minitest::Test
  WorktreeInfo = Ace::Git::Worktree::Models::WorktreeInfo

  def build(**overrides)
    WorktreeInfo.new(path: "/p/wt", commit: "abc", branch: "main", **overrides)
  end

  def test_defaults_preserve_existing_shape
    info = build
    hash = info.to_h

    assert_nil hash[:task_id_source]
    assert_equal [], hash[:task_ids]
    assert_nil hash[:active_within_window]
    assert_nil hash[:last_commit]
    assert_nil hash[:uncommitted]
    assert_nil hash[:pr]
    refute info.probe_failed?
  end

  def test_json_includes_existing_and_enrichment_keys
    info = build.with_enrichment(
      task_id: "k9y",
      task_id_source: "task_files",
      task_ids: %w[k9y xza],
      active_within_window: true,
      last_commit: {sha: "abc1234", age_hours: 2.1, committed_at: "2026-10-17T11:20:00Z", subject: "fix"},
      uncommitted: {staged: 2, unstaged: 4, untracked: 1, total: 7},
      pr: {number: 142, state: "open", draft: false, matched_by: "branch"}
    )
    hash = info.to_h

    assert_equal "/p/wt", hash[:path]
    assert_equal "main", hash[:branch]
    assert_equal "abc", hash[:commit]
    assert_equal "k9y", hash[:task_id]
    assert_equal "task_files", hash[:task_id_source]
    assert_equal %w[k9y xza], hash[:task_ids]
    assert_equal true, hash[:active_within_window]
    assert_equal 142, hash[:pr][:number]
    refute hash.key?(:probe_error)
  end

  def test_with_enrichment_returns_new_instance
    info = build
    enriched = info.with_enrichment(task_id: "k9y", task_id_source: "symlink")

    assert_nil info.task_id
    assert_equal "k9y", enriched.task_id
    assert_equal "symlink", enriched.task_id_source
    assert_equal "/p/wt", enriched.path
  end

  def test_probe_failure_flag
    info = build.with_enrichment(probe_error: true)

    assert info.probe_failed?
    assert_nil info.last_commit
  end
end
