# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Mark current phase as failed
        class Fail < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Mark current phase as failed"

          option :message, aliases: ["-m"], required: true, desc: "Error message"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(**options)
            message = options[:message]

            executor = Organisms::AssignmentExecutor.new
            result = executor.fail(message)

            unless options[:quiet]
              failed = result[:failed]
              puts "Phase #{failed.number} (#{failed.name}) marked as failed"
              puts "Updated: #{File.basename(failed.file_path)}"
              puts "Error: #{message}"
              puts
              puts "Options:"
              puts "- ace-assign add \"fix-phase\" to add a fix phase"
              puts "- ace-assign retry #{failed.number} to retry this phase"
            end
          end
        end
      end
    end
  end
end
