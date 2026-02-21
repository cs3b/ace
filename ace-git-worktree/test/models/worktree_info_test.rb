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
