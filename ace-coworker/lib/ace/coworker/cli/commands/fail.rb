# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Mark current step as failed
        class Fail < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Mark current step as failed"

          option :message, aliases: ["-m"], required: true, desc: "Error message"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(**options)
            message = options[:message]

            executor = Organisms::WorkflowExecutor.new
            result = executor.fail(message)

            unless options[:quiet]
              failed = result[:failed]
              puts "Step #{failed.number} (#{failed.name}) marked as failed"
              puts "Updated: #{File.basename(failed.file_path)}"
              puts "Error: #{message}"
              puts
              puts "Options:"
              puts "- ace-coworker add \"fix-step\" to add a fix step"
              puts "- ace-coworker retry #{failed.number} to retry this step"
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
