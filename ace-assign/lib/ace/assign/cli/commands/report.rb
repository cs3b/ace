# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Complete current phase with a report file
        class Report < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Complete current phase with report content"

          argument :file, required: true, desc: "Path to report file"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(file:, **options)
            executor = build_executor_for(options)
            result = executor.advance(file)

            unless options[:quiet]
              completed = result[:completed]
              puts "Phase #{completed.number} (#{completed.name}) completed"
              # Report the actual report file path, not the phase file
              assignment = result[:assignment]
              report_filename = Atoms::PhaseFileParser.generate_report_filename(completed.number, completed.name)
              report_path = File.join(assignment.reports_dir, report_filename)
              puts "Report saved to: #{report_path}"

              if result[:current]
                puts "Advancing to phase #{result[:current].number}: #{result[:current].name}"
                puts
                puts "Instructions:"
                puts result[:current].instructions
              else
                puts
                puts "Assignment completed! All phases done."
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
