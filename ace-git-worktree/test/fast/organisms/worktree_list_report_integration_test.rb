# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/worktree_repo_fixture"
require "json"

# End-to-end report test against a real multi-worktree git repository with the
# real forked probe runner, real task index, and real branch counter. Only the
# forge PR source is injected (no network in fast tests).
class WorktreeListReportIntegrationTest < Minitest::Test
  include WorktreeRepoFixture

  Report = Ace::Git::Worktree::Organisms::WorktreeListReport

  def setup
    @repo = build_repo
    write_task(@repo, "8xa.t.ega-alpha", id: "8xa.t.ega")
    commit_file(@repo, "README.md", "root\n", message: "root commit", date: Time.now - (10 * 60))

    @fresh = create_worktree(@repo, "fresh", branch: "codex/fresh")
    commit_file(@fresh, "fresh.txt", "fresh\n", message: "feat: fresh", date: Time.now - (5 * 60))

    @dirty = create_worktree(@repo, "dirty", branch: "codex/dirty")
    write_file(@dirty, "untracked.txt", "x\n")

    @stale = create_worktree(@repo, "stale", branch: "codex/stale")
    commit_file(@stale, "stale.txt", "stale\n", message: "old: stale", date: Time.now - (36 * 3600))

    @opaque = create_worktree(@repo, "opaque", branch: "codex/opaque-xyz")
    write_file(@opaque, ".ace-tasks/8xa.t.ega-alpha/notes.md", "note\n")
  end

  def teardown
    remove_repo(@repo)
  end

  def report(options = {})
    Dir.chdir(@repo) do
      Report.new(
        project_root: @repo,
        pr_resolver: Ace::Git::Worktree::Molecules::PrStatusResolver.new(query: ->(limit:) { [] }),
        env: {"HOME" => ENV["HOME"].to_s, "COLUMNS" => "200"}
      ).run(options)
    end
  end

  def test_compact_default_against_real_worktrees
    result = report
    output = result[:output]

    refute_nil result[:success]
    assert_match(/Active worktrees \(last 18h\) -- 4 of 5:/, output)
    assert_includes output, "codex/fresh"
    assert_includes output, "codex/dirty"
    refute_includes output, "codex/stale"
    assert_match(/Inactive: 1/, output)
  end

  def test_real_probe_populates_activity_and_dirty_state
    result = report(format: :json)
    rows = JSON.parse(result[:output])
    fresh = rows.find { |row| row["branch"] == "codex/fresh" }
    dirty = rows.find { |row| row["branch"] == "codex/dirty" }
    stale = rows.find { |row| row["branch"] == "codex/stale" }

    assert_equal true, fresh["active_within_window"]
    assert_equal "feat: fresh", fresh["last_commit"]["subject"]
    assert_equal 1, dirty["uncommitted"]["total"]
    assert_equal false, stale["active_within_window"]
    assert_operator stale["last_commit"]["age_hours"], :>=, 35
  end

  def test_real_task_file_inference_for_opaque_worktree
    result = report(format: :json)
    rows = JSON.parse(result[:output])
    opaque = rows.find { |row| row["branch"] == "codex/opaque-xyz" }

    assert_equal "ega", opaque["task_id"]
    assert_equal "task_files", opaque["task_id_source"]
    assert_equal ["ega"], opaque["task_ids"]
  end

  def test_full_mode_lists_every_worktree
    result = report(full: true)

    assert_includes result[:output], "codex/stale"
    assert_equal 5, result[:statistics][:total]
  end

  def test_recent_branch_without_worktree_is_counted
    commit_file(@repo, "branch-only.txt", "x\n", message: "feat: branch only", date: Time.now - 60)
    git!("-C", @repo, "branch", "recent-only")

    result = report

    assert_equal 1, result[:statistics][:recent_branches]
    assert_includes result[:output], "Recent branches without worktrees: 1"
  end

  def test_deterministic_output_across_runs
    first = report[:output]
    second = report[:output]

    assert_equal first, second
  end

  def test_pr_status_without_forge_renders_dashes
    result = report

    result[:worktrees].each do |worktree|
      assert_nil worktree.pr
    end
    assert_includes result[:output], "-"
  end
end
