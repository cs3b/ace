# frozen_string_literal: true
require_relative "../../test_helper"
module Ace
  module Assign
    class ProtectedInboxReconcileTest < AceAssignTestCase
      def test_malformed_local_proof_never_sends_or_constructs_local_coordinator
        Dir.mktmpdir("inbox-input-") do |root|
          paths = %w[registration receipt signature].to_h { |name| [name, File.join(root, name)] }
          registration = {"attempt_id" => "attempt", "event_id" => "event", "payload_sha256" => "a" * 64, "receipt_key_sha256" => "b" * 64}
          calls = []
          client = Object.new
          client.define_singleton_method(:call) { |*args, **options| calls << [args, options] }
          context = Authority::ProtectedAssignmentContext.new(deployment: nil, history: nil, env: {})
          context.define_singleton_method(:protected_participant?) { true }
          context.define_singleton_method(:client) { |**_| client }
          argv = ["inbox-reconcile", "--mapping", "mapping", "--assignment", "assignment", "--attempt", "attempt",
            "--event", "event", "--inbox-context", "context", "--expected-generation", "7", "--mutation", "original",
            "--registration", paths.fetch("registration"), "--receipt", paths.fetch("receipt"), "--signature", paths.fetch("signature")]
          reset = lambda do
            File.binwrite(paths.fetch("registration"), JSON.generate(registration))
            File.binwrite(paths.fetch("receipt"), '{}')
            File.binwrite(paths.fetch("signature"), "detached bytes")
          end
          Authority::ProtectedAssignmentContext.stub(:load, context) do
            Organisms::AttemptCoordinator.stub(:new, ->(*) { flunk "local coordinator constructed" }) do
              reset.call
              File.binwrite(paths.fetch("registration"), JSON.generate(registration.merge("attempt_id" => "foreign")))
              error = assert_raises(Ace::Support::Cli::Error) { CLI.start(argv) }
              assert_equal "Registration selectors differ", error.message
              reset.call
              File.binwrite(paths.fetch("registration"), '{"attempt_id":"attempt","attempt_id":"attempt"}')
              assert_raises(Ace::Support::Cli::Error) { CLI.start(argv) }
              reset.call
              File.binwrite(paths.fetch("receipt"), '[]')
              assert_raises(Ace::Support::Cli::Error) { CLI.start(argv) }
              reset.call
              File.binwrite(paths.fetch("receipt"), '{"state":1,"state":2}')
              assert_raises(Ace::Support::Cli::Error) { CLI.start(argv) }
              reset.call
              File.binwrite(paths.fetch("signature"), '')
              assert_raises(Ace::Support::Cli::Error) { CLI.start(argv) }
              assert_empty calls
            end
          end
          absent = Authority::ProtectedAssignmentContext.new(deployment: nil, history: nil, env: {})
          Authority::ProtectedAssignmentContext.stub(:load, absent) do
            Organisms::AttemptCoordinator.stub(:new, ->(*) { flunk "local fallback constructed" }) do
              %w[registration signature inbox-context].each do |flag|
                assert_raises(Ace::Support::Cli::Error) { CLI.start(["inbox-reconcile", "--#{flag}", ""]) }
                assert_raises(Ace::Support::Cli::Error) { CLI.start(["inbox-reconcile", "--#{flag}", "selected"]) }
              end
            end
          end
        end
      end
    end
  end
end
