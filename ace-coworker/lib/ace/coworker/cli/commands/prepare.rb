# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Prepare a new job configuration file
        #
        # This command is a stub for future functionality.
        # Currently, it provides a helpful message directing users
        # to create job.yaml files manually or use workflows.
        class Prepare < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Prepare a new job configuration file (not yet implemented)"

          def call(**_options)
            puts "The 'prepare' command is not yet implemented."
            puts
            puts "To create a new workflow session:"
            puts "  1. Create a job.yaml file manually, or"
            puts "  2. Use the workflow: ace-bundle wfi://prepare-coworker-job"
            puts
            puts "Then run: ace-coworker create <path-to-job.yaml>"

            0
          end
        end
      end
    end
  end
end
