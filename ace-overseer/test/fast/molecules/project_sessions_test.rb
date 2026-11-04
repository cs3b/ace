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
    @observer = Ace::Overseer::Molecules::ProjectSessions.new(root: @root, control: @control, root_resolver: resolver)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def isolated_observer(agents)
    executor = Object.new
    executor.define_singleton_method(:agent_list) { Struct.new(:parsed_json).new({"result" => {"agents" => agents}}) }
    control = Object.new
    control.define_singleton_method(:list_tabs) { raise "isolated observation cannot read host tabs" }
    resolver = Object.new
    def resolver.resolve(cwd:) = File.realpath(cwd)
    Ace::Overseer::Molecules::ProjectSessions.new(root: @root, control: control, root_resolver: resolver,
      executor: executor, env: {"ACE_LAB_SESSION" => "1", "ACE_TOOLCHAIN" => "installed"})
  end

  def test_isolated_observation_uses_native_role_identity_and_ignores_worker_or_spoofed_name
    agent = {"terminal_id" => "term_1234", "cwd" => @project, "agent_status" => "working",
      "isolated_session" => {"project" => "ace", "role" => "project-overseer"}}
    agents = [agent.merge("isolated_session" => nil, "name" => "overseer-ace"),
      agent.merge("isolated_session" => {"project" => "ace", "role" => "worker"})]
    observer = isolated_observer(agents)
    absent = observer.call.first
    assert_equal "absent", absent["state"]
    agents << agent
    working = observer.call.first
    assert_equal "working", working["state"]
    assert_equal "term_1234", working["pane"]
    refute_equal absent["revision"], working["revision"]
    assert_equal working, observer.call.first
  end

  def test_isolated_observation_rejects_duplicate_owners_and_foreign_root
    agent = {"terminal_id" => "term_1234", "cwd" => @root, "agent_status" => "idle",
      "isolated_session" => {"project" => "ace", "role" => "project-overseer"}}
    assert_equal "unavailable", isolated_observer([agent]).call.first["state"]
    agent["cwd"] = @project
    assert_equal "unavailable", isolated_observer([agent, agent.merge("terminal_id" => "term_5678")]).call.first["state"]
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
    refute_equal working.fetch("revision"), idle.fetch("revision")
    assert_equal "idle", idle.fetch("state")
  end

  def test_ambiguous_owner_never_looks_healthy
    @control.tabs = [{id: "t1", title: "overseer-ace"}, {id: "t2", title: "overseer-ace"}]
    @control.panes = [{id: "p1", tab: "t1", cwd: @project, agent_status: "idle"},
                      {id: "p2", tab: "t2", cwd: @project, agent_status: "idle"}]
    row = @observer.call.fetch(0)
    assert_equal "unavailable", row.fetch("state")
    assert_match(/ambiguous/, row.fetch("error"))
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
    observer = Ace::Overseer::Molecules::ProjectSessions.new(root: @root, control: @control)
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
    observer = Ace::Overseer::Molecules::ProjectSessions.new(root: @root, control: @control)
    row = observer.call.fetch(0)
    assert_equal "idle", row.fetch("state")
    assert_equal File.realpath(@project), row.fetch("root")
  end
end
