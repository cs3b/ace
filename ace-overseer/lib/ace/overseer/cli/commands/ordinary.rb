# frozen_string_literal: true

require_relative "../../organisms/ordinary_work_on"

module Ace
  module Overseer
    module CLI
      module Commands
        class Ordinary < Ace::Support::Cli::Command
          desc "Prepare, launch or resume one ordinary execution through installed Assign"
          option :operation, required: true, desc: "prepare, launch, status, resume (status/resume never dispatch)"
          option :project, required: true, desc: "Installed ordinary project ID"
          option :task, desc: "Reviewed leaf task for preparation"
          option :checkout, desc: "Explicit project checkout validated against installed common directory"
          option :output, desc: "New private retained input directory for preparation"
          option :provider, desc: "Explicit interactive provider/model/thinking selection"
          option :context, desc: "Original context.json for launch/status/resume"

          def call(operation:, project:, **options)
            entry = Organisms::OrdinaryWorkOn.new
            result = case operation
            when "prepare"
              entry.prepare(project: project, task: options.fetch(:task), checkout: options.fetch(:checkout),
                output: options.fetch(:output), provider: options.fetch(:provider))
            when "launch" then entry.launch(project: project, context: options.fetch(:context))
            when "status", "resume" then entry.resume(project: project, context: options.fetch(:context))
            else raise ArgumentError, "unknown ordinary operation"
            end
            puts JSON.generate(result)
          rescue ArgumentError, KeyError, SystemCallError, Ace::Overseer::Error, Ace::Assign::Error, Ace::Lab::Error, Ace::Runtime::Error, Ace::LLM::Error => error
            raise Ace::Support::Cli::Error, "ordinary handoff incomplete: #{error.message}; retain its inputs and inspect the original context"
          end
        end
      end
    end
  end
end
