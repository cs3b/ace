# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Complete current step with a report file
        class Report < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Complete current step with report content"

          argument :file, required: true, desc: "Path to report file"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(file:, **options)
            executor = Organisms::WorkflowExecutor.new
            result = executor.advance(file)

            unless options[:quiet]
              completed = result[:completed]
              puts "Step #{completed.number} (#{completed.name}) completed"
              # Report the actual report file path, not the job file
              session = result[:session]
              report_filename = Atoms::StepFileParser.generate_report_filename(completed.number, completed.name)
              report_path = File.join(session.reports_dir, report_filename)
              puts "Report saved to: #{report_path}"

              if result[:current]
                puts "Advancing to step #{result[:current].number}: #{result[:current].name}"
                puts
                puts "Instructions:"
                puts result[:current].instructions
              else
                puts
                puts "Session completed! All steps done."
              end
            end
          end
        end
      end
    end
  end
end
