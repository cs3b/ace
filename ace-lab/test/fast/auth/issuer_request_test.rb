# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/issuer_request"
require "socket"
require "open3"
require "rbconfig"

module Ace
  module Lab
    module Auth
      class IssuerRequestTest < Minitest::Test
        class FakeService
          attr_reader :arguments, :revoked
          def status(lease_id:) = {"state" => "issued"}
          def revoke(lease_id:)
            @revoked = lease_id
            :revoked
          end
          def store = self
          def with_issuer_lifecycle_lock(exclusive:)
            raise "issuer must use shared lock" if exclusive
            yield
          end

          def request(**arguments)
            @arguments = arguments
            {"id" => "lease-test", "token_ref" => "private-reference", "use_until" => (Time.now.utc + 30).iso8601}
          end
        end

        def setup
          @server, @client = UNIXSocket.pair
          @main_reader, @main_writer = IO.pipe
          @peer_handle = File.open(File::NULL)
          @identity = SessionPeer::Identity.new(pidfd: @peer_handle, main_pidfd: @main_reader)
          @service = FakeService.new
          @runner = IssuerRequest.new(authenticate: ->(_socket) { @identity },
            service_factory: ->(_identity, _invocation) { @service })
        end

        def teardown
          [@client, @server, @main_reader, @main_writer, @peer_handle].each { |io| io.close unless io.closed? }
        end

        def test_returns_the_lease_then_waits_for_the_session_without_exposing_token_reference
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32, supervising: -> { true }) }
          @client.write(JSON.generate("action" => "request", "profile" => "forge", "role" => "developer", "task" => "t",
            "assignment" => "a", "repos" => ["owner/repo"]) + "\n")
          response = JSON.parse(@client.gets)
          assert response.fetch("ok")
          assert_equal "lease-test", response.fetch("result").fetch("id")
          refute response.fetch("result").key?("token_ref")
          assert_equal "", @client.read
          assert thread.alive?
          @main_writer.close
          assert_equal :session_ended, thread.value
          assert_equal ["owner/repo"], @service.arguments.fetch(:repos)
          assert_equal "lease-test", @service.revoked
        end

        def test_missing_supervisor_refuses_before_issuance
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32) }
          @client.puts JSON.generate("action" => "request", "profile" => "forge", "role" => "worker",
            "task" => "t", "assignment" => "a", "repos" => ["o/r"])
          response = JSON.parse(@client.gets)
          refute response.fetch("ok")
          assert_match(/supervision is unavailable/, response.fetch("error"))
          assert_nil @service.arguments
          assert_equal :refused, thread.value
        end

        def test_native_report_dispatch_authenticates_the_session_and_preserves_acknowledgement
          identity = Struct.new(:closed) { def close = self.closed = true }.new(false)
          report = {"id" => "r1", "method" => "pane.report_agent", "params" => {
            "pane_id" => "term_abcdef", "agent" => "pi", "source" => "herdr:pi", "seq" => 1, "state" => "idle"}}
          reports = Object.new
          reports.define_singleton_method(:call) do |request, identity:|
            raise "identity absent" unless identity
            {"id" => request["id"], "result" => {"type" => "ok"}}
          end
          runner = IssuerRequest.new(authenticate: ->(_) { identity }, reports: reports,
            service_factory: ->(*) { raise "report must not use lease store" })
          @client.puts JSON.generate(report)
          assert_equal :completed, runner.call(@server, invocation: "a" * 32)
          assert_equal({"id" => "r1", "result" => {"type" => "ok"}}, JSON.parse(@client.gets))
          assert identity.closed
        end

        def test_scoped_native_control_reaches_authenticated_handler
          control = Object.new
          expected = @identity
          control.define_singleton_method(:call) do |request, identity:|
            raise "wrong identity" unless identity.equal?(expected)
            {"id" => request.fetch("id"), "result" => {"type" => "agent_list", "agents" => []}}
          end
          runner = IssuerRequest.new(authenticate: ->(_) { @identity }, control: control,
            service_factory: ->(*) { raise "control must not use lease store" })
          @client.puts JSON.generate("id" => "list", "method" => "agent.list", "params" => {})
          assert_equal :completed, runner.call(@server, invocation: "a" * 32)
          assert_equal [], JSON.parse(@client.gets).dig("result", "agents")
        end

        def test_isolated_delegation_uses_original_authenticated_session
          identity = Struct.new(:closed) { def close = self.closed = true }.new(false)
          request = {"id" => "d1", "method" => "agent.start_isolated", "params" => {
            "name" => "assignment-a", "workspace_id" => "w1", "project" => "ace", "role" => "worker"}}
          observed = []
          delegate = Object.new
          delegate.define_singleton_method(:call) do |message, identity:|
            observed << [message, identity]
            {"id" => message["id"], "result" => {"type" => "agent_isolated_started"}}
          end
          runner = IssuerRequest.new(authenticate: ->(_) { identity }, delegate: delegate,
            service_factory: ->(*) { raise "delegation must not use lease store" })
          @client.puts JSON.generate(request)
          assert_equal :completed, runner.call(@server, invocation: "a" * 32)
          assert_equal [[request, identity]], observed
          assert_equal "agent_isolated_started", JSON.parse(@client.gets).dig("result", "type")
          assert identity.closed
        end

        def test_launch_dispatch_requires_closed_schema_and_supervision_without_using_lease_identity
          invoked = []
          launch = Object.new
          launch.define_singleton_method(:call) do |_socket, **args|
            invoked << args
            :completed
          end
          runner = IssuerRequest.new(authenticate: ->(*) { raise "lease authentication must not select host launches" }, launch: launch)
          request = {"action" => "launch", "project" => "ace", "role" => "worker", "rows" => 24, "cols" => 80, "terminal_id" => "term_abcdef"}
          @client.puts JSON.generate(request)
          assert_equal :completed, runner.call(@server, invocation: "a" * 32, supervising: -> { true })
          assert_equal request, invoked.fetch(0).fetch(:request)
          assert_equal "a" * 32, invoked.fetch(0).fetch(:invocation)
        end

        def test_launch_refuses_arbitrary_runtime_identity_and_dimensions
          [{"terminal_id" => "w1:p1"}, {"terminal_id" => nil}, {"argv" => ["/bin/sh"]}, {"uid" => 0}, {"rows" => 0}, {"cols" => 65_536}, {"role" => "root"}].each do |extra|
            server, client = UNIXSocket.pair
            client.puts JSON.generate({"action" => "launch", "project" => "ace", "role" => "worker", "rows" => 24, "cols" => 80}.merge(extra))
            runner = IssuerRequest.new(authenticate: ->(*) { raise "invalid request reached authentication" })
            assert_equal :refused, runner.call(server, invocation: "a" * 32, supervising: -> { true })
            refute JSON.parse(client.gets).fetch("ok")
          ensure
            server&.close unless server&.closed?
            client&.close unless client&.closed?
          end
        end

        def test_unknown_issuance_failure_stops_issuer_even_without_a_returned_lease
          @service.define_singleton_method(:request) { |**| raise UnresolvedIssuanceError, "recovery required" }
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32, supervising: -> { true }) }
          @client.puts JSON.generate("action" => "request", "profile" => "forge", "role" => "worker",
            "task" => "t", "assignment" => "a", "repos" => ["o/r"])
          response = JSON.parse(@client.gets)
          refute response.fetch("ok")
          assert_equal "issuer recovery is required", response.fetch("error")
          assert_equal :cleanup_failed, thread.value
        end

        def test_rejects_unknown_request_fields_before_issuance
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32, supervising: -> { true }) }
          @client.write(JSON.generate("action" => "request", "profile" => "forge", "uid" => 0) + "\n")
          response = JSON.parse(@client.gets)
          refute response.fetch("ok")
          assert_nil @service.arguments
          assert_equal :refused, thread.value
        end

        def test_failed_revocation_reports_supervision_failure
          @service.define_singleton_method(:revoke) { |lease_id:| :"revoke-pending" }
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32, supervising: -> { true }) }
          @client.puts JSON.generate("action" => "request", "profile" => "forge", "role" => "worker",
            "task" => "t", "assignment" => "a", "repos" => ["o/r"])
          assert JSON.parse(@client.gets).fetch("ok")
          @main_writer.close
          assert_equal :cleanup_failed, thread.value
        end

        def test_exec_receives_stdio_only_after_authentication_and_returns_real_result
          @service.define_singleton_method(:exec) do |lease_id:, argv:|
            STDOUT.write("worker-output")
            STDOUT.flush
            {"exit" => 7, "lease" => lease_id, "cleanup" => "revoked"}
          end
          pid = fork do
            @client.close
            @runner.call(@server, invocation: "a" * 32, supervising: -> { true })
            exit! 0
          end
          @server.close
          Dir.mktmpdir do |dir|
            File.open(File.join(dir, "output"), "w+") do |output|
              @client.puts JSON.generate("action" => "exec", "lease" => "lease-test", "argv" => ["git", "status"])
              assert_equal({"stdio" => true}, JSON.parse(@client.gets))
              File.open(File::NULL) { |input| @client.send_io(input) }
              @client.send_io(output)
              @client.send_io(output)
              result = JSON.parse(@client.gets)
              assert_equal 7, result.fetch("result").fetch("exit")
              output.rewind
              assert_equal "worker-output", output.read
            end
          end
          Process.waitpid(pid)
          pid = nil
        ensure
          if pid
            Process.kill("KILL", pid)
            Process.waitpid(pid)
          end
        end

        def test_plain_byte_in_place_of_descriptor_does_not_block_handler
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32, supervising: -> { true }) }
          @client.puts JSON.generate("action" => "exec", "lease" => "lease-test", "argv" => ["true"])
          assert_equal({"stdio" => true}, JSON.parse(@client.gets))
          @client.write("x")
          assert thread.join(1), "malformed descriptor input held the connection"
          refute JSON.parse(@client.gets).fetch("ok")
          assert_equal :refused, thread.value
        ensure
          @client.close unless @client.closed?
          thread&.join(6)
        end

        def test_oversized_status_returns_bounded_refusal
          @service.define_singleton_method(:status) { |lease_id:| [{"task" => "x" * 70_000}] }
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32, supervising: -> { true }) }
          @client.puts JSON.generate("action" => "status")
          response = @client.gets
          assert_operator response.bytesize, :<, 1024
          refute JSON.parse(response).fetch("ok")
          assert_equal :refused, thread.value
        end

        def test_lifecycle_lock_is_held_until_the_main_session_ends
          parent = Process.euid.zero? && RUBY_PLATFORM.include?("linux") ? "/run" : nil
          Dir.mktmpdir("ace-issuer-request-", parent) do |directory|
            store = LeaseStore.new(directory)
            @service.define_singleton_method(:store) { store }
            issuer = Thread.new { @runner.call(@server, invocation: "a" * 32, supervising: -> { true }) }
            @client.write(JSON.generate("action" => "request", "profile" => "forge", "role" => "developer", "task" => "t",
              "assignment" => "a", "repos" => ["owner/repo"]) + "\n")
            assert JSON.parse(@client.gets).fetch("ok")
            recovery = Thread.new { store.with_issuer_lifecycle_lock(exclusive: true) { :recovered } }
            assert_nil recovery.join(0.05)
            @main_writer.close
            assert_equal :session_ended, issuer.value
            assert_equal :recovered, recovery.value
          ensure
            @main_writer.close unless @main_writer.closed?
            issuer&.join(2)
            recovery&.join(2)
          end
        end

        def test_rejects_duplicate_json_keys_before_issuance
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32, supervising: -> { true }) }
          @client.write('{"action":"request","profile":"forge","profile":"other","role":"worker","task":"t","assignment":"a","repos":["o/r"]}' + "\n")
          refute JSON.parse(@client.gets).fetch("ok")
          assert_nil @service.arguments
          assert_equal :refused, thread.value
        end

        def test_reports_unavailable_peer_verification_without_attempting_issuance
          runner = IssuerRequest.new(authenticate: ->(_socket) { raise Ace::Runtime::RuntimeUnavailableError, "unavailable" },
            service_factory: ->(_identity, _invocation) { @service })
          thread = Thread.new { runner.call(@server, invocation: "a" * 32) }
          refute JSON.parse(@client.gets).fetch("ok")
          assert_nil @service.arguments
          assert_equal :refused, thread.value
        end

        def test_internal_entry_point_refuses_an_ordinary_input_pipe
          entry = File.expand_path("../../../libexec/issuer-request", __dir__)
          lib = File.expand_path("../../../lib", __dir__)
          _, stderr, status = Open3.capture3({"INVOCATION_ID" => "a" * 32}, RbConfig.ruby, "-I", lib, entry, stdin_data: "{}\n")
          refute status.success?
          assert_match(/activated stream socket/, stderr)
        end
      end
    end
  end
end
