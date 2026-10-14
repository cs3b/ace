# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    # The serve entrypoint registration and its mode/selection refusals
    # (spec 8x3.t.xz9.4 serve entrypoint). The full listener lifecycle is
    # covered by OrdinaryListenEndToEndTest and the molecule tests.
    class ServiceListenCommandTest < Minitest::Test
      def test_listen_is_a_registered_service_command
        assert Ace::Lab::CLI::REGISTERED_COMMANDS.any? { |name, _| name == "service listen" }
        assert CLI::Commands::Service.const_defined?(:Listen)
      end

      def test_unknown_mode_refuses_before_any_configuration_load
        command = CLI::Commands::Service::Listen.new
        error = assert_raises(Ace::Support::Cli::Error) do
          capture_io do
            command.call(mode: "teleport", project: "atlas", config: "/nonexistent.yml")
          end
        end
        assert_includes error.message, "ordinary_merge_invalid_request"
      end

      def test_unreadable_configuration_is_the_unavailable_blocker
        command = CLI::Commands::Service::Listen.new
        error = assert_raises(Ace::Support::Cli::Error) do
          capture_io do
            command.call(mode: "ordinary-merge", project: "atlas",
              config: "/nonexistent/receiver.yml")
          end
        end
        assert_includes error.message, "ordinary_merge_unavailable"
      end

      def test_project_mismatch_refuses_as_selection_mismatch
        dir = Dir.mktmpdir("listen-cli")
        config = File.join(dir, "receiver.yml")
        File.write(config, YAML.safe_dump(
          "project" => "borealis", "receiver_id" => "ordinary-receiver",
          "socket_path" => "/tmp/x.sock", "receiver_uid" => Process.uid,
          "principal" => "overseer", "principal_uid" => Process.uid,
          "repo_path" => dir, "policy_path" => "/etc/lab/ace-lab/authorization.yml",
          "execution_identity" => {"checkout_id" => "c", "worktree_id" => "w",
                                   "branch" => "main"}
        ))
        command = CLI::Commands::Service::Listen.new
        error = assert_raises(Ace::Support::Cli::Error) do
          capture_io do
            command.call(mode: "ordinary-merge", project: "atlas", config: config)
          end
        end
        assert_includes error.message, "ordinary_merge_selection_mismatch"
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end
end
