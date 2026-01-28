# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Start a new workflow session from config file
        class Start < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Start a new workflow session from YAML config"

          option :config, aliases: ["-c"], required: true, desc: "Path to job.yaml config file"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(**options)
            config_path = options[:config]

            begin
              executor = Organisms::WorkflowExecutor.new
              result = executor.start(config_path)

              unless options[:quiet]
                print_session_header(result[:session])
                print_step_instructions(result[:current])
              end

              0
            rescue ConfigNotFoundError => e
              puts "Error: #{e.message}"
              3
            rescue Error => e
              puts "Error: #{e.message}"
              1
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
