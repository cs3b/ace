# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_delegate"

module Ace::Lab::Auth
  class SessionDelegateTest < Minitest::Test
    def setup
      @document = {"projects" => [{"id" => "ace", "path" => "/lab/ace"}, {"id" => "other", "path" => "/lab/other"}],
        "roles" => %w[worker project-overseer lab-overseer].map { |role| {"id" => role, "account" => "mo", "instructions" => "wfi://task/work"} },
        "grants" => {"mo" => %w[ace other], "session:project-overseer" => %w[ace other], "session:lab-overseer" => ["ace"]},
        "gemset" => {"gem_home" => "/opt/ace/gems"}, "session_runtime" => {}}
      @identity = SessionPeer::Identity.new(role: "project-overseer", project_root: "/lab/ace")
      @sent = []
      sent = @sent
      transport = Object.new
      transport.define_singleton_method(:call) do |message, **options|
        sent << [message, options]
        {"id" => message["id"], "result" => {"type" => "agent_isolated_started"}}
      end
      @delegate = SessionDelegate.new(configuration: SessionConfiguration.new(loader: -> { @document }), transport: transport)
      @request = {"id" => "delegate-1", "method" => "agent.start_isolated", "params" => {
        "name" => "assignment-a", "workspace_id" => "w1", "project" => "ace", "role" => "worker"}}
    end

    def test_authorized_delegation_preserves_original_identity_and_stable_name
      assert_equal "agent_isolated_started", @delegate.call(@request, identity: @identity).dig("result", "type")
      assert_equal @request, @sent.first.first
      refute_same @request, @sent.first.first
      assert_same @identity, @sent.first.last.fetch(:identity)
      assert_equal 60, @sent.first.last.fetch(:timeout)
    end

    def test_host_grants_cannot_replace_original_project_or_role_authority
      @request["params"]["project"] = "other"
      assert_raises(Error) { @delegate.call(@request, identity: @identity) }
      @request["params"]["project"] = "ace"
      @identity.role = "worker"
      assert_raises(Error) { @delegate.call(@request, identity: @identity) }
      @identity.role = "lab-overseer"
      @request["params"]["role"] = "lab-overseer"
      assert_raises(Error) { @delegate.call(@request, identity: @identity) }
      assert_empty @sent
    end

    def test_arbitrary_runtime_or_terminal_overrides_never_reach_native
      %w[terminal_id argv env cwd principal].each do |field|
        request = @request.merge("params" => @request["params"].merge(field => "injected"))
        assert_raises(Error) { @delegate.call(request, identity: @identity) }
      end
      assert_empty @sent
    end

    def test_revoked_grant_refuses_before_forwarding
      @document["grants"]["session:project-overseer"] = []
      assert_raises(Error) { @delegate.call(@request, identity: @identity) }
      assert_empty @sent
    end
  end
end
