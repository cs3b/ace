# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"
require "json"

class WorktreeListReportTest < Minitest::Test
  WorktreeInfo = Ace::Git::Worktree::Models::WorktreeInfo
  Report = Ace::Git::Worktree::Organisms::WorktreeListReport

  NOW = Time.utc(2026, 10, 17, 12, 0, 0)
  HOME = "/Users/mc"

  FakeLister = Struct.new(:worktrees, :success, :error, keyword_init: true) do
    def inventory
      {success: success, worktrees: worktrees, error: error}
    end

    def format_for_display(worktrees, _format)
      worktrees.map { |worktree| "#{worktree.branch} at #{worktree.path}" }.join("\n") + "\n"
    end
  end

  FakeProbeRunner = Struct.new(:payloads, keyword_init: true) do
    def run(_worktrees)
      payloads
    end
  end

  def setup
    @root = Dir.mktmpdir("list-report-test")
    @tasks_root = File.join(@root, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_root)
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def add_task(dir, id, worktree_path: nil, worktree_branch: nil)
    directory = File.join(@tasks_root, dir)
    FileUtils.mkdir_p(directory)
    lines = ["---", "id: #{id}", "status: pending"]
    if worktree_path || worktree_branch
      lines << "worktree:"
      lines << "  path: #{worktree_path}" if worktree_path
      lines << "  branch: #{worktree_branch}" if worktree_branch
    end
    lines << "---"
    File.write(File.join(directory, "#{dir}.s.md"), "#{lines.join("\n")}\n")
  end

  def worktree(path:, branch: "main", commit: "abc123", bare: false, detached: false)
    WorktreeInfo.new(path: path, branch: branch, commit: commit, bare: bare, detached: detached)
  end

  def payload(head_age_hours: 1.0, subject: "feat: work", staged: 0, unstaged: 0, untracked: 0,
    changed_task_files: [], committed_task_files: [], symlink_target: nil, head_sha: "abc123")
    {
      head_sha: head_sha,
      head_committer_epoch: (NOW - (head_age_hours * 3600)).to_i,
      head_subject: subject,
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
      changed_task_files: changed_task_files,
      committed_task_files: committed_task_files,
      symlink_target: symlink_target
    }
  end

  def build_report(worktrees:, probes:, branch_count: 0, pull_requests: [])
    Report.new(
      lister: FakeLister.new(worktrees: worktrees, success: true),
      task_index_builder: Ace::Git::Worktree::Molecules::TaskIndexBuilder.new(project_root: @root),
      probe_runner: FakeProbeRunner.new(payloads: probes),
      pr_resolver: Ace::Git::Worktree::Molecules::PrStatusResolver.new(
        query: ->(limit:) { pull_requests }
      ),
      branch_counter: ->(worktrees:, window_hours:, now:) { branch_count },
      clock: -> { NOW },
      project_root: @root,
      env: {"HOME" => HOME, "COLUMNS" => "120"}
    )
  end

  def run_report(worktrees:, probes:, options: {}, **kwargs)
    build_report(worktrees: worktrees, probes: probes, **kwargs).run(options)
  end

  def basic_fixture
    worktrees = [
      worktree(path: File.join(@root)),
      worktree(path: File.join(@root, ".ace-wt/fresh"), branch: "codex/fresh"),
      worktree(path: File.join(@root, ".ace-wt/dirty"), branch: "codex/dirty"),
      worktree(path: File.join(@root, ".ace-wt/stale"), branch: "codex/stale")
    ]
    probes = [
      payload(head_age_hours: 3.0, subject: "spec: root"),
      payload(head_age_hours: 8.0 / 60, subject: "feat: fresh"),
      payload(head_age_hours: 5.0, subject: "wip: dirty", untracked: 2),
      payload(head_age_hours: 36.0, subject: "old: stale")
    ]
    [worktrees, probes]
  end

  def test_compact_default_shows_only_active_rows_and_footer
    worktrees, probes = basic_fixture
    result = run_report(worktrees: worktrees, probes: probes, branch_count: 4)

    assert result[:success]
    lines = result[:output].lines(chomp: true)

    assert_equal "Active worktrees (last 18h) -- 3 of 4:", lines.first
    assert_includes result[:output], "Inactive: 1  (use --full to list all)"
    assert_includes result[:output], "Task-associated: 0    Usable: 4    Recent branches without worktrees: 4"
    assert_operator lines.length, :<=, 30
    refute result[:output].include?("codex/stale")
    assert result[:output].include?("codex/fresh")
  end

  def test_full_lists_every_worktree_with_absolute_paths
    worktrees, probes = basic_fixture
    result = run_report(worktrees: worktrees, probes: probes, options: {full: true})

    lines = result[:output].lines(chomp: true)

    assert_includes result[:output], File.expand_path(File.join(@root, ".ace-wt/stale"))
    assert_includes lines.first, "3 of 4"
    assert_equal 4, result[:statistics][:total]
  end

  def test_activity_window_can_be_widened_and_narrowed
    worktrees, probes = basic_fixture

    wide = run_report(worktrees: worktrees, probes: probes, options: {active_within: "2d"})
    assert_includes wide[:output], "Active worktrees (last 2d) -- 4 of 4:"
    assert_includes wide[:output], "codex/stale"

    narrow = run_report(worktrees: worktrees, probes: probes, options: {active_within: "90m"})
    assert_includes narrow[:output], "Active worktrees (last 90m) -- 2 of 4:"
    assert_includes narrow[:output], "codex/fresh"
    refute_includes narrow[:output], "codex/stale"
  end

  def test_zero_active_state_prints_message_and_footer
    worktrees = [worktree(path: @root, branch: "main")]
    probes = [payload(head_age_hours: 30.0)]
    result = run_report(worktrees: worktrees, probes: probes, branch_count: 2)

    assert_includes result[:output], "Active worktrees (last 18h) -- 0 of 1:"
    assert_includes result[:output], "No active worktrees in the last 18h."
    assert_includes result[:output], "Inactive: 1  (use --full to list all)"
  end

  def test_no_worktrees_at_all
    report = Report.new(
      lister: FakeLister.new(worktrees: [], success: true),
      task_index_builder: Ace::Git::Worktree::Molecules::TaskIndexBuilder.new(project_root: @root),
      probe_runner: FakeProbeRunner.new(payloads: []),
      pr_resolver: Ace::Git::Worktree::Molecules::PrStatusResolver.new(query: ->(limit:) { [] }),
      branch_counter: ->(**_) { 0 },
      clock: -> { NOW },
      project_root: @root,
      env: {"HOME" => HOME}
    )

    assert_equal "No worktrees found.", report.run[:output]
  end

  def test_inventory_failure_is_reported
    report = Report.new(
      lister: FakeLister.new(worktrees: [], success: false, error: "not a git repository"),
      task_index_builder: Ace::Git::Worktree::Molecules::TaskIndexBuilder.new(project_root: @root),
      probe_runner: FakeProbeRunner.new(payloads: []),
      pr_resolver: Ace::Git::Worktree::Molecules::PrStatusResolver.new(query: ->(limit:) { [] }),
      branch_counter: ->(**_) { 0 },
      clock: -> { NOW },
      project_root: @root,
      env: {"HOME" => HOME}
    )
    result = report.run

    refute result[:success]
    assert_equal "not a git repository", result[:error]
  end

  def test_filters_apply_before_split_and_update_counts
    add_task("8xa.t.ega-alpha", "8xa.t.ega", worktree_branch: "codex/fresh")
    worktrees, probes = basic_fixture
    result = run_report(worktrees: worktrees, probes: probes, options: {task_associated: true})

    lines = result[:output].lines(chomp: true)
    assert_equal "Active worktrees (last 18h) -- 1 of 1:", lines.first
    assert_includes lines.last, "Task-associated: 1    Usable: 1"
    assert_includes result[:output], "codex/fresh"
    refute_includes result[:output], "codex/dirty"
  end

  def test_recent_branch_count_is_independent_of_worktree_filters
    add_task("8xa.t.ega-alpha", "8xa.t.ega", worktree_branch: "codex/fresh")
    worktrees, probes = basic_fixture
    result = run_report(
      worktrees: worktrees, probes: probes,
      options: {task_associated: true}, branch_count: 7
    )

    assert_includes result[:output], "Recent branches without worktrees: 7"
  end

  def test_quiet_suppresses_footer_but_keeps_table
    worktrees, probes = basic_fixture
    result = run_report(worktrees: worktrees, probes: probes, options: {quiet: true})

    refute_includes result[:output], "Inactive:"
    refute_includes result[:output], "Task-associated:"
    assert_includes result[:output], "codex/fresh"
  end

  def test_json_is_complete_for_every_selected_worktree
    worktrees, probes = basic_fixture
    result = run_report(worktrees: worktrees, probes: probes, options: {format: :json})
    data = JSON.parse(result[:output])

    assert_equal 4, data.length
    row = data.find { |entry| entry["branch"] == "codex/fresh" }

    assert_equal "codex/fresh", row["branch"]
    assert_equal true, row["active_within_window"]
    assert_equal "abc123", row["last_commit"]["sha"]
    assert_equal 0.13, row["last_commit"]["age_hours"]
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, row["last_commit"]["committed_at"])
    assert_equal "feat: fresh", row["last_commit"]["subject"]
    assert_nil row["uncommitted"]
    assert_nil row["pr"]
    assert_nil row["task_id"]
    assert_nil row["task_id_source"]
    assert_equal [], row["task_ids"]

    dirty = data.find { |entry| entry["branch"] == "codex/dirty" }
    assert_equal 2, dirty["uncommitted"]["total"]
    assert_equal true, dirty["active_within_window"]
  end

  def test_json_ignores_detail_flags
    worktrees, probes = basic_fixture
    default = run_report(worktrees: worktrees, probes: probes)
    full = run_report(worktrees: worktrees, probes: probes)

    assert_equal default[:output], full[:output]
  end

  def test_task_file_inference_is_name_independent
    add_task("8xa.t.ega-alpha", "8xa.t.ega")
    worktrees = [
      worktree(path: File.join(@root, ".ace-wt/opaque"), branch: "codex/opaque-xyz"),
      worktree(path: @root, branch: "main")
    ]
    probes = [
      payload(head_age_hours: 1.0, changed_task_files: [".ace-tasks/8xa.t.ega-alpha/notes.md"]),
      payload(head_age_hours: 1.0)
    ]
    table = run_report(worktrees: worktrees, probes: probes)
    json = JSON.parse(build_report(worktrees: worktrees, probes: probes).run(format: :json)[:output])
    row = json.find { |entry| entry["branch"] == "codex/opaque-xyz" }

    assert_equal "ega", row["task_id"]
    assert_equal "task_files", row["task_id_source"]
    assert_equal ["ega"], row["task_ids"]
    assert_includes table[:output], "ega"
  end

  def test_probe_failure_renders_question_marks_and_stays_inactive
    worktrees = [
      worktree(path: @root, branch: "main"),
      worktree(path: File.join(@root, ".ace-wt/broken"), branch: "codex/broken")
    ]
    probes = [payload(head_age_hours: 1.0), nil]
    result = run_report(worktrees: worktrees, probes: probes, options: {full: true})

    broken_line = result[:output].lines.find { |line| line.include?("codex/broken") }
    refute_nil broken_line
    assert_equal 3, broken_line.scan("?").length
    broken = result[:worktrees].find { |wt| wt.branch == "codex/broken" }
    assert_equal false, broken.active_within_window
    assert broken.probe_failed?
  end

  def test_pr_cell_and_json_provenance
    worktrees = [worktree(path: @root, branch: "codex/fresh")]
    probes = [payload(head_age_hours: 1.0)]
    pull_requests = [{
      number: 142, state: :open, draft: true, head_ref: "codex/fresh",
      head_sha: "abc123", title: "feat", body: ""
    }]
    result = run_report(worktrees: worktrees, probes: probes, pull_requests: pull_requests)
    data = JSON.parse(build_report(worktrees: worktrees, probes: probes, pull_requests: pull_requests).run(format: :json)[:output])

    assert_includes result[:output], "#142 draft"
    assert_equal "branch", data.first["pr"]["matched_by"]
    assert_equal true, data.first["pr"]["draft"]
    assert_equal "open", data.first["pr"]["state"]
  end

  def test_simple_format_is_unchanged
    worktrees, probes = basic_fixture
    result = run_report(worktrees: worktrees, probes: probes, options: {format: :simple})

    lines = result[:output].lines(chomp: true)
    assert_equal 4, lines.length
    assert_equal "main at #{File.join(@root)}", lines.first
    refute_includes result[:output], "Active worktrees"
  end

  def test_bare_worktrees_are_never_active
    worktrees = [worktree(path: @root, branch: "main", bare: true)]
    probes = [payload(head_age_hours: 1.0)]
    result = run_report(worktrees: worktrees, probes: probes)

    assert_equal false, result[:worktrees].first.active_within_window
    assert_includes result[:output], "No active worktrees"
  end

  def test_narrow_columns_drop_path_column
    report = Report.new(
      lister: FakeLister.new(worktrees: [worktree(path: @root)], success: true),
      task_index_builder: Ace::Git::Worktree::Molecules::TaskIndexBuilder.new(project_root: @root),
      probe_runner: FakeProbeRunner.new(payloads: [payload]),
      pr_resolver: Ace::Git::Worktree::Molecules::PrStatusResolver.new(query: ->(limit:) { [] }),
      branch_counter: ->(**_) { 0 },
      clock: -> { NOW },
      project_root: @root,
      env: {"HOME" => HOME, "COLUMNS" => "60"}
    )
    output = report.run[:output]
    table_lines = output.split("\n\n").first.lines

    table_lines.each { |line| assert_operator line.chomp.length, :<=, 60, line.inspect }
    refute_includes output, "Path"
  end

  def test_repeated_runs_are_identical
    worktrees, probes = basic_fixture
    first = run_report(worktrees: worktrees, probes: probes)[:output]
    second = run_report(worktrees: worktrees, probes: probes)[:output]

    assert_equal first, second
  end
end
