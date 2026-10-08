# frozen_string_literal: true
require_relative "../../../authority/prepared_task_context"

module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class InboxContextSelection < Ace::Support::Cli::Command
            desc "Read the fixed installed inbox context selection"
            option :project, required: true, desc: "Installed project ID"
            option :mapping, required: true, desc: "Installed mapping ID"
            option :inbox_context, required: true, desc: "Installed inbox context ID"

            def call(**options)
              raise ArgumentError, "fixed inbox context options differ" unless options.keys.sort == %i[inbox_context mapping project]
              consumer = Ace::Assign::Authority::PreparedTaskContext.new(context: @protected_assignment_context)
              $stdout.write(consumer.inbox_selection(**options))
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
