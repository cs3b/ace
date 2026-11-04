# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_configuration"

module Ace::Lab::Auth
  class SessionConfigurationTest < Minitest::Test
    def setup
      @document = {"projects" => [{"id" => "ace", "path" => "/lab/ace"}],
        "roles" => [{"id" => "worker", "account" => "mo", "instructions" => "wfi://task/work"}],
        "grants" => {"mo" => ["ace"]}, "gemset" => {"gem_home" => "/opt/ace/runtime/gems"},
        "session_runtime" => {"node" => "/opt/node", "pi" => "/opt/pi.js"}}
      @configuration = SessionConfiguration.new(loader: -> { @document })
    end

    def test_execution_directory_cannot_widen_project_or_relocate_overseer
      selected = @configuration.resolve(project: "ace", role: "worker", principal: "mo")
      assert_equal "/lab/ace", selected.execution_directory
      worktree = "/lab/ace/.ace-wt/task-1"
      File.stub(:realpath, ->(path) { path }) do
        File.stub(:directory?, true) { assert_equal worktree, selected.execution_directory(worktree) }
      end
      ["/lab/other", "/lab/ace/.ace-wt/../other", "/lab/ace/.ace-wt/.private/deep", "/etc", 4].each do |path|
        assert_raises(Error) { selected.execution_directory(path) }
      end
      File.stub(:realpath, "/lab/other") do
        assert_raises(Error) { selected.execution_directory(worktree) }
      end
      overseer = SessionConfiguration::Selection.new(**selected.to_h.merge(role: "project-overseer"))
      assert_raises(Error) { overseer.execution_directory(worktree) }
    end

    def test_resolves_from_existing_host_manifest
      selected = @configuration.resolve(project: "ace", role: "worker", principal: "mo")
      assert_equal "/lab/ace", selected.path
      assert_equal "wfi://task/work", selected.instructions
      assert_equal "/opt/ace/runtime/gems", selected.gem_home
    end

    def test_only_granted_host_can_launch_coordinator_in_its_distinct_root
      @document["coordinator"] = {"id" => "lab", "path" => "/lab"}
      @document["roles"] << {"id" => "lab-overseer", "account" => "mo", "instructions" => "wfi://overseer/lab-start"}
      assert_raises(Error) { @configuration.resolve(project: "lab", role: "lab-overseer", principal: "mo") }
      @document["grants"]["mo"] << "lab"
      selected = @configuration.resolve(project: "lab", role: "lab-overseer", principal: "mo")
      assert_equal "/lab", selected.path
      assert_equal "wfi://overseer/lab-start", selected.instructions
      assert_raises(Error) { @configuration.resolve(project: "lab", role: "worker", principal: "mo") }
      assert_raises(Error) { @configuration.resolve(project: "ace", role: "lab-overseer", principal: "mo") }
      @document["grants"]["session:lab-overseer"] = %w[lab ace]
      caller = SessionPeer::Identity.new(role: "lab-overseer", project_root: "/lab")
      assert_raises(Error) { @configuration.resolve(project: "lab", role: "lab-overseer", session: caller) }
      assert_raises(Error) { @configuration.resolve(project: "lab", role: "worker", session: caller) }
      assert_equal "/lab/ace", @configuration.resolve(project: "ace", role: "worker", session: caller).path
    end

    def test_refuses_cross_principal_unknown_role_and_unknown_project
      [{principal: "other"}, {role: "integrator"}, {project: "other"}].each do |override|
        arguments = {project: "ace", role: "worker", principal: "mo"}.merge(override)
        assert_raises(Error) { @configuration.resolve(**arguments) }
      end
    end

    def test_missing_runtime_never_falls_back_to_checkout
      @document["gemset"] = nil
      assert_raises(Error) { @configuration.resolve(project: "ace", role: "worker", principal: "mo") }
    end

    def test_delegation_requires_explicit_grant_and_system_project_binding
      identity = SessionPeer::Identity.new(role: "project-overseer", project_root: "/lab/ace")
      assert_raises(Error) { @configuration.resolve(project: "ace", role: "worker", session: identity) }
      @document["grants"]["session:project-overseer"] = ["ace"]
      assert_equal "worker", @configuration.resolve(project: "ace", role: "worker", session: identity).role
      identity.project_root = "/lab/other"
      assert_raises(Error) { @configuration.resolve(project: "ace", role: "worker", session: identity) }
      identity.project_root = "/lab/ace"
      identity.role = "worker"
      @document["grants"]["session:worker"] = ["ace"]
      assert_raises(Error) { @configuration.resolve(project: "ace", role: "worker", session: identity) }
      assert_raises(Error) { @configuration.resolve(project: "ace", role: "worker", session: identity, principal: "mo") }
    end

    def test_lab_overseer_can_bootstrap_a_granted_project_but_not_another_lab_overseer
      identity = SessionPeer::Identity.new(role: "lab-overseer", project_root: "/lab")
      @document["grants"]["session:lab-overseer"] = ["ace"]
      assert_equal "/lab/ace", @configuration.resolve(project: "ace", role: "worker", session: identity).path
      @document["roles"] << {"id" => "lab-overseer", "account" => "mo", "instructions" => "wfi://overseer/start"}
      assert_raises(Error) { @configuration.resolve(project: "ace", role: "lab-overseer", session: identity) }
    end
  end
end
