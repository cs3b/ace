# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"

class TaskIndexTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir("task-index-test")
    @tasks_root = File.join(@root, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_root)
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def write_task(dir_name, frontmatter)
    dir = File.join(@tasks_root, dir_name)
    FileUtils.mkdir_p(dir)
    spec = File.join(dir, "#{File.basename(dir_name)}.s.md")
    File.write(spec, "---\n#{frontmatter}---\n\n# Task\n")
    dir
  end

  def build
    Ace::Git::Worktree::Molecules::TaskIndexBuilder.new(project_root: @root).build
  end

  def test_builds_full_and_short_ids
    write_task("8xg.t.k9y-list-table", "id: 8xg.t.k9y\nstatus: pending\n")
    index = build

    assert index.available?
    assert_equal ["8xg.t.k9y"], index.entries.map(&:full_id)
    assert_equal ["k9y"], index.entries.map(&:short_id)
    assert index.task?("k9y")
    assert index.task?("8xg.t.k9y")
    assert_equal "k9y", index.short_id_for("8xg.t.k9y")
  end

  def test_subtask_ids
    write_task("8wr.t.qk0.3-subtask", "id: 8wr.t.qk0.3\nstatus: pending\n")
    index = build

    assert_equal ["qk0.3"], index.entries.map(&:short_id)
    assert index.task?("qk0.3")
  end

  def test_recorded_worktree_metadata
    dir = write_task("8xa.t.ega-deliver", <<~YAML)
      id: 8xa.t.ega
      status: done
      worktree:
        branch: ega-deliver
        path: .ace-wt/ace-t.ega
    YAML
    index = build
    entry = index.entries.first

    assert_equal "ega-deliver", entry.worktree_branch
    assert_equal File.join(@root, ".ace-wt/ace-t.ega"), entry.worktree_path
    assert_equal dir, entry.directory
    assert_equal entry, index.find_by_worktree_path(File.join(@root, ".ace-wt/ace-t.ega"))
    assert_equal entry, index.find_by_worktree_branch("ega-deliver")
  end

  def test_current_tree_wins_over_archive_duplicate
    write_task("8xg.t.k9y-current", "id: 8xg.t.k9y\nstatus: done\n")
    write_task("_archive/8xg.t.k9y-archived", "id: 8xg.t.k9y\nstatus: done\n")
    index = build

    assert_equal 1, index.entries.length
    assert_includes index.entries.first.directory, "8xg.t.k9y-current"
  end

  def test_candidates_for_changed_paths_ranks_by_count_then_id
    a = write_task("8xa.t.ega-alpha", "id: 8xa.t.ega\n")
    b = write_task("8xb.t.iy6-beta", "id: 8xb.t.iy6\n")
    paths = [
      "#{a.sub(@root + "/", "")}/notes.md",
      "#{b.sub(@root + "/", "")}/spec.md",
      "#{b.sub(@root + "/", "")}/notes.md"
    ]

    candidates = build.candidates_for_paths(paths)

    assert_equal 2, candidates.length
    assert_equal "iy6", candidates.first[:entry].short_id
    assert_equal 2, candidates.first[:count]
    assert_equal "ega", candidates.last[:entry].short_id
  end

  def test_candidates_tie_break_is_lexicographic
    write_task("8xa.t.zzz-last", "id: 8xa.t.zzz\n")
    write_task("8xb.t.aaa-first", "id: 8xb.t.aaa\n")
    paths = [".ace-tasks/8xa.t.zzz-last/x.md", ".ace-tasks/8xb.t.aaa-first/x.md"]

    candidates = build.candidates_for_paths(paths)

    assert_equal %w[aaa zzz], candidates.map { |c| c[:entry].short_id }
  end

  def test_unknown_files_are_ignored
    write_task("8xa.t.ega-alpha", "id: 8xa.t.ega\n")
    assert_empty build.candidates_for_paths(["README.md", ""])
  end

  def test_rejects_unknown_three_character_name
    index = build
    refute index.task?("ace")
    assert_nil index.short_id_for("ace")
  end

  def test_no_task_tree_falls_back_to_unavailable_index
    FileUtils.rm_rf(@tasks_root)
    index = build

    refute index.available?
    assert index.empty?
    assert_nil index.short_id_for("ace")
  end

  def test_malformed_spec_is_skipped
    FileUtils.mkdir_p(File.join(@tasks_root, "broken"))
    File.write(File.join(@tasks_root, "broken", "broken.s.md"), "no frontmatter here")
    write_task("8xa.t.ega-alpha", "id: 8xa.t.ega\n")

    index = build
    assert_equal ["ega"], index.entries.map(&:short_id)
  end

  def test_find_by_directory_and_enclosing_paths
    dir = write_task("8xa.t.ega-alpha", "id: 8xa.t.ega\n")
    index = build

    assert_equal index.entries.first, index.find_by_directory(dir)
    candidates = index.candidates_for_paths([".ace-tasks/8xa.t.ega-alpha/nested/report.md"])
    assert_equal 1, candidates.first[:count]
  end
end
