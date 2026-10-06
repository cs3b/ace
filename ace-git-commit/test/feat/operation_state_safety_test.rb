# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "open3"
require "fileutils"

class OperationStateSafetyTest < TestCase
  ROOT = File.expand_path("../../..", __dir__)
  BIN = File.join(ROOT, "bin/ace-git-commit")
  MODES = [["shared.txt"], [], ["--only-staged"], ["--no-split"], ["--dry-run"], ["--quiet"], ["--debug"]].freeze

  def with_repo
    Dir.mktmpdir("ace-operation-") do |dir|
      @repo = dir
      @git_env = {}
      git("init", "-b", "main")
      git("config", "user.name", "Test")
      git("config", "user.email", "test@example.invalid")
      write("shared.txt", "base\n")
      git("add", ".")
      git("commit", "-m", "base")
      yield
    end
  end

  def test_resolved_and_unresolved_merge_preserve_state_and_complete
    with_repo do
      git("checkout", "-b", "side")
      write("shared.txt", "side\n")
      write("side.txt", "side\n")
      git("add", ".")
      git("commit", "-m", "side")
      side = git("rev-parse", "HEAD").strip
      git("checkout", "main")
      write("shared.txt", "main\n")
      git("add", ".")
      git("commit", "-m", "main")
      main = git("rev-parse", "HEAD").strip
      git("merge", "side", success: false)
      refused("merge", ["shared.txt"])
      write("shared.txt", "resolved\n")
      git("add", ".")
      MODES.each { |mode| refused("merge", mode) }
      git("commit", "-m", "merge")
      assert_equal [main, side], git("rev-list", "--parents", "-n", "1", "HEAD").split.drop(1)
      assert_equal "resolved\n", File.read(File.join(@repo, "shared.txt"))
      assert_equal "side\n", git("show", "HEAD:side.txt")
    end
  end

  def test_whitespace_prefixed_git_dir_preserves_merge_and_native_completion
    with_repo do
      FileUtils.mv(File.join(@repo, ".git"), File.join(@repo, " metadata"))
      @git_env = {"GIT_DIR" => " metadata"}
      git("checkout", "-b", "side")
      write("shared.txt", "side\n")
      write("side.txt", "side\n")
      git("add", "shared.txt", "side.txt")
      git("commit", "-m", "side")
      side = git("rev-parse", "HEAD").strip
      git("checkout", "main")
      write("shared.txt", "main\n")
      git("add", "shared.txt")
      git("commit", "-m", "main")
      main = git("rev-parse", "HEAD").strip
      git("merge", "side", success: false)
      refused("merge", ["shared.txt", "--quiet"])
      write("shared.txt", "resolved\n")
      git("add", "shared.txt")
      refused("merge", ["shared.txt", "--quiet"])
      git("commit", "-m", "merge")
      assert_equal [main, side], git("rev-list", "--parents", "-n", "1", "HEAD").split.drop(1)
      assert_equal "resolved\n", git("show", "HEAD:shared.txt")
      assert_equal "side\n", git("show", "HEAD:side.txt")
    end
  end

  def test_cherry_pick_and_rebase_in_linked_worktrees_can_continue
    [:cherry_pick, :rebase].each do |operation|
      with_repo do
        git("checkout", "-b", "side")
        write("shared.txt", "side\n")
        git("add", ".")
        git("commit", "-m", "side")
        git("checkout", "main")
        write("shared.txt", "main\n")
        git("add", ".")
        git("commit", "-m", "main")
        linked = File.join(@repo, "linked")
        git("worktree", "add", "-b", "linked", linked, (operation == :rebase) ? "side" : "main")
        parent = @repo
        @repo = linked
        if operation == :rebase
          git("rebase", "main", success: false)
          refused("rebase")
        else
          git("cherry-pick", "side", success: false)
          refused("cherry-pick")
        end
        # Main worktree has no operation markers, even while linked is conflicted.
        Dir.chdir(parent) { assert_nil Ace::GitCommit::Molecules::GitOperationDetector.new(Ace::GitCommit::Atoms::GitExecutor.new).detect }
        write("shared.txt", "resolved\n")
        git("add", ".")
        git((operation == :rebase) ? "rebase" : "cherry-pick", "--continue")
        assert_equal "resolved\n", git("show", "HEAD:shared.txt")
      end
    end
  end

  def test_revert_preserves_state_and_continues
    with_repo do
      write("shared.txt", "change\n")
      git("add", ".")
      git("commit", "-m", "change")
      change = git("rev-parse", "HEAD").strip
      write("shared.txt", "later\n")
      git("add", ".")
      git("commit", "-m", "later")
      git("revert", change, success: false)
      refused("revert")
      write("shared.txt", "resolved\n")
      git("add", ".")
      git("revert", "--continue")
      assert_equal "resolved\n", git("show", "HEAD:shared.txt")
    end
  end

  def test_real_git_am_refuses_and_continues
    with_repo do
      git("checkout", "-b", "side")
      write("shared.txt", "side\n")
      git("add", ".")
      git("commit", "-m", "side")
      patch = git("format-patch", "-1", "--stdout")
      git("checkout", "main")
      write("shared.txt", "main\n")
      git("add", ".")
      git("commit", "-m", "main")
      patch_path = File.join(@repo, "change.patch")
      File.write(patch_path, patch)
      git("am", patch_path, success: false)
      refused("git-am")
      write("shared.txt", "resolved\n")
      git("add", "shared.txt")
      git("am", "--continue")
      assert_equal "resolved\n", git("show", "HEAD:shared.txt")
    end
  end

  def test_sequencer_and_git_am_markers_refuse
    with_repo do
      ["sequencer", "rebase-apply"].each do |marker|
        path = git("rev-parse", "--git-path", marker).strip
        path = File.expand_path(path, @repo)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "applying"), "") if marker == "rebase-apply"
        refused((marker == "sequencer") ? "sequencer" : "git-am")
        FileUtils.rm_rf(path)
      end
    end
  end

  def test_ordinary_scoped_and_staged_only_commit_controls
    with_repo do
      write("shared.txt", "requested\n")
      write("unrelated.txt", "unrelated\n")
      output, status = cli(["shared.txt", "--no-split", "--quiet"])
      assert status.success?, output
      assert_equal ["shared.txt"], git("diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD").split
      assert_equal "?? unrelated.txt", git("status", "--porcelain").strip
      git("add", "unrelated.txt")
      write("shared.txt", "unstaged\n")
      output, status = cli(["--only-staged", "--quiet"])
      assert status.success?, output
      assert_equal ["unrelated.txt"], git("diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD").split
      assert_equal "requested\n", git("show", "HEAD:shared.txt")
    end
  end

  private

  def write(path, content)
    File.write(File.join(@repo, path), content)
  end

  def git(*args, success: true)
    env = {"GIT_EDITOR" => "true", "GIT_SEQUENCE_EDITOR" => "true"}.merge(@git_env)
    output, error, status = Open3.capture3(env, "git", *args, chdir: @repo)
    assert_equal success, status.success?, "git #{args.join(" ")}: #{output}#{error}"
    output
  end

  def cli(args)
    output, error, status = Open3.capture3(@git_env, BIN, *args, "-m", "test commit", chdir: @repo)
    [output + error, status]
  end

  def snapshot
    metadata = git("rev-parse", "--absolute-git-dir").delete_suffix("\n")
    # Exclude read-only status cache timestamps; compare actual index and operation contents.
    files = Dir.glob(File.join(metadata, "**", "*"), File::FNM_DOTMATCH).select { |p| File.file?(p) }
    metadata_content = files.to_h { |p| [p.delete_prefix(metadata), File.binread(p)] }
    working = Dir.glob(File.join(@repo, "**", "*"), File::FNM_DOTMATCH).select do |p|
      File.file?(p) && !p.start_with?(File.join(@repo, ".git")) && !p.include?("/linked/")
    end.to_h { |p| [p.delete_prefix(@repo), File.binread(p)] }
    [git("rev-parse", "HEAD"), git("show-ref"), git("ls-files", "--stage"), metadata_content, working]
  end

  def refused(operation, args = ["--only-staged", "--quiet"])
    before = snapshot
    output, status = cli(args)
    refute status.success?, output
    assert_match(/active #{Regexp.escape(operation)}/, output)
    assert_match((operation == "sequencer") ? /git status/ : /git .*continue|git commit/, output)
    assert_equal before, snapshot, "Git state changed after refusal: #{args.inspect}"
  end
end
