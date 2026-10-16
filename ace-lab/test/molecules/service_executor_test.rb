# frozen_string_literal: true

require_relative "../test_helper"
require "socket"
require "rbconfig"

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
          policy = policy_for({"project" => "ace", "service_id" => "executor", "argv" => [executable],
            "executor_uid" => Process.uid, "lease_expires_at" => (Time.now.utc + 3600).iso8601})
          operation = policy.operation!("forge-sync", project: "ace", service_id: "executor")
          receipt = Molecules::ServiceExecutor.new.execute(operation: operation, request: request,
            input: {"target" => {"resource" => "release"}}, policy_loader: -> { policy }, head_loader: -> { request["candidate_head"] },
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
          policy = policy_for(operation)
          receipt = Molecules::ServiceExecutor.new.execute(operation: operation, request: request,
            input: {"target" => {"resource" => "release"}}, policy_loader: -> { policy }, head_loader: -> { request["candidate_head"] },
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
          policy = policy_for({"project" => "ace", "service_id" => "executor", "argv" => [executable],
            "executor_uid" => Process.uid, "lease_expires_at" => (Time.now.utc + 3600).iso8601})
          operation = policy.operation!("forge-sync", project: "ace", service_id: "executor")
          error = assert_raises(SecurityError) do
            Molecules::ServiceExecutor.new.execute(operation: operation, request: request,
              input: {"target" => {"resource" => "release"}},
              policy_loader: -> { policy },
              head_loader: -> { "c" * 40 }, authorization: "decision-1")
          end
          assert_includes error.message, "candidate head changed"
        end
      end

      def test_timeout_preserves_uncertainty_and_closes_descendant_resources
        with_descendant_handler(stall: true) do |operation, port_file|
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          assert_nil execute_local(operation)
          assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 5
          assert_descendant_closed(port_file)
        end
      end

      def test_successful_handler_does_not_leave_its_descendant_running
        with_descendant_handler(stall: false) do |operation, port_file|
          receipt = execute_local(operation)
          assert_equal "succeeded", receipt.fetch("outcome")
          assert_descendant_closed(port_file)
        end
      end

      def test_excess_stdout_or_stderr_cannot_be_accepted_as_a_receipt
        ["STDOUT", "STDERR"].each do |stream|
          operation = local_operation([RbConfig.ruby, "-e",
            "STDIN.read; #{stream}.write('x' * 20000); puts #{JSON.generate(response).inspect}"])
          assert_nil execute_local(operation)
        end
      end

      def test_post_launch_cleanup_failure_is_an_unknown_outcome
        process = Ace::Herdr::Molecules::BoundedProcess
        operation = local_operation([RbConfig.ruby, "-e", "exit 0"])
        process.stub(:call, ->(*) { raise process::PostLaunchError, "cleanup unconfirmed" }) do
          assert_nil execute_operation(operation)
        end
      end

      private

      def local_operation(argv)
        {"project" => "ace", "service_id" => "executor", "argv" => argv,
         "executor_uid" => Process.uid, "lease_expires_at" => (Time.now.utc + 3600).iso8601}
      end

      def execute_operation(operation)
        policy = policy_for(operation)
        Molecules::ServiceExecutor.new.execute(operation: operation, request: request, input: {},
          policy_loader: -> { policy }, head_loader: -> { request.fetch("candidate_head") }, authorization: "decision-1")
      end

      def execute_local(operation)
        process = Ace::Herdr::Molecules::BoundedProcess
        original = process.method(:call)
        process.stub(:call, ->(argv, **options) {
          assert_equal 30, options.fetch(:timeout_s)
          assert_equal true, options.fetch(:cleanup_group)
          original.call(argv, **options.merge(timeout_s: 1.0))
        }) { execute_operation(operation) }
      end

      def with_descendant_handler(stall:)
        Dir.mktmpdir do |dir|
          port_file = File.join(dir, "descendant-port")
          script = File.join(dir, "handler.rb")
          File.write(script, <<~RUBY)
            require "socket"
            STDIN.read
            ready, announce = IO.pipe
            fork do
              ready.close
              STDOUT.reopen(File::NULL, "w")
              STDERR.reopen(File::NULL, "w")
              server = TCPServer.new("127.0.0.1", 0)
              File.write(#{port_file.inspect}, server.addr[1].to_s)
              announce.write("ready")
              announce.close
              sleep 30
            end
            announce.close
            ready.read
            ready.close
            #{stall ? 'sleep 30' : "puts #{JSON.generate(response).inspect}"}
          RUBY
          yield local_operation([RbConfig.ruby, script]), port_file
        end
      end

      def assert_descendant_closed(port_file)
        port = Integer(File.read(port_file))
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 1
        loop do
          begin
            TCPSocket.open("127.0.0.1", port) { |socket| socket.close }
          rescue Errno::ECONNREFUSED
            assert true
            return
          rescue Errno::ECONNRESET
            # The kernel may reset an in-flight connect while the killed
            # descendant is closing; require the subsequent refused connect.
          end
          flunk "handler descendant still owns its listening socket" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          sleep 0.005
        end
      end
    end
  end
end
