# frozen_string_literal: true

require_relative "../../test_helper"

class StatusSourcesTest < AceOverseerTestCase
  FakeWorktree = Struct.new(:path, :task_id, :bare)

  class FakeSource
    attr_reader :origin

    def initialize(origin: "fake origin", data: nil, error: nil)
      @origin = origin
      @data = data
      @error = error
    end

    def fetch
      raise @error if @error

      @data
    end
  end

  def collector_with(config:, sources:)
    Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: FakeWorktreeManager.new([]),
      context_collector: nil,
      project_root: "/project",
      config: {"status_sources" => config},
      sources: sources,
      # hermetic attention scan: no real ace-hitl inbox in these tests
      attention: Ace::Overseer::Organisms::StatusAttention.new(hitl_events: -> { [] })
    )
  end

  class FakeWorktreeManager
    def initialize(worktrees)
      @worktrees = worktrees
    end

    def list_all(**_options)
      {success: true, worktrees: @worktrees}
    end
  end

  def healthy_sources(overrides = {})
    {
      "worktrees" => FakeSource.new(data: {worktrees: []}),
      "forge" => FakeSource.new(data: []),
      "project_tasks" => FakeSource.new(data: []),
      "overseer_tree" => FakeSource.new(data: []),
      "herdr" => FakeSource.new(data: {workspaces: []}),
      "coworkers" => FakeSource.new(data: [])
    }.merge(overrides)
  end

  def test_all_sources_ok_report_status_origin_and_data
    collector = collector_with(config: {}, sources: healthy_sources)

    snapshot = collector.collect_sources
    payload = collector.to_sources_h(snapshot)

    sources = snapshot[:sources]
    Ace::Overseer::Organisms::StatusCollector::STATUS_SOURCE_ORDER.each do |key|
      assert_equal "ok", sources[key][:status], "#{key} should be ok"
      assert_equal "fake origin", sources[key][:origin]
    end
    assert_equal({worktrees: []}, sources["worktrees"][:data])

    json = JSON.generate(payload)
    parsed = JSON.parse(json)
    parsed["sources"].each do |key, entry|
      assert_equal "ok", entry["status"], key
      assert_equal "fake origin", entry["origin"], key
      assert entry.key?("data"), "#{key} must carry data in JSON"
    end
  end

  def test_disabled_source_in_config_is_respected
    collector = collector_with(
      config: {"forge" => {"enabled" => false}},
      sources: healthy_sources
    )

    snapshot = collector.collect_sources

    assert_equal "disabled", snapshot[:sources]["forge"][:status]
    refute_includes snapshot[:sources]["forge"], :data
    # Other sources still collected
    assert_equal "ok", snapshot[:sources]["worktrees"][:status]
    assert_equal "ok", snapshot[:sources]["herdr"][:status]
  end

  def test_source_without_configured_entry_defaults_to_enabled
    collector = collector_with(config: {}, sources: healthy_sources)

    snapshot = collector.collect_sources

    assert_equal "ok", snapshot[:sources]["forge"][:status]
  end

  def test_one_failing_source_shows_error_next_to_available_results
    collector = collector_with(
      config: {},
      sources: healthy_sources("herdr" => FakeSource.new(error: RuntimeError.new("runtime unreachable")))
    )

    snapshot = collector.collect_sources
    table = collector.to_sources_table(snapshot)

    herdr = snapshot[:sources]["herdr"]
    assert_equal "error", herdr[:status]
    assert_includes herdr[:error], "runtime unreachable"
    refute_includes herdr, :data
    # Available results stay present
    assert_equal "ok", snapshot[:sources]["worktrees"][:status]
    # Table renders both the error and healthy sections
    assert_includes table, "-- herdr"
    assert_includes table, "ERROR"
    assert_includes table, "RuntimeError: runtime unreachable"
    assert_includes table, "-- worktrees"
  end

  def test_table_renders_disabled_and_error_markers
    collector = collector_with(
      config: {"forge" => {"enabled" => false}},
      sources: healthy_sources("coworkers" => FakeSource.new(error: StandardError.new("probe boom")))
    )

    table = collector.to_sources_table(collector.collect_sources)

    assert_includes table, "-- forge: disabled"
    assert_includes table, "-- coworkers"
    assert_includes table, "ERROR StandardError: probe boom"
  end

  def test_worktrees_source_failure_is_error_not_empty_list
    # The worktrees pipeline raising must read as an error, never as
    # "no worktrees" (which could pass for free resources).
    collector = collector_with(
      config: {},
      sources: healthy_sources("worktrees" => FakeSource.new(error: Ace::Overseer::Error.new("worktree listing failed")))
    )

    snapshot = collector.collect_sources

    assert_equal "error", snapshot[:sources]["worktrees"][:status]
    assert_includes snapshot[:sources]["worktrees"][:error], "worktree listing failed"
  end

  # --- ForgeSource offline degradation ---

  class FakeProvider
    def initialize(pull_requests)
      @pull_requests = pull_requests
    end

    def recent_pull_requests(limit:)
      @pull_requests.first(limit)
    end
  end

  FakePullRequest = Data.define(:number, :title, :state, :draft, :head_ref, :url)

  def test_forge_source_maps_recent_pull_requests
    provider = FakeProvider.new([
      FakePullRequest.new(number: 42, title: "Fix", state: :open, draft: true, head_ref: "t-1", url: "https://x/42")
    ])
    source = Ace::Overseer::Organisms::StatusSources::ForgeSource.new(
      server_resolver: -> { "server" },
      provider_factory: ->(_server) { provider }
    )

    data = source.fetch

    assert_equal 1, data[:pull_requests].length
    assert_equal 42, data[:pull_requests][0][:number]
    assert_equal "open", data[:pull_requests][0][:state]
    assert_equal true, data[:pull_requests][0][:draft]
    assert_includes source.origin, "ace-git"
  end

  def test_forge_source_lists_issues_when_the_provider_has_a_listing_api
    issue = Data.define(:number, :title, :state, :url)
    provider = FakeProvider.new([])
    provider.define_singleton_method(:recent_issues) do |limit:|
      [issue.new(number: 7, title: "Broken build", state: :open, url: "https://x/issues/7")].first(limit)
    end
    source = Ace::Overseer::Organisms::StatusSources::ForgeSource.new(
      server_resolver: -> { "server" },
      provider_factory: ->(_server) { provider }
    )

    issues = source.fetch[:issues]

    assert_equal 1, issues.length
    assert_equal 7, issues[0][:number]
    assert_equal "open", issues[0][:state]
  end

  def test_forge_source_marks_issues_unavailable_when_provider_has_no_listing_api
    # Spec .6.1 promises PRs AND issues; a provider without an issue
    # listing API must surface an explicit unavailable marker, never a
    # silent pull-request-only view.
    provider = FakeProvider.new([])
    source = Ace::Overseer::Organisms::StatusSources::ForgeSource.new(
      server_resolver: -> { "server" },
      provider_factory: ->(_server) { provider }
    )

    issues = source.fetch[:issues]

    assert_equal({status: "unavailable", reason: Ace::Overseer::Organisms::StatusSources::ForgeSource::ISSUES_UNAVAILABLE}, issues)
    collector = collector_with(config: {}, sources: healthy_sources("forge" => source))
    table = collector.to_sources_table(collector.collect_sources)
    assert_includes table, "issues: UNAVAILABLE"
    assert_includes table, "no issue-listing API"
  end

  def test_forge_source_offline_raises_and_aggregates_as_error
    source = Ace::Overseer::Organisms::StatusSources::ForgeSource.new(
      server_resolver: -> { raise Ace::Git::AmbiguousRemoteError, "no configured server" }
    )
    collector = collector_with(config: {"forge" => {}}, sources: healthy_sources("forge" => source))

    snapshot = collector.collect_sources

    forge = snapshot[:sources]["forge"]
    assert_equal "error", forge[:status]
    assert_includes forge[:error], "no configured server"
    assert_equal "ok", snapshot[:sources]["project_tasks"][:status]
  end

  # --- ProjectTasksSource / OverseerTreeSource mapping ---

  FakeTask = Struct.new(:id, :status, :title, :priority, :dependencies, :special_folder, keyword_init: true)

  class FakeManager
    def initialize(tasks, root_dir: ".ace-tasks")
      @tasks = tasks
      @root_dir = root_dir
    end

    attr_reader :root_dir

    def list(in_folder:, sort:)
      @tasks.select { |t| in_folder == "all" || in_folder == "_overseer" }
    end
  end

  def test_project_tasks_source_maps_task_fields
    manager = FakeManager.new([
      FakeTask.new(id: "8x1", status: "pending", title: "First", priority: "high", dependencies: ["8x0"])
    ])
    source = Ace::Overseer::Organisms::StatusSources::ProjectTasksSource.new(
      manager_factory: -> { manager }
    )

    data = source.fetch

    assert_equal "8x1", data[0][:id]
    assert_equal "pending", data[0][:status]
    assert_equal ["8x0"], data[0][:dependencies]
  end

  def test_overseer_tree_source_uses_private_folder
    manager = FakeManager.new([
      FakeTask.new(id: "8o1", status: "in-progress", title: "Overseer step", priority: nil, dependencies: [])
    ])
    source = Ace::Overseer::Organisms::StatusSources::OverseerTreeSource.new(
      manager_factory: -> { manager }
    )

    data = source.fetch

    assert_equal "8o1", data[0][:id]
  end

  # --- HerdrSource reuse of ace-herdr composition ---

  class FakeControlSurface
    def list_workspaces
      [{id: "w1", title: "lab", number: 0, focused: true}]
    end

    def list_tabs(workspace_id: nil)
      [{id: "t1", title: "work", workspace: "w1", number: 0, focused: false}]
    end

    def list_panes(workspace_id: nil)
      [{id: "p1", title: "pi", tab: "t1", workspace: "w1", number: 0, focused: false, cwd: "/tmp"}]
    end
  end

  def test_herdr_source_composes_live_layout
    source = Ace::Overseer::Organisms::StatusSources::HerdrSource.new(
      control_surface: -> { FakeControlSurface.new }
    )

    data = source.fetch

    assert_equal 1, data[:workspaces].length
    assert_equal 1, data[:workspaces][0][:pane_count]
  end

  def test_herdr_source_unreachable_runtime_raises
    source = Ace::Overseer::Organisms::StatusSources::HerdrSource.new(
      control_surface: -> { raise RuntimeError, "herdr native unreachable" }
    )

    error = assert_raises(RuntimeError) { source.fetch }
    assert_includes error.message, "herdr native unreachable"
  end

  # --- CoworkersSource: unknown assignment is never a free worktree ---

  class FakeProbe
    def initialize(config, assignments)
      @config = config
      @assignments = assignments
    end

    def probe(_worktree_path)
      {config: @config, assignments: @assignments}
    end
  end

  def coworkers_source(worktrees, probe)
    Ace::Overseer::Organisms::StatusSources::CoworkersSource.new(
      worktree_manager: FakeWorktreeManager.new(worktrees),
      probe_factory: ->(_path) { probe }
    )
  end

  def test_coworkers_source_unknown_commissioned_assignment_reads_busy_unknown
    # Commission names an assignment absent from the inventory: the
    # coworker rule reports state "unknown" and active — never free.
    source = coworkers_source(
      [FakeWorktree.new("/wt/ace-task.230", "230", false)],
      FakeProbe.new({"assignment" => "8or5kx"}, [])
    )

    rows = source.fetch

    assert_nil rows[0][:error]
    assert_equal true, rows[0][:active]
    assert_equal "unknown", rows[0][:evidence]["state"]
    assert_equal "8or5kx", rows[0][:evidence]["assignment"]
  end

  def test_coworkers_source_unparseable_config_reads_busy
    source = coworkers_source(
      [FakeWorktree.new("/wt/ace-task.230", "230", false)],
      FakeProbe.new(Ace::Coworker::Atoms::ActiveExecutorRule::UNPARSEABLE, [])
    )

    rows = source.fetch

    assert_equal true, rows[0][:active]
    assert_equal "unparseable", rows[0][:evidence]["state"]
  end

  def test_coworkers_source_free_worktree_without_executor
    source = coworkers_source(
      [FakeWorktree.new("/wt/ace-task.230", "230", false)],
      FakeProbe.new(nil, [{"id" => "a1", "state" => "completed"}])
    )

    rows = source.fetch

    assert_equal false, rows[0][:active]
    assert_nil rows[0][:evidence]
  end

  def test_coworkers_source_per_worktree_failure_shows_next_to_results
    failing = FakeProbe.new(nil, [])
    failing.define_singleton_method(:probe) { |_p| raise "ace-assign CLI missing" }
    ok = FakeProbe.new({"assignment" => "a1"}, [{"id" => "a1", "state" => "running"}])
    source = Ace::Overseer::Organisms::StatusSources::CoworkersSource.new(
      worktree_manager: FakeWorktreeManager.new([
        FakeWorktree.new("/wt/a", "a", false),
        FakeWorktree.new("/wt/b", "b", false)
      ]),
      probe_factory: ->(path) { path == "/wt/a" ? failing : ok }
    )

    rows = source.fetch

    assert_includes rows[0][:error], "ace-assign CLI missing"
    assert_equal true, rows[1][:active]
  end

  # --- WorktreesSource wraps the existing collector pipeline ---

  def test_worktrees_source_reuses_collector_snapshot
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignments: [],
      git_status: {"clean" => true}
    )
    fake_collector = Object.new
    fake_collector.define_singleton_method(:collect) { {contexts: [context]} }
    fake_collector.define_singleton_method(:to_h) { |_snapshot| {worktrees: [{task_id: "230"}]} }
    source = Ace::Overseer::Organisms::StatusSources::WorktreesSource.new(collector: fake_collector)

    data = source.fetch

    assert_equal [{task_id: "230"}], data[:worktrees]
  end

  # --- Review round 1: main-repo label survives the sources table ---

  def make_assignment(id:, state:)
    {
      "assignment" => {"state" => state, "id" => id, "name" => "work-on-task"},
      "step_summary" => {"total" => 5, "done" => 2, "failed" => 0, "active" => 1, "pending" => 2}
    }
  end

  def make_context(path:, task_id:, assignments:, location_type: :worktree)
    Ace::Overseer::Models::WorkContext.new(
      task_id: task_id,
      worktree_path: path,
      branch: "#{task_id}-branch",
      assignments: assignments,
      git_status: {"clean" => true},
      location_type: location_type
    )
  end

  def worktrees_collector_with_main_assignments
    worktree_context = make_context(
      path: "/wt/ace-task.230", task_id: "230",
      assignments: [make_assignment(id: "8or5kx", state: "running")]
    )
    main_context = make_context(
      path: "/project", task_id: "main",
      assignments: [make_assignment(id: "xyz99", state: "running")],
      location_type: :main
    )
    inner = Ace::Overseer::Organisms::StatusCollector.new(
      worktree_manager: FakeWorktreeManager.new([FakeWorktree.new("/wt/ace-task.230", "230")]),
      context_collector: MainAwareContextCollector.new(worktree_context, main_context),
      project_root: "/project"
    )
    source = Ace::Overseer::Organisms::StatusSources::WorktreesSource.new(collector: inner)
    collector_with(config: {}, sources: healthy_sources("worktrees" => source))
  end

  class MainAwareContextCollector
    def initialize(context, main_context)
      @context = context
      @main_context = main_context
    end

    def collect(_path, location_type: :worktree)
      location_type == :main ? @main_context : @context
    end
  end

  def test_sources_table_keeps_main_label_and_sorts_main_last
    collector = worktrees_collector_with_main_assignments

    table = collector.to_sources_table(collector.collect_sources)
    section = table.split("-- worktrees", 2)[1]

    dim_main = "\e[2m#{'main'.ljust(Ace::Overseer::Atoms::StatusFormatter::COL_LOCATION)}\e[0m"
    assert_includes section, dim_main
    assert_includes section, "ace-task.230"
    # The main row sorts last (after the regular worktree row).
    assert_operator section.index("ace-task.230"), :<, section.index(dim_main)
  end

  def test_worktrees_payload_serializes_location_type
    collector = worktrees_collector_with_main_assignments

    snapshot = collector.collect_sources
    entries = snapshot[:sources]["worktrees"][:data][:worktrees]

    assert_equal :main, entries.first[:location_type]
    assert_equal :worktree, entries.last[:location_type]
  end

  # --- Review round 1: unknown status_sources keys are never silent ---

  def test_unknown_source_and_option_keys_render_warnings
    collector = collector_with(
      config: {"herder" => {}, "forge" => {"enabeld" => false, "enabled" => false}},
      sources: healthy_sources
    )

    snapshot = collector.collect_sources
    table = collector.to_sources_table(snapshot)
    payload = collector.to_sources_h(snapshot)

    assert_includes snapshot[:unknown_keys], "herder"
    assert_includes snapshot[:unknown_keys], "forge.enabeld"
    assert_includes table, "-- herder: unknown source (ignored)"
    assert_includes table, "-- forge.enabeld: unknown option (ignored)"
    parsed = JSON.parse(JSON.generate(payload))
    assert_includes parsed["unknown_keys"], "herder"
    assert_includes parsed["unknown_keys"], "forge.enabeld"
  end

  def test_known_config_keys_are_not_reported_unknown
    collector = collector_with(
      config: {"forge" => {"enabled" => false, "limit" => 5}},
      sources: healthy_sources
    )

    snapshot = collector.collect_sources

    assert_empty snapshot[:unknown_keys]
  end

  # --- Review round 1: partial snapshot does not raise ---

  def test_to_sources_table_skips_missing_snapshot_entries
    collector = collector_with(config: {}, sources: healthy_sources)

    table = collector.to_sources_table({sources: {"worktrees" => {status: "ok", origin: "o", data: {worktrees: []}}}})

    assert_includes table, "-- worktrees"
    refute_includes table, "-- forge"
  end

  # --- Review round 1: ForgeSource limit config wiring ---

  def pull_requests(count)
    Array.new(count) { |i| FakePullRequest.new(number: i + 1, title: "PR #{i + 1}", state: :open, draft: false, head_ref: "b-#{i}", url: "https://x/#{i + 1}") }
  end

  def forge_source_with(pull_count, config: {})
    Ace::Overseer::Organisms::StatusSources::ForgeSource.new(
      config: config,
      server_resolver: -> { "server" },
      provider_factory: ->(_server) { FakeProvider.new(pull_requests(pull_count)) }
    )
  end

  def test_forge_limit_config_is_wired_through
    source = forge_source_with(3, config: {"limit" => 2})

    assert_equal 2, source.fetch[:pull_requests].length
  end

  def test_forge_limit_typo_falls_back_to_default
    source = forge_source_with(3, config: {"limit" => "lots"})

    assert_equal 3, source.fetch[:pull_requests].length
  end

  def test_forge_explicit_zero_limit_lists_nothing
    source = forge_source_with(3, config: {"limit" => 0})

    assert_empty source.fetch[:pull_requests]
  end

  def test_forge_negative_limit_clamps_to_zero
    source = forge_source_with(3, config: {"limit" => -5})

    assert_empty source.fetch[:pull_requests]
  end

  # --- Full descendant tree through the real ace-task owner (PR393 P2) ---

  def with_real_task_tree(&block)
    require "tmpdir"
    Dir.mktmpdir("pr393-status") do |root|
      parent = File.join(root, "_overseer", "8xg.t.mgr-manage")
      FileUtils.mkdir_p(File.join(parent, "0-implement"))
      FileUtils.mkdir_p(File.join(parent, "1-integrate"))
      File.write(File.join(parent, "8xg.t.mgr.s.md"), "---\nstatus: progress\n---\n# Manage\n")
      File.write(File.join(parent, "0-implement", "8xg.t.mgr.0.s.md"),
        "---\nstatus: done\nparent: 8xg.t.mgr\nprocessed_report: ab12cd\n---\n# Implement\n")
      File.write(File.join(parent, "1-integrate", "8xg.t.mgr.1.s.md"),
        "---\nstatus: pending\nparent: 8xg.t.mgr\ndependencies: [8xg.t.missing]\n---\n# Integrate\n")
      yield root
    end
  end

  def test_overseer_tree_source_includes_lifecycle_steps_and_their_recorded_report
    with_real_task_tree do |root|
      tm = Ace::Task::Organisms::TaskManager.new(root_dir: root)

      data = Ace::Overseer::Organisms::StatusSources::OverseerTreeSource.new(manager_factory: -> { tm }).fetch

      ids = data.map { |row| row[:id] }
      assert_equal %w[8xg.t.mgr 8xg.t.mgr.0 8xg.t.mgr.1], ids,
        "the source must flatten the manager's full step tree, not only the manager row"
      blocked = data.find { |row| row[:id] == "8xg.t.mgr.1" }
      assert_equal ["8xg.t.missing"], blocked[:dependencies],
        "a blocked child's dependency must survive so attention can resolve it"
      recorded = data.find { |row| row[:id] == "8xg.t.mgr.0" }
      assert_equal "ab12cd", recorded[:processed_report],
        "the step's processed report must travel with the row"
    end
  end

  def test_project_tasks_source_flattens_three_level_backlog
    require "tmpdir"
    Dir.mktmpdir("pr393-backlog") do |root|
      primary = File.join(root, "8xg.t.prj-backlog")
      group = File.join(primary, "6-l7-status")
      leaf = File.join(group, "1-zebrac-status")
      FileUtils.mkdir_p(leaf)
      File.write(File.join(primary, "8xg.t.prj.s.md"), "---\nstatus: progress\n---\n# Backlog\n")
      File.write(File.join(group, "8xg.t.prj.6.s.md"),
        "---\nstatus: progress\nparent: 8xg.t.prj\n---\n# Status group\n")
      File.write(File.join(leaf, "8xg.t.prj.6.1.s.md"),
        "---\nstatus: pending\nparent: 8xg.t.prj.6\ndependencies: [8xg.t.prj.6]\n---\n# Configure status\n")
      tm = Ace::Task::Organisms::TaskManager.new(root_dir: root)

      data = Ace::Overseer::Organisms::StatusSources::ProjectTasksSource.new(manager_factory: -> { tm }).fetch

      ids = data.map { |row| row[:id] }
      assert_includes ids, "8xg.t.prj.6.1",
        "grandchildren must be flattened through the owner's scanner/loader, not dropped"
      assert_equal %w[8xg.t.prj 8xg.t.prj.6 8xg.t.prj.6.1], ids
    end
  end

  # --- Descendant re-scan is rooted at the manager's tree (review fix) ---

  def test_descendant_rescan_uses_the_managers_root_dir_not_a_hardcoded_literal
    require "tmpdir"
    Dir.mktmpdir("rooted-descendants") do |root|
      primary = File.join(root, "8xg.t.rtd-rooted")
      group = File.join(primary, "0-group")
      leaf = File.join(group, "1-leaf")
      FileUtils.mkdir_p(leaf)
      File.write(File.join(primary, "8xg.t.rtd.s.md"), "---\nstatus: progress\n---\n# Rooted\n")
      File.write(File.join(group, "8xg.t.rtd.0.s.md"),
        "---\nstatus: progress\nparent: 8xg.t.rtd\n---\n# Group\n")
      File.write(File.join(leaf, "8xg.t.rtd.0.1.s.md"),
        "---\nstatus: pending\nparent: 8xg.t.rtd.0\n---\n# Leaf\n")
      tm = Ace::Task::Organisms::TaskManager.new(root_dir: root)

      scanner_class = Ace::Task::Molecules::TaskScanner
      scanned_roots = []
      scanner_class.singleton_class.send(:alias_method, :__original_new, :new)
      scanner_class.define_singleton_method(:new) do |root_dir, &blk|
        scanned_roots << root_dir
        method(:__original_new).call(root_dir, &blk)
      end
      begin
        data = Ace::Overseer::Organisms::StatusSources::ProjectTasksSource.new(manager_factory: -> { tm }).fetch
      ensure
        scanner_class.singleton_class.send(:alias_method, :new, :__original_new)
        scanner_class.singleton_class.send(:remove_method, :__original_new)
      end

      ids = data.map { |row| row[:id] }
      assert_includes ids, "8xg.t.rtd.0.1",
        "grandchildren of a manager rooted outside .ace-tasks must still resolve"
      assert_includes scanned_roots, root,
        "the descendant re-scan must be rooted at the manager's root_dir"
      refute_includes scanned_roots, ".ace-tasks",
        "the descendant re-scan must never fall back to a CWD-relative .ace-tasks literal"
    end
  end
end
