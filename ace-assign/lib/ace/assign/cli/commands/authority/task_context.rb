# frozen_string_literal: true
require_relative "../../../authority/prepared_task_context"

module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class TaskContext < Ace::Support::Cli::Command
            desc "Return the captured original task context through the fixed selected entry"
            option :mapping, required: true, desc: "Installed original mapping ID"
            option :assignment, required: true, desc: "Original assignment ID@SCOPE"
            option :attempt, required: true, desc: "Original protected attempt ID"
            option :task, required: true, desc: "Captured canonical task ID"

            def call(**options)
              unless options.keys.sort == %i[assignment attempt mapping task]
                raise ArgumentError, "fixed task-context accepts only its four selectors"
              end
              consumer = Ace::Assign::Authority::PreparedTaskContext.new(context: @protected_assignment_context)
              $stdout.write(consumer.call(**options))
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
