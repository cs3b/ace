# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/issuer_request"

module Ace
  module Lab
    module Auth
      class SessionLaunchRequestTest < Minitest::Test
        class Launcher
          attr_reader :events
          attr_accessor :handoff_error
          def initialize(events)
            @events = events
          end

          def start(unit:, terminal:)
            @events << :start
            @reader, writer = IO.pipe
            @pid = fork do
              @reader.close
              terminal.gets
              writer.close
              exit! 0
            end
            writer.close
            SessionLauncher::Launch.new(unit: unit.name, transport_pid: @pid)
          end

          def identify(launch)
            @events << :identify
            SessionLauncher::Identity.new(unit: launch.unit, invocation_id: "b" * 32, process: {}, pidfd: @reader, cgroup: {handle: @reader})
          end

          def handoff(*)
            @events << :handoff
            raise Error, "handoff failed" if handoff_error
          end

          def stop(_identity)
            @events << :stop
            Process.kill("TERM", @pid) unless IO.select([@reader], nil, nil, 0)
            true
          end
        end

        def setup
          @events = []
          @server, @client = UNIXSocket.pair
          @caller, @caller_writer = IO.pipe
          @launcher = Launcher.new(@events)
          @preparation = Object.new
          @mount = Object.new
          @service = Object.new
          events = @events
          @preparation.define_singleton_method(:call) { |**| events << :prepare }
          @mount.define_singleton_method(:call) { |**| events << :mount }
          @service.define_singleton_method(:revoke_session) { |**args| events << [:revoke, args] }
          @handler = SessionLaunchRequest.new(launcher: @launcher, preparation: @preparation,
            mount: @mount, service: -> { @service })
          @unit = SessionUnit.new(role: "worker", id: "0123456789abcdef", directory: "/lab/ace", command: ["/usr/bin/true"])
          @selection = SessionConfiguration::Selection.new(project: "ace", path: "/lab/ace", role: "worker",
            instructions: "/instructions", gem_home: "/gems", runtime: {})
        end

        def teardown
          [@server, @client, @caller, @caller_writer].each { |io| io.close unless io.closed? }
        end

        def run_session
          @handler.send(:run, @server, {"rows" => 24, "cols" => 80}, "a" * 32, @unit, @selection, @caller)
        end

        def test_natural_completion_confirms_whole_unit_stop_and_revocation_before_reply
          assert_equal :completed, run_session
          assert_equal [:start, :identify, :prepare, :mount, :handoff, :stop], @events.first(6)
          assert_equal [:revoke, {issuer_invocation: "a" * 32, unit: @unit.name, invocation: "b" * 32}], @events.last
          response = JSON.parse(@client.gets)
          assert_equal true, response.fetch("cleanup_confirmed")
          assert_equal 0, response.fetch("exit_code")
          assert_equal "b" * 32, response.fetch("invocation")
        end

        def test_preparation_failure_stops_gated_process_and_cleans_without_handoff
          @mount.define_singleton_method(:call) { |**| raise Error, "credential-secret-must-not-escape" }
          output, diagnostic = capture_io { assert_equal :refused, run_session }
          assert_empty output
          assert_equal({"event" => "session_launch_failed", "stage" => "mount",
            "error_class" => "Ace::Lab::Auth::Error", "contained" => true, "cleaned" => true},
            JSON.parse(diagnostic))
          refute_includes diagnostic, "credential-secret-must-not-escape"
          assert_includes @events, :stop
          refute_includes @events, :handoff
          assert_equal :revoke, @events.last.first
          assert_nil IO.select([@client], nil, nil, 0)
        end

        def test_handoff_failure_cleans_unit_and_never_reports_success
          @launcher.handoff_error = true
          assert_equal :refused, run_session
          assert_equal :stop, @events[-2]
          assert_equal :revoke, @events.last.first
          assert_nil IO.select([@client], nil, nil, 0)
        end

        def test_failed_revoke_never_produces_successful_terminal_outcome
          @service.define_singleton_method(:revoke_session) { |**| raise Error, "unconfirmed" }
          assert_equal :cleanup_failed, run_session
          assert_includes @events, :stop
          assert_nil IO.select([@client], nil, nil, 0)
        end

        def test_disconnected_native_client_does_not_fail_the_issuer_after_confirmed_cleanup
          @client.close
          assert_equal :refused, run_session
          assert_equal :stop, @events[-2]
          assert_equal :revoke, @events.last.first
        end

        def test_lifecycle_control_rejects_another_invocation
          main, keep_main = IO.pipe
          identity = SessionLauncher::Identity.new(unit: @unit.name, invocation_id: "b" * 32, process: {}, pidfd: main, cgroup: {handle: main})
          @client.puts JSON.generate("action" => "stop", "unit" => @unit.name, "invocation" => "c" * 32)
          assert_raises(Error) { @handler.send(:await_exit, @server, identity, @caller) }
        ensure
          main&.close
          keep_main&.close
        end
      end
    end
  end
end
