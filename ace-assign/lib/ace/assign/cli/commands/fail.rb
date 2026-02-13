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
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(**options)
            message = options[:message]

            executor = build_executor_for(options)
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
