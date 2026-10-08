# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Assign
    class InboxObserveTest < AceAssignTestCase
      def test_public_command_forwards_exact_original_selectors_and_generations
        options = {project: "ace", mapping: "mapping", assignment: "assignment", attempt: "attempt",
          inbox_context: "context", event: "event", claim_generation: "2", mutation: "mutation", expected_generation: "7"}
        calls = []
        context = Object.new
        context.define_singleton_method(:protected_participant?) { true }
        context.define_singleton_method(:verify_attempt_hints!) { |**selection| calls << selection }
        context.define_singleton_method(:client) { |**_| :client }
        context.define_singleton_method(:with_inbox_workflow) do |**selection, &block|
          calls << selection
          block.call(:deployment, :kernel, {"project_id" => "ace"})
        end
        producer = Object.new
        producer.define_singleton_method(:observe) { |**selection| calls << selection; {"outcome" => "uncertain"} }
        command = CLI::Commands::InboxObserve.new
        command.instance_variable_set(:@protected_assignment_context, context)
        Authority::InboxObservationProducer.stub(:new, lambda { |**selection|
          assert_equal({client: :client, deployment: :deployment, kernel: :kernel}, selection)
          producer
        }) do
          output, = capture_io { command.call(**options) }
          assert_equal({"outcome" => "uncertain"}, JSON.parse(output))
          assert_equal({assignment_id: "assignment", attempt_id: "attempt", event_id: "event", inbox_context_id: "context",
            claim_generation: 2, mutation_id: "mutation", expected_generation: 7}, calls.last)
          assert_equal({assignment_id: "assignment", attempt_id: "attempt"}, calls.first)
          [:mapping, :project, :event].each do |missing|
            assert_raises(Ace::Support::Cli::Error) { command.call(**options.reject { |key, _| key == missing }) }
          end
          assert_raises(Ace::Support::Cli::Error) { command.call(**options.merge(observation: "/caller/evidence")) }
          assert_raises(Ace::Support::Cli::Error) { command.call(**options.merge(claim_generation: "0")) }
          assert_raises(Ace::Support::Cli::Error) { command.call(**options.merge(expected_generation: "7e0")) }
        end
      end
    end
  end
end
