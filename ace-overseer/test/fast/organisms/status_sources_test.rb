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
      sources: sources
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

    assert_equal 1, data.length
    assert_equal 42, data[0][:number]
    assert_equal "open", data[0][:state]
    assert_equal true, data[0][:draft]
    assert_includes source.origin, "ace-git"
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

  FakeTask = Struct.new(:id, :status, :title, :priority, :dependencies, keyword_init: true)

  class FakeManager
    def initialize(tasks)
      @tasks = tasks
    end

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
end
