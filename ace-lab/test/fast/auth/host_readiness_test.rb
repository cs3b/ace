# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/host_readiness"

module Ace::Lab::Auth
  class HostReadinessTest < Minitest::Test
    def setup
      @request = {"action" => "readiness", "project" => "ace", "role" => "project-overseer", "terminal_id" => "term_1234"}
      @events = []
      @uid = 1000
      @socket = Object.new
      owner = self
      @socket.define_singleton_method(:getsockopt) { |*_| Struct.new(:data).new([123, owner.uid, 1000].pack("i!3")) }
      @handle, @writer = IO.pipe
      @selection = SessionConfiguration::Selection.new(project: "ace", path: "/lab/ace", role: "project-overseer",
        instructions: "wfi://overseer/start", gem_home: "/opt/ace/gems", runtime: {})
      @agent = {"terminal_id" => "term_1234", "isolated_session" => {"project" => "ace", "role" => "project-overseer"}}
      peer = Object.new
      peer.define_singleton_method(:with_selection) { |socket, **args, &block| owner.select(socket, args, block) }
      transport = Object.new
      transport.define_singleton_method(:call) { |request, identity:| owner.native(request, identity) }
      readiness = Object.new
      readiness.define_singleton_method(:call) { |**args| owner.evaluate(args) }
      @handler = HostReadiness.new(peer: peer, transport: transport, readiness: readiness)
    end

    attr_reader :uid
    def teardown = [@handle, @writer].each { |io| io.close unless io.closed? }

    def select(socket, args, block)
      assert_same @socket, socket
      assert_equal({project: "ace", role: "project-overseer"}, args)
      @events << :authorize
      raise Refusal, "not granted" if @refuse
      block.call(@selection, @handle)
    end

    def native(request, identity)
      @events << :native
      assert_equal "agent.get", request.fetch("method")
      assert_equal({"target" => "term_1234"}, request.fetch("params"))
      assert_kind_of SessionNativeTransport::HostCaller, identity
      assert_same @handle, identity.pidfd
      {"id" => request.fetch("id"), "result" => {"agent" => @agent}}
    end

    def evaluate(args)
      @events << :evaluate
      assert_same @agent, args.fetch(:agent)
      {"ready" => false, "terminal_id" => "term_1234", "root" => "/lab/ace", "role" => "project-overseer"}
    end

    def test_operator_grant_precedes_lookup_and_owner_evaluation
      refute @handler.call(@socket, request: @request).fetch("ready")
      assert_equal %i[authorize native evaluate], @events
    end

    def test_ungranted_host_cannot_observe_native_target
      @refuse = true
      assert_raises(Refusal) { @handler.call(@socket, request: @request) }
      assert_equal [:authorize], @events
    end

    def test_dynamic_session_cannot_use_operator_route
      @uid = 62000
      assert_raises(Refusal) { @handler.call(@socket, request: @request) }
      assert_empty @events
    end

    def test_target_scope_mismatch_never_opens_private_evidence
      @agent["isolated_session"]["project"] = "other"
      assert_raises(Error) { @handler.call(@socket, request: @request) }
      assert_equal %i[authorize native], @events
    end

    def test_closed_schema_rejects_names_runtime_and_identity_overrides
      [{"terminal_id" => "overseer"}, {"role" => "worker"}, {"uid" => 1000}, {"command" => "sh"}].each do |extra|
        assert_raises(Error) { @handler.call(@socket, request: @request.merge(extra)) }
      end
      assert_empty @events
    end

    def test_native_host_lifetime_rejects_exited_or_closed_handle
      transport = SessionNativeTransport.new
      caller = SessionNativeTransport::HostCaller.new(pidfd: @handle)
      assert transport.send(:live!, caller)
      @writer.close
      assert_raises(Error) { transport.send(:live!, caller) }
      @handle.close
      assert_raises(Error) { transport.send(:live!, caller) }
    end
  end
end
