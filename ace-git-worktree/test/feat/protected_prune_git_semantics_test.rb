# frozen_string_literal: true

require "test_helper"
require "open3"

# Ordinary Git mechanics only: this does not exercise privileged prune admission.
class ProtectedPruneGitSemanticsTest < Minitest::Test
  def with_linked_worktree
    Dir.mktmpdir("prune-git-mechanics") do |temporary_root|
      root = File.realpath(temporary_root)
      main = File.join(root, "main")
      old = File.join(root, "old")
      FileUtils.mkdir_p(main)
      git!(main, "init", "-q")
      git!(main, "config", "user.name", "Fixture")
      git!(main, "config", "user.email", "fixture@example.invalid")
      File.binwrite(File.join(main, "tracked"), "committed\n")
      File.binwrite(File.join(main, ".gitignore"), "ignored\n")
      git!(main, "add", "tracked", ".gitignore")
      git!(main, "commit", "-qm", "fixture")
      git!(main, "worktree", "add", "-qb", "retained", old)
      yield root, main, old
    end
  end

  def test_dirty_capture_requires_internal_force_after_external_byte_preservation
    with_linked_worktree do |root, main, old|
      contents = {"tracked" => "dirty\x00bytes", "untracked" => "new bytes", "ignored" => "ignored bytes"}
      preserved = File.join(root, "preserved")
      FileUtils.mkdir_p(preserved)
      contents.each do |name, bytes|
        File.binwrite(File.join(old, name), bytes)
        File.binwrite(File.join(preserved, name), File.binread(File.join(old, name)))
      end
      head = git!(main, "rev-parse", "refs/heads/retained")
      inode = File.stat(old).ino
      captured = File.join(root, "captured")
      git!(main, "worktree", "move", "--", old, captured)
      assert_equal inode, File.stat(captured).ino
      _, _, status = git(main, "worktree", "remove", "--", captured)
      refute status.success?, "ordinary remove must refuse dirty/untracked worktree"
      assert Dir.exist?(captured)
      assert_includes git!(main, "worktree", "list", "--porcelain"), "worktree #{captured}"
      contents.each { |name, bytes| assert_equal bytes, File.binread(File.join(captured, name)) }
      git!(main, "worktree", "remove", "--force", "--", captured)
      refute File.exist?(captured)
      refute_includes git!(main, "worktree", "list", "--porcelain"), "worktree #{captured}"
      assert_equal head, git!(main, "rev-parse", "refs/heads/retained")
      assert_equal "committed\n", File.binread(File.join(main, "tracked"))
      contents.each { |name, bytes| assert_equal bytes, File.binread(File.join(preserved, name)) }
    end
  end

  def test_ignored_data_requires_preservation_independent_of_git_cleanliness
    with_linked_worktree do |root, main, old|
      File.binwrite(File.join(old, "ignored"), "must retain")
      retained = File.join(root, "retained-ignored")
      File.binwrite(retained, File.binread(File.join(old, "ignored")))
      assert_empty git!(old, "status", "--porcelain")
      git!(main, "worktree", "remove", "--", old)
      refute File.exist?(old)
      assert_equal "must retain", File.binread(retained)
    end
  end

  private

  def git(directory, *arguments)
    Open3.capture3({"GIT_CONFIG_NOSYSTEM" => "1", "GIT_CONFIG_GLOBAL" => File::NULL,
                   "GIT_TERMINAL_PROMPT" => "0"}, "git", "-C", directory, *arguments)
  end

  def git!(directory, *arguments)
    stdout, stderr, status = git(directory, *arguments)
    assert status.success?, "Git #{arguments.first} failed: #{stderr}"
    stdout
  end
end
