# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Retry a failed step (creates new step linked to original)
        class RetryCmd < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          desc "Retry a step by creating a new linked step"

          argument :step_ref, required: true, desc: "Step number to retry (e.g., 040)"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(step_ref:, **options)
            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            result = executor.retry_step(step_ref)

            unless options[:quiet]
              retry_step = result[:retry]
              original = result[:original]

              puts "Created: steps/#{File.basename(retry_step.file_path)} (retry of #{original.number})"
              puts "Original #{original.number}-#{original.name} preserved: #{original.status}"

              if result[:state].current && result[:state].current.number != retry_step.number
                puts "Note: Step #{result[:state].current.number} (#{result[:state].current.name}) must complete first"
              end
            end
          end

          private
        end
      end
    end
  end
end
