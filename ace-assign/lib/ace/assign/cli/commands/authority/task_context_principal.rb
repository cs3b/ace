# frozen_string_literal: true
require_relative "../../../authority/prepared_task_context"

module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class TaskContextPrincipal < Ace::Support::Cli::Command
            desc "Classify this actual caller through the installed and retained protected owners"

            def call(**options)
              raise ArgumentError, "fixed task-context-principal accepts no options" unless options.empty?
              consumer = Ace::Assign::Authority::PreparedTaskContext.new(context: @protected_assignment_context)
              $stdout.write(consumer.principal)
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
