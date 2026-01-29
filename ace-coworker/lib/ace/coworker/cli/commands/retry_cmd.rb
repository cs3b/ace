# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Retry a failed step (creates new step linked to original)
        class RetryCmd < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Retry a step by creating a new linked step"

          argument :step_ref, required: true, desc: "Step number to retry (e.g., 040)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(step_ref:, **options)
            executor = Organisms::WorkflowExecutor.new
            result = executor.retry_step(step_ref)

            unless options[:quiet]
              retry_step = result[:retry]
              original = result[:original]

              puts "Created: jobs/#{File.basename(retry_step.file_path)} (retry of #{original.number})"
              puts "Original #{original.number}-#{original.name} preserved: #{original.status}"

              if result[:state].current && result[:state].current.number != retry_step.number
                puts "Note: Step #{result[:state].current.number} (#{result[:state].current.name}) must complete first"
              end
            end

            0
          rescue NoActiveSessionError => e
            puts "Error: #{e.message}"
            2
          rescue StepNotFoundError => e
            puts "Error: #{e.message}"
            4
          rescue Error => e
            puts "Error: #{e.message}"
            1
          end
        end
      end
    end
  end
end
