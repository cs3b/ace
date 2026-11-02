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
          attr_reader :arguments
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
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32) }
          @client.write(JSON.generate("profile" => "forge", "role" => "developer", "task" => "t",
            "assignment" => "a", "repos" => ["owner/repo"]) + "\n")
          response = JSON.parse(@client.gets)
          assert response.fetch("ok")
          assert_equal "lease-test", response.fetch("lease").fetch("id")
          refute response.fetch("lease").key?("token_ref")
          assert_equal "", @client.read
          assert thread.alive?
          @main_writer.close
          assert_equal :session_ended, thread.value
          assert_equal ["owner/repo"], @service.arguments.fetch(:repos)
        end

        def test_rejects_unknown_request_fields_before_issuance
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32) }
          @client.write(JSON.generate("profile" => "forge", "uid" => 0) + "\n")
          response = JSON.parse(@client.gets)
          refute response.fetch("ok")
          assert_nil @service.arguments
          assert_equal :refused, thread.value
        end

        def test_lifecycle_lock_is_held_until_the_main_session_ends
          parent = Process.euid.zero? && RUBY_PLATFORM.include?("linux") ? "/run" : nil
          Dir.mktmpdir("ace-issuer-request-", parent) do |directory|
            store = LeaseStore.new(directory)
            @service.define_singleton_method(:store) { store }
            issuer = Thread.new { @runner.call(@server, invocation: "a" * 32) }
            @client.write(JSON.generate("profile" => "forge", "role" => "developer", "task" => "t",
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
          thread = Thread.new { @runner.call(@server, invocation: "a" * 32) }
          @client.write('{"profile":"forge","profile":"other","role":"worker","task":"t","assignment":"a","repos":["o/r"]}' + "\n")
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
