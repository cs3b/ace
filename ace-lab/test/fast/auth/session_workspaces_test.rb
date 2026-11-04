# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_workspaces"

module Ace::Lab::Auth
  class SessionWorkspacesTest < Minitest::Test
    def setup
      @identity = SessionPeer::Identity.new(role: "lab-overseer", project_root: "/lab", terminal_id: "term_1111")
      @document = {"projects" => [{"id" => "ace", "path" => "/lab/ace"}, {"id" => "other", "path" => "/lab/other"}],
        "roles" => [{"id" => "worker", "instructions" => "wfi://coworker/worker"}],
        "grants" => {"session:lab-overseer" => ["ace"], "session:project-overseer" => %w[ace other]},
        "gemset" => {"gem_home" => "/opt/ace/gems"}, "session_runtime" => {}}
      @sent = []
      @row = {"workspace_id" => "w2", "label" => "ace", "tokens" => {"secret" => "hidden"},
        "worktree" => {"checkout_path" => "/private"}}
      owner = self
      transport = Object.new
      transport.define_singleton_method(:call) { |message, **options| owner.respond(message, options) }
      @handler = SessionWorkspaces.new(loader: -> { @document }, transport: transport)
    end

    def respond(message, options)
      assert_same @identity, options.fetch(:identity)
      @sent << message
      result = if message["method"] == "workspace.list"
        {"workspaces" => [@row, @row.merge("label" => "other"), @row.merge("label" => "manual")]}
      else
        {"workspace" => @row, "root_pane" => {"cwd" => "/private"}}
      end
      {"id" => message["id"], "result" => result}
    end

    def call(method, params = {})
      @handler.call({"id" => "spaces", "method" => method, "params" => params}, identity: @identity)
    end

    def test_list_exposes_only_granted_project_grouping_without_metadata
      assert_equal [{"workspace_id" => "w2", "label" => "ace"}], call("workspace.list").dig("result", "workspaces")
    end

    def test_creation_uses_configured_path_and_drops_host_pane_details
      reply = call("workspace.create", {"label" => "ace"})
      assert_equal({"label" => "ace", "cwd" => "/lab/ace", "focus" => false}, @sent.last["params"])
      assert_equal({"workspace_id" => "w2", "label" => "ace"}, reply.dig("result", "workspace"))
      refute reply.fetch("result").key?("root_pane")
    end

    def test_foreign_project_and_runtime_overrides_fail_before_native_mutation
      [{"label" => "other"}, {"label" => "ace", "cwd" => "/tmp"}, {"label" => "ace", "focus" => true},
        {"label" => "ace", "env" => {"PATH" => "/tmp"}}, {"label" => "ace", "source_workspace_id" => "w1"}].each do |params|
        assert_raises(Error) { call("workspace.create", params) }
      end
      assert_empty @sent
    end

    def test_worker_cannot_discover_or_create_workspaces
      @identity.role = "worker"
      assert_raises(Error) { call("workspace.list") }
      assert_raises(Error) { call("workspace.create", {"label" => "ace"}) }
      assert_empty @sent
    end

    def test_project_supervisor_cannot_manage_sibling_despite_global_role_grant
      @identity.role = "project-overseer"
      @identity.project_root = "/lab/ace"
      assert_equal ["ace"], call("workspace.list").dig("result", "workspaces").map { |row| row["label"] }
      assert_raises(Error) { call("workspace.create", {"label" => "other"}) }
      assert_equal 1, @sent.size
    end

    def test_creation_refuses_mismatched_native_identity
      @row["label"] = "other"
      assert_raises(Error) { call("workspace.create", {"label" => "ace"}) }
    end
  end
end
