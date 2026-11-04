# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_control"

module Ace::Lab::Auth
  class SessionControlTest < Minitest::Test
    def setup
      @identity = SessionPeer::Identity.new(role: "project-overseer", project_root: "/lab/ace", terminal_id: "term_1111")
      document = {"projects" => [{"id" => "ace", "path" => "/lab/ace"}, {"id" => "other", "path" => "/lab/other"}],
        "roles" => [{"id" => "worker", "instructions" => "wfi://coworker/worker"}],
        "grants" => {"session:project-overseer" => %w[ace other]}, "gemset" => {"gem_home" => "/opt/ace/gems"}, "session_runtime" => {}}
      @agent = {"terminal_id" => "term_2222", "name" => "worker", "agent_status" => "idle",
        "isolated_session" => {"project" => "ace", "role" => "worker"},
        "agent_session" => {"value" => "/private/transcript"}, "tokens" => {"secret" => "private"}, "title" => "private text"}
      @origin = {"terminal_id" => "term_2222", "runtime_incarnation" => "fixed", "child" => {"uid" => 62000}}
      @sent = []
      owner = self
      transport = Object.new
      transport.define_singleton_method(:call) { |message, **options| owner.respond(message, options) }
      @control = SessionControl.new(configuration: SessionConfiguration.new(loader: -> { document }), transport: transport)
    end

    def respond(message, options)
      assert_same @identity, options.fetch(:identity)
      @sent << message
      result = case message["method"]
      when "agent.list" then {"agents" => [@agent, @agent.merge("terminal_id" => "term_3333", "isolated_session" => {"project" => "other", "role" => "worker"}), @agent.merge("isolated_session" => nil)]}
      when "agent.get" then {"agent" => @agent}
      when "pane.process_info" then {"process_info" => {"guarded_prompt" => !@origin.nil?, "guarded_prompt_origin" => @origin}}
      when "agent.prompt" then {"agent" => @agent, "submission" => "issued"}
      end
      {"id" => message["id"], "result" => result}
    end

    def call(method, params = {})
      @control.call({"id" => "control", "method" => method, "params" => params}, identity: @identity)
    end

    def test_current_pane_uses_only_authenticated_terminal_and_project_root
      @identity.terminal_id = "term_2222"
      pane = call("pane.current", {"caller_pane_id" => "term_2222"}).dig("result", "pane")
      assert_equal "/lab/ace", pane["cwd"]
      assert_equal "term_2222", @sent.last.dig("params", "target")
      refute pane.key?("agent_session")
      assert_raises(Error) { call("pane.current", {"caller_pane_id" => "term_3333"}) }
      assert_equal 1, @sent.size
      @agent["terminal_id"] = "term_3333"
      assert_raises(Error) { call("pane.current") }
    end

    def test_list_filters_foreign_and_nonisolated_agents_and_private_metadata
      agents = call("agent.list").dig("result", "agents")
      assert_equal 1, agents.size
      assert_equal %w[agent_status isolated_session name terminal_id], agents.first.keys.sort
    end

    def test_prompt_is_bound_to_resolved_terminal_and_captured_runtime
      result = call("agent.prompt", {"target" => "worker", "text" => "Complete your assignment"})
      assert_equal "issued", result.dig("result", "submission")
      assert_equal({"target" => "term_2222", "text" => "Complete your assignment", "expected_origin" => @origin}, @sent.last["params"])
      refute result.dig("result", "agent").key?("agent_session")
      refute result["result"].key?("origin")
    end

    def test_worker_can_read_only_itself_and_cannot_prompt
      @identity.role = "worker"
      assert_raises(Error) { call("agent.get", {"target" => "worker"}) }
      @identity.terminal_id = "term_2222"
      assert_equal "worker", call("agent.get", {"target" => "worker"}).dig("result", "agent", "name")
      assert_raises(Error) { call("agent.prompt", {"target" => "worker", "text" => "Run"}) }
      refute @sent.any? { |request| request["method"] == "agent.prompt" }
    end

    def test_unavailable_or_host_runtime_cannot_receive_prompt
      [nil, @origin.merge("child" => {"uid" => 1000}), @origin.merge("terminal_id" => "term_3333")].each do |origin|
        @origin = origin
        assert_raises(Error) { call("agent.prompt", {"target" => "worker", "text" => "Run"}) }
      end
      refute @sent.any? { |request| request["method"] == "agent.prompt" }
    end

    def test_caller_cannot_supply_guard_wait_or_raw_command
      [{"expected_origin" => @origin}, {"wait" => {}}, {"argv" => ["sh"]}].each do |extra|
        assert_raises(Error) { call("agent.prompt", {"target" => "worker", "text" => "Run"}.merge(extra)) }
      end
      assert_empty @sent
    end
  end
end
