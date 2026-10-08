# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/cli/commands/inbox_settle"

module Ace
  module Assign
    class InboxSettleTest < AceAssignTestCase
      def test_public_command_requires_project_and_forwards_only_fixed_selectors
        options = {project: "ace", mapping: "mapping", assignment: "assignment", attempt: "attempt",
          inbox_context: "context", event: "event", evidence: "evidence", mutation: "mutation", expected_generation: "7"}
        calls = []
        context = Object.new
        context.define_singleton_method(:protected_participant?) { true }
        context.define_singleton_method(:verify_attempt_hints!) { |**selection| calls << selection }
        context.define_singleton_method(:client) { |**_| :client }
        context.define_singleton_method(:with_inbox_workflow) { |**_, &block| block.call(:deployment, :kernel, {"project_id" => "ace"}) }
        command = CLI::Commands::InboxSettle.new
        command.instance_variable_set(:@protected_assignment_context, context)
        signer = Object.new
        signer.define_singleton_method(:settle) { |**selection| calls << selection; {"state" => "completed"} }
        Authority::InboxObservationSigner.stub(:new, lambda { |**selection|
          assert_equal({client: :client, deployment: :deployment, kernel: :kernel}, selection)
          signer
        }) do
          output, = capture_io { command.call(**options) }
          assert_equal({"state" => "completed"}, JSON.parse(output))
          assert_equal 7, calls.last.fetch(:expected_generation)
          assert_equal "evidence", calls.last.fetch(:evidence_id)
          assert_raises(Ace::Support::Cli::Error) { command.call(**options.reject { |key, _| key == :project }) }
          assert_raises(Ace::Support::Cli::Error) { command.call(**options.merge(receipt: "/caller/proof")) }
          assert_raises(Ace::Support::Cli::Error) { command.call(**options.merge(expected_generation: "7e0")) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { command.call(**options.merge(project: "other")) }
        end
      end
    end
  end
end
