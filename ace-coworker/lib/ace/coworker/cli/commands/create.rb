# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Create a new workflow session from config file
        class Create < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Create a new workflow session from YAML config"

          argument :config, required: true, desc: "Path to job.yaml config file"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(config:, **options)
            executor = Organisms::WorkflowExecutor.new
            result = executor.start(config)

            unless options[:quiet]
              print_session_header(result[:session])
              print_step_instructions(result[:current])
            end
          end

          private

          def print_session_header(session)
            puts "Session: #{session.name} (#{session.id})"
            puts "Created: #{session.cache_dir}/"
            puts
          end

          def print_step_instructions(step)
            return unless step

            puts "Step #{step.number}: #{step.name} [#{step.status}]"
            puts
            puts "Instructions:"
            puts step.instructions
          end
        end
      end
    end
  end
end
