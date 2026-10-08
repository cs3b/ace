# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Assign
    class ProtectedAttemptCommandsTest < AceAssignTestCase
      def installed_context
        deployment = Object.new
        deployment.define_singleton_method(:data) do
          {"authorities" => {"authority" => {"uid" => 4001}}, "launch_mappings" => {}, "projects" => {}}
        end
        history = Object.new
        history.define_singleton_method(:descriptors) { [] }
        Authority::ProtectedAssignmentContext.new(deployment: deployment, history: history, uid: 4001, env: {})
      end

      def without_local_authority
        Authority::ProtectedAssignmentContext.stub(:load, installed_context) do
          Organisms::AttemptCoordinator.stub(:new, ->(*) { flunk "protected participant loaded local coordinator" }) do
            yield
          end
        end
      end

      def test_installed_authority_never_uses_local_receipt_or_local_recovery
        without_local_authority do
          %w[finish reconcile].each do |operation|
            error = assert_raises(Ace::Support::Cli::Error) do
              CLI.start(["attempt", operation, "--attempt", "original", "--receipt", "local.json"])
            end
            assert_match(/forbids --receipt/, error.message)
          end
          assert_raises(Ace::Support::Cli::Error) do
            CLI.start(["attempt", "reconcile", "--attempt", "original"])
          end
          assert_raises(Ace::Support::Cli::Error) { CLI.start(["inbox-bind"]) }
        end
      end

      def test_explicit_empty_protected_flag_never_falls_back_to_local_receipt
        context = Authority::ProtectedAssignmentContext.new(deployment: nil, history: nil, env: {})
        Authority::ProtectedAssignmentContext.stub(:load, context) do
          Organisms::AttemptCoordinator.stub(:new, ->(*) { flunk "empty protected selector loaded local coordinator" }) do
            %w[finish reconcile].each do |operation|
              error = assert_raises(Ace::Support::Cli::Error) do
                CLI.start(["attempt", operation, "--mapping", "", "--attempt", "original", "--receipt", "local.json"])
              end
              assert_match(/invalid argument|Empty protected/, error.message)
            end
            [CLI::Commands::Attempt::Finish, CLI::Commands::Attempt::Reconcile].each do |command|
              error = assert_raises(Ace::Support::Cli::Error) { command.new.call(mapping: "", attempt: "original", receipt: "local.json") }
              assert_match(/Empty protected/, error.message)
            end
          end
        end
      end

      def test_protected_transport_errors_are_classified_without_retry_or_local_authority
        common = ["--mapping", "mapping", "--assignment", "assignment", "--attempt", "attempt",
          "--mutation", "original", "--expected-generation", "1"]
        commands = [["attempt", "reconcile", *common], ["attempt", "finish", *common, "--result", "result", "--head", "a" * 40,
          "--candidate-generation", "1"], ["inbox-bind", *common, "--event", "event", "--inbox-context", "context"]]
        [SecurityError, Ace::Runtime::RuntimeUnavailableError].each do |failure|
          commands.each do |args|
            context = installed_context
            calls = 0
            client = Object.new
            client.define_singleton_method(:call) do |*_, **_|
              calls += 1
              raise failure, "private injected diagnostic"
            end
            context.define_singleton_method(:client) { |**_| client }
            Authority::ProtectedAssignmentContext.stub(:load, context) do
              Organisms::AttemptCoordinator.stub(:new, ->(*) { flunk "transport refusal loaded local coordinator" }) do
                error = assert_raises(Ace::Support::Cli::Error) { CLI.start(args) }
                assert_equal 5, error.exit_code
                assert_instance_of failure, error.cause
                assert_match(/outcome unavailable/, error.message)
                refute_match(/private injected diagnostic/, error.message)
                assert_equal 1, calls
              end
            end
          end
        end
      end
    end
  end
end
