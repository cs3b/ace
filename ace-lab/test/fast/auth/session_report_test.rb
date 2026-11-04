# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_report"

module Ace::Lab::Auth
  class SessionReportTest < Minitest::Test
    def setup
      @identity = SessionPeer::Identity.new(terminal_id: "term_abcdef", runtime_dir: "/run/ace-auth-1234567890abcdef")
      @request = {"id" => "report-1", "method" => "pane.report_agent", "params" => {
        "pane_id" => "term_abcdef", "agent" => "pi", "source" => "herdr:pi", "seq" => 1, "state" => "working"}}
    end

    def test_transport_checks_endpoint_and_live_invocation_before_forwarding
      worker = nil
      wire = Ace::Runtime::Molecules::ProtectedSocket
      client, server = UNIXSocket.pair
      reader, writer = IO.pipe
      @identity.pidfd = reader
      @identity.main_pidfd = reader
      @identity.unit = "ace-auth-session-worker-1234567890abcdef.service"
      @identity.invocation_id = "a" * 32
      manager = Object.new
      binding = {"unit" => @identity.unit, "invocation_id" => @identity.invocation_id}
      manager.define_singleton_method(:unit_for_pidfd) { |**| binding }
      client.define_singleton_method(:getsockopt) { |*| Struct.new(:data).new([123, 1001, 1001].pack("i!3")) }
      endpoint = {"account" => "mo", "socket" => "/run/lab/herdr.sock"}
      reporter = SessionReport.new(loader: -> { {"session_runtime" => {"herdr" => endpoint}} },
        account: ->(_) { Struct.new(:uid, :gid).new(1001, 1001) }, manager: ->(_) { manager })
      connector = ->(_path, **_options, &block) { block.call(client) }
      wire.stub(:root_path!, true) do
        wire.stub(:socket_identity, [1, 2, 1001]) do
          wire.stub(:connect, connector) do
            binding["invocation_id"] = "b" * 32
            assert_raises(Error) { reporter.call(@request, identity: @identity) }
            assert_nil IO.select([server], nil, nil, 0), "stale session must not write to native"
            binding["invocation_id"] = "a" * 32
            worker = Thread.new do
              observed = JSON.parse(server.gets)
              server.puts JSON.generate("id" => observed["id"], "result" => {"type" => "ok"})
              observed
            end
            assert_equal({"id" => "report-1", "result" => {"type" => "ok"}}, reporter.call(@request, identity: @identity))
            assert_equal @request, worker.value
            writer.close
            assert_raises(Error) { reporter.call(@request, identity: @identity) }
            assert_nil IO.select([server], nil, nil, 0)
          end
        end
      end
    ensure
      [client, server, reader, writer].compact.each { |io| io.close unless io.closed? }
      worker&.join
    end

    def test_own_report_is_projected_without_mutating_input
      original = Marshal.load(Marshal.dump(@request))
      result = SessionReport.project(@request, identity: @identity)
      assert_equal original, result
      refute_same @request["params"], result["params"]
      assert_equal original, @request
    end

    def test_no_binding_or_wrong_terminal_never_falls_back_to_pane_alias
      @identity.terminal_id = nil
      assert_raises(Error) { SessionReport.project(@request, identity: @identity) }
      @identity.terminal_id = "term_abcdef1"
      assert_raises(Error) { SessionReport.project(@request, identity: @identity) }
    end

    def test_execution_and_foreign_session_fields_are_refused
      [{"resume_argv" => ["/bin/sh"]}, {"source" => "other"}, {"agent" => "shell"},
        {"seq" => 1.5}, {"state" => "done"}, {"agent_session_path" => "/home/mo/private"},
        {"agent_session_path" => "/run/ace-auth-1234567890abcdef/pi/sessions/../auth.json"}].each do |extra|
        request = @request.merge("params" => @request["params"].merge(extra))
        assert_raises(Error) { SessionReport.project(request, identity: @identity) }
      end
      assert_raises(Error) { SessionReport.project(@request.merge("method" => "pane.run"), identity: @identity) }
    end

    def test_session_report_keeps_only_a_path_inside_its_private_runtime
      params = @request["params"].reject { |key, _| key == "state" }.merge(
        "agent_session_path" => "/run/ace-auth-1234567890abcdef/pi/sessions/project/session.jsonl")
      request = @request.merge("method" => "pane.report_agent_session", "params" => params)
      assert_equal request, SessionReport.project(request, identity: @identity)
      assert_raises(Error) { SessionReport.project(request.merge("unexpected" => true), identity: @identity) }
    end
  end
end
