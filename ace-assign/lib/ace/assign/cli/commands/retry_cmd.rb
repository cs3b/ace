# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Retry a failed phase (creates new phase linked to original)
        class RetryCmd < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Retry a phase by creating a new linked phase"

          argument :phase_ref, required: true, desc: "Phase number to retry (e.g., 040)"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(phase_ref:, **options)
            executor = build_executor_for(options)
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

          def build_executor_for(options)
            assignment_id = options[:assignment] || ENV["ACE_ASSIGN_ID"]
            return Organisms::AssignmentExecutor.new unless assignment_id

            manager = Molecules::AssignmentManager.new
            assignment = manager.load(assignment_id)
            raise AssignmentNotFoundError, "Assignment '#{assignment_id}' not found" unless assignment

            executor = Organisms::AssignmentExecutor.new
            executor.assignment_manager.define_singleton_method(:find_active) { assignment }
            executor
          end
        end
      end
    end
  end
end
