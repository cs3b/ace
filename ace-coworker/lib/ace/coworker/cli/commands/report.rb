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
              puts "Report appended to: #{File.basename(completed.file_path)}"

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

            0
          rescue NoActiveSessionError => e
            puts "Error: #{e.message}"
            2
          rescue Error => e
            puts "Error: #{e.message}"
            if e.message.include?("not found")
              3
            else
              1
            end
          end
        end
      end
    end
  end
end
