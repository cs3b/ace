# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"

class ProjectSessionsTest < Minitest::Test
  Control = Struct.new(:tabs, :panes) do
    def list_tabs = tabs
    def list_panes = panes
  end

  def setup
    @root = Dir.mktmpdir("ace-project-sessions")
    @project = File.join(@root, "ace")
    FileUtils.mkdir_p([@project, File.join(@root, ".ace/lab")])
    File.write(File.join(@root, ".ace/lab/config.yml"),
      {"topology" => {"projects" => [{"id" => "ace", "path" => @project},
                                     {"id" => "self", "path" => @root}]}}.to_yaml)
    @control = Control.new([], [])
    resolver = Object.new
    def resolver.resolve(cwd:) = File.realpath(cwd)
    @executor = Object.new
    def @executor.agent_get(_pane)
      Struct.new(:parsed_json).new({"agent" => {"agent_status" => "idle"}})
    end
    @readiness = Struct.new(:ready).new(false)
    def @readiness.ready?(**_args) = ready
    @observer = Ace::Overseer::Molecules::ProjectSessions.new(root: @root, control: @control,
      root_resolver: resolver, executor: @executor, eyes_evidence: @readiness)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end




  def test_project_session_lifecycle_revises_without_observing_self
    absent = @observer.call.fetch(0)
    assert_equal "absent", absent.fetch("state")
    @control.tabs = [{id: "tab1", title: "overseer-ace"}, {id: "lab", title: "overseer-lab"}]
    @control.panes = [{id: "p1", tab: "tab1", cwd: @project, agent_status: "working"},
                      {id: "self", tab: "lab", cwd: @root, agent_status: "working"}]
    working = @observer.call.fetch(0)
    refute_equal absent.fetch("revision"), working.fetch("revision")
    assert_equal "working", working.fetch("state")
    assert_equal [working], @observer.call
    @control.panes.first[:agent_status] = "idle"
    idle = @observer.call.fetch(0)
    assert_equal working.fetch("revision"), idle.fetch("revision"), "ordinary project turns do not require lab action"
    assert_equal "idle", idle.fetch("state")
  end

  def test_retained_single_terminal_without_agent_is_absent
    @control.tabs = [{id: "tab1", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "tab1", cwd: @project, agent_status: "idle"}]
    live = @observer.call.first
    executor = Object.new
    def executor.agent_get(_pane) = raise(Ace::Herdr::AgentNotFoundError, "exited")
    @observer.instance_variable_set(:@executor, executor)
    dead = @observer.call.first
    assert_equal "absent", dead["state"]
    refute_equal live["revision"], dead["revision"]
    assert_equal dead, @observer.call.first
  end

  def ready_project
    @control.tabs = [{id: "tab1", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "tab1", cwd: @project, agent_status: "working"}]
    agent = {"terminal_id" => "terminal-1", "agent_session" => {"value" => "session-1"}}
    @executor.define_singleton_method(:agent_get) do |_pane|
      Struct.new(:parsed_json).new({"agent" => agent.dup})
    end
    agent
  end

  def test_readiness_confirmation_is_stable_across_inconclusive_samples_and_ordinary_turns
    ready_project
    initializing = @observer.call
    assert_equal 1, initializing.length
    @readiness.ready = true
    ready = @observer.call
    assert_equal initializing.first, ready.first
    marker = ready.fetch(1)
    assert_equal "project-ready", marker.fetch("type")
    assert marker.fetch("ready")
    %w[idle done working].each do |state|
      @control.panes.first[:agent_status] = state
      current = @observer.call
      assert_equal initializing.first.fetch("revision"), current.first.fetch("revision")
      assert_equal marker, current.fetch(1)
    end
    @readiness.ready = false
    assert_equal 1, @observer.call.length
    @readiness.ready = true
    assert_equal marker, @observer.call.fetch(1)
  end

  def test_replacement_session_has_a_distinct_confirmation_even_in_the_same_terminal
    agent = ready_project
    @readiness.ready = true
    original = @observer.call.fetch(1)
    agent["agent_session"] = {"value" => "session-2"}
    replacement = @observer.call.fetch(1)
    refute_equal original.fetch("key"), replacement.fetch("key")
    refute_equal original.fetch("revision"), replacement.fetch("revision")
  end

  def test_agent_exit_during_proof_does_not_emit_readiness
    ready_project
    executor = @executor
    @readiness.define_singleton_method(:ready?) do |**_args|
      executor.define_singleton_method(:agent_get) do |_pane|
        raise Ace::Herdr::AgentNotFoundError, "exited during proof"
      end
      true
    end
    assert_equal 1, @observer.call.length
    assert_equal "absent", @observer.call.first.fetch("state")
  end

  def test_replacement_during_proof_does_not_emit_old_session_readiness
    agent = ready_project
    @readiness.define_singleton_method(:ready?) do |**_args|
      agent["agent_session"] = {"value" => "replacement"}
      true
    end
    assert_equal 1, @observer.call.length
  end

  def test_ambiguous_owner_never_looks_healthy
    @control.tabs = [{id: "t1", title: "overseer-ace"}, {id: "t2", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "t1", cwd: @project, agent_status: "idle"},
                      {id: "p2", tab: "t2", cwd: @project, agent_status: "idle"}]
    executor = Object.new
    def executor.agent_get(_pane)
      Struct.new(:parsed_json).new({"agent" => {"agent_status" => "idle"}})
    end
    @observer.instance_variable_set(:@executor, executor)
    row = @observer.call.fetch(0)
    assert_equal "unavailable", row.fetch("state")
    assert_match(/ambiguous/, row.fetch("error"))
  end

  def test_dead_previous_panel_does_not_hide_live_replacement
    @control.tabs = [{id: "t1", title: "overseer-ace"}, {id: "t2", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "t1", cwd: @project, agent_status: "idle"},
                      {id: "p2", tab: "t2", cwd: @project, agent_status: "working"}]
    executor = Object.new
    def executor.agent_get(pane)
      raise Ace::Herdr::AgentNotFoundError, "gone" if pane == "p1"
      Struct.new(:parsed_json).new({"result" => {"agent" => {"agent_status" => "working"}}})
    end
    @observer.instance_variable_set(:@executor, executor)
    row = @observer.call.fetch(0)
    assert_equal "working", row.fetch("state")
    assert_equal "p2", row.fetch("pane")
    assert_equal row, @observer.call.fetch(0)
  end

  def test_all_retained_panels_without_agents_are_absent_not_ambiguous
    @control.tabs = [{id: "t1", title: "overseer-ace"}, {id: "t2", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "t1", cwd: @project, agent_status: "idle"},
                      {id: "p2", tab: "t2", cwd: @project, agent_status: "idle"}]
    def @executor.agent_get(_pane) = raise(Ace::Herdr::AgentNotFoundError, "exited")

    row = @observer.call.fetch(0)
    assert_equal "absent", row.fetch("state")
    assert_nil row.fetch("pane")
    refute row.key?("error")
    assert_equal row, @observer.call.fetch(0)
  end

  def test_missing_project_does_not_hide_healthy_project
    File.write(File.join(@root, ".ace/lab/config.yml"),
      {"topology" => {"projects" => [{"id" => "ace", "path" => @project},
                                     {"id" => "missing", "path" => File.join(@root, "missing")}]}}.to_yaml)
    rows = @observer.call
    assert_equal "absent", rows.find { |row| row["project"] == "ace" }.fetch("state")
    assert_equal "unavailable", rows.find { |row| row["project"] == "missing" }.fetch("state")
  end

  def test_self_only_topology_does_not_contact_herdr
    File.write(File.join(@root, ".ace/lab/config.yml"),
      {"topology" => {"projects" => [{"id" => "self", "path" => @root}]}}.to_yaml)
    def @control.list_tabs = raise("unexpected herdr call")
    assert_empty @observer.call
  end

  def test_duplicate_project_root_does_not_emit_colliding_event_keys
    File.write(File.join(@root, ".ace/lab/config.yml"),
      {"topology" => {"projects" => [{"id" => "ace", "path" => @project},
                                     {"id" => "other", "path" => @project}]}}.to_yaml)
    rows = @observer.call
    assert_equal 2, rows.map { |row| row.fetch("key") }.uniq.length
    assert_equal "unavailable", rows.find { |row| row["project"] == "other" }.fetch("state")
  end

  def test_unreported_pane_directory_is_not_accepted_as_matching_owner
    @control.tabs = [{id: "t1", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "t1", cwd: nil, agent_status: "idle"}]
    row = @observer.call.fetch(0)
    assert_equal "unavailable", row.fetch("state")
    assert_match(/did not report a working directory/, row.fetch("error"))
  end

  def test_foreign_pane_directory_is_not_accepted_as_matching_owner
    other = File.join(@root, "other")
    FileUtils.mkdir_p(other)
    @control.tabs = [{id: "t1", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "t1", cwd: other, agent_status: "idle"}]
    row = @observer.call.fetch(0)
    assert_equal "unavailable", row.fetch("state")
    assert_match(/different root/, row.fetch("error"))
  end

  def test_configured_subdirectory_uses_the_same_git_root_as_start
    assert system("git", "init", "-q", @project)
    nested = File.join(@project, "nested")
    FileUtils.mkdir_p(nested)
    File.write(File.join(@root, ".ace/lab/config.yml"),
      {"topology" => {"projects" => [{"id" => "ace", "path" => nested}]}}.to_yaml)
    @control.tabs = [{id: "tab1", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "tab1", cwd: @project, agent_status: "working"}]
    observer = Ace::Overseer::Molecules::ProjectSessions.new(root: @root, control: @control, executor: @executor, eyes_evidence: @readiness)
    row = observer.call.fetch(0)
    assert_equal "working", row.fetch("state")
    assert_equal File.realpath(@project), row.fetch("root")
  end

  def test_configured_linked_worktree_observes_the_main_project_session
    assert system("git", "init", "-q", @project)
    assert system("git", "-C", @project, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
      "commit", "--allow-empty", "-qm", "fixture")
    linked = File.join(@root, "linked")
    assert system("git", "-C", @project, "worktree", "add", "--detach", "-q", linked)
    File.write(File.join(@root, ".ace/lab/config.yml"),
      {"topology" => {"projects" => [{"id" => "ace", "path" => linked}]}}.to_yaml)
    @control.tabs = [{id: "tab1", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "tab1", cwd: @project, agent_status: "idle"}]
    observer = Ace::Overseer::Molecules::ProjectSessions.new(root: @root, control: @control, executor: @executor, eyes_evidence: @readiness)
    row = observer.call.fetch(0)
    assert_equal "idle", row.fetch("state")
    assert_equal File.realpath(@project), row.fetch("root")
  end
end
