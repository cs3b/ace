# frozen_string_literal: true
require_relative "../../../authority/prepared_task_context"

module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class InboxContextPrincipal < Ace::Support::Cli::Command
            desc "Classify the actual caller through every retained protected owner"

            def call(**options)
              raise ArgumentError, "fixed inbox context options differ" unless options.empty?
              consumer = Ace::Assign::Authority::PreparedTaskContext.new(context: @protected_assignment_context)
              $stdout.write(consumer.inbox_principal())
              0
            rescue ArgumentError, Ace::Runtime::Error, Ace::Assign::Error => error
              raise Ace::Support::Cli::Error, error.message
            end
          end
        end
      end
    end
  end
end
