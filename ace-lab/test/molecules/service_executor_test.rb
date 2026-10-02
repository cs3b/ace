# frozen_string_literal: true

require_relative "../test_helper"
require "socket"

module Ace
  module Lab
    class ServiceExecutorTest < Minitest::Test
      def request
        {"request_id" => "req-1", "input_digest" => "a" * 64,
         "operation" => "forge-sync", "project_id" => "ace", "service_id" => "executor",
         "assignment_id" => "assignment-1", "attempt_id" => "attempt-1",
         "target" => {"resource" => "release"}, "candidate_head" => "b" * 40,
         "caller_uid" => Process.uid}
      end

      def policy_for(operation)
        Molecules::ServicePolicy.new("operations" => {"forge-sync" => operation},
          "authorizations" => {"decision-1" => request.merge("expires_at" => (Time.now.utc + 3600).iso8601)})
      end

      def response
        {"request_id" => "req-1", "input_digest" => "a" * 64,
         "outcome" => "succeeded", "evidence" => [{"ref" => "artifact/one", "sha256" => "b" * 64}]}
      end

      def test_fixed_local_argv_runs_under_actual_os_identity
        Dir.mktmpdir do |dir|
          executable = File.join(dir, "handler")
          script = <<~RUBY
            #!/usr/bin/env ruby
            require "json"
            input = JSON.parse(STDIN.read)
            puts JSON.generate(
              "request_id" => input.fetch("request").fetch("request_id"),
              "input_digest" => input.fetch("request").fetch("input_digest"),
              "outcome" => "succeeded",
              "evidence" => [{"ref" => "artifact/one", "sha256" => "#{'b' * 64}"}]
            )
          RUBY
          File.write(executable, script)
          File.chmod(0o700, executable)
          operation = {"project" => "ace", "service_id" => "executor", "argv" => [executable],
            "executor_uid" => Process.uid, "lease_expires_at" => (Time.now.utc + 3600).iso8601}
          receipt = Molecules::ServiceExecutor.new.execute(operation: operation, request: request,
            input: {"target" => {"resource" => "release"}}, policy_loader: -> { policy_for(operation) }, head_loader: -> { request["candidate_head"] },
            authorization: "decision-1")
          assert_equal "succeeded", receipt["outcome"]
          assert_equal Process.uid, receipt["executor_uid"]
          wrong_uid = operation.merge("executor_uid" => Process.uid + 1)
          assert_raises(Ace::Lab::InvalidConfigurationError) do
            Molecules::ServiceExecutor.new.execute(operation: wrong_uid, request: request, input: {},
              policy_loader: -> { policy_for(wrong_uid) }, head_loader: -> { request["candidate_head"] }, authorization: "decision-1")
          end
          expired = operation.merge("lease_expires_at" => (Time.now.utc - 1).iso8601)
          assert_raises(SecurityError) do
            Molecules::ServiceExecutor.new.execute(operation: expired, request: request, input: {},
              policy_loader: -> { policy_for(expired) }, head_loader: -> { request["candidate_head"] }, authorization: "decision-1")
          end
        end
      end

      def test_unix_transport_checks_peer_uid_and_receipt
        Dir.mktmpdir do |dir|
          path = File.join(dir, "service.sock")
          server = UNIXServer.new(path)
          thread = Thread.new do
            client = server.accept
            begin
              caller_uid, = client.getpeereid
              raise "unexpected caller" unless caller_uid == Process.uid
              payload = JSON.parse(client.gets)
              raise "unexpected request" unless payload.dig("request", "request_id") == "req-1"
              client.puts(JSON.generate(response))
            ensure
              client.close
            end
          end
          operation = {"project" => "ace", "service_id" => "executor", "transport" => "unix",
            "socket_path" => path, "executor_uid" => Process.uid,
            "lease_expires_at" => (Time.now.utc + 3600).iso8601}
          receipt = Molecules::ServiceExecutor.new.execute(operation: operation, request: request,
            input: {"target" => {"resource" => "release"}}, policy_loader: -> { policy_for(operation) }, head_loader: -> { request["candidate_head"] },
            authorization: "decision-1")
          assert_equal "succeeded", receipt["outcome"]
          thread.join
          server.close
        end
      end

      def test_policy_is_reloaded_at_the_effect_boundary
        Dir.mktmpdir do |dir|
          executable = File.join(dir, "handler")
          File.write(executable, "#!/usr/bin/env ruby\n")
          File.chmod(0o700, executable)
          operation = {"project" => "ace", "service_id" => "executor", "argv" => [executable],
            "executor_uid" => Process.uid, "lease_expires_at" => (Time.now.utc + 3600).iso8601}
          # The pre-claim operation snapshot is passed in, but the trusted
          # policy has since been revoked: the fresh read at dispatch is what
          # governs, and it no longer configures the operation.
          calls = 0
          loader = lambda do
            calls += 1
            Molecules::ServicePolicy.new("operations" => {}, "authorizations" => {})
          end
          error = assert_raises(SecurityError) do
            Molecules::ServiceExecutor.new.execute(operation: operation, request: request,
              input: {"target" => {"resource" => "release"}}, policy_loader: loader, head_loader: -> { request["candidate_head"] },
              authorization: "decision-1")
          end
          assert_includes error.message, "not configured"
          assert_equal 1, calls
        end
      end

      def test_candidate_head_is_revalidated_at_the_effect_boundary
        Dir.mktmpdir do |dir|
          executable = File.join(dir, "handler")
          File.write(executable, "#!/usr/bin/env ruby\n")
          File.chmod(0o700, executable)
          operation = {"project" => "ace", "service_id" => "executor", "argv" => [executable],
            "executor_uid" => Process.uid, "lease_expires_at" => (Time.now.utc + 3600).iso8601}
          error = assert_raises(SecurityError) do
            Molecules::ServiceExecutor.new.execute(operation: operation, request: request,
              input: {"target" => {"resource" => "release"}},
              policy_loader: -> { policy_for(operation) },
              head_loader: -> { "c" * 40 }, authorization: "decision-1")
          end
          assert_includes error.message, "candidate head changed"
        end
      end
    end
  end
end
