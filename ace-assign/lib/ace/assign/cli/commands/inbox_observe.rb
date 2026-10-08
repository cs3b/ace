# frozen_string_literal: true

require_relative "protected_submission"
require_relative "../../authority/inbox_observation_producer"

module Ace
  module Assign
    module CLI
      module Commands
        class InboxObserve < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include ProtectedSubmission
          desc "Import an owner-verified native observation into the canonical assignment journal"
          option :project, desc: "Exact installed project ID"
          option :mapping, desc: "Exact installed mapping ID"
          option :assignment, desc: "Original assignment ID"
          option :attempt, desc: "Original attempt ID"
          option :inbox_context, desc: "Installed Inbox context ID"
          option :event, desc: "Original Inbox event ID"
          option :claim_generation, desc: "Original positive claim generation"
          option :mutation, desc: "Stable original import mutation ID"
          option :expected_generation, desc: "Original authority generation"

          def call(**options)
            expected = %i[project mapping assignment attempt inbox_context event claim_generation mutation expected_generation]
            unless options.keys.sort == expected.sort
              raise Ace::Support::Cli::Error, "inbox-observe requires exactly the fixed selectors"
            end
            context = protected_context(options)
            raise AttemptErrors::EvidenceUnavailable, "observation requires installed protected authority" unless context
            usage = "inbox-observe with explicit project/mapping/assignment/attempt/context/event and original generations/mutation"
            require_option(options, :project, usage)
            client, params, mutation = protected_attempt_request(context, options, usage)
            event = require_option(options, :event, usage)
            inbox_context = require_option(options, :inbox_context, usage)
            generation = integer_option(options, :claim_generation, usage, positive: true)
            context.with_inbox_workflow(options: options) do |deployment, kernel, _mapping|
              result = Ace::Assign::Authority::InboxObservationProducer.new(client: client, deployment: deployment, kernel: kernel).observe(
                assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), event_id: event,
                inbox_context_id: inbox_context, claim_generation: generation, mutation_id: mutation,
                expected_generation: params.fetch("expected_generation"))
              emit_json(result)
            end
          end
        end
      end
    end
  end
end
