# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Retry a failed phase (creates new phase linked to original)
        class RetryCmd < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base
          include AssignmentTarget

          desc "Retry a phase by creating a new linked phase"

          argument :phase_ref, required: true, desc: "Phase number to retry (e.g., 040)"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(phase_ref:, **options)
            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            result = executor.retry_phase(phase_ref)

            unless options[:quiet]
              retry_phase = result[:retry]
              original = result[:original]

              puts "Created: phases/#{File.basename(retry_phase.file_path)} (retry of #{original.number})"
              puts "Original #{original.number}-#{original.name} preserved: #{original.status}"

              if result[:state].current && result[:state].current.number != retry_phase.number
                puts "Note: Phase #{result[:state].current.number} (#{result[:state].current.name}) must complete first"
              end
            end
          end

          private
        end
      end
    end
  end
end
