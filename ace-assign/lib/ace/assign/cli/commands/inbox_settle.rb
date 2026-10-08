# frozen_string_literal: true
require_relative "protected_submission"
require_relative "../../authority/inbox_observation_signer"

module Ace
  module Assign
    module CLI
      module Commands
        class InboxSettle < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include ProtectedSubmission
          desc "Settle a canonical native observation through the installed signer"
          option :project, desc: "Exact installed project"
          option :mapping, desc: "Exact installed mapping"
          option :assignment, desc: "Original assignment"
          option :attempt, desc: "Original attempt"
          option :inbox_context, desc: "Fixed Inbox context"
          option :event, desc: "Original event"
          option :evidence, desc: "Opaque authority observation ID"
          option :mutation, desc: "Stable original reconciliation mutation"
          option :expected_generation, desc: "Original authority generation"

          def call(**options)
            expected = %i[project mapping assignment attempt inbox_context event evidence mutation expected_generation]
            raise Ace::Support::Cli::Error, "inbox-settle requires exactly the fixed selectors" unless options.keys.sort == expected.sort
            usage = "inbox-settle --project ID --mapping ID --assignment ID --attempt ID --inbox-context ID --event ID --evidence ID --mutation ID --expected-generation N"
            expected.reject { |key| key == :expected_generation }.each { |key| require_option(options, key, usage) }
            generation = integer_option(options, :expected_generation, usage)
            context = protected_context(options)
            raise AttemptErrors::EvidenceUnavailable, "inbox-settle requires installed protected authority" unless context
            context.verify_attempt_hints!(assignment_id: options.fetch(:assignment), attempt_id: options.fetch(:attempt))
            context.with_inbox_workflow(options: options) do |deployment, kernel, mapping|
              unless mapping.fetch("project_id") == options.fetch(:project)
                raise AttemptErrors::EvidenceUnavailable, "installed signer project differs"
              end
              result = Ace::Assign::Authority::InboxObservationSigner.new(client: context.client(options: options),
                deployment: deployment, kernel: kernel).settle(assignment_id: options.fetch(:assignment),
                  attempt_id: options.fetch(:attempt), event_id: options.fetch(:event),
                  inbox_context_id: options.fetch(:inbox_context), evidence_id: options.fetch(:evidence),
                  mutation_id: options.fetch(:mutation), expected_generation: generation)
              emit_json(result)
            end
          end
        end
      end
    end
  end
end
