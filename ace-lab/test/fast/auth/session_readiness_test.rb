# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_readiness"

module Ace::Lab::Auth
  class SessionReadinessTest < Minitest::Test
    def setup
      @dir = Dir.mktmpdir
      @path = File.join(@dir, "session.jsonl")
      File.write(@path, "private evidence")
      @caller = SessionPeer::Identity.new(role: "lab-overseer")
      @target = SessionPeer::Identity.new(role: "project-overseer", project_root: "/lab/ace",
        terminal_id: "term_1234", invocation_id: "a" * 32,
        pidfd: File.open(File::NULL), main_pidfd: File.open(File::NULL))
      @origin = {"terminal_id" => "term_1234", "runtime_incarnation" => "original",
        "child" => {"pid" => 123, "uid" => 62000, "started_at" => "birth"}}
      @agent = {"terminal_id" => "term_1234", "pane_id" => "w1:p2",
        "isolated_session" => {"project" => "ace", "role" => "project-overseer"},
        "agent_session" => {"agent" => "pi", "kind" => "path", "value" => @path}}
      @checks, @contexts, @calls = 0, [], []
      owner = self
      peer = Object.new
      peer.define_singleton_method(:authenticate_process) { |expected| owner.authenticate(expected) }
      peer.define_singleton_method(:live!) { |target| owner.live(target) }
      reader = Object.new
      reader.define_singleton_method(:open) { |path, identity:| owner.open(path, identity) }
      evaluator = Object.new
      evaluator.define_singleton_method(:call) { |context, file:| owner.evaluate(context, file) }
      transport = Object.new
      transport.define_singleton_method(:call) { |request, identity:| owner.native(request, identity) }
      @readiness = SessionReadiness.new(peer: peer, reader: reader, evaluator: evaluator, transport: transport,
        loader: -> { {"projects" => [{"id" => "ace", "path" => "/lab/ace"}]} })
    end

    def teardown
      @target.close
      FileUtils.remove_entry(@dir)
    end

    def authenticate(expected)
      assert_equal @origin["child"], expected
      @target
    end

    def live(target)
      assert_same @target, target
      @checks += 1
      raise Error, "session ended" if @fail_check == @checks
      true
    end

    def open(path, identity)
      assert_equal @path, path
      assert_same @target, identity
      @file = File.open(path, File::RDONLY)
    end

    def evaluate(context, file)
      assert_same @file, file
      @contexts << context
      @after = @agent.merge("agent_session" => @agent["agent_session"].merge("value" => "/changed")) if @replace
      true
    end

    def native(request, identity)
      assert_same @caller, identity
      @calls << request
      result = if request["method"] == "agent.get"
        {"agent" => @after || @agent}
      else
        {"process_info" => {"guarded_prompt" => true, "guarded_prompt_origin" => @origin}}
      end
      {"id" => request["id"], "result" => result}
    end

    def call = @readiness.call(agent: @agent, identity: @caller, request_id: "readiness")

    def test_evaluates_authenticated_target_and_closes_private_descriptor_and_handles
      result = call
      assert_equal({"ready" => true, "terminal_id" => "term_1234", "invocation_id" => "a" * 32, "root" => "/lab/ace", "role" => "project-overseer"}, result)
      assert_equal 4, @checks
      assert_equal @origin["child"], @contexts.first["process"]
      assert_equal "project-overseer", @contexts.first["role"]
      assert @file.closed?
      assert @target.pidfd.closed?
      refute result.key?("session_path")
    end

    def test_wrong_systemd_target_refuses_before_opening_file
      @target.project_root = "/lab/other"
      assert_raises(Error) { call }
      assert_nil @file
      assert_empty @contexts
    end

    def test_target_exit_after_open_cannot_produce_ready
      @fail_check = 2
      assert_raises(Error) { call }
      assert @file.closed?
      assert_empty @contexts
    end

    def test_replaced_session_path_during_evaluation_is_refused
      @replace = true
      assert_raises(Error) { call }
      assert @file.closed?
    end

    def test_no_reported_pi_session_is_not_ready
      @agent.delete("agent_session")
      refute call.fetch("ready")
      assert_nil @file
      assert_empty @contexts
    end
  end
end
