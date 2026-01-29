# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Add a new step dynamically
        class Add < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Add a new step to the queue dynamically"

          argument :name, required: true, desc: "Step name"
          option :instructions, aliases: ["-i"], desc: "Step instructions"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(name:, **options)
            instructions = options[:instructions] || "Complete this step and report: ace-coworker report report.md"

            executor = Organisms::WorkflowExecutor.new
            result = executor.add(name, instructions)

            unless options[:quiet]
              added = result[:added]
              puts "Created: jobs/#{File.basename(added.file_path)}"
              puts "Status: #{added.status}"

              if added.status == :in_progress
                puts
                puts "Instructions:"
                puts added.instructions
              end
            end

            0
          rescue NoActiveSessionError => e
            puts "Error: #{e.message}"
            2
          rescue Error => e
            puts "Error: #{e.message}"
            1
          end
        end
      end
    end
  end
end
