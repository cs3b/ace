# frozen_string_literal: true
require_relative "../../../authority/prepared_task_context"

module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class TaskContextSelection < Ace::Support::Cli::Command
            desc "Return the authenticated original task-context entry without captured text"
            option :mapping, required: true, desc: "Installed original mapping ID"
            option :assignment, required: true, desc: "Original assignment ID@SCOPE"
            option :attempt, required: true, desc: "Original protected attempt ID"

            def call(**options)
              unless options.keys.sort == %i[assignment attempt mapping]
                raise ArgumentError, "fixed task-context-selection accepts only its three selectors"
              end
              consumer = Ace::Assign::Authority::PreparedTaskContext.new(context: @protected_assignment_context)
              $stdout.write(consumer.selection(**options))
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
