# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/issuer_client"
require "timeout"
require "open3"

module Ace
  module Lab
    module Auth
      class IssuerClientTest < Minitest::Test
        def test_client_refusal_loads_without_service_in_a_fresh_process
          script = <<~RUBY
            require "ace/lab/auth/issuer_client"
            abort "unexpected service dependency" if defined?(Ace::Lab::Auth::Service)
            begin
              Ace::Lab::Auth::IssuerClient.new.reconcile
            rescue Ace::Lab::Auth::Refusal
              exit 0
            end
            abort "expected refusal"
          RUBY
          _, stderr, status = Open3.capture3(RbConfig.ruby, "-I", $LOAD_PATH.join(File::PATH_SEPARATOR), "-e", script)
          assert status.success?, stderr
        end

        def exchange(response)
          server, peer = UNIXSocket.pair
          client = IssuerClient.new
          client.define_singleton_method(:connect_verified) { |&block| block.call(peer) }
          observed = nil
          thread = Thread.new do
            observed = JSON.parse(server.gets)
            server.puts JSON.generate(response)
          end
          result = Timeout.timeout(3) { yield client }
          thread.value
          [result, observed]
        ensure
          server&.close
          peer&.close
          thread&.join(1)
        end

        def test_request_sends_scope_without_caller_claimed_identity
          result, message = exchange("ok" => true, "result" => {"id" => "lease"}) do |client|
            client.request(profile_name: "forge", role: "worker", task: "t", assignment: "a", repos: ["owner/repo"])
          end
          assert_equal({"id" => "lease"}, result)
          assert_equal %w[action assignment profile repos role task], message.keys.sort
          assert_equal "request", message["action"]
        end

        def test_readiness_sends_only_target_and_requires_native_boolean_acknowledgement
          response = {"id" => "ace-lab:readiness", "result" => {"type" => "agent_readiness", "ready" => true}}
          result, message = exchange(response) { |client| client.readiness(target: "term_1234") }
          assert result.fetch("ready")
          assert_equal({"target" => "term_1234"}, message.fetch("params"))
          assert_equal "agent.readiness", message.fetch("method")
          assert_raises(Refusal) do
            exchange(response.merge("id" => "foreign")) { |client| client.readiness(target: "term_1234") }
          end
          response["result"]["ready"] = "true"
          assert_raises(Refusal) { exchange(response) { |client| client.readiness(target: "term_1234") } }
        end

        def test_status_and_revoke_use_the_same_public_lease_id
          _, status = exchange("ok" => true, "result" => {"state" => "issued"}) { |client| client.status(lease_id: "lease") }
          result, revoke = exchange("ok" => true, "result" => {"cleanup" => "revoked"}) { |client| client.revoke(lease_id: "lease") }
          assert_equal "lease", status.fetch("lease")
          assert_equal "lease", revoke.fetch("lease")
          assert_equal :revoked, result
        end

        def test_refusal_is_not_treated_as_success
          assert_raises(Refusal) do
            exchange("ok" => false, "error" => "different session") { |client| client.status(lease_id: "foreign") }
          end
        end

        def test_session_cannot_force_terminal_cleanup_or_reconcile
          client = IssuerClient.new
          assert_raises(Refusal) { client.revoke(lease_id: "lease", force: true) }
          assert_raises(Refusal) { client.reconcile }
        end
      end
    end
  end
end
