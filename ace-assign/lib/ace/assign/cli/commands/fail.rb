# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Mark current step as failed
        class Fail < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          desc "Mark current step as failed"

          option :message, aliases: ["-m"], required: true, desc: "Error message"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(**options)
            message = options[:message]

            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            result = executor.fail(message)

            unless options[:quiet]
              failed = result[:failed]
              puts "Step #{failed.number} (#{failed.name}) marked as failed"
              puts "Updated: #{File.basename(failed.file_path)}"
              puts "Error: #{message}"
              puts
              puts "Options:"
              puts "- ace-assign add \"fix-step\" to add a fix step"
              puts "- ace-assign retry #{failed.number} to retry this step"
            end
          end

          private
        end
      end
    end
  end
end
