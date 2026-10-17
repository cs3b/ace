# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class TaskAssociationResolverTest < Minitest::Test
  WorktreeInfo = Ace::Git::Worktree::Models::WorktreeInfo
  Resolver = Ace::Git::Worktree::Molecules::TaskAssociationResolver
  TaskIndex = Ace::Git::Worktree::Models::TaskIndex
  Entry = TaskIndex::Entry

  def setup
    @root = Dir.mktmpdir("association-test")
    @tasks_root = File.join(@root, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_root)
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def add_task(dir, id, worktree_path: nil, worktree_branch: nil)
    directory = File.join(@tasks_root, dir)
    FileUtils.mkdir_p(directory)
    frontmatter = ["---", "id: #{id}", "status: pending"]
    if worktree_path || worktree_branch
      frontmatter << "worktree:"
      frontmatter << "  path: #{worktree_path}" if worktree_path
      frontmatter << "  branch: #{worktree_branch}" if worktree_branch
    end
    frontmatter << "---"
    File.write(File.join(directory, "#{dir}.s.md"), "#{frontmatter.join("\n")}\n")
    directory
  end

  def index(available: true)
    if available
      Ace::Git::Worktree::Molecules::TaskIndexBuilder.new(project_root: @root).build
    else
      TaskIndex.new(available: false, project_root: @root)
    end
  end

  def worktree(path:, branch: nil)
    WorktreeInfo.new(path: path, branch: branch, commit: "abc")
  end

  def resolve(worktree, probe = {}, available: true)
    Resolver.new(task_index: index(available: available)).resolve(worktree, probe)
  end

  def test_metadata_path_takes_precedence
    add_task("8xa.t.ega-renamed", "8xa.t.ega", worktree_path: ".ace-wt/renamed-dir")
    resolved = resolve(worktree(path: File.join(@root, ".ace-wt/renamed-dir")))

    assert_equal "ega", resolved.task_id
    assert_equal "metadata", resolved.task_id_source
    assert_equal ["ega"], resolved.task_ids
  end

  def test_metadata_branch_takes_precedence
    add_task("8xa.t.ega-renamed", "8xa.t.ega", worktree_branch: "codex/ega-deliver")
    resolved = resolve(worktree(path: "/tmp/anything", branch: "codex/ega-deliver"))

    assert_equal "ega", resolved.task_id
    assert_equal "metadata", resolved.task_id_source
  end

  def test_symlink_resolution
    directory = add_task("8xa.t.ega-alpha", "8xa.t.ega")
    probe = {symlink_target: File.realpath(directory)}
    resolved = resolve(worktree(path: "/tmp/useless-name"), probe)

    assert_equal "ega", resolved.task_id
    assert_equal "symlink", resolved.task_id_source
  end

  def test_validated_path_extraction
    add_task("8xa.t.ega-alpha", "8xa.t.ega")
    resolved = resolve(worktree(path: "/tmp/.ace-wt/t.ega"))

    assert_equal "ega", resolved.task_id
    assert_equal "path", resolved.task_id_source
  end

  def test_validated_branch_extraction
    add_task("8xa.t.ega-alpha", "8xa.t.ega")
    resolved = resolve(worktree(path: "/tmp/useless", branch: "codex/t.ega"))

    assert_equal "ega", resolved.task_id
    assert_equal "branch", resolved.task_id_source
  end

  def test_unmatched_three_character_name_is_rejected
    add_task("8xa.t.ega-alpha", "8xa.t.ega")
    resolved = resolve(worktree(path: File.join(@root), branch: "main"))

    assert_nil resolved.task_id
    assert_nil resolved.task_id_source
    assert_empty resolved.task_ids
  end

  def test_no_task_tree_keeps_legacy_extraction
    resolved = resolve(worktree(path: "/tmp/ace"), available: false)

    assert_equal "ace", resolved.task_id
    assert_equal "path", resolved.task_id_source
  end

  def test_uncommitted_task_files_resolve_task
    add_task("8xa.t.ega-alpha", "8xa.t.ega")
    probe = {changed_task_files: [".ace-tasks/8xa.t.ega-alpha/notes.md"]}
    resolved = resolve(worktree(path: "/tmp/useless"), probe)

    assert_equal "ega", resolved.task_id
    assert_equal "task_files", resolved.task_id_source
  end

  def test_committed_task_files_used_when_no_uncommitted
    add_task("8xa.t.ega-alpha", "8xa.t.ega")
    probe = {committed_task_files: [".ace-tasks/8xa.t.ega-alpha/spec.md"]}
    resolved = resolve(worktree(path: "/tmp/useless"), probe)

    assert_equal "ega", resolved.task_id
    assert_equal "task_files", resolved.task_id_source
  end

  def test_task_file_ambiguity_uses_dominant_and_tie_break
    add_task("8xa.t.zzz-last", "8xa.t.zzz")
    add_task("8xb.t.aaa-first", "8xb.t.aaa")
    probe = {
      changed_task_files: [
        ".ace-tasks/8xa.t.zzz-last/a.md",
        ".ace-tasks/8xb.t.aaa-first/a.md",
        ".ace-tasks/8xb.t.aaa-first/b.md"
      ]
    }
    resolved = resolve(worktree(path: "/tmp/useless"), probe)

    assert_equal "aaa", resolved.task_id
    assert_equal %w[aaa zzz], resolved.task_ids
    assert_equal "task_files", resolved.task_id_source
  end

  def test_non_task_changes_do_not_resolve
    add_task("8xa.t.ega-alpha", "8xa.t.ega")
    resolved = resolve(worktree(path: "/tmp/useless"), {changed_task_files: ["lib/foo.rb"]})

    assert_nil resolved.task_id
  end

  def test_precedence_order_metadata_over_symlink_over_name_over_files
    directory = add_task("8xa.t.ega-alpha", "8xa.t.ega", worktree_path: ".ace-wt/ega")
    add_task("8xb.t.aaa-other", "8xb.t.aaa")
    probe = {
      symlink_target: File.realpath(directory),
      changed_task_files: [".ace-tasks/8xb.t.aaa-other/x.md"]
    }
    resolved = resolve(worktree(path: File.join(@root, ".ace-wt/ega")), probe)

    assert_equal "metadata", resolved.task_id_source
    assert_equal "ega", resolved.task_id
  end

  def test_repeat_resolution_is_deterministic
    add_task("8xa.t.ega-alpha", "8xa.t.ega")
    worktree = worktree(path: "/tmp/useless")
    resolver = Resolver.new(task_index: index)
    first = resolver.resolve(worktree, {changed_task_files: [".ace-tasks/8xa.t.ega-alpha/x.md"]})
    second = resolver.resolve(worktree, {changed_task_files: [".ace-tasks/8xa.t.ega-alpha/x.md"]})

    assert_equal first.task_id, second.task_id
    assert_equal first.task_ids, second.task_ids
  end

  def test_metadata_path_relative_to_project_root
    add_task("8xa.t.ega-alpha", "8xa.t.ega", worktree_path: ".ace-wt/t.ega")
    resolved = resolve(worktree(path: File.join(@root, ".ace-wt/t.ega")))

    assert_equal "ega", resolved.task_id
    assert_equal "metadata", resolved.task_id_source
  end
end
